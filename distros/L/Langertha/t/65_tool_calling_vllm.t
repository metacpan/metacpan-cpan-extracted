#!/usr/bin/env perl
# ABSTRACT: Test MCP tool calling support for vLLM engine

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::Engine::vLLM;

# Test: url is required
eval { Langertha::Engine::vLLM->new(model => 'test-model') };
like($@, qr/url/, 'url is required');

# Test: model defaults to 'default' (single-model server)
{
  my $vllm_no_model = Langertha::Engine::vLLM->new(url => 'http://test.invalid:8000');
  is($vllm_no_model->model, 'default', 'model defaults to default');
}

my $vllm = Langertha::Engine::vLLM->new(
  url   => 'http://test.invalid:8000',
  model => 'Qwen/Qwen2.5-3B-Instruct',
);

# Test: api_key is undef (no auth needed for local server)
is($vllm->api_key, undef, 'api_key defaults to undef');

# Test: composes OpenAICompatible
ok($vllm->does('Langertha::Role::OpenAICompatible'), 'vLLM composes OpenAICompatible');

# Test: composes Embedding (karr #70)
ok($vllm->does('Langertha::Role::Embedding'), 'vLLM composes Embedding');

# Test: composes Runtime::MetricsPoll
ok($vllm->does('Langertha::Role::Runtime::MetricsPoll'), 'vLLM composes Runtime::MetricsPoll');

# Test: _build_supported_operations contains createEmbedding (karr #70)
{
  my $ops = $vllm->_build_supported_operations;
  ok((grep { $_ eq 'createEmbedding' } @$ops),
    '_build_supported_operations contains createEmbedding');
  ok((grep { $_ eq 'createChatCompletion' } @$ops),
    '_build_supported_operations contains createChatCompletion');
}

# Test: no fixed embedding model on a single-model server (karr #70, k297:
# the 'default' placeholder 404s on vLLM 0.10/0.11, so no model is sent)
is($vllm->default_embedding_model, undef,
  'default_embedding_model is undef');

# Test: embedding_model falls back to the caller's model
is($vllm->embedding_model, 'Qwen/Qwen2.5-3B-Instruct',
  'embedding_model is the caller-set model when no embedding_model is set');

# Test: tool calling methods available
ok($vllm->can('format_tools'), 'has format_tools');
ok($vllm->can('response_tool_calls'), 'has response_tool_calls');
ok($vllm->can('extract_tool_call'), 'has extract_tool_call');
ok($vllm->can('format_tool_results'), 'has format_tool_results');
ok($vllm->can('response_text_content'), 'has response_text_content');
ok($vllm->can('chat_with_tools_f'), 'has chat_with_tools_f');
is_deeply($vllm->mcp_servers, [], 'mcp_servers defaults to empty');
is($vllm->tool_max_iterations, 10, 'tool_max_iterations defaults to 10');

# Test: format_tools (same as OpenAI)
{
  my $mcp_tools = [
    {
      name => 'add',
      description => 'Add two numbers',
      inputSchema => {
        type => 'object',
        properties => {
          a => { type => 'number' },
          b => { type => 'number' },
        },
        required => ['a', 'b'],
      },
    },
  ];

  my $formatted = $vllm->format_tools($mcp_tools);
  is(scalar @$formatted, 1, 'one tool formatted');
  is($formatted->[0]{type}, 'function', 'tool type is function');
  is($formatted->[0]{function}{name}, 'add', 'function name');
  is($formatted->[0]{function}{parameters}{type}, 'object', 'parameters type');
}

# Test: response_tool_calls (OpenAI format)
{
  my $data = {
    choices => [{
      message => {
        role => 'assistant',
        content => undef,
        tool_calls => [
          {
            id => 'call_123',
            type => 'function',
            function => {
              name => 'add',
              arguments => '{"a":7,"b":15}',
            },
          },
        ],
      },
      finish_reason => 'tool_calls',
    }],
  };

  my $calls = $vllm->response_tool_calls($data);
  is(scalar @$calls, 1, 'one tool call extracted');
  is($calls->[0]{function}{name}, 'add', 'tool call name');
}

# Test: extract_tool_call (OpenAI format - JSON string arguments)
{
  my $tc = {
    id => 'call_123',
    type => 'function',
    function => {
      name => 'add',
      arguments => '{"a":7,"b":15}',
    },
  };

  my ($name, $input) = $vllm->extract_tool_call($tc);
  is($name, 'add', 'extracted tool name');
  is_deeply($input, { a => 7, b => 15 }, 'extracted and parsed arguments');
}

# Test: response_text_content
{
  my $data = {
    choices => [{
      message => {
        role => 'assistant',
        content => '22',
      },
      finish_reason => 'stop',
    }],
  };

  is($vllm->response_text_content($data), '22', 'text content extracted');
}

# Test: format_tool_results
{
  my $data = {
    choices => [{
      message => {
        role => 'assistant',
        content => undef,
        tool_calls => [
          { id => 'call_123', type => 'function', function => { name => 'add', arguments => '{"a":7,"b":15}' } },
        ],
      },
    }],
  };

  my $results = [
    {
      tool_call => { id => 'call_123', type => 'function', function => { name => 'add', arguments => '{"a":7,"b":15}' } },
      result => {
        content => [{ type => 'text', text => '22' }],
        isError => JSON->false,
      },
    },
  ];

  my @messages = $vllm->format_tool_results($data, $results);
  is(scalar @messages, 2, 'two messages (assistant + tool result)');
  is($messages[0]{role}, 'assistant', 'first is assistant');
  ok($messages[0]{tool_calls}, 'tool_calls preserved');
  is($messages[1]{role}, 'tool', 'second is tool result');
  is($messages[1]{tool_call_id}, 'call_123', 'tool_call_id matches');
}

done_testing;
