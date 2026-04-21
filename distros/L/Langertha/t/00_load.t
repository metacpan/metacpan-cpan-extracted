#!/usr/bin/env perl
# ABSTRACT: Verify all Langertha modules load successfully

use strict;
use warnings;

use Test2::Bundle::More;
use Module::Runtime qw( use_module );

# Loading the deprecated facade modules emits a one-time carp by design.
# Suppress those during the load smoketest so test output stays clean.
$SIG{__WARN__} = sub {
  return if $_[0] =~ /backwards-compatibility facade/;
  warn @_;
};

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
  Langertha::Engine::MiniMaxAnthropic
  Langertha::Engine::Mistral
  Langertha::Engine::NousResearch
  Langertha::Engine::OpenAI
  Langertha::Engine::OpenRouter
  Langertha::Engine::Ollama
  Langertha::Engine::OllamaOpenAI
  Langertha::Engine::Perplexity
  Langertha::Engine::Replicate
  Langertha::Engine::SGLang
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
  Langertha::Input
  Langertha::Input::Tools
  Langertha::Output
  Langertha::Output::Tools
  Langertha::Metrics
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
