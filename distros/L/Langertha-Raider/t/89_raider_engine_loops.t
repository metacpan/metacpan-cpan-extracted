#!/usr/bin/env perl
# ABSTRACT: Every engine of one raider must run on the same event loop
use strict;
use warnings;
use Test2::Bundle::More;
use IO::Async::Loop;
use IO::Async::Loop::Poll;
use Langertha::Raider;

# A raid awaits the futures of every engine it uses: engine / active_engine for
# the turns, compression_engine for auto-compression, the inline MCP on the
# engine's loop (ADR 0028 in core). One ->get drives exactly one IO::Async
# loop, so engines on two different loops (injected clients on foreign loops)
# leave the raid waiting forever on a loop nobody runs (core karr k228). Raider
# refuses such a configuration at raid start with a clear error; engines
# without a loop (sync fallback) share the process-wide IO::Async::Loop->new,
# so the default setup is unaffected.

{
  package LoopResponse;
  use Moose;
  sub is_success  { 1 }
  sub status_line { '200 OK' }
  sub content     { '' }
  __PACKAGE__->meta->make_immutable;
}

{
  # A duck-typed engine whose HTTP futures complete only when its own loop runs.
  package LoopEngine;
  use Moose;
  has loop     => (is => 'ro');   # undef: sync fallback, no loop
  has requests => (is => 'rw', default => 0);

  sub async_loop  { $_[0]->loop }
  sub mcp_servers { [] }
  sub async_request_f {
    my ( $self ) = @_;
    $self->requests($self->requests + 1);
    my $loop = $self->loop // IO::Async::Loop->new;
    return $loop->delay_future(after => 0.01)->then_done(LoopResponse->new);
  }
  sub chat_request            { return { request => 1 } }
  sub build_tool_chat_request { return { request => 1 } }
  sub parse_response          { return { text => 'done' } }
  sub response_tool_calls     { return [] }
  sub response_text_content   { return $_[1]->{text} }
  sub format_tools            { return $_[1] }
  sub think_tag_filter        { 0 }
  __PACKAGE__->meta->make_immutable;
}

my @inline_tools = ({
  name => 'noop', description => 'no-op',
  input_schema => { type => 'object', properties => {} },
  code => sub { $_[0]->text_result('ok') },
});

# Compression goes first on its engine, the turn follows on the main engine.
sub compressing_raider {
  my ( %engines ) = @_;
  return Langertha::Raider->new(
    %engines,
    no_session_embeddings => 1,
    tools                 => \@inline_tools,
    history               => [ { role => 'user', content => 'old turn' } ],
    max_context_tokens    => 10,
    _last_prompt_tokens   => 100,
  );
}

# Runs the raid with an alarm, so a hang fails the test instead of CI.
sub raid_with_timeout {
  my ( $raider ) = @_;
  my $result = eval {
    local $SIG{ALRM} = sub { die "TIMEOUT: raid hung\n" };
    alarm 5;
    my $r = $raider->raid('hi');
    alarm 0;
    $r;
  };
  alarm 0;
  return ( $result, $@ );
}

subtest 'engines on two foreign loops: refused at raid start, not hung' => sub {
  my $main  = LoopEngine->new(loop => IO::Async::Loop::Poll->new);
  my $compr = LoopEngine->new(loop => IO::Async::Loop::Poll->new);
  isnt($main->async_loop, $compr->async_loop, 'two distinct loops');

  my ( $result, $err ) = raid_with_timeout(
    compressing_raider(engine => $main, compression_engine => $compr));
  unlike($err, qr/TIMEOUT/, 'the raid does not hang');
  like($err, qr/compression_engine.*different event loop/s,
    'croaks naming the engine on the other loop');
  is($compr->requests + $main->requests, 0, 'no request was sent');
};

subtest 'catalog engine on a foreign loop is refused too' => sub {
  my $main  = LoopEngine->new(loop => IO::Async::Loop::Poll->new);
  my $other = LoopEngine->new(loop => IO::Async::Loop::Poll->new);
  my $raider = Langertha::Raider->new(
    engine                => $main,
    engine_catalog        => { other => { engine => $other } },
    no_session_embeddings => 1,
    tools                 => \@inline_tools,
  );
  my ( $result, $err ) = raid_with_timeout($raider);
  like($err, qr/engine_catalog 'other'.*different event loop/s, 'catalog engine named');
};

subtest 'default: engines without a loop share the process-wide loop' => sub {
  my $main  = LoopEngine->new;
  my $compr = LoopEngine->new(loop => IO::Async::Loop->new);
  my $raider = compressing_raider(engine => $main, compression_engine => $compr,
    engine_catalog => { again => { engine => LoopEngine->new } });
  my ( $result, $err ) = raid_with_timeout($raider);
  is($err, '', 'no error');
  is("$result", 'done', 'raid completes');
  is($compr->requests, 1, 'compression ran on the compression engine');
  is($main->requests, 1, 'the turn ran on the main engine');
};

subtest 'several engines on one shared foreign loop work' => sub {
  my $loop  = IO::Async::Loop::Poll->new;
  my $main  = LoopEngine->new(loop => $loop);
  my $compr = LoopEngine->new(loop => $loop);
  my ( $result, $err ) = raid_with_timeout(
    compressing_raider(engine => $main, compression_engine => $compr));
  is($err, '', 'no error');
  is("$result", 'done', 'raid completes');
  is($compr->requests + $main->requests, 2, 'both engines were used');
};

done_testing;
