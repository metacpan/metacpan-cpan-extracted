#!/usr/bin/env perl
# ABSTRACT: Live integration test for the MiniMax engine

use strict;
use warnings;

use Test2::Bundle::More;

BEGIN {
  unless ($ENV{TEST_LANGERTHA_MINIMAX_API_KEY}) {
    plan skip_all => 'Set TEST_LANGERTHA_MINIMAX_API_KEY to run this test';
  }
}

use Langertha::Engine::MiniMax;
use Langertha::Engine::MiniMaxAnthropic;

# --- simple_chat ---

my $minimax = Langertha::Engine::MiniMax->new(
  api_key => $ENV{TEST_LANGERTHA_MINIMAX_API_KEY},
);

my $response = $minimax->simple_chat('Say exactly: Hello Langertha');
ok(defined $response, 'simple_chat returns a response');
ok(length $response > 0, 'simple_chat response is non-empty');
diag "MiniMax chat response: $response";

# --- list_models ---
# MiniMax has no /v1/models endpoint, so the engine composes
# Langertha::Role::StaticModels: list_models returns the hardcoded list
# (no HTTP) rather than throwing. Mirrors t/50_list_models.t.

my $model_ids = $minimax->list_models;
is(ref($model_ids), 'ARRAY', 'list_models returns an arrayref (static list, no HTTP)');
ok(scalar(@$model_ids) > 0, 'list_models is non-empty');
ok((grep { $_ eq 'MiniMax-M3' } @$model_ids), 'list_models contains MiniMax-M3');
diag "MiniMax static models: @$model_ids";

# --- MiniMaxAnthropic simple_chat (regression for karr #18) ---
# The Anthropic-shim url default must compose a single /v1/messages; a double
# /v1 used to 404 on every model.

my $minimax_anthropic = Langertha::Engine::MiniMaxAnthropic->new(
  api_key => $ENV{TEST_LANGERTHA_MINIMAX_API_KEY},
  model   => 'MiniMax-M3',
);

my $anthropic_response = $minimax_anthropic->simple_chat('Say exactly: Hello Langertha');
ok(defined $anthropic_response, 'MiniMaxAnthropic simple_chat returns a response');
ok(length $anthropic_response > 0, 'MiniMaxAnthropic simple_chat response is non-empty');
diag "MiniMaxAnthropic chat response: $anthropic_response";

# The Coding Plan web-search-via-Raider integration moved to the
# langertha-raider distribution together with Langertha::Raider.

done_testing;
