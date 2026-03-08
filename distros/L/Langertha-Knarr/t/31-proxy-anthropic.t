use strict;
use warnings;
use Test::More;

use Langertha::Knarr::Proxy::Anthropic;

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
  });
  is $params->{max_tokens}, 4096, 'max_tokens extracted';
  is $params->{temperature}, 0.5, 'temperature extracted';
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
