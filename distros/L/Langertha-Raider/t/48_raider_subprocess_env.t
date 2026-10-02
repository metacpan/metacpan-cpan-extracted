#!/usr/bin/env perl
# ABSTRACT: raider subprocess tests never leak a dummy engine key to the child

use strict;
use warnings;
use Test2::V0;
use Path::Tiny;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();

# karr #52: t/39_cli_main.t and friends only deleted six known *_API_KEY
# names before spawning bin/raider, so an engine not on that list --
# MINIMAX_API_KEY among them -- stayed in the child's environment. Harmless
# while raider's own autodetection only checks those six, but
# env_var_for_engine and _engine_class in Langertha::Raider::CLI already
# know minimax, so an explicit -e minimax (or a future autodetection
# change) would read straight through. clear_engine_env() is the fix:
# every *_API_KEY, plus the handful of token/URL envs that don't end in
# that suffix, is gone before any raider subprocess test forks a child.

my $repo = path(__FILE__)->absolute->parent->parent;
my $bin  = $repo->child('bin', 'raider');
my $q    = sub { join ' ', map { "'$_'" } @_ };

subtest 'clear_engine_env scrubs every *_API_KEY plus the token/URL extras' => sub {
  local %ENV = %ENV;
  @ENV{qw( ANTHROPIC_API_KEY MINIMAX_API_KEY LANGERTHA_MINIMAX_API_KEY
    HF_TOKEN REPLICATE_API_TOKEN OLLAMA_URL WHISPER_URL )} = ('x') x 7;
  $ENV{UNRELATED_THING} = 'kept';

  clear_engine_env();

  ok(!exists $ENV{$_}, "$_ cleared") for qw(
    ANTHROPIC_API_KEY MINIMAX_API_KEY LANGERTHA_MINIMAX_API_KEY
    HF_TOKEN REPLICATE_API_TOKEN OLLAMA_URL WHISPER_URL
  );
  is($ENV{UNRELATED_THING}, 'kept', 'unrelated env vars are left alone');
};

subtest 'a raider subprocess never sees a dummy MINIMAX_API_KEY once clear_engine_env has run' => sub {
  local $ENV{MINIMAX_API_KEY} = 'x';

  # Sanity: without clearing, the child inherits it like any other env var
  # -- this is the leak karr #52 is about, and it proves the detection
  # below (grepping the child's own report of its config sources) works.
  my $leaked = `@{[ $q->($^X, '-I'.$repo->child('lib'), $bin, 'config', 'explain', '-e', 'minimax', '--no-color') ]} 2>&1 </dev/null`;
  like($leaked, qr/env MINIMAX_API_KEY/, 'without clearing, the child does inherit it')
    or diag $leaked;

  clear_engine_env();

  my $clean = `@{[ $q->($^X, '-I'.$repo->child('lib'), $bin, 'config', 'explain', '-e', 'minimax', '--no-color') ]} 2>&1 </dev/null`;
  unlike($clean, qr/MINIMAX_API_KEY/, 'after clear_engine_env, the child no longer sees it')
    or diag $clean;
};

done_testing;
