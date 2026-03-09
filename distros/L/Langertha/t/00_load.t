#!/usr/bin/env perl
# ABSTRACT: Verify all Langertha modules load successfully

use strict;
use warnings;

use Test2::Bundle::More;
use Module::Runtime qw( use_module );

my @modules = qw(
  Langertha
  Langertha::Engine::Remote
  Langertha::Engine::OpenAIBase
  Langertha::Engine::AKI
  Langertha::Engine::AKIOpenAI
  Langertha::Engine::Anthropic
  Langertha::Engine::AnthropicBase
  Langertha::Engine::Cerebras
  Langertha::Engine::DeepSeek
  Langertha::Engine::Gemini
  Langertha::Engine::Groq
  Langertha::Engine::LlamaCpp
  Langertha::Engine::LMStudio
  Langertha::Engine::LMStudioAnthropic
  Langertha::Engine::LMStudioOpenAI
  Langertha::Engine::MiniMax
  Langertha::Engine::Mistral
  Langertha::Engine::NousResearch
  Langertha::Engine::OpenAI
  Langertha::Engine::OpenRouter
  Langertha::Engine::Ollama
  Langertha::Engine::OllamaOpenAI
  Langertha::Engine::Perplexity
  Langertha::Engine::Replicate
  Langertha::Engine::vLLM
  Langertha::Engine::Whisper
  Langertha::Raider
  Langertha::Raider::Result
  Langertha::Result
  Langertha::RunContext
  Langertha::Role::Runnable
  Langertha::Raid
  Langertha::Raid::Sequential
  Langertha::Raid::Parallel
  Langertha::Raid::Loop
  Langertha::Request::HTTP
  Langertha::Response
  Langertha::Role::Langfuse
  Langertha::Role::OpenAICompatible
  Langertha::Role::Tools
  LangerthaX
);

plan(scalar @modules);

for my $module (@modules) {
  eval {
    is(use_module($module), $module, 'Loaded '.$module);
  };
  if ($@) { fail('Loading of module '.$module.' failed with '.$@) }
}

done_testing;
