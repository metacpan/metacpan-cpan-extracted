#!/usr/bin/env perl
# ABSTRACT: An undecodable tool call yields an isError result, not a run on {}
use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use HTTP::Response;
use Langertha::Engine::OpenAI;
use Langertha::Raider;

# karr k345: a tool call whose arguments the model did not send as valid JSON
# decodes to {}. On a reply that hit its token limit the call is dropped upstream
# (k85 / core tool_loop_calls). This is the OTHER case — a reply that did NOT hit
# its token limit but still carried undecodable arguments: Raider used to run the
# tool on {} anyway. It now answers such a call with the same isError result core
# does ("arguments are not valid JSON: ...") and the raid keeps going, so the
# model can retry, instead of the tool acting on empty arguments.
#
# This needs a real engine carrying the tool_loop_response hook, so the call
# reaches the dispatch as a Langertha::ToolCall with arguments_undecodable set.
# The duck-typed engines in the other raid-loop tests take the legacy fallback
# path, where that flag is not tracked.

plan skip_all => 'this Langertha has no public tool_loop_response hook'
  unless Langertha::Engine::OpenAI->can('tool_loop_response')
      && Langertha::Engine::OpenAI->can('chat_response');

{
  # A real OpenAI engine whose only overrides are the HTTP round trip (a canned
  # 200 per turn) and recording each conversation it is asked to send; parsing,
  # chat_response and tool_loop_response stay the genuine ones, so replies are
  # read exactly as core reads them.
  package FakeOpenAI;
  use Moose;
  use HTTP::Response;
  extends 'Langertha::Engine::OpenAI';
  has _loop    => (is => 'ro', default => sub { IO::Async::Loop->new });
  has turns    => (is => 'ro', required => 1);   # ArrayRef of wire bodies, one per request
  has requests => (is => 'rw', default => 0);
  has recorded => (is => 'ro', default => sub { [] });
  sub async_loop { $_[0]->_loop }
  sub build_tool_chat_request {
    my ( $self, $conversation, @rest ) = @_;
    push @{$self->recorded}, [ @$conversation ];
    return $self->SUPER::build_tool_chat_request($conversation, @rest);
  }
  sub async_request_f {
    my ( $self ) = @_;
    my $n = $self->requests;
    $self->requests($n + 1);
    my $body = $self->turns->[$n] // $self->turns->[-1];
    my $http = HTTP::Response->new(200, 'OK',
      [ 'Content-Type' => 'application/json' ], $self->json->encode($body));
    return $self->_loop->delay_future(after => 0)->then_done($http);
  }
  __PACKAGE__->meta->make_immutable;
}

# The tool code records the arguments it is handed and whether it ran at all.
my @noop_runs;
my @inline_tools = ({
  name => 'noop', description => 'no-op',
  input_schema => { type => 'object', properties => {} },
  code => sub { push @noop_runs, $_[1]; $_[0]->text_result('ran-on-args') },
});

# A tool-call turn carrying one function call with the given raw arguments string.
sub call_turn {
  my ( %call ) = @_;   # name, id, arguments (raw string), finish_reason
  return {
    id => 'r', model => 'gpt-test',
    choices => [ {
      index => 0, finish_reason => ( $call{finish_reason} // 'tool_calls' ),
      message => {
        role => 'assistant', content => undef,
        tool_calls => [ {
          id => $call{id}, type => 'function',
          function => { name => $call{name}, arguments => $call{arguments} },
        } ],
      },
    } ],
  };
}

sub final_turn {
  my ( $text ) = @_;
  return {
    id => 'r', model => 'gpt-test',
    choices => [ {
      index => 0, finish_reason => 'stop',
      message => { role => 'assistant', content => $text },
    } ],
  };
}

# The tool-result messages an OpenAI conversation carries (role => 'tool').
sub tool_results {
  my ( $conversation ) = @_;
  return grep { ref eq 'HASH' && ( $_->{role} // '' ) eq 'tool' } @$conversation;
}

# Runs a raid (or continuation) under an alarm, so a hang fails the test.
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

subtest 'main loop: undecodable arguments give an isError result, not a run on {}' => sub {
  @noop_runs = ();
  my $engine = FakeOpenAI->new(api_key => 'x', turns => [
    call_turn( name => 'noop', id => 'call_1', arguments => 'this is not json{' ),
    final_turn('all done'),
  ]);
  my $raider = Langertha::Raider->new(
    engine                => $engine,
    no_session_embeddings => 1,
    tools                 => \@inline_tools,
  );

  my ( $result, $err ) = guarded(sub { $raider->raid('hi') });
  unlike($err, qr/TIMEOUT/, 'the raid does not hang');
  is($err, '', 'the raid does not die');
  ok($result->is_final, 'the raid runs to a final result');
  is("$result", 'all done', 'the raid continues to completion');

  is(scalar @noop_runs, 0, 'the tool was NOT executed');   # red before fix: it ran on {}

  # The error result went back to the model as the tool result for that call.
  my @results = tool_results($engine->recorded->[1]);
  is(scalar @results, 1, 'one tool result was fed back');
  is($results[0]{tool_call_id}, 'call_1', 'it answers the offending call');
  like($results[0]{content}, qr/arguments are not valid JSON/,
    'the isError text matches core');                       # red before fix: was "ran-on-args"
  unlike($results[0]{content}, qr/ran-on-args/, 'the tool output never reached the model');
  is($engine->requests, 2, 'the raid took a second turn with the error result');
};

subtest 'a decodable call in the same reply still runs' => sub {
  @noop_runs = ();
  my $engine = FakeOpenAI->new(api_key => 'x', turns => [
    call_turn( name => 'noop', id => 'call_ok', arguments => '{"path":"/tmp"}' ),
    final_turn('done'),
  ]);
  my $raider = Langertha::Raider->new(
    engine                => $engine,
    no_session_embeddings => 1,
    tools                 => \@inline_tools,
  );
  my ( $result, $err ) = guarded(sub { $raider->raid('hi') });
  is($err, '', 'no error');
  is(scalar @noop_runs, 1, 'a decodable call still runs the tool');
  is($noop_runs[0], { path => '/tmp' }, 'with the decoded arguments');
  is("$result", 'done', 'the raid completes');
};

subtest 'respond_f: an undecodable call in the resumed batch is guarded too' => sub {
  @noop_runs = ();
  # First reply: ask_user (valid args, pauses the raid) followed by noop with
  # undecodable args. The noop call is left pending and handled by respond_f.
  my $first = {
    id => 'r', model => 'gpt-test',
    choices => [ {
      index => 0, finish_reason => 'tool_calls',
      message => {
        role => 'assistant', content => undef,
        tool_calls => [
          { id => 'call_ask', type => 'function',
            function => { name => 'raider_ask_user', arguments => '{"question":"go?"}' } },
          { id => 'call_bad', type => 'function',
            function => { name => 'noop', arguments => 'nope{' } },
        ],
      },
    } ],
  };
  my $engine = FakeOpenAI->new(api_key => 'x', turns => [ $first, final_turn('resumed done') ]);
  my $raider = Langertha::Raider->new(
    engine                => $engine,
    no_session_embeddings => 1,
    tools                 => \@inline_tools,
    raider_mcp            => { ask_user => 1 },
  );

  my ( $q, $qerr ) = guarded(sub { $raider->raid('hi') });
  is($qerr, '', 'the first turn does not die');
  ok($q->is_question, 'the raid pauses on the ask_user self-tool');
  is($engine->requests, 1, 'only the first turn has been sent');

  my ( $result, $err ) = guarded(sub { $raider->respond('yes') });
  is($err, '', 'the resume does not die');
  is("$result", 'resumed done', 'the resumed raid completes');
  is(scalar @noop_runs, 0, 'the undecodable call was NOT executed on resume');

  # The resumed turn carries an answer for ask_user AND the error for noop.
  my @results = tool_results($engine->recorded->[1]);
  my ($bad) = grep { ( $_->{tool_call_id} // '' ) eq 'call_bad' } @results;
  ok($bad, 'the offending call got a tool result');
  like($bad->{content}, qr/arguments are not valid JSON/,
    'the isError text matches core');   # red before fix: noop ran on {} -> "ran-on-args"
};

done_testing;
