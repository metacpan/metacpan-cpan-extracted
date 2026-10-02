#!/usr/bin/env perl
# ABSTRACT: Test MCP tool calling support for Ollama engine

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::Engine::Ollama;

my $ollama = Langertha::Engine::Ollama->new(
  url => 'http://test.invalid:11434',
  model => 'llama3.3',
);

# Test: basics
is_deeply($ollama->mcp_servers, [], 'mcp_servers defaults to empty');
ok($ollama->can('chat_with_tools_f'), 'chat_with_tools_f available');

# Test: format_tools converts MCP to OpenAI-style function format
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
  ];

  my $formatted = $ollama->format_tools($mcp_tools);
  is(scalar @$formatted, 1, 'one tool formatted');
  is($formatted->[0]{type}, 'function', 'tool type is function');
  is($formatted->[0]{function}{name}, 'echo', 'function name');
  is($formatted->[0]{function}{description}, 'Echo the input text', 'function description');
  is($formatted->[0]{function}{parameters}{type}, 'object', 'parameters type');
}

# Test: response_tool_calls extracts from Ollama response
# Ollama puts tool_calls in message (not in choices like OpenAI)
{
  my $data = {
    message => {
      role => 'assistant',
      content => '',
      tool_calls => [
        {
          function => {
            name => 'echo',
            arguments => { message => 'hello' },
          },
        },
      ],
    },
  };

  my $calls = $ollama->response_tool_calls($data);
  is(scalar @$calls, 1, 'one tool call extracted');
  is($calls->[0]{function}{name}, 'echo', 'tool call function name');
  is_deeply($calls->[0]{function}{arguments}, { message => 'hello' }, 'arguments as hashref (not JSON string)');
}

# Test: response_tool_calls returns empty for text-only
{
  my $data = {
    message => {
      role => 'assistant',
      content => 'Just a normal response.',
    },
  };

  my $calls = $ollama->response_tool_calls($data);
  is(scalar @$calls, 0, 'no tool calls in text-only response');
}

# Test: response_text_content
{
  my $data = {
    message => {
      role => 'assistant',
      content => 'Hello world!',
    },
  };

  is($ollama->response_text_content($data), 'Hello world!', 'text content extracted');
}

# Test: response_text_content returns empty for tool call
{
  my $data = {
    message => {
      role => 'assistant',
      content => '',
      tool_calls => [{ function => { name => 'echo', arguments => {} } }],
    },
  };

  is($ollama->response_text_content($data), '', 'empty content for tool call');
}

# Test: format_tool_results
{
  my $data = {
    message => {
      role => 'assistant',
      content => '',
      tool_calls => [
        { function => { name => 'echo', arguments => { message => 'hi' } } },
      ],
    },
  };

  my $results = [
    {
      tool_call => { function => { name => 'echo', arguments => { message => 'hi' } } },
      result => {
        content => [{ type => 'text', text => 'Echo: hi' }],
        isError => JSON->false,
      },
    },
  ];

  my @messages = $ollama->format_tool_results($data, $results);
  is(scalar @messages, 2, 'two messages returned');

  is($messages[0]{role}, 'assistant', 'first message is assistant');
  ok($messages[0]{tool_calls}, 'tool_calls preserved');

  is($messages[1]{role}, 'tool', 'second message role is tool');
  ok($messages[1]{content}, 'tool result content set');
}

# Test: format_tool_results with multiple results
{
  my $data = {
    message => {
      role => 'assistant',
      content => '',
      tool_calls => [
        { function => { name => 'echo', arguments => {} } },
        { function => { name => 'add', arguments => {} } },
      ],
    },
  };

  my $results = [
    {
      tool_call => { function => { name => 'echo' } },
      result => { content => [{ type => 'text', text => 'r1' }], isError => JSON->false },
    },
    {
      tool_call => { function => { name => 'add' } },
      result => { content => [{ type => 'text', text => 'r2' }], isError => JSON->false },
    },
  ];

  my @messages = $ollama->format_tool_results($data, $results);
  is(scalar @messages, 3, 'three messages (assistant + 2 tool results)');
  is($messages[1]{role}, 'tool', 'first tool result');
  is($messages[2]{role}, 'tool', 'second tool result');
}

# karr k136: Ollama keeps the chain-of-thought in message.thinking; it must
# survive into the assistant echo, like reasoning_content does on the openai
# branch. Absent thinking still yields exactly the old three keys.
{
  my $data = {
    message => {
      role       => 'assistant',
      content    => '',
      thinking   => 'The user wants an echo, so I call the tool.',
      tool_calls => [
        { function => { name => 'echo', arguments => { message => 'hi' } } },
      ],
    },
  };

  my $results = [
    {
      tool_call => { function => { name => 'echo', arguments => { message => 'hi' } } },
      result => { content => [{ type => 'text', text => 'Echo: hi' }], isError => JSON->false },
    },
  ];

  my @messages = $ollama->format_tool_results($data, $results);
  is($messages[0]{thinking}, 'The user wants an echo, so I call the tool.',
    'message.thinking echoed back into the assistant message');
  ok($messages[0]{tool_calls}, 'tool_calls still preserved alongside it');

  delete $data->{message}{thinking};
  my @plain = $ollama->format_tool_results($data, $results);
  is_deeply([sort keys %{$plain[0]}], [qw( content role tool_calls )],
    'without thinking the echo is exactly role/content/tool_calls');
}


done_testing;
