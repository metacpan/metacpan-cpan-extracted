#!/usr/bin/env perl
# ABSTRACT: A raid can be cancelled: it stops at the next safe point and abandons the model call or tool it waits for (ADR 0009)
use strict;
use warnings;
use Test2::V0;
use Future;
use IO::Async::Loop;
use Langertha::Raider;

my $loop = IO::Async::Loop->new;

{
  package CancelResponse;
  use Moose;
  sub is_success  { 1 }
  sub status_line { '200 OK' }
  sub content     { '' }
  __PACKAGE__->meta->make_immutable;
}

{
  # Tools of a raid: call_tool runs $CODE{$name}, which returns a Future.
  package CancelMCP;
  use Moose;
  has code  => (is => 'ro', default => sub { {} });
  has calls => (is => 'ro', default => sub { [] });
  sub list_tools { Future->done([ map { { name => $_ } } sort keys %{ $_[0]->code } ]) }
  sub call_tool {
    my ( $self, $name, $input ) = @_;
    push @{ $self->calls }, $name;
    return $self->code->{$name}->($input);
  }
  __PACKAGE__->meta->make_immutable;
}

{
  # A duck-typed engine answering from a script: each entry is a hash
  # { tool_calls => [ [ name, input ], ... ] } or { text => ... }, or
  # 'hang' for a request that never completes (its future is kept, to see
  # whether it was cancelled).
  package CancelEngine;
  use Moose;
  has script      => (is => 'rw', default => sub { [] });
  has mcp_servers => (is => 'ro', default => sub { [] });
  has requests    => (is => 'rw', default => 0);
  has pending     => (is => 'rw');
  has _next       => (is => 'rw');

  sub async_loop { $loop }
  sub async_request_f {
    my ( $self ) = @_;
    $self->requests($self->requests + 1);
    my $step = shift @{ $self->script } // { text => 'done' };
    if (!ref $step && $step eq 'hang') {
      my $f = $loop->new_future;
      $self->pending($f);
      return $f;
    }
    $self->_next($step);
    return $loop->delay_future(after => 0.01)->then_done(CancelResponse->new);
  }
  sub build_tool_chat_request { return { request => 1 } }
  sub parse_response          { return $_[0]->_next }
  sub response_tool_calls     { return $_[1]->{tool_calls} // [] }
  sub response_text_content   { return $_[1]->{text} }
  sub extract_tool_call       { return @{ $_[1] } }
  sub format_tools            { return $_[1] }
  sub format_tool_results     { return map { { role => 'tool', content => 'r' } } @{ $_[2] } }
  sub think_tag_filter        { 0 }
  sub chat_model              { 'cancel-model' }
  __PACKAGE__->meta->make_immutable;
}

sub raider {
  my ( %o ) = @_;
  my $mcp = CancelMCP->new(code => $o{tools} // { noop => sub { Future->done({ content => [] }) } });
  my $engine = CancelEngine->new(script => $o{script} // [], mcp_servers => [ $mcp ]);
  my @events;
  my $raider = Langertha::Raider->new(
    engine                => $engine,
    no_session_embeddings => 1,
    plugins               => [ '+Langertha::Raider::Plugin::Events', { on_event => sub { push @events, [ @_ ] } } ],
  );
  return ( $raider, $engine, $mcp, \@events );
}

# Runs the raid on the loop; a hang fails the test instead of CI.
sub raid {
  my ( $raider, @setup ) = @_;
  my $f = $raider->raid_f('hi');
  my $ok = eval {
    local $SIG{ALRM} = sub { die "TIMEOUT: raid hung\n" };
    alarm 10;
    $loop->await($f);
    alarm 0;
    1;
  };
  alarm 0;
  die $@ unless $ok;
  return $f->get;
}

sub cancel_after {
  my ( $raider, $seconds ) = @_;
  $loop->watch_time(after => $seconds, code => sub { $raider->cancel });
}

subtest 'cancelled while the model answers: the request is abandoned' => sub {
  my ( $raider, $engine ) = raider(script => [ 'hang' ]);
  cancel_after($raider, 0.2);
  my $r = raid($raider);
  ok($r->is_cancelled, 'the raid ends cancelled');
  is($r->type, 'cancelled', 'type cancelled');
  ok($engine->pending->is_cancelled, 'the request future was cancelled');
  is($raider->history, [], 'nothing added to the history');

  my $next = raid($raider);
  ok($next->is_final, 'the next raid is not cancelled');
  is("$next", 'done', 'and answers');
  is(scalar @{ $raider->history }, 2, 'that one is in the history');
};

subtest 'cancelled while a tool runs: the call gets a cancelled result, no further model call' => sub {
  my $tool_f;
  my ( $raider, $engine, $mcp, $events ) = raider(
    script => [ { tool_calls => [ [ slow => {} ], [ never => {} ] ] } ],
    tools  => {
      slow  => sub { $tool_f = $loop->new_future },
      never => sub { Future->done({ content => [] }) },
    },
  );
  cancel_after($raider, 0.2);
  my $r = raid($raider);
  ok($r->is_cancelled, 'cancelled');
  is($mcp->calls, [ 'slow' ], 'the second tool never ran');
  is($engine->requests, 1, 'no model call after the cancel');
  ok($tool_f->is_cancelled, 'the tool future was cancelled');
  is([ map { [ $_->[0], { @$_[1 .. $#$_] }->{status} ] } @$events ],
    [ [ 'tool.call', 'dispatched' ], [ 'tool.result', 'cancelled' ] ], 'tool.result cancelled');
  is($raider->metrics->{tool_calls}, 1, 'the cut-off call counts');
  is($raider->metrics->{raids}, 0, 'the raid does not count as done');
};

subtest 'cancelled by a tool that finishes: the next tool does not run' => sub {
  my $raider;
  ( $raider, my $engine, my $mcp, my $events ) = raider(
    script => [ { tool_calls => [ [ first => {} ], [ second => {} ] ] } ],
    tools  => {
      first  => sub { $raider->cancel; Future->done({ content => [ { type => 'text', text => 'ok' } ] }) },
      second => sub { Future->done({ content => [] }) },
    },
  );
  my $r = raid($raider);
  ok($r->is_cancelled, 'cancelled');
  is($mcp->calls, [ 'first' ], 'only the first tool ran');
  is($engine->requests, 1, 'no model call after it');
  is([ map { { @$_[1 .. $#$_] }->{status} } grep { $_->[0] eq 'tool.result' } @$events ], [ 'succeeded' ],
    'its result is kept as it was');
};

subtest 'a tool that fails once the cancel is requested: reported cancelled' => sub {
  # The tool ends with an error right after the cancel, before the loop
  # sees it -- as when the tool subprocess was ended by the canceller.
  for my $how (qw( error fail )) {
    my $tool_f;
    my ( $raider, $engine, $mcp, $events ) = raider(
      script => [ { tool_calls => [ [ slow => {} ], [ never => {} ] ] } ],
      tools  => {
        slow  => sub { $tool_f = $loop->new_future },
        never => sub { Future->done({ content => [] }) },
      },
    );
    $loop->watch_time(after => 0.2, code => sub {
      $raider->cancel;
      $how eq 'error'
        ? $tool_f->done({ content => [ { type => 'text', text => 'killed by SIGTERM' } ], isError => 1 })
        : $tool_f->fail('connection lost');
    });
    my $r = raid($raider);
    ok($r->is_cancelled, $how.': cancelled');
    is($mcp->calls, [ 'slow' ], $how.': the second tool never ran');
    is([ map { [ $_->[0], { @$_[1 .. $#$_] }->{status} ] } @$events ],
      [ [ 'tool.call', 'dispatched' ], [ 'tool.result', 'cancelled' ] ], $how.': tool.result cancelled, not failed');
  }
};

subtest 'a cancel before the raid starts ends it before the first model call' => sub {
  my ( $raider, $engine ) = raider();
  $raider->cancel;
  ok($raider->cancel_requested, 'requested');
  ok(raid($raider)->is_cancelled, 'the raid ends cancelled');
  is($engine->requests, 0, 'without a model call');
  ok(!$raider->cancel_requested, 'the request is used up');
  ok(raid($raider)->is_final, 'the next raid runs');

  $raider->cancel;
  $raider->clear_cancel;
  ok(!$raider->cancel_requested, 'clear_cancel drops a pending request');
  ok(raid($raider)->is_final, 'so the raid runs');
};

subtest 'cancel from a signal handler while the loop waits' => sub {
  my ( $raider, $engine ) = raider(script => [ 'hang' ]);
  local $SIG{USR1} = sub { $raider->cancel };
  my $parent = $$;
  my $pid = fork // die 'fork: '.$!;
  unless ($pid) {
    select undef, undef, undef, 0.3;
    kill USR1 => $parent;
    require POSIX;
    POSIX::_exit(0);
  }
  my $r = raid($raider);
  waitpid $pid, 0;
  ok($r->is_cancelled, 'cancelled by the signal');
  ok($engine->pending->is_cancelled, 'the request abandoned');
};

done_testing;
