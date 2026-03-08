use strict;
use warnings;
use Test::More;

use Langertha::Knarr::Proxy::Ollama;

my $class = 'Langertha::Knarr::Proxy::Ollama';

# Test: format_name
is $class->format_name, 'ollama', 'format name';

# Test: streaming_content_type
is $class->streaming_content_type, 'application/x-ndjson', 'NDJSON content type';

# Test: extract_model
{
  is $class->extract_model({ model => 'llama3.2' }), 'llama3.2', 'extract model';
  is $class->extract_model({}), 'default', 'default model';
}

# Test: extract_stream (Ollama defaults to streaming)
{
  ok $class->extract_stream({}), 'stream default true';
  ok $class->extract_stream({ stream => 1 }), 'stream explicit true';
  ok !$class->extract_stream({ stream => 0 }), 'stream explicit false';
}

# Test: extract_messages
{
  my $msgs = $class->extract_messages({
    messages => [
      { role => 'system', content => 'Be helpful' },
      { role => 'user', content => 'Hello' },
    ],
  });
  is scalar @$msgs, 2, 'two messages extracted';
  is $msgs->[0]{role}, 'system', 'system role';
}

# Test: extract_params
{
  my $params = $class->extract_params({
    options => {
      temperature => 0.8,
      num_predict => 256,
      top_p       => 0.9,
    },
  });
  is $params->{temperature}, 0.8, 'temperature from options';
  is $params->{num_predict}, 256, 'num_predict from options';
}

# Test: extract_params without options
{
  my $params = $class->extract_params({});
  is_deeply $params, {}, 'no params without options';
}

# Test: format_response
{
  my $response = $class->format_response('Hello world', 'llama3.2');
  is $response->{model}, 'llama3.2', 'model in response';
  is $response->{message}{role}, 'assistant', 'assistant role';
  is $response->{message}{content}, 'Hello world', 'content';
  ok $response->{done}, 'done flag';
  is $response->{done_reason}, 'stop', 'done reason';
  ok $response->{created_at}, 'has timestamp';
}

# Test: format_error
{
  my $err = $class->format_error('Something broke');
  is $err->{error}, 'Something broke', 'error message';
}

# Test: format_models_response
{
  my $models = [
    { id => 'llama3.2', engine => 'OllamaOpenAI', model => 'llama3.2' },
    { id => 'qwen2.5', engine => 'OllamaOpenAI', model => 'qwen2.5' },
  ];
  my $response = $class->format_models_response($models);
  ok exists $response->{models}, 'has models key';
  is scalar @{$response->{models}}, 2, 'two models';
  is $response->{models}[0]{name}, 'llama3.2', 'first model name';
  is $response->{models}[0]{details}{family}, 'OllamaOpenAI', 'family from engine';
}

# Test: stream_end_marker
is $class->stream_end_marker, undef, 'no stream end marker for NDJSON';

done_testing;
