#!/usr/bin/env perl
# ABSTRACT: Test MCP tool calling support for Gemini engine

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::Engine::Gemini;

my $gemini = Langertha::Engine::Gemini->new(
  api_key => 'test-key',
  model => 'gemini-2.0-flash',
);

# Test: basics
is_deeply($gemini->mcp_servers, [], 'mcp_servers defaults to empty');
ok($gemini->can('chat_with_tools_f'), 'chat_with_tools_f available');

# Test: format_tools converts MCP format to Gemini functionDeclarations
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

  my $formatted = $gemini->format_tools($mcp_tools);
  is(scalar @$formatted, 1, 'one tools object (wrapping array)');
  ok($formatted->[0]{functionDeclarations}, 'functionDeclarations present');

  my $decls = $formatted->[0]{functionDeclarations};
  is(scalar @$decls, 2, 'two function declarations');
  is($decls->[0]{name}, 'echo', 'first function name');
  is($decls->[0]{description}, 'Echo the input text', 'first function description');
  is($decls->[0]{parametersJsonSchema}{type}, 'object', 'parametersJsonSchema type');
  is_deeply($decls->[0]{parametersJsonSchema}{required}, ['message'], 'parametersJsonSchema required');
  is($decls->[1]{name}, 'add', 'second function name');
}

# Test: response_tool_calls extracts functionCall parts
{
  my $data = {
    candidates => [{
      content => {
        role => 'model',
        parts => [
          { functionCall => { name => 'echo', args => { message => 'hello' } } },
        ],
      },
    }],
  };

  my $calls = $gemini->response_tool_calls($data);
  is(scalar @$calls, 1, 'one tool call extracted');
  is($calls->[0]{functionCall}{name}, 'echo', 'function call name');
  is_deeply($calls->[0]{functionCall}{args}, { message => 'hello' }, 'function call args');
}

# Test: response_tool_calls returns empty for text-only
{
  my $data = {
    candidates => [{
      content => {
        role => 'model',
        parts => [{ text => 'Just a normal response.' }],
      },
    }],
  };

  my $calls = $gemini->response_tool_calls($data);
  is(scalar @$calls, 0, 'no tool calls in text-only response');
}

# Test: response_tool_calls handles mixed content
{
  my $data = {
    candidates => [{
      content => {
        role => 'model',
        parts => [
          { text => 'Let me call tools.' },
          { functionCall => { name => 'echo', args => { message => 'a' } } },
          { functionCall => { name => 'add', args => { a => 1, b => 2 } } },
        ],
      },
    }],
  };

  my $calls = $gemini->response_tool_calls($data);
  is(scalar @$calls, 2, 'two tool calls from mixed content');
  is($calls->[0]{functionCall}{name}, 'echo', 'first call name');
  is($calls->[1]{functionCall}{name}, 'add', 'second call name');
}

# Test: response_text_content extracts text parts
{
  my $data = {
    candidates => [{
      content => {
        role => 'model',
        parts => [
          { text => 'Hello ' },
          { text => 'world!' },
        ],
      },
    }],
  };

  is($gemini->response_text_content($data), 'Hello world!', 'text content joined');
}

# Test: response_text_content skips functionCall parts
{
  my $data = {
    candidates => [{
      content => {
        role => 'model',
        parts => [
          { text => 'Before. ' },
          { functionCall => { name => 'echo', args => {} } },
          { text => 'After.' },
        ],
      },
    }],
  };

  is($gemini->response_text_content($data), 'Before. After.', 'text skips functionCall');
}

# Test: format_tool_results builds Gemini message structure
{
  my $data = {
    candidates => [{
      content => {
        role => 'model',
        parts => [
          { functionCall => { name => 'echo', args => { message => 'hi' } } },
        ],
      },
    }],
  };

  my $results = [
    {
      tool_call => { functionCall => { name => 'echo', args => { message => 'hi' } } },
      result => {
        content => [{ type => 'text', text => 'Echo: hi' }],
        isError => JSON->false,
      },
    },
  ];

  my @messages = $gemini->format_tool_results($data, $results);
  is(scalar @messages, 2, 'two messages returned');

  # First: model with original parts
  is($messages[0]{role}, 'model', 'first message role is model');
  ok($messages[0]{parts}, 'model message has parts');
  ok($messages[0]{parts}[0]{functionCall}, 'original functionCall preserved');

  # Second: user with functionResponse
  is($messages[1]{role}, 'user', 'second message role is user');
  is(scalar @{$messages[1]{parts}}, 1, 'one function response');
  ok($messages[1]{parts}[0]{functionResponse}, 'functionResponse present');
  is($messages[1]{parts}[0]{functionResponse}{name}, 'echo', 'response function name');
  is_deeply($messages[1]{parts}[0]{functionResponse}{response},
    { result => 'Echo: hi' }, 'response content');
}

done_testing;
