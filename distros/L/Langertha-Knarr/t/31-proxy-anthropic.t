use strict;
use warnings;
use Test::More;

use Langertha::Knarr::Proxy::Anthropic;
use Langertha::Response;
use Langertha::Engine::OpenAI;

my $class = 'Langertha::Knarr::Proxy::Anthropic';

# Test: format_name
is $class->format_name, 'anthropic', 'format name';

# Test: streaming_content_type
is $class->streaming_content_type, 'text/event-stream', 'SSE content type';

# Test: extract_model
{
  is $class->extract_model({ model => 'claude-sonnet-4-6' }), 'claude-sonnet-4-6', 'extract model';
  is $class->extract_model({}), 'default', 'default model';
}

# Test: extract_stream
{
  ok $class->extract_stream({ stream => 1 }), 'stream true';
  ok !$class->extract_stream({ stream => 0 }), 'stream false';
  ok !$class->extract_stream({}), 'stream default false';
}

# Test: extract_messages (with system prompt)
{
  my $msgs = $class->extract_messages({
    system   => 'You are helpful',
    messages => [
      { role => 'user', content => 'Hello' },
    ],
  });
  is scalar @$msgs, 2, 'system + user = two messages';
  is $msgs->[0]{role}, 'system', 'first is system';
  is $msgs->[0]{content}, 'You are helpful', 'system content';
  is $msgs->[1]{role}, 'user', 'second is user';
}

# Test: extract_messages (without system prompt)
{
  my $msgs = $class->extract_messages({
    messages => [
      { role => 'user', content => 'Hello' },
    ],
  });
  is scalar @$msgs, 1, 'just one message';
}

# Test: extract_params
{
  my $params = $class->extract_params({
    max_tokens  => 4096,
    temperature => 0.5,
    top_p       => 0.9,
    tools       => [{ name => 'add', input_schema => { type => 'object' } }],
    tool_choice => { type => 'tool', name => 'add' },
  });
  is $params->{max_tokens}, 4096, 'max_tokens extracted';
  is $params->{temperature}, 0.5, 'temperature extracted';
  is scalar @{$params->{tools}}, 1, 'tools extracted';
  is $params->{tool_choice}{name}, 'add', 'tool_choice extracted';
}

# Test: prepare_engine_params converts Anthropic tools -> OpenAI tools
{
  my $engine = Langertha::Engine::OpenAI->new(api_key => 'test-key', model => 'gpt-4o-mini');
  my $prepared = $class->prepare_engine_params($engine, {
    tools => [{
      name => 'add',
      description => 'Add numbers',
      input_schema => { type => 'object', properties => { a => { type => 'number' } } },
    }],
    tool_choice => { type => 'tool', name => 'add' },
  });

  is $prepared->{tools}[0]{type}, 'function', 'converted to OpenAI function tool';
  is $prepared->{tools}[0]{function}{name}, 'add', 'tool name preserved';
  is $prepared->{tool_choice}{type}, 'function', 'tool_choice converted to function';
  is $prepared->{tool_choice}{function}{name}, 'add', 'tool_choice name preserved';
}

# Test: prepare_engine_messages converts Anthropic tool blocks -> OpenAI messages
{
  my $engine = Langertha::Engine::OpenAI->new(api_key => 'test-key', model => 'gpt-4o-mini');
  my $prepared = $class->prepare_engine_messages($engine, [
    {
      role => 'assistant',
      content => [
        { type => 'text', text => 'I will call a tool.' },
        { type => 'tool_use', id => 'toolu_1', name => 'add', input => { a => 1, b => 1 } },
      ],
    },
    {
      role => 'user',
      content => [
        { type => 'tool_result', tool_use_id => 'toolu_1', content => '2' },
      ],
    },
  ], {});

  is $prepared->[0]{role}, 'assistant', 'assistant message preserved';
  ok ref($prepared->[0]{tool_calls}) eq 'ARRAY', 'assistant tool_calls generated';
  is $prepared->[0]{tool_calls}[0]{function}{name}, 'add', 'tool_call function name';
  is $prepared->[1]{role}, 'tool', 'tool_result mapped to tool role';
  is $prepared->[1]{tool_call_id}, 'toolu_1', 'tool_call_id mapped';
}

# Test: format_response
{
  my $response = $class->format_response('Hello world', 'claude-sonnet-4-6');
  is $response->{type}, 'message', 'correct type';
  is $response->{role}, 'assistant', 'assistant role';
  is $response->{model}, 'claude-sonnet-4-6', 'model in response';
  is $response->{content}[0]{type}, 'text', 'content block type';
  is $response->{content}[0]{text}, 'Hello world', 'content text';
  is $response->{stop_reason}, 'end_turn', 'stop reason';
  like $response->{id}, qr/^msg-knarr-/, 'id format';
}

# Test: format_response maps OpenAI tool_calls -> Anthropic tool_use blocks
{
  my $result = Langertha::Response->new(
    content => '',
    raw => {
      choices => [{
        message => {
          content => '',
          tool_calls => [{
            id => 'call_123',
            type => 'function',
            function => {
              name => 'add',
              arguments => '{"a":1,"b":1}',
            },
          }],
        },
      }],
    },
  );
  my $response = $class->format_response($result, 'gpt-proxy');
  is $response->{content}[0]{type}, 'tool_use', 'tool_use block emitted';
  is $response->{content}[0]{name}, 'add', 'tool_use name mapped';
  is $response->{stop_reason}, 'tool_use', 'stop_reason set to tool_use';
}

# Test: format_response parses Hermes <tool_call> XML into tool_use
{
  my $response = $class->format_response(
    "before\n<tool_call>{\"name\":\"add\",\"arguments\":{\"a\":1,\"b\":2}}</tool_call>\nafter",
    'claude-proxy',
  );
  my @tool_use = grep { ($_->{type} // '') eq 'tool_use' } @{$response->{content}};
  ok @tool_use, 'Hermes tool_call mapped to tool_use';
  is $tool_use[0]{name}, 'add', 'tool_use name extracted';
  is $response->{stop_reason}, 'tool_use', 'stop_reason indicates tool use';
}

# Test: format_error
{
  my $err = $class->format_error('Something broke', 'server_error');
  is $err->{type}, 'error', 'error type field';
  is $err->{error}{message}, 'Something broke', 'error message';
  is $err->{error}{type}, 'server_error', 'error detail type';
}

# Test: stream_end_marker
is $class->stream_end_marker, "event: message_stop\ndata: {}\n\n", 'Anthropic stream end';

done_testing;
