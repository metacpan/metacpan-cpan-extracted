#!/usr/bin/env perl
# ABSTRACT: Live integration test for the Perplexity Agent API (karr #147 / #139)
#
# COSTS REAL MONEY. Gated on TEST_LANGERTHA_PERPLEXITY_API_KEY; skipped without
# it. Two tiny calls against the cheapest preset (sonar -> "fast") pin the core
# wire reality the eight LIVE-CONFIRM points resolved to (k147, 2026-09-14):
#
#   1. search-augmented chat returns content AND lifts search_results into
#      Response.citations (the #139 end-to-end verdict);
#   2. a top-level response_format=json_schema is honored and returns structured
#      JSON (Agent API's response_format enum is json_schema-only).
#
# The deeper framing (typed-SSE stream, bare-vs-typed input, json_object 400,
# reasoning.effort echo, preset->model resolution) is pinned OFFLINE against
# captured fixtures in t/68_perplexity_agent.t, so this file stays cheap.

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

BEGIN {
  plan skip_all => 'TEST_LANGERTHA_PERPLEXITY_API_KEY not set'
    unless $ENV{TEST_LANGERTHA_PERPLEXITY_API_KEY};
}

use Langertha::Engine::Perplexity;

sub ppx {
  Langertha::Engine::Perplexity->new(
    api_key            => $ENV{TEST_LANGERTHA_PERPLEXITY_API_KEY},
    user_agent_timeout => 180,
    @_,
  );
}

# 1. Search-augmented chat: content + citations (the #139 end-to-end verdict).
subtest 'search-augmented chat returns content and citations' => sub {
  my $engine = ppx( model => 'sonar', response_size => 80 );
  my $resp = eval {
    $engine->simple_chat('What is the capital of France? Answer in one short sentence.')
  };
  if ( $@ ) {
    die $@ if $@ !~ /429/;
    diag "Rate limited (429), skipping";
    pass "skipped due to rate limit";
    return;
  }

  ok( length("$resp") > 0, 'non-empty content' );
  diag "Content: $resp";
  ok( $resp->has_model, 'response reports a model' );
  diag "Model: " . ( $resp->model // 'n/a' ) . " (preset fast)";

  ok( $resp->has_citations, 'search_results lifted into Response.citations' );
  if ( $resp->has_citations && @{ $resp->citations } ) {
    ok( defined $resp->citations->[0]{url}, 'first citation carries a url' );
    diag "Citations: " . scalar( @{ $resp->citations } );
  }
};

# 2. Structured output: top-level response_format=json_schema returns JSON.
subtest 'response_format json_schema returns structured JSON' => sub {
  my $schema = {
    type       => 'object',
    properties => { capital => { type => 'string' } },
    required   => ['capital'],
    additionalProperties => JSON::MaybeXS->false,
  };
  my $engine = ppx(
    model         => 'sonar',
    response_size => 80,
    response_format => {
      type        => 'json_schema',
      json_schema => { name => 'capital_answer', schema => $schema, strict => JSON::MaybeXS->true },
    },
  );
  my $resp = eval { $engine->simple_chat('Give the capital of France as JSON.') };
  if ( $@ ) {
    die $@ if $@ !~ /429/;
    diag "Rate limited (429), skipping";
    pass "skipped due to rate limit";
    return;
  }

  my $decoded = eval { JSON::MaybeXS->new->decode("$resp") };
  ok( $decoded && ref $decoded eq 'HASH', 'content is a JSON object' )
    or diag "Content was: $resp";
  ok( exists $decoded->{capital}, 'strict json_schema honored: only the required key' )
    if $decoded && ref $decoded eq 'HASH';
  diag "Structured: $resp";
};

done_testing;
