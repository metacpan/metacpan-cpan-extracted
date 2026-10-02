#!/usr/bin/env perl
# ABSTRACT: Test AKI.IO OpenAI-compatible request/response quirks (karr #102, #127)

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use HTTP::Response;

use Langertha::Engine::AKIOpenAI;

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

my $aki = Langertha::Engine::AKIOpenAI->new(
  api_key => 'testkey',
  model   => 'minimax-m2.5-230b',
);

sub mock_http {
  my ($body) = @_;
  my $http = HTTP::Response->new(200, 'OK');
  $http->content($json->encode($body));
  $http->header('Content-Type' => 'application/json');
  return $http;
}

# --- karr #102: AKI.IO /openai/v1 speaks native OpenAI tool calling.
#     This engine used to compose Role::HermesTools and force
#     tool_wire_format 'hermes', teaching the model an XML protocol in the
#     system prompt that the endpoint never needed. The live probe that
#     settled it is t/data/akiopenai_tool_call_response.json, replayed in
#     t/28_aki_fixtures.t: native tools array in, native tool_calls block
#     out, on llama3-chat-8b — AKI's own table rates that model only
#     "Basic Support", so the weakest documented case is the one verified. ---

is($aki->tool_wire_format, 'openai', 'AKIOpenAI speaks the native OpenAI tool wire');
ok(!$aki->does('Langertha::Role::HermesTools'), 'AKIOpenAI does not compose HermesTools');
ok($aki->does('Langertha::Role::Tools'), 'AKIOpenAI still composes Tools');
ok($aki->supports('tools_native'), 'AKIOpenAI advertises tools_native');
ok(!$aki->supports('tools_hermes'), 'AKIOpenAI no longer advertises tools_hermes');

# The request side is what the flip actually changed: tools ride as an API
# parameter, and no XML scaffold is prepended to the conversation.
{
  my $tools = $aki->format_tools([{
    name        => 'add',
    description => 'Add two numbers',
    input_schema => {
      type       => 'object',
      properties => { a => { type => 'number' }, b => { type => 'number' } },
      required   => [ 'a', 'b' ],
    },
  }]);
  my $request = $aki->build_tool_chat_request(
    [ { role => 'user', content => 'What is 7 plus 15? Use the add tool.' } ],
    $tools,
  );
  my $body = $json->decode( $request->content );
  is($body->{tools}[0]{type}, 'function', 'tools go out as a native OpenAI tools array');
  is($body->{tools}[0]{function}{name}, 'add', 'tool name in the function envelope');
  is(scalar @{ $body->{messages} }, 1, 'no Hermes system prompt prepended');
  is($body->{messages}[0]{role}, 'user', 'the only message is the user turn');
}

# --- karr #127.1: AKI ships model reasoning under the bare `reasoning` key,
#     which the shared OpenAI-compatible path (reasoning_content only) drops.
#     AKIOpenAI lifts it onto Response.thinking. ---

my $reasoning_resp = $aki->chat_response(mock_http({
  id      => 'chatcmpl-aki-1',
  model   => 'minimax-m2.5-230b',
  choices => [{
    index         => 0,
    finish_reason => 'stop',
    message       => {
      role      => 'assistant',
      reasoning => 'The user wants me to add 7 and 15.',
      content   => '22',
    },
  }],
}));

is("$reasoning_resp", '22', 'AKIOpenAI content parsed');
ok($reasoning_resp->has_thinking, 'AKIOpenAI lifts the bare reasoning field onto thinking');
is($reasoning_resp->thinking, 'The user wants me to add 7 and 15.', 'thinking carries AKI reasoning');

# The shared reasoning_content spelling still wins where a provider sends it.
my $rc_resp = $aki->chat_response(mock_http({
  id      => 'chatcmpl-aki-2',
  model   => 'minimax-m2.5-230b',
  choices => [{
    index         => 0,
    finish_reason => 'stop',
    message       => {
      role              => 'assistant',
      reasoning_content => 'canonical spelling',
      content           => 'ok',
    },
  }],
}));
is($rc_resp->thinking, 'canonical spelling', 'reasoning_content spelling still surfaces');

# A plain response carries no thinking.
my $plain_resp = $aki->chat_response(mock_http({
  id      => 'chatcmpl-aki-3',
  model   => 'minimax-m2.5-230b',
  choices => [{
    index         => 0,
    finish_reason => 'stop',
    message       => { role => 'assistant', content => 'hello' },
  }],
}));
ok(!$plain_resp->has_thinking, 'plain AKIOpenAI response has no thinking');

done_testing;
