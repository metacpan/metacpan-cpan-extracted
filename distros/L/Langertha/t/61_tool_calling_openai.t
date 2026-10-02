#!/usr/bin/env perl
# ABSTRACT: Test MCP tool calling support for OpenAI-compatible engines

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::Engine::OpenAI;

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

my $openai = Langertha::Engine::OpenAI->new(
  api_key => 'test-key',
  model => 'gpt-4o-mini',
  system_prompt => 'You are a helpful assistant',
);

# Test: mcp_servers defaults to empty
is_deeply($openai->mcp_servers, [], 'mcp_servers defaults to empty');
is($openai->tool_max_iterations, 10, 'tool_max_iterations defaults to 10');

# Test: format_tools converts MCP format to OpenAI function format
{
  my $mcp_tools = [
    {
      name => 'echo',
      description => 'Echo the input text',
      inputSchema => {
        type => 'object',
        properties => { message => { type => 'string' } },
        required => ['message'],
      },
    },
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

  my $formatted = $openai->format_tools($mcp_tools);
  is(scalar @$formatted, 2, 'two tools formatted');

  is($formatted->[0]{type}, 'function', 'first tool type is function');
  is($formatted->[0]{function}{name}, 'echo', 'first tool function name');
  is($formatted->[0]{function}{description}, 'Echo the input text', 'first tool description');
  is($formatted->[0]{function}{parameters}{type}, 'object', 'parameters type preserved');
  is_deeply($formatted->[0]{function}{parameters}{required}, ['message'], 'parameters required preserved');
  ok(!exists $formatted->[0]{inputSchema}, 'no inputSchema at top level');

  is($formatted->[1]{type}, 'function', 'second tool type');
  is($formatted->[1]{function}{name}, 'add', 'second tool function name');
}

# Test: response_tool_calls extracts tool calls from OpenAI response
{
  my $data = {
    choices => [{
      message => {
        role => 'assistant',
        content => undef,
        tool_calls => [
          {
            id => 'call_abc123',
            type => 'function',
            function => {
              name => 'echo',
              arguments => '{"message":"hello"}',
            },
          },
        ],
      },
      finish_reason => 'tool_calls',
    }],
  };

  my $calls = $openai->response_tool_calls($data);
  is(scalar @$calls, 1, 'one tool call extracted');
  is($calls->[0]{id}, 'call_abc123', 'tool call id');
  is($calls->[0]{function}{name}, 'echo', 'tool function name');
  is($calls->[0]{function}{arguments}, '{"message":"hello"}', 'tool arguments (JSON string)');
}

# Test: response_tool_calls returns empty for text-only response
{
  my $data = {
    choices => [{
      message => {
        role => 'assistant',
        content => 'Just a normal response.',
      },
      finish_reason => 'stop',
    }],
  };

  my $calls = $openai->response_tool_calls($data);
  is(scalar @$calls, 0, 'no tool calls in text-only response');
}

# Test: response_tool_calls handles multiple tool calls
{
  my $data = {
    choices => [{
      message => {
        role => 'assistant',
        content => undef,
        tool_calls => [
          { id => 'call_1', type => 'function', function => { name => 'echo', arguments => '{}' } },
          { id => 'call_2', type => 'function', function => { name => 'add', arguments => '{}' } },
        ],
      },
    }],
  };

  my $calls = $openai->response_tool_calls($data);
  is(scalar @$calls, 2, 'two tool calls extracted');
  is($calls->[0]{function}{name}, 'echo', 'first call name');
  is($calls->[1]{function}{name}, 'add', 'second call name');
}

# Test: response_text_content extracts text
{
  my $data = {
    choices => [{
      message => {
        role => 'assistant',
        content => 'Hello world!',
      },
      finish_reason => 'stop',
    }],
  };

  is($openai->response_text_content($data), 'Hello world!', 'text content extracted');
}

# Test: response_text_content returns empty for tool call response
{
  my $data = {
    choices => [{
      message => {
        role => 'assistant',
        content => undef,
        tool_calls => [{ id => 'call_1', function => { name => 'echo', arguments => '{}' } }],
      },
    }],
  };

  is($openai->response_text_content($data), '', 'empty string for null content');
}

# Test: format_tool_results builds correct message structure
{
  my $data = {
    choices => [{
      message => {
        role => 'assistant',
        content => 'Let me echo that.',
        tool_calls => [
          { id => 'call_abc', type => 'function', function => { name => 'echo', arguments => '{"message":"hi"}' } },
        ],
      },
    }],
  };

  my $results = [
    {
      tool_call => { id => 'call_abc', type => 'function', function => { name => 'echo', arguments => '{"message":"hi"}' } },
      result => {
        content => [{ type => 'text', text => 'Echo: hi' }],
        isError => JSON->false,
      },
    },
  ];

  my @messages = $openai->format_tool_results($data, $results);
  is(scalar @messages, 2, 'two messages returned (assistant + 1 tool result)');

  # First message: assistant with original content + tool_calls
  is($messages[0]{role}, 'assistant', 'first message is assistant');
  is($messages[0]{content}, 'Let me echo that.', 'assistant content preserved');
  is(scalar @{$messages[0]{tool_calls}}, 1, 'tool_calls preserved in assistant message');
  is($messages[0]{tool_calls}[0]{id}, 'call_abc', 'tool_call id preserved');

  # Second message: tool result
  is($messages[1]{role}, 'tool', 'second message role is tool');
  is($messages[1]{tool_call_id}, 'call_abc', 'tool_call_id matches');
  ok($messages[1]{content}, 'tool result content is set');
}

# Test: format_tool_results with multiple results
{
  my $data = {
    choices => [{
      message => {
        role => 'assistant',
        content => undef,
        tool_calls => [
          { id => 'call_1', type => 'function', function => { name => 'echo', arguments => '{}' } },
          { id => 'call_2', type => 'function', function => { name => 'add', arguments => '{}' } },
        ],
      },
    }],
  };

  my $results = [
    {
      tool_call => { id => 'call_1' },
      result => { content => [{ type => 'text', text => 'result1' }], isError => JSON->false },
    },
    {
      tool_call => { id => 'call_2' },
      result => { content => [{ type => 'text', text => 'result2' }], isError => JSON->false },
    },
  ];

  my @messages = $openai->format_tool_results($data, $results);
  is(scalar @messages, 3, 'three messages (assistant + 2 tool results)');
  is($messages[1]{role}, 'tool', 'first tool result');
  is($messages[1]{tool_call_id}, 'call_1', 'first tool_call_id');
  is($messages[2]{role}, 'tool', 'second tool result');
  is($messages[2]{tool_call_id}, 'call_2', 'second tool_call_id');
}

# Test: Groq inherits tool support from OpenAI
{
  use Langertha::Engine::Groq;
  my $groq = Langertha::Engine::Groq->new(
    api_key => 'test-key',
    model => 'llama3-70b-8192',
  );
  ok($groq->can('format_tools'), 'Groq has format_tools');
  ok($groq->can('response_tool_calls'), 'Groq has response_tool_calls');
  ok($groq->can('chat_with_tools_f'), 'Groq has chat_with_tools_f');
  is_deeply($groq->mcp_servers, [], 'Groq mcp_servers defaults to empty');
}

# Test: vLLM inherits tool support from OpenAI
{
  use Langertha::Engine::vLLM;
  my $vllm = Langertha::Engine::vLLM->new(
    url => 'http://test.invalid:8000',
    model => 'some-model',
  );
  ok($vllm->can('format_tools'), 'vLLM has format_tools');
  ok($vllm->can('response_tool_calls'), 'vLLM has response_tool_calls');
  ok($vllm->can('chat_with_tools_f'), 'vLLM has chat_with_tools_f');
}

# karr k136: the assistant echo must carry the provider's reasoning fields back.
# DeepSeek answers HTTP 400 on the next iteration of a tool loop when
# reasoning_content is missing while tools are present; Moonshot, OpenRouter,
# Mistral and xAI have the same obligation in softer forms.
{
  my $details = [ { type => 'reasoning.text', text => 'call echo', signature => 'sig_1' } ];
  my $data = {
    choices => [{
      message => {
        role              => 'assistant',
        content           => undef,
        reasoning_content => 'The user wants an echo, so I call the tool.',
        reasoning         => 'The user wants an echo, so I call the tool.',
        reasoning_details => $details,
        tool_calls        => [
          { id => 'call_r1', type => 'function', function => { name => 'echo', arguments => '{}' } },
        ],
      },
    }],
  };

  my $results = [
    {
      tool_call => { id => 'call_r1' },
      result => { content => [{ type => 'text', text => 'Echo: hi' }], isError => JSON->false },
    },
  ];

  my @messages = $openai->format_tool_results($data, $results);
  is($messages[0]{reasoning_content}, 'The user wants an echo, so I call the tool.',
    'reasoning_content echoed back (DeepSeek 400s on the next iteration without it)');
  is($messages[0]{reasoning}, 'The user wants an echo, so I call the tool.',
    'the reasoning spelling is echoed too');
  is_deeply($messages[0]{reasoning_details}, $details,
    'reasoning_details round-trip unmodified, signature included (OpenRouter)');
  is($messages[0]{tool_calls}[0]{id}, 'call_r1', 'tool_calls still preserved');
}

# The echo is an allowlist, not the whole message: a provider that sends no
# reasoning gets exactly the three keys it always got, and no key whose value
# is undef (some OpenAI-compatible servers reject unknown inbound keys).
{
  my $data = {
    choices => [{
      message => {
        role       => 'assistant',
        content    => 'Let me echo that.',
        tool_calls => [
          { id => 'call_abc', type => 'function', function => { name => 'echo', arguments => '{}' } },
        ],
        # not echoed: neither a reasoning field nor part of the old three keys
        annotations => [],
      },
    }],
  };

  my $results = [
    {
      tool_call => { id => 'call_abc' },
      result => { content => [{ type => 'text', text => 'Echo: hi' }], isError => JSON->false },
    },
  ];

  my @messages = $openai->format_tool_results($data, $results);
  is_deeply([sort keys %{$messages[0]}], [qw( content role tool_calls )],
    'without reasoning the echo is exactly role/content/tool_calls, nothing invented');
}


done_testing;
