#!/usr/bin/env perl
# ABSTRACT: finish_reason "error" without an error object and a Gemini stream error chunk croak
use strict;
use warnings;
use Test2::Bundle::More;
use JSON::MaybeXS;
use HTTP::Response;

use Langertha::Engine::OpenAI;
use Langertha::Engine::OpenRouter;
use Langertha::Engine::Gemini;

# karr k317, the gaps k311 left (t/44_choice_error_responses.t):
#  - a choice whose finish_reason is 'error' with no error object anywhere
#    (none on the choice, none at the top level) passed as a normal finish:
#    the caller got an empty or truncated answer that looked complete. The
#    provider said the generation failed, so it croaks
#    "<class> response|stream ended with finish_reason error".
#  - a Gemini stream chunk with a top-level `error` object (the error Google
#    sends into an already-open stream) had no candidate and no blockReason,
#    so it was skipped and the stream ended as a short, silent success. It
#    croaks "<class> stream carried an error: <message> (<code>)", k301/k311
#    wording. Bodies are shaped from the API references, not live captures.

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

sub mock_http {
  my ($body) = @_;
  my $http = HTTP::Response->new( 200, 'OK' );
  $http->content( $json->encode($body) );
  $http->header( 'Content-Type' => 'application/json' );
  return $http;
}

my $openai     = Langertha::Engine::OpenAI->new( api_key => 'k' );
my $openrouter = Langertha::Engine::OpenRouter->new( api_key => 'k', model => 'openai/gpt-4o' );

subtest 'OpenAI-compatible: finish_reason error without an error object croaks' => sub {
  my $resp = eval {
    $openrouter->chat_response( mock_http( {
      id => 'gen-3', model => 'openai/gpt-4o',
      choices => [ { finish_reason => 'error', message => { role => 'assistant', content => 'partial' } } ],
    } ) );
  };
  ok !defined $resp, 'no Response returned';
  like $@, qr/\ALangertha::Engine::OpenRouter response ended with finish_reason error at /,
    'croak names the engine and the finish_reason';

  eval { $openai->chat_response( mock_http( {
    error => undef,
    choices => [ { finish_reason => 'error', error => undef, message => { content => '' } } ],
  } ) ) };
  like $@, qr/\ALangertha::Engine::OpenAI response ended with finish_reason error at /,
    'error null on the choice and at the top level is still no error object';

  eval { $openai->chat_response( mock_http( {
    choices => [ { finish_reason => 'error', message => { content => '' },
      error => { message => 'with object', code => 500 } } ],
  } ) ) };
  like $@, qr/response carried an error: with object \(500\)/,
    'an error object still wins with its own message (k311)';

  my $ok = $openai->chat_response( mock_http( {
    choices => [ { finish_reason => 'stop', message => { content => 'fine' } } ],
  } ) );
  is "$ok", 'fine', 'another finish_reason is an answer';
};

subtest 'OpenAI-compatible stream: finish_reason error without an error object croaks' => sub {
  my $got = eval {
    $openrouter->parse_stream_chunk( {
      choices => [ { index => 0, delta => { content => '' }, finish_reason => 'error' } ],
    }, undef, {} );
  };
  ok !defined $got, 'no chunk returned';
  like $@, qr/\ALangertha::Engine::OpenRouter stream ended with finish_reason error at /,
    'the stream croaks, naming the engine';

  my $chunk = $openai->parse_stream_chunk(
    { choices => [ { index => 0, delta => { content => 'x' }, finish_reason => 'stop' } ] }, undef, {} );
  is $chunk->finish_reason, 'stop', 'an ordinary final chunk is unchanged';
};

subtest 'Gemini stream: a top-level error object croaks' => sub {
  my $gemini = Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-2.5-flash' );
  my $got = eval {
    $gemini->parse_stream_chunk( {
      error => { code => 503, message => 'The model is overloaded. Please try again later.',
        status => 'UNAVAILABLE' },
    } );
  };
  ok !defined $got, 'no chunk returned';
  like $@, qr/\ALangertha::Engine::Gemini stream carried an error: The model is overloaded\. Please try again later\. \(503\)/,
    'croak names the engine, the message and the code';

  eval { $gemini->parse_stream_chunk( { error => { error => { message => 'nested', code => 500 } } } ) };
  like $@, qr/stream carried an error: nested \(500\)/, 'a nested error object is unwrapped';

  my $chunk = $gemini->parse_stream_chunk( {
    candidates => [ { content => { parts => [ { text => 'hi' } ] } } ],
  } );
  is $chunk->content, 'hi', 'an ordinary chunk is unchanged';
};

done_testing;
