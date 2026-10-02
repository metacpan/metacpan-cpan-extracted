#!/usr/bin/env perl
# ABSTRACT: Usage reads Gemini's cache count and AKI/Ollama native top-level counts at the universal door (k197)

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use HTTP::Response;
use Path::Tiny qw( path );

use Langertha::Usage;
use Langertha::Engine::AKI;
use Langertha::Engine::Ollama;
use Langertha::Engine::Gemini;

# karr k197, ADR 0018 tier 1 / ADR 0028. Langertha::Usage is the universal
# inbound door for token counts: from_hash for a usage block, from_raw for a
# whole decoded body (what a sibling dist such as langertha-raider holds when it
# sends its own request). A spelling only an engine's chat_response knows is
# lost to every caller that never gets a Response, so:
#   - Gemini's cachedContentTokenCount must reach Usage.cached_tokens (it was
#     always undef, so Gemini cache-hit telemetry read as "not reported");
#   - AKI native's top-level prompt_length / num_generated_tokens /
#     num_cached_tokens must be found by from_raw (it returned undef);
#   - from_raw must agree with Engine::Ollama on "no usage": the engine treats a
#     zero count as not reported, so a zero-only body is undef, not Usage(0).

my $data_dir = path(__FILE__)->parent->child('data');
my $json     = JSON::MaybeXS->new->canonical(1)->utf8(1);

sub capture { $json->decode( $data_dir->child("$_[0].json")->slurp_raw ) }

sub http_json {
  my ($body) = @_;
  my $res = HTTP::Response->new( 200, 'OK' );
  $res->header( 'Content-Type' => 'application/json' );
  $res->content($body);
  return $res;
}

subtest 'AKI native: from_raw reads the verbatim capture like the engine does' => sub {
  my $data  = capture('aki_chat_response');
  my $usage = Langertha::Usage->from_raw($data);
  isa_ok( $usage, ['Langertha::Usage'], 'prompt_length body is a reported usage' );
  is( $usage->input_tokens,  38, 'prompt_length -> input_tokens' );
  is( $usage->output_tokens, 3,  'num_generated_tokens -> output_tokens' );
  is( $usage->total_tokens,  41, 'total derived' );
  is( $usage->cached_tokens, 16, 'num_cached_tokens -> cached_tokens' );

  # Same bytes through the engine: from_raw must not disagree with it.
  my $engine = Langertha::Engine::AKI->new( api_key => 'testkey' );
  my $resp = $engine->chat_response(
    http_json( $data_dir->child('aki_chat_response.json')->slurp_raw ) );
  is_deeply( [ $resp->prompt_tokens, $resp->completion_tokens, $resp->cached_tokens ],
      [ 38, 3, 16 ], 'Engine::AKI chat_response reads the same capture' );
  # Response.usage is the documented cross-provider place to read the cache
  # count; it must agree with the Response.cached_tokens shortcut (k197 I1).
  is( $resp->usage->cached_tokens, 16, 'Response->usage->cached_tokens carries num_cached_tokens' );
  is( $resp->usage->{prompt_tokens}, 38, 'usage->{prompt_tokens} hash key unchanged' );
  is( $resp->usage->{completion_tokens}, 3, 'usage->{completion_tokens} hash key unchanged' );

  # The capture with only its cache count left: the engine keeps the count,
  # so from_raw must too.
  my %cached_only = %$data;
  delete @cached_only{qw( prompt_length num_generated_tokens )};
  my $cached = Langertha::Usage->from_raw( \%cached_only );
  isa_ok( $cached, ['Langertha::Usage'], 'a cache-count-only body is reported usage' );
  is( $cached && $cached->cached_tokens, 16, 'from_raw keeps the lone cache count' );
  my $cached_resp = $engine->chat_response( http_json( $json->encode( \%cached_only ) ) );
  is( $cached_resp->usage && $cached_resp->usage->cached_tokens, 16, 'Engine::AKI agrees' );
};

subtest 'Ollama native: from_raw follows the engine on zero counts' => sub {
  my $data = capture('ollama_tool_result_response');
  my $usage = Langertha::Usage->from_raw($data);
  is_deeply( [ $usage->input_tokens, $usage->output_tokens ], [ 200, 99 ], 'verbatim capture counts' );

  # The capture with its counts zeroed / dropped (a fully prompt-cached,
  # generation-less turn): Engine::Ollama reports no usage, so must from_raw.
  my %zero = %$data;
  $zero{prompt_eval_count} = 0;
  delete $zero{eval_count};
  is( Langertha::Usage->from_raw( \%zero ), undef,
      'prompt_eval_count 0 and no eval_count is not reported usage' );
  my $engine = Langertha::Engine::Ollama->new( url => 'http://localhost:11434' );
  ok( !$engine->chat_response( http_json( $json->encode( \%zero ) ) )->has_usage,
      'Engine::Ollama agrees: no usage' );

  # A zero input with a real output count is still reported.
  my %half = %zero;
  $half{eval_count} = 99;
  my $half = Langertha::Usage->from_raw( \%half );
  is_deeply( [ $half->input_tokens, $half->output_tokens ], [ 0, 99 ], 'zero input, real output' );
};

# No verbatim Gemini chat capture exists in t/data; the usageMetadata shape
# below follows t/47_gemini_cached_content.t and the documented
# generateContent response (ai.google.dev/api/generate-content).
my $gemini_body = {
  candidates => [ {
    content      => { parts => [ { text => 'cached answer' } ], role => 'model' },
    finishReason => 'STOP',
  } ],
  usageMetadata => {
    promptTokenCount        => 100,
    candidatesTokenCount    => 5,
    totalTokenCount         => 105,
    cachedContentTokenCount => 80,
  },
  modelVersion => 'gemini-2.5-pro',
};

subtest 'Gemini: cachedContentTokenCount reaches cached_tokens' => sub {
  my $raw = Langertha::Usage->from_raw($gemini_body);
  is( $raw->cached_tokens, 80, 'from_raw on the raw body (camelCase)' );
  is( $raw->total_tokens, 105, 'totalTokenCount kept' );

  my $engine = Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-2.5-pro' );
  my $resp = $engine->chat_response( http_json( $json->encode($gemini_body) ) );
  is( $resp->usage->cached_tokens, 80, 'engine path (snake_case rename) -> Usage.cached_tokens' );
  is( $resp->cached_tokens, 80, 'lifted onto Response.cached_tokens' );

  # The engine keeps its snake_case rename: the %{} overload serves that hash
  # verbatim, and these keys are the documented back-compat surface.
  is( $resp->usage->{prompt_tokens}, 100, 'usage->{prompt_tokens} still served' );
  is( $resp->usage->{cached_content_token_count}, 80, 'usage->{cached_content_token_count} still served' );

  my %plain = %{ $gemini_body->{usageMetadata} };
  delete $plain{cachedContentTokenCount};
  is( Langertha::Usage->from_hash( \%plain )->cached_tokens, undef, 'absent cache count stays undef' );
};

done_testing;
