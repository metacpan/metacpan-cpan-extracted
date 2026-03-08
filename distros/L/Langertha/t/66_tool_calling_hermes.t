#!/usr/bin/env perl
# ABSTRACT: Test Hermes-native tool calling via <tool_call> XML tags

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use Path::Tiny;

use lib path(__FILE__)->parent->child('lib')->stringify;

use Langertha::Engine::NousResearch;
use Langertha::Engine::OpenAI;

my $json = JSON::MaybeXS->new(utf8 => 1, canonical => 1);

# ========================================================================
# NousResearch engine basics
# ========================================================================

{
  my $nous = Langertha::Engine::NousResearch->new(
    api_key => 'test-key',
    model   => 'Hermes-4-70B',
  );

  ok($nous->does('Langertha::Role::OpenAICompatible'), 'NousResearch composes OpenAICompatible');
  ok($nous->does('Langertha::Role::HermesTools'), 'NousResearch composes HermesTools');
  is($nous->default_model, 'Hermes-4-70B', 'default model');
  ok($nous->can('chat_with_tools_f'), 'has chat_with_tools_f');
  is_deeply($nous->mcp_servers, [], 'mcp_servers defaults to empty');
}

# ========================================================================
# Hermes attribute defaults
# ========================================================================

{
  my $nous = Langertha::Engine::NousResearch->new(
    api_key => 'test-key',
    model   => 'test',
  );

  is($nous->hermes_call_tag, 'tool_call', 'default call tag');
  is($nous->hermes_response_tag, 'tool_response', 'default response tag');
  like($nous->hermes_tool_instructions, qr/function calling AI model/, 'default instructions');
  like($nous->hermes_tool_prompt, qr/<tool_call>/, 'prompt contains call tag');
  like($nous->hermes_tool_prompt, qr/<tools>/, 'prompt contains tools block');
  like($nous->hermes_tool_prompt, qr/%s/, 'prompt contains placeholder');
}

# ========================================================================
# Custom tag configuration
# ========================================================================

{
  my $engine = Langertha::Engine::NousResearch->new(
    api_key            => 'test-key',
    model              => 'test',
    hermes_call_tag    => 'function_call',
    hermes_response_tag => 'function_response',
  );

  is($engine->hermes_call_tag, 'function_call', 'custom call tag');
  is($engine->hermes_response_tag, 'function_response', 'custom response tag');
  like($engine->hermes_tool_prompt, qr/<function_call>/, 'prompt uses custom call tag');
  unlike($engine->hermes_tool_prompt, qr/<tool_call>/, 'prompt does not have default tag');
}

# ========================================================================
# Custom instructions
# ========================================================================

{
  my $engine = Langertha::Engine::NousResearch->new(
    api_key                  => 'test-key',
    model                    => 'test',
    hermes_tool_instructions => 'Du bist ein hilfreicher Assistent.',
  );

  like($engine->hermes_tool_prompt, qr/Du bist ein hilfreicher/, 'custom instructions in prompt');
  unlike($engine->hermes_tool_prompt, qr/function calling AI model/, 'default instructions replaced');
  like($engine->hermes_tool_prompt, qr/<tools>/, 'structure preserved with custom instructions');
  like($engine->hermes_tool_prompt, qr/<tool_call>/, 'tags preserved with custom instructions');
}

# ========================================================================
# OpenAI does NOT compose HermesTools
# ========================================================================

{
  my $openai = Langertha::Engine::OpenAI->new(
    api_key => 'test-key',
    model   => 'test',
  );

  ok(!$openai->does('Langertha::Role::HermesTools'), 'OpenAI: does not compose HermesTools');
}

# ========================================================================
# hermes_extract_content
# ========================================================================

{
  my $nous = Langertha::Engine::NousResearch->new(
    api_key => 'test-key',
    model   => 'test',
  );

  my $data = {
    choices => [{
      message => {
        role    => 'assistant',
        content => 'Hello world',
      },
    }],
  };
  is($nous->hermes_extract_content($data), 'Hello world', 'extract content from OpenAI format');

  is($nous->hermes_extract_content(undef), undef, 'undef data returns undef');
  is($nous->hermes_extract_content({}), undef, 'empty data returns undef');
  is($nous->hermes_extract_content({ choices => [] }), undef, 'empty choices returns undef');
}

# ========================================================================
# response_tool_calls — single tool call
# ========================================================================

{
  my $nous = Langertha::Engine::NousResearch->new(
    api_key => 'test-key',
    model   => 'test',
  );

  my $data = {
    choices => [{
      message => {
        role    => 'assistant',
        content => "<tool_call>\n{\"name\": \"add\", \"arguments\": {\"a\": 7, \"b\": 15}}\n</tool_call>",
      },
    }],
  };

  my $calls = $nous->response_tool_calls($data);
  is(scalar @$calls, 1, 'one tool call parsed');
  is($calls->[0]{name}, 'add', 'tool call name');
  is_deeply($calls->[0]{arguments}, { a => 7, b => 15 }, 'tool call arguments');
}

# ========================================================================
# response_tool_calls — multiple tool calls
# ========================================================================

{
  my $nous = Langertha::Engine::NousResearch->new(
    api_key => 'test-key',
    model   => 'test',
  );

  my $data = {
    choices => [{
      message => {
        role    => 'assistant',
        content => "I'll call both tools.\n"
          . "<tool_call>\n{\"name\": \"add\", \"arguments\": {\"a\": 7, \"b\": 15}}\n</tool_call>\n"
          . "<tool_call>\n{\"name\": \"multiply\", \"arguments\": {\"a\": 3, \"b\": 4}}\n</tool_call>",
      },
    }],
  };

  my $calls = $nous->response_tool_calls($data);
  is(scalar @$calls, 2, 'two tool calls parsed');
  is($calls->[0]{name}, 'add', 'first tool call name');
  is($calls->[1]{name}, 'multiply', 'second tool call name');
  is_deeply($calls->[1]{arguments}, { a => 3, b => 4 }, 'second tool call arguments');
}

# ========================================================================
# response_tool_calls — no tool calls
# ========================================================================

{
  my $nous = Langertha::Engine::NousResearch->new(
    api_key => 'test-key',
    model   => 'test',
  );

  my $data = {
    choices => [{
      message => {
        role    => 'assistant',
        content => 'The result is 22.',
      },
    }],
  };

  my $calls = $nous->response_tool_calls($data);
  is(scalar @$calls, 0, 'no tool calls in plain text');
}

# ========================================================================
# response_tool_calls — empty/undef content
# ========================================================================

{
  my $nous = Langertha::Engine::NousResearch->new(
    api_key => 'test-key',
    model   => 'test',
  );

  is_deeply($nous->response_tool_calls({}), [], 'empty data returns empty');
  is_deeply($nous->response_tool_calls({ choices => [] }), [], 'empty choices returns empty');
}

# ========================================================================
# response_tool_calls — malformed JSON inside tags (skipped)
# ========================================================================

{
  my $nous = Langertha::Engine::NousResearch->new(
    api_key => 'test-key',
    model   => 'test',
  );

  my $data = {
    choices => [{
      message => {
        role    => 'assistant',
        content => "<tool_call>\nnot valid json\n</tool_call>\n"
          . "<tool_call>\n{\"name\": \"add\", \"arguments\": {\"a\": 1, \"b\": 2}}\n</tool_call>",
      },
    }],
  };

  my $calls = $nous->response_tool_calls($data);
  is(scalar @$calls, 1, 'malformed JSON skipped, valid one parsed');
  is($calls->[0]{name}, 'add', 'valid tool call extracted');
}

# ========================================================================
# response_text_content — strips tool_call tags
# ========================================================================

{
  my $nous = Langertha::Engine::NousResearch->new(
    api_key => 'test-key',
    model   => 'test',
  );

  my $data = {
    choices => [{
      message => {
        role    => 'assistant',
        content => "Some text before\n<tool_call>\n{\"name\":\"add\",\"arguments\":{\"a\":1,\"b\":2}}\n</tool_call>\nSome text after",
      },
    }],
  };

  is($nous->response_text_content($data), "Some text before\n\nSome text after", 'tool_call tags stripped, text preserved');
}

# ========================================================================
# response_text_content — plain text (no tags)
# ========================================================================

{
  my $nous = Langertha::Engine::NousResearch->new(
    api_key => 'test-key',
    model   => 'test',
  );

  my $data = {
    choices => [{
      message => {
        role    => 'assistant',
        content => '  The result is 22.  ',
      },
    }],
  };

  is($nous->response_text_content($data), 'The result is 22.', 'text trimmed, no tags to strip');
}

# ========================================================================
# format_tool_results
# ========================================================================

{
  my $nous = Langertha::Engine::NousResearch->new(
    api_key => 'test-key',
    model   => 'test',
  );

  my $data = {
    choices => [{
      message => {
        role    => 'assistant',
        content => "<tool_call>\n{\"name\":\"add\",\"arguments\":{\"a\":7,\"b\":15}}\n</tool_call>",
      },
    }],
  };

  my $results = [
    {
      tool_call => { name => 'add', arguments => { a => 7, b => 15 } },
      result    => {
        content => [{ type => 'text', text => '22' }],
      },
    },
  ];

  my @messages = $nous->format_tool_results($data, $results);
  is(scalar @messages, 2, 'two messages (assistant + tool result)');

  is($messages[0]{role}, 'assistant', 'first is assistant');
  like($messages[0]{content}, qr/<tool_call>/, 'assistant message preserves tool_call tags');

  is($messages[1]{role}, 'tool', 'second is tool result');
  like($messages[1]{content}, qr/<tool_response>/, 'tool result wrapped in tool_response tags');
  like($messages[1]{content}, qr/<\/tool_response>/, 'closing tool_response tag');

  my ($inner_json) = $messages[1]{content} =~ m{<tool_response>\n(.*)\n</tool_response>}s;
  my $parsed = $json->decode($inner_json);
  is($parsed->{name}, 'add', 'tool result name');
  is($parsed->{content}, '22', 'tool result content');
}

# ========================================================================
# format_tool_results — custom response tag
# ========================================================================

{
  my $engine = Langertha::Engine::NousResearch->new(
    api_key             => 'test-key',
    model               => 'test',
    hermes_response_tag => 'fn_response',
  );

  my $data = {
    choices => [{
      message => {
        role    => 'assistant',
        content => "<tool_call>{\"name\":\"add\",\"arguments\":{\"a\":1,\"b\":2}}</tool_call>",
      },
    }],
  };

  my $results = [
    {
      tool_call => { name => 'add', arguments => { a => 1, b => 2 } },
      result    => { content => [{ type => 'text', text => '3' }] },
    },
  ];

  my @messages = $engine->format_tool_results($data, $results);
  like($messages[1]{content}, qr/<fn_response>/, 'custom response tag used');
  unlike($messages[1]{content}, qr/<tool_response>/, 'default response tag not used');
}

# ========================================================================
# response_tool_calls — custom call tag
# ========================================================================

{
  my $engine = Langertha::Engine::NousResearch->new(
    api_key         => 'test-key',
    model           => 'test',
    hermes_call_tag => 'function_call',
  );

  my $data = {
    choices => [{
      message => {
        role    => 'assistant',
        content => "<function_call>\n{\"name\": \"add\", \"arguments\": {\"a\": 5, \"b\": 3}}\n</function_call>",
      },
    }],
  };

  my $calls = $engine->response_tool_calls($data);
  is(scalar @$calls, 1, 'custom call tag parsed');
  is($calls->[0]{name}, 'add', 'tool name from custom tag');

  # Default tag should NOT match
  my $data_default_tag = {
    choices => [{
      message => {
        role    => 'assistant',
        content => "<tool_call>\n{\"name\": \"add\", \"arguments\": {\"a\": 5, \"b\": 3}}\n</tool_call>",
      },
    }],
  };

  my $calls2 = $engine->response_tool_calls($data_default_tag);
  is(scalar @$calls2, 0, 'default tag NOT matched when custom tag is set');
}

# ========================================================================
# response_text_content — custom call tag stripped
# ========================================================================

{
  my $engine = Langertha::Engine::NousResearch->new(
    api_key         => 'test-key',
    model           => 'test',
    hermes_call_tag => 'fn_call',
  );

  my $data = {
    choices => [{
      message => {
        role    => 'assistant',
        content => "Result: <fn_call>{\"name\":\"x\",\"arguments\":{}}</fn_call>",
      },
    }],
  };

  is($engine->response_text_content($data), 'Result:', 'custom call tag stripped from text');
}

# ========================================================================
# Mock round-trip test — full Hermes tool calling loop
# ========================================================================

my $has_async_deps;
BEGIN {
  $has_async_deps = eval {
    require IO::Async::Loop;
    require Future::AsyncAwait;
    require Net::Async::MCP;
    require MCP::Server;
    1;
  };
}

SKIP: {
  skip 'Requires IO::Async, Future::AsyncAwait, Net::Async::MCP, and MCP modules', 15
    unless $has_async_deps;

  # Must import async/await at compile time, so we loaded in BEGIN above
  Future::AsyncAwait->import;
  require Test::MockAsyncHTTP;

  my $server = MCP::Server->new(name => 'test', version => '1.0');

  $server->tool(
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
  );

  my $loop = IO::Async::Loop->new;
  my $mcp = Net::Async::MCP->new(server => $server);
  $loop->add($mcp);

  # Hermes-style responses: text with <tool_call> tags
  my $tool_call_response = Test::MockAsyncHTTP->mock_json_response({
    choices => [{
      message => {
        role    => 'assistant',
        content => "<tool_call>\n{\"name\": \"add\", \"arguments\": {\"a\": 7, \"b\": 15}}\n</tool_call>",
      },
      finish_reason => 'stop',
    }],
  });

  my $final_response = Test::MockAsyncHTTP->mock_json_response({
    choices => [{
      message => {
        role    => 'assistant',
        content => 'The result of adding 7 and 15 is 22.',
      },
      finish_reason => 'stop',
    }],
  });

  my $mock_http = Test::MockAsyncHTTP->new(
    responses => [ $tool_call_response, $final_response ],
  );

  my $nous = Langertha::Engine::NousResearch->new(
    api_key     => 'test-key',
    model       => 'Hermes-4-70B',
    mcp_servers => [$mcp],
    _async_http => $mock_http,
  );

  # Use Future directly instead of async sub (avoids compile-time syntax issue)
  my $run = sub {
    $mcp->initialize->then(sub {
      $nous->chat_with_tools_f('What is 7 plus 15? Use the add tool.');
    })->then(sub {
      my ($response) = @_;

      like($response, qr/22/, 'Hermes round-trip: correct result');

      is($mock_http->request_count, 2, 'two HTTP requests made');

      my @requests = $mock_http->requests;

      # First request: tools in system prompt, NOT as parameter
      my $first_body = $json->decode($requests[0]->content);
      ok(!$first_body->{tools}, 'first request: no tools parameter (Hermes mode)');
      my $system_msg = $first_body->{messages}[0];
      is($system_msg->{role}, 'system', 'first message is system prompt');
      like($system_msg->{content}, qr/<tools>/, 'system prompt contains <tools> block');
      like($system_msg->{content}, qr/"add"/, 'system prompt contains tool definition');
      like($system_msg->{content}, qr/<tool_call>/, 'system prompt contains call tag example');

      # Second request: tool result conversation
      my $second_body = $json->decode($requests[1]->content);
      ok(!$second_body->{tools}, 'second request: no tools parameter');
      my @messages = @{$second_body->{messages}};

      # system -> user -> assistant (with tool_call) -> tool (result)
      is($messages[0]{role}, 'system', 'msg 0: system prompt');
      is($messages[1]{role}, 'user', 'msg 1: user');
      is($messages[2]{role}, 'assistant', 'msg 2: assistant with tool_call');
      like($messages[2]{content}, qr/<tool_call>/, 'assistant content has tool_call tag');
      is($messages[3]{role}, 'tool', 'msg 3: tool result');
      like($messages[3]{content}, qr/<tool_response>/, 'tool result has tool_response tag');
      like($messages[3]{content}, qr/22/, 'tool result contains 22');

      Future->done;
    });
  };

  $run->()->get;
}

done_testing;
