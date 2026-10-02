#!/usr/bin/env perl
# ABSTRACT: Verify all Langertha modules load successfully

use strict;
use warnings;

use Test2::Bundle::More;
use Module::Runtime qw( use_module );
use Path::Tiny qw( path );
use FindBin;

# Loading the deprecated facade modules emits a one-time carp by design.
# Suppress those during the load smoketest so test output stays clean.
$SIG{__WARN__} = sub {
  return if $_[0] =~ /backwards-compatibility facade/;
  warn @_;
};

# Discover every *.pm under lib/ instead of maintaining a hand-written list.
# The load smoketest has no editorial judgement — every module that ships
# should compile standalone. (karr #107 — the previous hardcoded list was
# missing 35 modules.)
my $lib = path($FindBin::Bin)->parent->child('lib');

my @modules;
if ($lib->is_dir) {
  $lib->visit(
    sub {
      my ($path) = @_;
      return unless -f $path && $path->basename =~ /\.pm\z/;
      my $rel = $path->relative($lib)->stringify;
      $rel =~ s/\.pm\z//;
      push @modules, join '::', split m{/}, $rel;
    },
    { recurse => 1 },
  );
}

# Sort by dotted module name so glob order does not shuffle the report.
@modules = sort @modules;

# 35 modules the previous hand-maintained list missed (karr #107). Asserting
# the discovery actually sees them guards against a future disk walk that
# silently narrows itself (e.g. someone refactoring to walk only Engine/).
my @must_have = (
  # Engines
  qw(
    Langertha::Engine::AKIAnthropic
    Langertha::Engine::HuggingFace
    Langertha::Engine::Moonshot
    Langertha::Engine::MoonshotAnthropic
    Langertha::Engine::OpenAIResponses
    Langertha::Engine::TranscriptionBase
    Langertha::Engine::VLLMHook
    Langertha::Engine::XAI
  ),
  # Roles
  qw(
    Langertha::Role::AnthropicCompatible
    Langertha::Role::CachedContent
    Langertha::Role::Capabilities
    Langertha::Role::Chat
    Langertha::Role::ContextSize
    Langertha::Role::Embedding
    Langertha::Role::HermesTools
    Langertha::Role::HTTP
    Langertha::Role::ImageGeneration
    Langertha::Role::JSON
    Langertha::Role::KeepAlive
    Langertha::Role::Models
    Langertha::Role::OpenAPI
    Langertha::Role::ParallelToolUse
    Langertha::Role::PluginHost
    Langertha::Role::PromptCache
    Langertha::Role::ReasoningEffort
    Langertha::Role::ResponseFormat
    Langertha::Role::ResponseSize
    Langertha::Role::RuntimeKnobs
    Langertha::Role::Seed
    Langertha::Role::StaticModels
    Langertha::Role::Streaming
    Langertha::Role::SystemPrompt
    Langertha::Role::Temperature
    Langertha::Role::ThinkTag
    Langertha::Role::Transcription
  ),
);

# TAP requires the plan before any test output.
# 1 (lib is_dir) + 1 (scalar @modules) + 35 (must-have) + scalar @modules (load)
plan( 37 + scalar @modules );

ok( $lib->is_dir, "located the lib/ tree at $lib" )
  or BAIL_OUT("no directory at $lib — the smoketest cannot see the modules");

ok( scalar @modules, 'discovered at least one module' )
  or BAIL_OUT('disk walk found no modules — discovery is broken');

my %seen = map { $_ => 1 } @modules;
for my $module (@must_have) {
  ok( $seen{$module}, "discovery includes $module" );
}

for my $module (@modules) {
  eval {
    is(use_module($module), $module, 'Loaded '.$module);
  };
  if ($@) { fail('Loading of module '.$module.' failed with '.$@) }
}

done_testing;
