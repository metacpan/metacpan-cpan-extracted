#!/usr/bin/env perl
# ABSTRACT: Demo showing Engine, Embedder, Chat, and Raider abstractions
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

$|=1;

use IO::Async::Loop;
use Future::AsyncAwait;
use Langertha::Chat;
use Langertha::Embedder;
use Langertha::Raider;

# --- Configuration ---
# Supports Ollama (default) or OpenAI via env vars.
#
#   Ollama (default):
#     OLLAMA_URL=http://localhost:11434 perl ex/raider_rag.pl
#
#   OpenAI:
#     OPENAI_API_KEY=sk-... perl ex/raider_rag.pl

my ($engine, $embedder);

if ($ENV{OPENAI_API_KEY}) {
  require Langertha::Engine::OpenAI;
  $engine = Langertha::Engine::OpenAI->new(
    api_key => $ENV{OPENAI_API_KEY},
    model   => $ENV{OPENAI_MODEL} || 'gpt-4o-mini',
  );
  # OpenAI: same engine can embed (text-embedding-3-small default)
  $embedder = Langertha::Embedder->new(engine => $engine);
  printf "Engine: OpenAI %s\n", $engine->model;
} else {
  my $url = $ENV{OLLAMA_URL} || 'http://localhost:11434';
  require Langertha::Engine::Ollama;
  $engine = Langertha::Engine::Ollama->new(
    url   => $url,
    model => $ENV{OLLAMA_MODEL} || 'qwen3:1.7b',
  );
  # Ollama: different model for embeddings — Embedder handles the override
  $embedder = Langertha::Embedder->new(
    engine => $engine,
    model  => 'nomic-embed-text-v2-moe',
  );
  printf "Engine: Ollama %s + nomic-embed (via Embedder)\n", $engine->model;
}

# --- Demo 1: Chat abstraction ---

print "\n=== Chat abstraction ===\n";

my $casual_chat = Langertha::Chat->new(
  engine        => $engine,
  system_prompt => 'You are a casual, friendly assistant. Keep answers short.',
  temperature   => 0.9,
);

my $formal_chat = Langertha::Chat->new(
  engine        => $engine,
  system_prompt => 'You are a formal, precise assistant. Be concise.',
  temperature   => 0.1,
);

printf "Casual: %s\n", $casual_chat->simple_chat('What is Perl in one sentence?');
printf "Formal: %s\n", $formal_chat->simple_chat('What is Perl in one sentence?');

# --- Demo 2: Embedder abstraction ---

print "\n=== Embedder abstraction ===\n";
my $vec = $embedder->simple_embedding('Perl is a great language');
printf "Embedding dimensions: %d\n", scalar @$vec;
printf "First 3 values: [%.4f, %.4f, %.4f]\n", @{$vec}[0..2];

# --- Demo 3: Raider with plugin Name => Args syntax ---

print "\n=== Raider with plugins ===\n\n";

async sub main {
  my $raider = Langertha::Raider->new(
    engine     => $engine,
    raider_mcp => 1,
    mission    => 'You are a helpful Perl programming assistant. Be concise.',
  );

  my $r1 = await $raider->raid_f('What is Moose in Perl? One paragraph.');
  printf "Answer:\n%s\n\n", $r1;

  printf "Metrics: raids=%d, iterations=%d, tool_calls=%d, time=%.0fms\n",
    $raider->metrics->{raids},
    $raider->metrics->{iterations},
    $raider->metrics->{tool_calls},
    $raider->metrics->{time_ms};
}

main()->get;
