#!/usr/bin/env perl

use strict;
use warnings;

use Test2::Bundle::More;
use Module::Runtime qw( use_module );

my @modules = qw(
  Langertha
  Langertha::Engine::Anthropic
  Langertha::Engine::Groq
  Langertha::Engine::OpenAI
  Langertha::Engine::Ollama
  Langertha::Engine::vLLM
  Langertha::Engine::Whisper
  Langertha::Request::HTTP
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
