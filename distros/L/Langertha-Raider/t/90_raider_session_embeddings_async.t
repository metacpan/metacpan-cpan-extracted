#!/usr/bin/env perl
# ABSTRACT: Session history embeddings run in the background on the raid's loop
use strict;
use warnings;
use Log::Any::Test;
use Log::Any qw( $log );
use Test2::Bundle::More;
use Future;
use IO::Async::Loop;
use IO::Async::Loop::Poll;
use Langertha::Raider;

# The raider embeds every session_history entry through simple_embedding_f and
# never waits for it (k24): the raid goes on while the embedding is in flight,
# the slot is reserved at once and filled when the vector lands, and only if
# the slot still belongs to the same entry by then.

{
  package LoopResponse;
  use Moose;
  sub is_success  { 1 }
  sub status_line { '200 OK' }
  sub content     { '' }
  __PACKAGE__->meta->make_immutable;
}

{
  # A duck-typed turn engine whose HTTP futures complete only while its loop runs.
  package LoopEngine;
  use Moose;
  has loop => (is => 'ro');
  sub async_loop  { $_[0]->loop }
  sub mcp_servers { [] }
  sub async_request_f {
    my ( $self ) = @_;
    return ( $self->loop // IO::Async::Loop->new )
      ->delay_future(after => 0.01)->then_done(LoopResponse->new);
  }
  sub build_tool_chat_request { return { request => 1 } }
  sub parse_response          { return { text => 'done' } }
  sub response_tool_calls     { return [] }
  sub response_text_content   { return $_[1]->{text} }
  sub format_tools            { return $_[1] }
  sub think_tag_filter        { 0 }
  __PACKAGE__->meta->make_immutable;
}

{
  # An embedding engine that answers only when the test says so: while `hold`
  # is set every simple_embedding_f returns a pending future, recorded in
  # `pending` as [ text, future ].
  package HeldEmbedder;
  use Moose;
  use Future;
  my @VOCAB = qw( aardvark zebra narwhal tusk berlin weather );

  has loop    => (is => 'ro');
  has hold    => (is => 'rw', default => 1);
  has pending => (is => 'ro', default => sub { [] });

  sub async_loop { $_[0]->loop }

  sub vector {
    my ( $self, $text ) = @_;
    my $lc = lc $text;
    return [ map { scalar( () = $lc =~ /\Q$_\E/g ) } @VOCAB ];
  }

  sub simple_embedding_f {
    my ( $self, $text ) = @_;
    return Future->done($self->vector($text)) unless $self->hold;
    my $f = ( $self->loop // IO::Async::Loop->new )->new_future;
    push @{$self->pending}, [ $text, $f ];
    return $f;
  }

  # Completes the held request for $text with its vector.
  sub release {
    my ( $self, $text ) = @_;
    for my $p (@{$self->pending}) {
      next unless $p->[0] eq $text && !$p->[1]->is_ready;
      $p->[1]->done($self->vector($text));
      return 1;
    }
    return 0;
  }
  __PACKAGE__->meta->make_immutable;
}

# A raid needs at least one tool.
sub new_raider {
  my ( %args ) = @_;
  return Langertha::Raider->new(
    tools => [ {
      name => 'noop', description => 'no-op',
      input_schema => { type => 'object', properties => {} },
      code => sub { $_[0]->text_result('ok') },
    } ],
    %args,
  );
}

sub raid_with_timeout {
  my ( $raider ) = @_;
  my $result = eval {
    local $SIG{ALRM} = sub { die "TIMEOUT: raid hung\n" };
    alarm 5;
    my $r = $raider->raid('aardvark question');
    alarm 0;
    $r;
  };
  alarm 0;
  return ( $result, $@ );
}

subtest 'a raid is not held up by an embedding still in flight' => sub {
  my $loop     = IO::Async::Loop->new;
  my $embedder = HeldEmbedder->new;
  my $raider   = new_raider(
    engine           => LoopEngine->new,
    embedding_engine => $embedder,
  );

  # The loop keeps turning while the raid runs: a timer set before it fires.
  my $ticked = 0;
  my $tick = $loop->delay_future(after => 0.001)->on_done(sub { $ticked++ });

  my ( $result, $err ) = raid_with_timeout($raider);
  is($err, '', 'the raid finishes');
  is("$result", 'done', 'with the final answer');
  ok($ticked, 'the reactor ran a timer during the raid');

  is(scalar @{$raider->session_history}, 2, 'user input and answer in the history');
  is(scalar @{$raider->_session_embeddings}, 2, 'one slot reserved per entry');
  is(scalar( grep { defined } @{$raider->_session_embeddings} ), 0,
    'no vector yet: both embeddings are still in flight');
  is(scalar keys %{$raider->_pending_embeddings}, 2,
    'the raider holds both in-flight futures');

  ok($embedder->release('aardvark question'), 'the first embedding lands');
  is_deeply($raider->_session_embeddings->[0], $embedder->vector('aardvark question'),
    'its vector fills slot 0');
  is($raider->_session_embeddings->[1], undef, 'slot 1 is still waiting');
  is(scalar keys %{$raider->_pending_embeddings}, 1, 'the landed future is let go');
};

subtest 'a failed embedding is logged and leaves its slot undef' => sub {
  $log->clear;
  my $embedder = HeldEmbedder->new;
  my $raider = new_raider(
    engine           => LoopEngine->new,
    embedding_engine => $embedder,
  );
  $raider->add_session_history({ role => 'user', content => 'zebra' });
  $embedder->pending->[0][1]->fail("backend down\n");
  is(scalar @{$raider->_session_embeddings}, 1, 'the slot stays');
  is($raider->_session_embeddings->[0], undef, 'without a vector');
  $log->contains_ok(qr/session history embedding failed: backend down/, 'the failure is logged');
  is(scalar keys %{$raider->_pending_embeddings}, 0, 'and the future is let go');

  my ( $result, $err ) = raid_with_timeout($raider);
  $embedder->pending->[$_][1]->fail("still down\n") for 1..2;
  is($err, '', 'failing embeddings never break a raid');
};

subtest 'an in-flight fill survives clear_session_history' => sub {
  my $embedder = HeldEmbedder->new;
  my $raider = new_raider(
    engine           => LoopEngine->new,
    embedding_engine => $embedder,
  );
  $raider->add_session_history({ role => 'user', content => 'berlin weather' });
  my $old = $embedder->pending->[0][1];

  $raider->clear_session_history;
  ok($old->is_cancelled, 'the in-flight embedding of a cleared entry is cancelled');
  is(scalar keys %{$raider->_pending_embeddings}, 0, 'nothing is held any more');

  $raider->add_session_history({ role => 'user', content => 'narwhal tusk' });
  ok($embedder->release('narwhal tusk'), 'the new entry is embedded');
  is(scalar @{$raider->_session_embeddings}, scalar @{$raider->session_history},
    'the 1:1 invariant holds');
  is_deeply($raider->_session_embeddings->[0], $embedder->vector('narwhal tusk'),
    'slot 0 holds the vector of the entry now at 0');
};

subtest 'a late vector never lands on an entry that replaced its own' => sub {
  my $embedder = HeldEmbedder->new;
  my $raider = new_raider(
    engine           => LoopEngine->new,
    embedding_engine => $embedder,
  );
  $raider->add_session_history({ role => 'user', content => 'berlin weather' });

  # Public ArrayRefs: code outside the raider can swap an entry in place and
  # keep the two arrays the same length.
  $raider->session_history->[0] = { role => 'user', content => 'zebra' };
  ok($embedder->release('berlin weather'), 'the old embedding lands late');
  is($raider->_session_embeddings->[0], undef,
    'its vector is dropped: slot 0 belongs to another entry now');
};

subtest 'search works with partly filled slots' => sub {
  my $embedder = HeldEmbedder->new;
  my $raider = new_raider(
    engine           => LoopEngine->new,
    embedding_engine => $embedder,
    raider_mcp       => 1,
  );
  $raider->add_session_history(
    { role => 'user',      content => 'aardvark migration' },
    { role => 'assistant', content => 'narwhal tusk measurements' },
    { role => 'assistant', content => 'narwhal tusk and zebra notes' },
  );
  ok($embedder->release('aardvark migration'), 'slot 0 filled');
  ok($embedder->release('narwhal tusk measurements'), 'slot 1 filled');

  $embedder->hold(0);   # the query embedding answers at once
  my $text = $raider->_query_session_history_f({ search => 'narwhal tusk' })->get;
  my @hits = split /\n\n/, $text;
  like($hits[0], qr/narwhal tusk measurements/, 'the embedded match ranks first');
  unlike($text, qr/zebra notes/, 'the entry still in flight is not scored, not waited for');
  is(scalar @hits, 2, 'only the embedded entries are ranked');
};

subtest 'the embedding engine must share the raid loop' => sub {
  my $main  = LoopEngine->new(loop => IO::Async::Loop::Poll->new);
  my $embed = HeldEmbedder->new(loop => IO::Async::Loop::Poll->new);

  my ( $result, $err ) = raid_with_timeout(new_raider(
    engine => $main, embedding_engine => $embed));
  unlike($err, qr/TIMEOUT/, 'no hang');
  like($err, qr/embedding_engine.*different event loop/s,
    'croaks naming the embedding engine');
  is(scalar @{$embed->pending}, 0, 'nothing was embedded');

  ( $result, $err ) = raid_with_timeout(new_raider(
    engine => $main, embedding_engine => $embed, no_session_embeddings => 1));
  is($err, '', 'no_session_embeddings leaves it out of the check');
  is("$result", 'done', 'and the raid runs');
  is(scalar @{$embed->pending}, 0, 'without embedding anything');

  my $shared = LoopEngine->new(loop => $embed->loop);
  ( $result, $err ) = raid_with_timeout(new_raider(
    engine => $shared, embedding_engine => $embed));
  is($err, '', 'an embedding engine on the same loop is fine');
};

done_testing;
