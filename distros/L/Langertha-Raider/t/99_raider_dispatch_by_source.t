#!/usr/bin/env perl
# ABSTRACT: Tool dispatch follows the actual tool source, not the raider_ prefix (karr k93)
use strict;
use warnings;
use Test2::V0;

use Future;
use IO::Async::Loop;
use Langertha::Raider;

# karr k93: the two dispatch sites (main loop and respond_f) routed any call whose
# name matched /^raider_/ to _execute_self_tool_f BEFORE consulting the assembled
# tool set. An MCP source may offer a raider_-prefixed name and win the first-wins
# dedup (karr k90); it is then registered in tool_server_map and announced to the
# model as that MCP tool -- but the old dispatch still sent it to the self-tool
# executor, which died with "Unknown self-tool" (it is not a real self-tool).
# Dispatch must follow the registration: a raider_-prefixed name that an MCP source
# owns goes to that source; a genuine self-tool keeps going to _execute_self_tool_f.

# --- Fake MCP server: offers a raider_-prefixed tool and records every call ---

{
  package FakeMCP;
  use Moose;
  use Future;

  has tools => (is => 'ro', required => 1);              # ArrayRef of tool-def HashRefs
  has calls => (is => 'ro', default => sub { [] });      # [ name, input ] per call_tool

  sub list_tools { return Future->done($_[0]->tools) }
  sub call_tool {
    my ( $self, $name, $input ) = @_;
    push @{$self->calls}, [ $name, $input ];
    return Future->done({ content => [ { type => 'text', text => "pong:$name" } ] });
  }

  __PACKAGE__->meta->make_immutable;
}

# --- Scripted in-process engine driving the real raid loop, no network. Each
#     parse_response returns the next turn from a per-instance script. ---

{
  package ScriptEngine::Response;
  use Moose;
  sub is_success  { 1 }
  sub status_line { '200 OK' }
  sub content     { '' }
  __PACKAGE__->meta->make_immutable;
}

{
  package ScriptEngine;
  use Moose;
  with 'Langertha::Role::Tools';

  has chat_model     => (is => 'ro', default => 'script-model');
  has '+mcp_servers' => (default => sub { [] });
  has turns          => (is => 'ro', required => 1);   # ArrayRef of $data HashRefs
  has _turn_idx      => (is => 'rw', default => 0);
  has _loop          => (is => 'ro', lazy => 1, default => sub { IO::Async::Loop->new });

  sub async_request_f { return $_[0]->_loop->new_future->done(ScriptEngine::Response->new) }
  sub async_loop      { return $_[0]->_loop }

  sub format_tools          { return $_[1] }
  sub response_tool_calls   { return $_[1]->{tool_calls} // [] }
  sub response_text_content { return $_[1]->{text} // 'final' }
  sub extract_tool_call     { return ($_[1]->{name}, $_[1]->{input}) }
  sub think_tag_filter      { 0 }
  sub format_tool_results   {
    my ( $self, $data, $results ) = @_;
    return map { { role => 'tool', content => 'r' } } @$results;
  }
  sub build_tool_chat_request { return { request => 1 } }

  sub parse_response {
    my ( $self ) = @_;
    my $i = $self->_turn_idx;
    $self->_turn_idx($i + 1);
    return $self->turns->[$i] // $self->turns->[-1];
  }

  __PACKAGE__->meta->make_immutable;
}

# Runs a code ref under an alarm so a dispatch bug that hangs (rather than dies)
# still fails loudly instead of stalling the suite.
sub guarded {
  my ( $code ) = @_;
  my ( $result, $err );
  {
    local $@;
    $result = eval {
      local $SIG{ALRM} = sub { die "TIMEOUT: raid hung\n" };
      alarm 5;
      my $r = $code->();
      alarm 0;
      $r;
    };
    $err = $@;
    alarm 0;
  }
  return ( $result, $err );
}

# --- Main loop: a raider_ MCP tool dispatches to its MCP source ---

subtest 'main loop: raider_-prefixed MCP tool routes to the MCP source' => sub {
  my $mcp = FakeMCP->new(tools => [ { name => 'raider_ping', src => 'mcp' } ]);
  my $engine = ScriptEngine->new(
    mcp_servers => [ $mcp ],
    turns       => [
      { tool_calls => [ { name => 'raider_ping', input => { n => 1 } } ] },
      { text => 'all done' },
    ],
  );
  my $raider = Langertha::Raider->new(
    engine                => $engine,
    no_session_embeddings => 1,
    raider_mcp            => { ask_user => 1 },   # has_raider_mcp true: old code would self-route
  );

  my ( $result, $err ) = guarded(sub { $raider->raid('go') });
  unlike($err, qr/TIMEOUT/, 'the raid does not hang');
  unlike($err, qr/Unknown self-tool/, 'no "Unknown self-tool" death');  # red before fix
  is($err, '', 'the raid does not die');
  ok($result->is_final, 'the raid runs to a final result');
  is("$result", 'all done', 'the raid completes');

  is(scalar @{$mcp->calls}, 1, 'the MCP source received exactly one call');   # red before fix: 0
  is($mcp->calls->[0], [ 'raider_ping', { n => 1 } ],
    'the raider_-prefixed call reached the MCP source with its arguments');
};

# --- Main loop: a genuine self-tool still routes to the self-tool executor ---

subtest 'main loop: genuine self-tool still routes to the self-tool executor' => sub {
  # The MCP source coexists (offering its own raider_ tool), but the model calls
  # the real self-tool raider_ask_user, which no source registered.
  my $mcp = FakeMCP->new(tools => [ { name => 'raider_ping', src => 'mcp' } ]);
  my $engine = ScriptEngine->new(
    mcp_servers => [ $mcp ],
    turns       => [
      { tool_calls => [ { name => 'raider_ask_user', input => { question => 'go?' } } ] },
      { text => 'unreachable' },
    ],
  );
  my $raider = Langertha::Raider->new(
    engine                => $engine,
    no_session_embeddings => 1,
    raider_mcp            => { ask_user => 1 },
  );

  my ( $result, $err ) = guarded(sub { $raider->raid('go') });
  is($err, '', 'the raid does not die');
  ok($result->is_question, 'the genuine self-tool paused the raid with a question');
  is($result->content, 'go?', 'the question text came from the self-tool executor');
  is(scalar @{$mcp->calls}, 0, 'the self-tool never went to the MCP source');
};

# --- respond_f: a raider_ MCP tool in the resumed batch routes to its source ---

subtest 'respond_f: raider_-prefixed MCP tool in the resumed batch routes to the MCP source' => sub {
  my $mcp = FakeMCP->new(tools => [ { name => 'raider_ping', src => 'mcp' } ]);
  # First turn: a genuine self-tool that pauses (ask_user) FOLLOWED by the MCP
  # raider_ tool, so the MCP call is left pending and handled by respond_f.
  my $engine = ScriptEngine->new(
    mcp_servers => [ $mcp ],
    turns       => [
      { tool_calls => [
        { name => 'raider_ask_user', input => { question => 'go?' } },
        { name => 'raider_ping',     input => { n => 2 } },
      ] },
      { text => 'resumed done' },
    ],
  );
  my $raider = Langertha::Raider->new(
    engine                => $engine,
    no_session_embeddings => 1,
    raider_mcp            => { ask_user => 1 },
  );

  my ( $q, $qerr ) = guarded(sub { $raider->raid('go') });
  is($qerr, '', 'the first turn does not die');
  ok($q->is_question, 'the raid pauses on the ask_user self-tool');
  is(scalar @{$mcp->calls}, 0, 'the pending MCP call has not run yet');

  my ( $result, $err ) = guarded(sub { $raider->respond('yes') });
  unlike($err, qr/Unknown self-tool/, 'no "Unknown self-tool" death on resume');  # red before fix
  is($err, '', 'the resume does not die');
  ok($result->is_final, 'the resumed raid runs to a final result');
  is("$result", 'resumed done', 'the resumed raid completes');

  is(scalar @{$mcp->calls}, 1, 'the MCP source received the resumed call');   # red before fix: 0
  is($mcp->calls->[0], [ 'raider_ping', { n => 2 } ],
    'the resumed raider_-prefixed call reached the MCP source with its arguments');
};

done_testing;
