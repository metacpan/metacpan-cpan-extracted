#!/usr/bin/env perl
# ABSTRACT: tool_loop_response / tool_loop_calls are the public tool-loop reply reader; response_tool_calls agrees with it

use strict;
use warnings;

use Test2::Bundle::More;

# karr k341, ADR 0028 Update (k341). langertha-raider runs its own tool loop
# and reads each reply off the raw body (parse_response, response_tool_calls,
# response_text_content): no body-error croak, no blocked-prompt croak, no
# drop of calls cut off by the token limit -- everything the core loops do
# since k321/k324/k339. The core loops' reader was private
# (_tool_loop_response, _tool_loop_calls). These tests pin its public face,
# and that the raw reader response_tool_calls names the same calls, so a loop
# built on either runs the same tools.

use JSON::MaybeXS;
use HTTP::Response;

use Langertha::Engine::Anthropic;
use Langertha::Engine::Gemini;
use Langertha::Engine::Groq;
use Langertha::Engine::NousResearch;
use Langertha::Engine::Ollama;
use Langertha::Engine::OpenAI;
use Langertha::Engine::OpenAIResponses;

sub http_for {
  my ( $body, @headers ) = @_;
  return HTTP::Response->new( 200, 'OK',
    [ 'Content-Type' => 'application/json', @headers ], encode_json($body) );
}

sub strip_location { my ($err) = @_; $err =~ s/ at \S+ line \d+\.?\n?\z//; return $err }

my $openai_tool_turn = { id => 'c1', choices => [ { index => 0, finish_reason => 'tool_calls',
  message => { role => 'assistant', content => undef, tool_calls => [
    { id => 'call_1', type => 'function', function => { name => 'echo', arguments => '{"m":"a"}' } },
  ] } } ] };

subtest 'tool_loop_response takes the HTTP::Response or the decoded body' => sub {
  my $openai = Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-x' );
  ok( $openai->can('tool_loop_response'), 'public method' );
  my $from_http = $openai->tool_loop_response( http_for($openai_tool_turn) );
  my $from_data = $openai->tool_loop_response($openai_tool_turn);
  for my $reply ( $from_http, $from_data ) {
    isa_ok( $reply, ['Langertha::Response'], 'a Response' );
    is( $reply->tool_call->name, 'echo', 'the call' );
    is_deeply( $reply->tool_call->arguments, { m => 'a' }, 'decoded arguments' );
    is_deeply( $reply->raw, $openai_tool_turn, 'raw is the wire body' );
  }
  is( $openai->_tool_loop_response($openai_tool_turn)->tool_call->id, 'call_1',
    'the private name answers the same' );
};

subtest 'the decoded-body path leaves the engine rate limit alone' => sub {
  my $groq = Langertha::Engine::Groq->new( api_key => 'k', model => 'm' );
  $groq->tool_loop_response( http_for( $openai_tool_turn,
    'x-ratelimit-remaining-requests' => 3, 'x-ratelimit-limit-requests' => 10 ) );
  is( $groq->rate_limit->requests_remaining, 3, 'an HTTP::Response updates it' );
  $groq->tool_loop_response($openai_tool_turn);
  is( $groq->rate_limit->requests_remaining, 3, 'a decoded body does not clear it' );
};

subtest 'an error in the body croaks with chat_f\'s text' => sub {
  my $openai = Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-x' );
  my $body = { error => { message => 'upstream overloaded', code => 502 } };
  eval { $openai->tool_loop_response($body) };
  my $err = strip_location($@);
  eval { $openai->chat_response( http_for($body) ) };
  is( $err, strip_location($@), 'the chat_response croak' );
  like( $err, qr/response carried an error: upstream overloaded \(502\)/, 'naming the error' );

  my $claude = Langertha::Engine::Anthropic->new( api_key => 'k', model => 'claude-x' );
  eval { $claude->tool_loop_response( { type => 'error', error => { message => 'Overloaded' } } ) };
  like( $@, qr/Anthropic response carried an error: Overloaded/, 'Anthropic error envelope too (k338)' );
};

subtest 'a blocked Gemini prompt croaks' => sub {
  my $gemini = Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-x' );
  eval { $gemini->tool_loop_response( { promptFeedback => { blockReason => 'SAFETY' } } ) };
  like( $@, qr/\ALangertha::Engine::Gemini prompt blocked: SAFETY/, 'prompt blocked: REASON (k339)' );
};

subtest 'hermes: the calls are lifted out of the text' => sub {
  my $nous = Langertha::Engine::NousResearch->new( api_key => 'k' );
  my $reply = $nous->tool_loop_response( { choices => [ { index => 0, finish_reason => 'stop',
    message => { role => 'assistant',
      content => "Let me look.\n<tool_call>{\"name\":\"echo\",\"arguments\":{\"m\":\"b\"}}</tool_call>" } } ] } );
  is( $reply->tool_call->name, 'echo', 'the call is on tool_calls' );
  is_deeply( $reply->tool_call->arguments, { m => 'b' }, 'with its arguments' );
  unlike( $reply->content, qr/tool_call/, 'and gone from content' );
};

subtest 'tool_loop_calls drops calls cut off by the token limit' => sub {
  my $openai = Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-x' );
  ok( $openai->can('tool_loop_calls'), 'public method' );
  my $body = { id => 'c1', choices => [ { index => 0, finish_reason => 'length',
    message => { role => 'assistant', content => undef, tool_calls => [
      { id => 'call_ok',  type => 'function', function => { name => 'echo', arguments => '{"m":"a"}' } },
      { id => 'call_cut', type => 'function', function => { name => 'echo', arguments => '{"m":"b' } },
    ] } } ] };
  my $reply = $openai->tool_loop_response($body);
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my ( $calls, $data ) = $openai->tool_loop_calls($reply);
  is_deeply( [ map { $_->id } @$calls ], ['call_ok'], 'only the complete call runs' );
  is_deeply( [ map { $_->{id} } @{ $data->{choices}[0]{message}{tool_calls} } ], ['call_ok'],
    'the echo body (defaulted from ->raw) leaves the cut call out' );
  is( scalar @warnings, 1, 'one warning' );
  like( $warnings[0], qr/dropped 1 tool call\(s\) with truncated arguments/, 'naming the drop' );

  my $lone = { id => 'c2', choices => [ { index => 0, finish_reason => 'length',
    message => { role => 'assistant', content => undef, tool_calls => [
      { id => 'call_cut', type => 'function', function => { name => 'echo', arguments => '{"m":' } },
    ] } } ] };
  eval { $openai->tool_loop_calls( $openai->tool_loop_response($lone) ) };
  like( $@, qr/tool call arguments truncated \(finish_reason length\); raise response_size/,
    'a lone cut call croaks' );
};

# --- response_tool_calls names the calls tool_loop_response runs -----------

sub raw_names_args {
  my ( $engine, $data ) = @_;
  return [ map { [ $engine->extract_tool_call($_) ] } @{ $engine->response_tool_calls($data) } ];
}

sub reply_names_args {
  my ( $engine, $data ) = @_;
  my $reply = $engine->tool_loop_response($data);
  return [ map { [ $_->name, $_->arguments ] } @{ $reply->has_tool_calls ? $reply->tool_calls : [] } ];
}

my @agreement = (
  [ 'OpenAI, a call without a name beside a real one',
    Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-x' ),
    { id => 'c1', choices => [ { index => 0, finish_reason => 'tool_calls',
      message => { role => 'assistant', content => undef, tool_calls => [
        { id => 'call_x', type => 'function', function => { arguments => '{}' } },
        { id => 'call_1', type => 'function', function => { name => 'echo', arguments => '{"m":"a"}' } },
      ] } } ] },
    [ [ echo => { m => 'a' } ] ] ],
  [ 'Anthropic tool_use beside thinking and text',
    Langertha::Engine::Anthropic->new( api_key => 'k', model => 'claude-x' ),
    { id => 'msg_1', type => 'message', role => 'assistant', stop_reason => 'tool_use', content => [
      { type => 'thinking', thinking => 'hm', signature => 's' },
      { type => 'text', text => 'Calling.' },
      { type => 'tool_use', id => 'tu_1', name => 'echo', input => { m => 'c' } },
      { type => 'tool_use', id => 'tu_2', input => {} },
    ] },
    [ [ echo => { m => 'c' } ] ] ],
  [ 'Gemini functionCall beside a thought part',
    Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-x' ),
    { candidates => [ { finishReason => 'STOP', content => { role => 'model', parts => [
      { text => 'plan', thought => JSON::MaybeXS::true() },
      { functionCall => { name => 'echo', args => { m => 'd' } } },
    ] } } ] },
    [ [ echo => { m => 'd' } ] ] ],
  [ 'Ollama native',
    Langertha::Engine::Ollama->new( url => 'http://localhost:11434', model => 'llama3' ),
    { model => 'llama3', done => JSON::MaybeXS::true(), message => { role => 'assistant', content => '',
      tool_calls => [ { function => { name => 'echo', arguments => { m => 'e' } } } ] } },
    [ [ echo => { m => 'e' } ] ] ],
  [ 'Responses function_call',
    Langertha::Engine::OpenAIResponses->new( api_key => 'k', model => 'gpt-5.5-pro' ),
    { id => 'resp_1', object => 'response', status => 'completed', output => [
      { type => 'function_call', id => 'fc_1', call_id => 'call_1', name => 'echo', arguments => '{"m":"f"}' },
    ] },
    [ [ echo => { m => 'f' } ] ] ],
  [ 'hermes, a call inside <think> is none',
    Langertha::Engine::NousResearch->new( api_key => 'k', think_tag_filter => 1 ),
    { choices => [ { index => 0, finish_reason => 'stop', message => { role => 'assistant',
      content => "<think><tool_call>{\"name\":\"echo\",\"arguments\":{\"m\":\"no\"}}</tool_call></think>"
        . "<tool_call>{\"name\":\"echo\",\"arguments\":{\"m\":\"g\"}}</tool_call>" } } ] },
    [ [ echo => { m => 'g' } ] ] ],
  [ 'hermes engine, the server parsed the call natively',
    Langertha::Engine::NousResearch->new( api_key => 'k' ),
    { choices => [ { index => 0, finish_reason => 'tool_calls', message => { role => 'assistant',
      content => undef, tool_calls => [
        { id => 'call_1', type => 'function', function => { name => 'echo', arguments => '{"m":"h"}' } },
      ] } } ] },
    [ [ echo => { m => 'h' } ] ] ],
);

for my $case (@agreement) {
  my ( $label, $engine, $data, $want ) = @$case;
  subtest "response_tool_calls agrees with tool_loop_response: $label" => sub {
    my $loop = reply_names_args( $engine, $data );
    is_deeply( $loop, $want, 'tool_loop_response runs the expected calls' );
    is_deeply( raw_names_args( $engine, $data ), $loop, 'response_tool_calls names the same calls' );
  };
}

subtest 'response_tool_calls never croaks on a body chat_response rejects' => sub {
  my $nous = Langertha::Engine::NousResearch->new( api_key => 'k' );
  is_deeply( eval { $nous->response_tool_calls( { error => { message => 'x' } } ) }, [],
    'hermes: an error body gives no calls' );
  is_deeply( eval { $nous->response_tool_calls( {} ) }, [], 'an empty body gives none' );
};

done_testing;
