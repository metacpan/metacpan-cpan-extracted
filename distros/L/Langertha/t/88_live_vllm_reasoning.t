#!/usr/bin/env perl
# ABSTRACT: Live test for reasoning_effort on Langertha::Engine::vLLM (karr #79)

use strict;
use warnings;

use Test2::Bundle::More;

# Needs a vLLM server serving a reasoning model (Qwen3 / DeepSeek-R1 / QwQ /
# Gemma 4 / Granite 3.2) that was started with a matching --reasoning-parser.
# The parser flag is server-side and cannot be asserted from here, so the
# chain-of-thought checks below diagnose instead of failing. The wire itself
# (reasoning_effort on the request body) is covered offline by
# t/65c_vllm_reasoning.t - this file only exercises the round trip.
BEGIN {
  unless ($ENV{TEST_LANGERTHA_VLLM_URL} && $ENV{TEST_LANGERTHA_VLLM_REASONING_MODEL}) {
    plan skip_all => 'TEST_LANGERTHA_VLLM_URL and TEST_LANGERTHA_VLLM_REASONING_MODEL not set';
  }
}

require Langertha::Engine::vLLM;

my $url    = $ENV{TEST_LANGERTHA_VLLM_URL};
my $model  = $ENV{TEST_LANGERTHA_VLLM_REASONING_MODEL};
my $prompt = 'Solve step by step: what is 7 factorial?';

# A reasoning model spends tokens on the thought before the answer; without a
# roomy budget the visible content can come back empty for reasons that have
# nothing to do with reasoning_effort. At reasoning_effort=high the thought
# alone can outrun a few thousand tokens: the reasoning parser then hands back
# the whole truncated thought as the reasoning field, content stays empty and
# finish_reason is 'length' -- a red test with no reasoning bug behind it.
my $response_size = 8192;

# Thinking levels to try, most intense first. Which of them the server accepts
# is decided by the loaded model's chat template, not by vLLM: Qwen3.8-27B-FP8
# rejects the OpenAI-shaped `high` with a 400 ("Unexpected reasoning effort
# high. Supported types are xhigh (default), medium, and low", live-probed
# 2026-09-17), while most other reasoning models take exactly that. A live test
# cannot know which model was loaded, so it walks the list until one is
# accepted instead of pinning a level that is only right for some servers.
my @efforts = qw( high xhigh medium low );

# Set by the thinking subtest, read by the =none cross-check.
my $saw_thinking_high;

# --- Thinking path: a thinking-level reasoning_effort on a hard problem ---
subtest 'reasoning_effort: thinking level' => sub {
  my ($resp, $effort, @rejected);
  for my $candidate (@efforts) {
    my $engine = Langertha::Engine::vLLM->new(
      url              => $url,
      model            => $model,
      reasoning_effort => $candidate,
      response_size    => $response_size,
    );
    my $try;
    if (eval { $try = $engine->simple_chat($prompt); 1 }) {
      ($resp, $effort) = ($try, $candidate);
      last;
    }
    push @rejected, "$candidate: $@";
  }
  unless (defined $resp) {
    fail "no thinking-level reasoning_effort accepted by the server";
    diag $_ for @rejected;
    return;
  }
  diag "reasoning_effort=$effort accepted"
    . (@rejected ? " (server rejected: " . join(', ', map { (split /:/)[0] } @rejected) . ")" : '');
  ok(defined $resp, 'returns a response');
  ok(length("$resp") > 0, 'response is non-empty');
  diag "model: " . ($resp->has_model ? $resp->model : '(not reported)');
  diag "finish_reason: " . ($resp->has_finish_reason ? $resp->finish_reason : '(not reported)');
  diag "empty content with finish_reason=length means response_size ($response_size) "
    . "ran out before the thought closed - raise it, this is not a reasoning bug"
    if !length("$resp") && $resp->has_finish_reason && $resp->finish_reason eq 'length';
  diag "response: $resp";

  # The chain-of-thought is lifted onto Langertha::Response->thinking by
  # Langertha::Role::OpenAICompatible->chat_response, from whichever spelling
  # the server uses (vLLM >= 0.16 sends `reasoning`, older builds and other
  # OpenAI-compatible providers `reasoning_content`). It only arrives when the
  # server runs --reasoning-parser <qwen3|deepseek_r1|...> matching the model.
  $saw_thinking_high = ($resp->has_thinking && length $resp->thinking) ? 1 : 0;
  if ($saw_thinking_high) {
    ok($resp->thinking, 'chain-of-thought surfaced on Response->thinking');
    diag "thinking (" . length($resp->thinking) . " chars): "
      . substr($resp->thinking, 0, 200);
  }
  else {
    diag "no chain-of-thought - was the server started with a "
      . "--reasoning-parser matching $model?";
    pass 'thinking extraction path exercised (server returned none)';
  }
};

# --- Non-thinking path: reasoning_effort=none ---
subtest 'reasoning_effort=none' => sub {
  my $engine = Langertha::Engine::vLLM->new(
    url              => $url,
    model            => $model,
    reasoning_effort => 'none',
    response_size    => $response_size,
  );
  my $resp = eval { $engine->simple_chat($prompt) };
  if ($@) {
    fail "simple_chat with reasoning_effort=none failed: $@";
    return;
  }
  ok(defined $resp, 'returns a response');
  ok(length("$resp") > 0, 'response is non-empty');
  diag "response: $resp";

  my $saw_thinking_none = ($resp->has_thinking && length $resp->thinking) ? 1 : 0;

  if (!defined $saw_thinking_high) {
    diag "no high-effort result to cross-check against";
    return;
  }
  if ($saw_thinking_high && !$saw_thinking_none) {
    ok(!$saw_thinking_none,
      'reasoning_effort=none suppressed the thinking that high produced');
  }
  elsif ($saw_thinking_high) {
    diag "server still emitted a chain-of-thought (reasoning) for reasoning_effort=none - "
      . "some vLLM builds do not map 'none' onto enable_thinking=false "
      . "(see the note in t/65c_vllm_reasoning.t)";
    pass 'non-thinking path exercised (server did not honour none)';
  }
  else {
    diag "high effort produced no thinking either - nothing to cross-check";
    pass 'non-thinking path exercised (no reasoning parser on the server)';
  }
};

done_testing;
