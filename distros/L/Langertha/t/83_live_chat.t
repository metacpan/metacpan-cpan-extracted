#!/usr/bin/env perl
# ABSTRACT: Live simple_chat test for all engines

use strict;
use warnings;

use Test2::Bundle::More;

BEGIN {
  my @available;
  push @available, 'openai'       if $ENV{TEST_LANGERTHA_OPENAI_API_KEY};
  push @available, 'anthropic'    if $ENV{TEST_LANGERTHA_ANTHROPIC_API_KEY};
  push @available, 'gemini'       if $ENV{TEST_LANGERTHA_GEMINI_API_KEY};
  push @available, 'groq'         if $ENV{TEST_LANGERTHA_GROQ_API_KEY};
  push @available, 'mistral'      if $ENV{TEST_LANGERTHA_MISTRAL_API_KEY};
  push @available, 'deepseek'     if $ENV{TEST_LANGERTHA_DEEPSEEK_API_KEY};
  push @available, 'minimax'      if $ENV{TEST_LANGERTHA_MINIMAX_API_KEY};
  push @available, 'perplexity'   if $ENV{TEST_LANGERTHA_PERPLEXITY_API_KEY};
  push @available, 'cerebras'     if $ENV{TEST_LANGERTHA_CEREBRAS_API_KEY};
  push @available, 'openrouter'   if $ENV{TEST_LANGERTHA_OPENROUTER_API_KEY};
  push @available, 'nousresearch' if $ENV{TEST_LANGERTHA_NOUSRESEARCH_API_KEY};
  push @available, 'aki'          if $ENV{TEST_LANGERTHA_AKI_API_KEY};
  push @available, 'ollama'       if $ENV{TEST_LANGERTHA_OLLAMA_URL};
  push @available, 'ollamaopenai' if $ENV{TEST_LANGERTHA_OLLAMA_URL};
  push @available, 'vllm'         if $ENV{TEST_LANGERTHA_VLLM_URL};
  push @available, 'llamacpp'     if $ENV{TEST_LANGERTHA_LLAMACPP_URL};
  push @available, 'lmstudio'     if $ENV{TEST_LANGERTHA_LMSTUDIO_URL};
  unless (@available) {
    plan skip_all => 'No TEST_LANGERTHA_* env vars set';
  }
}

my $prompt = 'Say exactly: Hello Langertha';

sub test_chat {
  my ($name, $engine) = @_;
  subtest "$name simple_chat" => sub {
    my $response = eval { $engine->simple_chat($prompt) };
    if ($@) {
      if ($@ =~ /429/) {
        diag "$name: rate limited (429), skipping";
        pass "skipped due to rate limit";
        return;
      }
      fail "simple_chat failed: $@";
      return;
    }
    ok(defined $response, 'returns a response');
    ok(length("$response") > 0, 'response is non-empty');
    diag "$name: $response";

    # Check response metadata
    if ($response->can('model') && $response->model) {
      diag "  model: " . $response->model;
    }
  };
}

# --- OpenAI ---
if ($ENV{TEST_LANGERTHA_OPENAI_API_KEY}) {
  require Langertha::Engine::OpenAI;
  test_chat('OpenAI', Langertha::Engine::OpenAI->new(
    api_key => $ENV{TEST_LANGERTHA_OPENAI_API_KEY},
    model => 'gpt-4o-mini',
  ));
}

# --- Anthropic ---
if ($ENV{TEST_LANGERTHA_ANTHROPIC_API_KEY}) {
  require Langertha::Engine::Anthropic;
  test_chat('Anthropic', Langertha::Engine::Anthropic->new(
    api_key => $ENV{TEST_LANGERTHA_ANTHROPIC_API_KEY},
    model => 'claude-haiku-4-5-20251001',
  ));
}

# --- Gemini ---
if ($ENV{TEST_LANGERTHA_GEMINI_API_KEY}) {
  require Langertha::Engine::Gemini;
  test_chat('Gemini', Langertha::Engine::Gemini->new(
    api_key => $ENV{TEST_LANGERTHA_GEMINI_API_KEY},
    model => 'gemini-2.5-flash',
  ));
}

# --- Groq ---
if ($ENV{TEST_LANGERTHA_GROQ_API_KEY}) {
  require Langertha::Engine::Groq;
  test_chat('Groq', Langertha::Engine::Groq->new(
    api_key => $ENV{TEST_LANGERTHA_GROQ_API_KEY},
    model => 'llama-3.3-70b-versatile',
  ));
}

# --- Mistral ---
if ($ENV{TEST_LANGERTHA_MISTRAL_API_KEY}) {
  require Langertha::Engine::Mistral;
  test_chat('Mistral', Langertha::Engine::Mistral->new(
    api_key => $ENV{TEST_LANGERTHA_MISTRAL_API_KEY},
  ));
}

# --- DeepSeek ---
if ($ENV{TEST_LANGERTHA_DEEPSEEK_API_KEY}) {
  require Langertha::Engine::DeepSeek;
  test_chat('DeepSeek', Langertha::Engine::DeepSeek->new(
    api_key => $ENV{TEST_LANGERTHA_DEEPSEEK_API_KEY},
    model => 'deepseek-chat',
  ));
}

# --- MiniMax ---
if ($ENV{TEST_LANGERTHA_MINIMAX_API_KEY}) {
  require Langertha::Engine::MiniMax;
  test_chat('MiniMax', Langertha::Engine::MiniMax->new(
    api_key => $ENV{TEST_LANGERTHA_MINIMAX_API_KEY},
  ));
}

# --- Perplexity ---
if ($ENV{TEST_LANGERTHA_PERPLEXITY_API_KEY}) {
  require Langertha::Engine::Perplexity;
  test_chat('Perplexity', Langertha::Engine::Perplexity->new(
    api_key => $ENV{TEST_LANGERTHA_PERPLEXITY_API_KEY},
  ));
}

# --- Cerebras ---
if ($ENV{TEST_LANGERTHA_CEREBRAS_API_KEY}) {
  require Langertha::Engine::Cerebras;
  test_chat('Cerebras', Langertha::Engine::Cerebras->new(
    api_key => $ENV{TEST_LANGERTHA_CEREBRAS_API_KEY},
  ));
}

# --- OpenRouter (use :free model) ---
if ($ENV{TEST_LANGERTHA_OPENROUTER_API_KEY}) {
  require Langertha::Engine::OpenRouter;
  my $model = $ENV{TEST_LANGERTHA_OPENROUTER_MODEL} || 'meta-llama/llama-3.3-70b-instruct:free';
  test_chat("OpenRouter/$model", Langertha::Engine::OpenRouter->new(
    api_key => $ENV{TEST_LANGERTHA_OPENROUTER_API_KEY},
    model => $model,
  ));
}

# --- NousResearch ---
if ($ENV{TEST_LANGERTHA_NOUSRESEARCH_API_KEY}) {
  require Langertha::Engine::NousResearch;
  test_chat('NousResearch', Langertha::Engine::NousResearch->new(
    api_key => $ENV{TEST_LANGERTHA_NOUSRESEARCH_API_KEY},
    model => 'Hermes-4-70B',
  ));
}

# --- AKI (native) ---
if ($ENV{TEST_LANGERTHA_AKI_API_KEY}) {
  require Langertha::Engine::AKI;
  test_chat('AKI', Langertha::Engine::AKI->new(
    api_key => $ENV{TEST_LANGERTHA_AKI_API_KEY},
  ));
}

# --- Ollama (native) ---
if ($ENV{TEST_LANGERTHA_OLLAMA_URL}) {
  require Langertha::Engine::Ollama;
  my $model = $ENV{TEST_LANGERTHA_OLLAMA_MODEL} || 'qwen3:8b';
  test_chat("Ollama/$model", Langertha::Engine::Ollama->new(
    url => $ENV{TEST_LANGERTHA_OLLAMA_URL},
    model => $model,
  ));

  # --- OllamaOpenAI (same URL, /v1 appended) ---
  require Langertha::Engine::OllamaOpenAI;
  test_chat("OllamaOpenAI/$model", Langertha::Engine::OllamaOpenAI->new(
    url => $ENV{TEST_LANGERTHA_OLLAMA_URL} . '/v1',
    model => $model,
  ));
}

# --- vLLM ---
if ($ENV{TEST_LANGERTHA_VLLM_URL}) {
  require Langertha::Engine::vLLM;
  my $model = $ENV{TEST_LANGERTHA_VLLM_MODEL};
  if ($model) {
    test_chat("vLLM/$model", Langertha::Engine::vLLM->new(
      url => $ENV{TEST_LANGERTHA_VLLM_URL},
      model => $model,
    ));
  } else {
    diag "Skipping vLLM: TEST_LANGERTHA_VLLM_MODEL not set";
  }
}

# --- LlamaCpp ---
if ($ENV{TEST_LANGERTHA_LLAMACPP_URL}) {
  require Langertha::Engine::LlamaCpp;
  test_chat('LlamaCpp', Langertha::Engine::LlamaCpp->new(
    url => $ENV{TEST_LANGERTHA_LLAMACPP_URL},
  ));
}

# --- LMStudio ---
if ($ENV{TEST_LANGERTHA_LMSTUDIO_URL}) {
  require Langertha::Engine::LMStudio;
  require Langertha::Engine::LMStudioAnthropic;
  require Langertha::Engine::LMStudioOpenAI;
  my $model = $ENV{TEST_LANGERTHA_LMSTUDIO_MODEL} || 'default';
  test_chat("LMStudio/$model", Langertha::Engine::LMStudio->new(
    url => $ENV{TEST_LANGERTHA_LMSTUDIO_URL},
    model => $model,
    $ENV{TEST_LANGERTHA_LMSTUDIO_API_KEY}
      ? (api_key => $ENV{TEST_LANGERTHA_LMSTUDIO_API_KEY})
      : (),
  ));

  test_chat("LMStudioAnthropic/$model", Langertha::Engine::LMStudioAnthropic->new(
    url => $ENV{TEST_LANGERTHA_LMSTUDIO_URL},
    model => $model,
    api_key => ($ENV{TEST_LANGERTHA_LMSTUDIO_API_KEY} || 'lmstudio'),
  ));

  test_chat("LMStudioOpenAI/$model", Langertha::Engine::LMStudioOpenAI->new(
    url => $ENV{TEST_LANGERTHA_LMSTUDIO_URL} . '/v1',
    model => $model,
    $ENV{TEST_LANGERTHA_LMSTUDIO_API_KEY}
      ? (api_key => $ENV{TEST_LANGERTHA_LMSTUDIO_API_KEY})
      : (),
  ));
}

done_testing;
