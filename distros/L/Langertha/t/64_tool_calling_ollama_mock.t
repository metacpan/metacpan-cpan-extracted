#!/usr/bin/env perl
# ABSTRACT: Mock round-trip test for Ollama MCP tool calling

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use Path::Tiny;

use lib path(__FILE__)->parent->child('lib')->stringify;

BEGIN {
  eval {
    require Future::AsyncAwait;
    1;
  } or plan skip_all => 'Requires Future::AsyncAwait';
}

use Future::AsyncAwait;
use Test::MockMCP;
use Test::MockAsyncHTTP;

my $data_dir = path(__FILE__)->parent->child('data');
my $json = JSON::MaybeXS->new(utf8 => 1);

# --- Build a duck-typed MCP server (Test::MockMCP) with the add tool ---

my $mcp = Test::MockMCP->new(
  tools => [
    {
      name        => 'add',
      description => 'Add two numbers together and return the result',
      input_schema => {
        type       => 'object',
        properties => {
          a => { type => 'number', description => 'First number' },
          b => { type => 'number', description => 'Second number' },
        },
        required => ['a', 'b'],
      },
      code => sub {
        my ($self, $args) = @_;
        my $result = $args->{a} + $args->{b};
        return $self->text_result("$result");
      },
    },
  ],
);

# --- Load fixtures captured from real Ollama API ---

my $tool_call_fixture = $json->decode(
  $data_dir->child('ollama_tool_call_response.json')->slurp_raw
);
my $tool_result_fixture = $json->decode(
  $data_dir->child('ollama_tool_result_response.json')->slurp_raw
);

# --- Test full tool calling round-trip ---

async sub run_tests {
  await $mcp->initialize;

  require Langertha::Engine::Ollama;

  # Create engine with mock HTTP and real MCP
  my $mock_http = Test::MockAsyncHTTP->new(
    responses => [
      Test::MockAsyncHTTP->mock_json_response($tool_call_fixture),   # 1st: LLM returns tool_calls
      Test::MockAsyncHTTP->mock_json_response($tool_result_fixture), # 2nd: LLM returns final text
    ],
  );

  my $ollama = Langertha::Engine::Ollama->new(
    url         => 'http://test.invalid:11434',
    model       => 'qwen3:8b',
    mcp_servers => [$mcp],
    _async_http => $mock_http,
  );

  # Run the full tool calling loop
  my $response = await $ollama->chat_with_tools_f(
    'What is 7 plus 15? Use the add tool.'
  );

  # Verify final response
  is($response, '22', 'tool calling loop returned correct result');

  # Verify two HTTP requests were made (tool call + final)
  is($mock_http->request_count, 2, 'two HTTP requests made');

  my @requests = $mock_http->requests;

  # Verify first request contained tools
  my $first_body = $json->decode($requests[0]->content);
  ok($first_body->{tools}, 'first request has tools');
  is(scalar @{$first_body->{tools}}, 1, 'one tool sent');
  is($first_body->{tools}[0]{function}{name}, 'add', 'tool name is add');
  is($first_body->{model}, 'qwen3:8b', 'model is qwen3:8b');

  # Verify second request contains tool result conversation
  my $second_body = $json->decode($requests[1]->content);
  ok($second_body->{tools}, 'second request still has tools');
  my @messages = @{$second_body->{messages}};
  ok(scalar @messages >= 3, 'second request has at least 3 messages (user + assistant + tool)');

  # Check conversation flow: user -> assistant (with tool_calls) -> tool (result)
  is($messages[0]{role}, 'user', 'first message is user');
  is($messages[1]{role}, 'assistant', 'second message is assistant');
  ok($messages[1]{tool_calls}, 'assistant message has tool_calls');
  is($messages[1]{tool_calls}[0]{function}{name}, 'add', 'tool call is add');
  is($messages[2]{role}, 'tool', 'third message is tool result');

  # Verify tool was actually executed (MCP called add(7, 15) = 22)
  my $tool_content = $json->decode($messages[2]{content});
  like($json->encode($tool_content), qr/22/, 'tool result contains 22');
}

run_tests()->get;

done_testing;
