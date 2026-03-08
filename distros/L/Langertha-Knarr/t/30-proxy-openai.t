use strict;
use warnings;
use Test::More;

use Langertha::Knarr::Proxy::OpenAI;

my $class = 'Langertha::Knarr::Proxy::OpenAI';

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
  });
  is $params->{temperature}, 0.7, 'temperature extracted';
  is $params->{max_tokens}, 1024, 'max_tokens extracted';
  is $params->{top_p}, 0.9, 'top_p extracted';
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
