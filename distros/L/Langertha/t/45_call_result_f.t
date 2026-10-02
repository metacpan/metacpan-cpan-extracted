#!/usr/bin/env perl
# ABSTRACT: simple_embedding_result_f / simple_transcription_call_f / simple_image_result_f return a Langertha::CallResult (mocked async)
use strict;
use warnings;
use Test2::Bundle::More;
use lib 't/lib';

use HTTP::Response;
use JSON::MaybeXS;
use Test::MockAsyncHTTP;
use Langertha::Engine::OpenAI;
use Langertha::Engine::Gemini;
use Langertha::Engine::Ollama;
use Langertha::Engine::Whisper;

# karr k314 (ADR 0034): simple_embedding, simple_transcription and
# simple_image return bare values, so the usage block the provider bills by
# (OpenAI embeddings, GPT image tokens, gpt-transcribe tokens), the rate limit
# of that response and the call's duration were thrown away -- a caller could
# not account for or back off from a non-chat call. The *_result / *_call
# variants keep the bare value in ->value and carry the rest; the bare methods
# stay unchanged. The usage is read through Usage->from_raw so every wire
# spelling it knows (usage, Ollama's prompt_eval_count) counts, and a
# duration-billed transcription gets no Usage: zero tokens would be a lie.

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

sub json_response {
  my ( $data, %headers ) = @_;
  my $response = Test::MockAsyncHTTP->mock_json_response($data);
  $response->header( $_ => $headers{$_} ) for sort keys %headers;
  return $response;
}

my %RATE = ( 'x-ratelimit-remaining-requests' => 4999, 'x-ratelimit-limit-requests' => 5000 );

sub openai {
  my ( $mock, %args ) = @_;
  return Langertha::Engine::OpenAI->new( api_key => 'sk-test', url => 'http://mock.invalid/v1',
    _async_http => $mock, %args );
}

subtest 'simple_embedding_result_f: vector, usage, rate limit, answering model, timing' => sub {
  my $mock = Test::MockAsyncHTTP->new( responses => [
    json_response({ object => 'list', model => 'text-embedding-3-small-20260101',
      data => [ { object => 'embedding', index => 0, embedding => [ 0.1, 0.2 ] } ],
      usage => { prompt_tokens => 7, total_tokens => 7 } }, %RATE),
  ] );
  my $e = openai( $mock, embedding_model => 'text-embedding-3-small' );
  my $result = $e->simple_embedding_result_f('hello')->get;
  isa_ok $result, 'Langertha::CallResult';
  is_deeply $result->value, [ 0.1, 0.2 ], 'value is what simple_embedding_f resolves to';
  ok $result->has_usage, 'usage kept';
  is $result->usage->input_tokens, 7, 'prompt_tokens read as input_tokens';
  is $result->usage->total_tokens, 7, 'total_tokens';
  ok $result->has_rate_limit, 'rate limit of this response';
  is $result->rate_limit->requests_remaining, 4999, 'requests_remaining from the headers';
  is $result->model, 'text-embedding-3-small-20260101', 'the model the body names wins over the requested one';
  ok $result->has_total_seconds && $result->total_seconds >= 0, 'total_seconds measured';
  is $result->raw->{object}, 'list', 'decoded body in raw';
  is $json->decode( ( $mock->requests )[0]->content )->{model}, 'text-embedding-3-small', 'requested model sent';
};

subtest 'simple_embedding_result_f: a batch, and an HTTP error fails like simple_embedding_f' => sub {
  my $mock = Test::MockAsyncHTTP->new( responses => [
    json_response({ data => [ { index => 1, embedding => [ 2 ] }, { index => 0, embedding => [ 1 ] } ] }),
    json_response({ error => { message => 'Invalid API key' } }),
  ] );
  $mock->{responses}[1]->code(401);
  $mock->{responses}[1]->message('Unauthorized');
  my $e = openai($mock);
  my $result = $e->simple_embedding_result_f([ 'a', 'b' ])->get;
  is_deeply $result->value, [ [1], [2] ], 'ArrayRef of vectors in input order';
  ok !$result->has_usage, 'no usage block, no usage';
  ok !$result->has_rate_limit, 'no rate limit headers, no rate limit';
  is $result->model, 'text-embedding-3-large', 'no model in the body: the requested model';

  my $f = $e->simple_embedding_result_f('x');
  ok $f->is_failed, 'fails on a 401';
  like scalar $f->failure, qr/401 Unauthorized.*Invalid API key/s, 'with the sync croak text';
};

subtest 'Gemini and Ollama embeddings' => sub {
  my $gmock = Test::MockAsyncHTTP->new( responses => [ json_response({ embedding => { values => [ 0.3 ] } }) ] );
  my $gemini = Langertha::Engine::Gemini->new( api_key => 'k', _async_http => $gmock );
  my $result = $gemini->simple_embedding_result_f('x')->get;
  is_deeply $result->value, [ 0.3 ], 'Gemini vector';
  ok !$result->has_usage, 'Gemini reports no usage';
  is $result->model, $gemini->embedding_model, 'requested model';

  my $omock = Test::MockAsyncHTTP->new( responses => [
    json_response({ model => 'all-minilm', embeddings => [ [ 0.4 ] ], prompt_eval_count => 5,
      total_duration => 1000 }),
  ] );
  my $ollama = Langertha::Engine::Ollama->new( url => 'http://mock.invalid', model => 'all-minilm',
    _async_http => $omock );
  $result = $ollama->simple_embedding_result_f('x')->get;
  is_deeply $result->value, [ 0.4 ], 'Ollama vector';
  is $result->usage->input_tokens, 5, "Ollama's prompt_eval_count read as input_tokens";
  is $result->model, 'all-minilm', 'model';
};

subtest 'simple_transcription_call_f: text value, token usage, duration usage, text body' => sub {
  my $mock = Test::MockAsyncHTTP->new( responses => [
    json_response({ text => 'hello world',
      usage => { type => 'tokens', input_tokens => 14, output_tokens => 45, total_tokens => 59,
        input_token_details => { text_tokens => 0, audio_tokens => 14 } } }, %RATE),
    json_response({ text => 'hi', duration => 1.5, segments => [ { text => 'hi' } ],
      usage => { type => 'duration', seconds => 2 } }),
    { content => "1\n00:00:00,000 --> 00:00:01,000\nhi\n", content_type => 'text/plain' },
  ] );
  my $e = openai($mock);
  my $audio = "RIFF\0\x01" x 8;
  my $result = $e->simple_transcription_call_f( \$audio, filename => 'a.wav' )->get;
  isa_ok $result, 'Langertha::CallResult';
  is $result->value, 'hello world', 'value is the transcript text, as simple_transcription_f';
  is $result->usage->input_tokens, 14, 'token usage';
  is $result->usage->output_tokens, 45, 'output tokens';
  is $result->rate_limit->requests_remaining, 4999, 'rate limit';
  is $result->model, 'gpt-transcribe', 'requested model';

  $result = $e->simple_transcription_call_f( \$audio, filename => 'a.wav', model => 'whisper-1',
    response_format => 'verbose_json' )->get;
  is $result->value, 'hi', 'verbose_json text';
  ok !$result->has_usage, 'duration-billed usage is no token Usage';
  is $result->raw->{usage}{seconds}, 2, 'the billed seconds stay in raw';
  is $result->raw->{segments}[0]{text}, 'hi', 'segments reachable in raw';
  is $result->model, 'whisper-1', 'a model in %extra is the requested model';

  $result = $e->simple_transcription_call_f( \$audio, filename => 'a.wav', model => 'whisper-1',
    response_format => 'srt' )->get;
  like $result->value, qr/-->/, 'plain-text answer is the value';
  ok !$result->has_raw, 'no raw for a plain-text body';
  ok !$result->has_usage, 'no usage';
};

subtest 'Whisper server: simple_transcription_call_f' => sub {
  my $mock = Test::MockAsyncHTTP->new( responses => [ json_response({ text => 'ok' }) ] );
  my $e = Langertha::Engine::Whisper->new( url => 'http://mock.invalid/v1', _async_http => $mock,
    transcription_model => 'Systran/faster-whisper-small' );
  my $result = $e->simple_transcription_call_f( \"RIFF\0", filename => 'a.wav' )->get;
  is $result->value, 'ok', 'text';
  is $result->model, 'Systran/faster-whisper-small', 'model';
};

subtest 'simple_image_result_f: images, gpt-image usage, model' => sub {
  my $mock = Test::MockAsyncHTTP->new( responses => [
    json_response({ created => 1, data => [ { b64_json => 'aGk=' } ],
      usage => { input_tokens => 50, output_tokens => 4160, total_tokens => 4210,
        input_tokens_details => { text_tokens => 50, image_tokens => 0 } } }, %RATE),
    json_response({ created => 1, data => [] }),
  ] );
  my $e = openai($mock);
  my $result = $e->simple_image_result_f( 'A cat', size => '1024x1024' )->get;
  isa_ok $result, 'Langertha::CallResult';
  is_deeply $result->value, [ { b64_json => 'aGk=' } ], 'value is what simple_image_f resolves to';
  is $result->usage->output_tokens, 4160, 'image output tokens';
  is $result->usage->total_tokens, 4210, 'total tokens';
  is $result->rate_limit->requests_remaining, 4999, 'rate limit';
  is $result->model, 'gpt-image-2', 'requested model (the body names none)';

  my $f = $e->simple_image_result_f('A dog');
  ok $f->is_failed, 'no image fails the future';
  like scalar $f->failure, qr/image response contained no image/, 'with the sync croak text';
};

done_testing;
