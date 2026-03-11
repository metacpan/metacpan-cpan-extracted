use strict;
use warnings;
use Test::More;

use Langertha::Knarr::Proxy::OpenAI;
use Langertha::Response;

my $class = 'Langertha::Knarr::Proxy::OpenAI';

{
  package Langertha::Engine::AnthropicBase;
  1;
}

{
  package Test::Knarr::Engine::AnthropicLike;
  our @ISA = ('Langertha::Engine::AnthropicBase');
}

# Test: format_name
is $class->format_name, 'openai', 'format name';

# Test: streaming_content_type
is $class->streaming_content_type, 'text/event-stream', 'SSE content type';

# Test: extract_model
{
  is $class->extract_model({ model => 'gpt-4o' }), 'gpt-4o', 'extract model';
  is $class->extract_model({}), 'default', 'default model';
}

# Test: extract_stream
{
  ok $class->extract_stream({ stream => 1 }), 'stream true';
  ok !$class->extract_stream({ stream => 0 }), 'stream false';
  ok !$class->extract_stream({}), 'stream default false';
}

# Test: extract_messages
{
  my $msgs = $class->extract_messages({
    messages => [
      { role => 'user', content => 'Hello' },
      { role => 'assistant', content => 'Hi' },
    ],
  });
  is scalar @$msgs, 2, 'two messages extracted';
  is $msgs->[0]{role}, 'user', 'first message role';
}

# Test: extract_params
{
  my $params = $class->extract_params({
    temperature => 0.7,
    max_tokens  => 1024,
    top_p       => 0.9,
    tools       => [{ type => 'function', function => { name => 'add' } }],
    tool_choice => 'required',
  });
  is $params->{temperature}, 0.7, 'temperature extracted';
  is $params->{max_tokens}, 1024, 'max_tokens extracted';
  is $params->{top_p}, 0.9, 'top_p extracted';
  is scalar @{$params->{tools}}, 1, 'tools extracted';
  is $params->{tool_choice}, 'required', 'tool_choice extracted';
}

# Test: prepare_engine_params converts OpenAI tools -> Anthropic tools
{
  my $engine = bless {}, 'Test::Knarr::Engine::AnthropicLike';
  my $prepared = $class->prepare_engine_params($engine, {
    tools => [{
      type => 'function',
      function => {
        name => 'add',
        description => 'Add numbers',
        parameters => { type => 'object', properties => { a => { type => 'number' } } },
      },
    }],
    tool_choice => {
      type => 'function',
      function => { name => 'add' },
    },
  });

  is $prepared->{tools}[0]{name}, 'add', 'tool name converted';
  is $prepared->{tools}[0]{input_schema}{type}, 'object', 'parameters converted to input_schema';
  is $prepared->{tool_choice}{type}, 'tool', 'tool_choice converted to anthropic tool';
  is $prepared->{tool_choice}{name}, 'add', 'tool_choice name preserved';
}

# Test: prepare_engine_params converts required -> any for Anthropic
{
  my $engine = bless {}, 'Test::Knarr::Engine::AnthropicLike';
  my $prepared = $class->prepare_engine_params($engine, {
    tool_choice => 'required',
  });
  is $prepared->{tool_choice}{type}, 'any', 'required converted to any';
}

# Test: prepare_engine_messages converts OpenAI tool calls/results -> Anthropic blocks
{
  my $engine = bless {}, 'Test::Knarr::Engine::AnthropicLike';
  my $prepared = $class->prepare_engine_messages($engine, [
    { role => 'system', content => 'You are helpful.' },
    {
      role => 'assistant',
      content => 'I will call a tool.',
      tool_calls => [{
        id       => 'call_1',
        type     => 'function',
        function => { name => 'add', arguments => '{"a":1,"b":2}' },
      }],
    },
    { role => 'tool', tool_call_id => 'call_1', content => '3' },
  ], {});

  is $prepared->[0]{role}, 'system', 'system role preserved';
  is ref($prepared->[1]{content}), 'ARRAY', 'assistant content converted to block array';
  is $prepared->[1]{content}[1]{type}, 'tool_use', 'assistant tool_call mapped to tool_use';
  is $prepared->[1]{content}[1]{name}, 'add', 'tool name mapped';
  is $prepared->[2]{role}, 'user', 'tool result mapped to user role';
  is $prepared->[2]{content}[0]{type}, 'tool_result', 'tool result block emitted';
  is $prepared->[2]{content}[0]{tool_use_id}, 'call_1', 'tool_use_id mapped';
}

# Test: format_response
{
  my $response = $class->format_response('Hello world', 'gpt-4o');
  is $response->{object}, 'chat.completion', 'correct object type';
  is $response->{model}, 'gpt-4o', 'model in response';
  is $response->{choices}[0]{message}{content}, 'Hello world', 'content in response';
  is $response->{choices}[0]{finish_reason}, 'stop', 'finish reason';
  like $response->{id}, qr/^chatcmpl-knarr-/, 'id format';
}

# Test: format_error
{
  my $err = $class->format_error('Something broke', 'server_error');
  is $err->{error}{message}, 'Something broke', 'error message';
  is $err->{error}{type}, 'server_error', 'error type';
}

# Test: format_response preserves tool_calls from raw OpenAI response
{
  my $result = Langertha::Response->new(
    content => '',
    raw => {
      choices => [{
        message => {
          content => '',
          tool_calls => [{
            id       => 'call_1',
            type     => 'function',
            function => { name => 'add', arguments => '{"a":1,"b":1}' },
          }],
        },
      }],
    },
  );
  my $response = $class->format_response($result, 'gpt-4o');
  ok ref($response->{choices}[0]{message}{tool_calls}) eq 'ARRAY', 'tool_calls present in response';
  is $response->{choices}[0]{finish_reason}, 'tool_calls', 'finish_reason set to tool_calls';
}

# Test: format_response parses Hermes <tool_call> XML in content
{
  my $response = $class->format_response(
    "before\n<tool_call>{\"name\":\"add\",\"arguments\":{\"a\":1,\"b\":2}}</tool_call>\nafter",
    'gpt-4o',
  );
  ok ref($response->{choices}[0]{message}{tool_calls}) eq 'ARRAY', 'Hermes tool_call mapped to OpenAI tool_calls';
  is $response->{choices}[0]{message}{tool_calls}[0]{function}{name}, 'add', 'tool name extracted';
  unlike $response->{choices}[0]{message}{content}, qr/<tool_call>/, 'tool_call XML removed from visible content';
}

# Test: format_models_response
{
  my $models = [
    { id => 'gpt-4o', engine => 'OpenAI', model => 'gpt-4o' },
    { id => 'llama', engine => 'Ollama', model => 'llama3.2' },
  ];
  my $response = $class->format_models_response($models);
  is $response->{object}, 'list', 'list object type';
  is scalar @{$response->{data}}, 2, 'two models';
  is $response->{data}[0]{id}, 'gpt-4o', 'first model id';
  like $response->{data}[0]{owned_by}, qr/knarr:OpenAI/, 'owned_by format';
}

# Test: stream_end_marker
is $class->stream_end_marker, "data: [DONE]\n\n", 'SSE done marker';

done_testing;
