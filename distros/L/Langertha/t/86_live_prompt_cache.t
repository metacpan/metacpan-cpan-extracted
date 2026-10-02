#!/usr/bin/env perl
# ABSTRACT: Live integration test for request-side prompt caching (karr #16, slice 2)
#
# COSTS REAL MONEY. Gated on the matching TEST_LANGERTHA_<ENGINE>_API_KEY;
# subtests without a key are skipped. Spend is kept tiny (small response_size).
#
# Anthropic: two identical requests with a long cacheable prefix and
# prompt_cache => 1, asserting the second request reads from the cache
# (usage.cache_read_input_tokens > 0). The prefix is built deliberately above
# Anthropic's minimum cacheable size (~4096 tokens on claude-opus-4-8; ~2048 on
# Sonnet) so caching engages reliably.
#
# OpenAI: caching is automatic with no per-request enable, so we only confirm
# the prompt_cache_key routing hint is ACCEPTED on the wire (HTTP 200) — there
# is no cheap, deterministic cache-hit assertion for OpenAI.

use strict;
use warnings;

use Test2::Bundle::More;

BEGIN {
  my @available;
  push @available, 'anthropic' if $ENV{TEST_LANGERTHA_ANTHROPIC_API_KEY};
  push @available, 'openai'    if $ENV{TEST_LANGERTHA_OPENAI_API_KEY};
  unless (@available) {
    plan skip_all => 'No TEST_LANGERTHA_{ANTHROPIC,OPENAI}_API_KEY set (live prompt cache test)';
  }
}

# A long, deterministic, byte-stable prefix. No timestamps/UUIDs — any volatile
# byte in the prefix would silently prevent a cache hit. ~100 repeats of a
# ~60-token paragraph lands comfortably above the ~4096-token Opus minimum.
my $PARAGRAPH = join(' ',
  'Langertha is a Perl framework for talking to large language model engines.',
  'It composes capabilities from Moose roles and routes tool calls through value',
  'objects keyed by a wire-format tag. This paragraph exists only to build a',
  'large, stable, cacheable prefix so the provider can store and reuse it across',
  'two identical requests during this prompt-caching integration test.'
) . "\n";
my $BIG_PREFIX = $PARAGRAPH x 100;

# Anthropic — cache_control:{type:ephemeral}; second identical request must read it.
SKIP: {
  skip 'no TEST_LANGERTHA_ANTHROPIC_API_KEY', 1
    unless $ENV{TEST_LANGERTHA_ANTHROPIC_API_KEY};
  require Langertha::Engine::Anthropic;
  my $e = Langertha::Engine::Anthropic->new(
    api_key       => $ENV{TEST_LANGERTHA_ANTHROPIC_API_KEY},
    model         => 'claude-opus-4-8',
    system_prompt => $BIG_PREFIX,
    prompt_cache  => 1,
    response_size => 16,
  );

  my $r1 = eval { $e->simple_chat('Reply with the single word: ok') };
  diag("Anthropic first call error: $@") if $@;
  my $r2 = eval { $e->simple_chat('Reply with the single word: ok') };
  diag("Anthropic second call error: $@") if $@;

  my $u1 = ( ref $r1 && $r1->has_usage ) ? $r1->usage : {};
  my $u2 = ( ref $r2 && $r2->has_usage ) ? $r2->usage : {};
  diag(sprintf('call 1 usage: creation=%s read=%s input=%s',
    $u1->{cache_creation_input_tokens} // 'n/a',
    $u1->{cache_read_input_tokens} // 'n/a',
    $u1->{input_tokens} // 'n/a'));
  diag(sprintf('call 2 usage: creation=%s read=%s input=%s',
    $u2->{cache_creation_input_tokens} // 'n/a',
    $u2->{cache_read_input_tokens} // 'n/a',
    $u2->{input_tokens} // 'n/a'));

  # Caching engaged at all on call 1 (created now, or read from a recent run).
  ok( ( ( $u1->{cache_creation_input_tokens} // 0 )
      + ( $u1->{cache_read_input_tokens} // 0 ) ) > 0,
    'Anthropic: prompt cache engaged on first request (cache_control accepted)' );

  # The load-bearing assertion: the second identical request reads the cache.
  ok( ( $u2->{cache_read_input_tokens} // 0 ) > 0,
    'Anthropic: second identical request reads from prompt cache' );
}

# OpenAI — confirm prompt_cache_key is accepted on the wire (HTTP 200).
SKIP: {
  skip 'no TEST_LANGERTHA_OPENAI_API_KEY', 1
    unless $ENV{TEST_LANGERTHA_OPENAI_API_KEY};
  require Langertha::Engine::OpenAI;
  my $e = Langertha::Engine::OpenAI->new(
    api_key          => $ENV{TEST_LANGERTHA_OPENAI_API_KEY},
    model            => 'gpt-4o-mini',
    prompt_cache_key => 'langertha-prompt-cache-test',
    response_size    => 16,
  );
  my $resp = eval { $e->simple_chat('Reply with the single word: ok') };
  ok( $resp && length("$resp"),
    'OpenAI accepts flat prompt_cache_key (HTTP 200)' )
    or diag("OpenAI live error: $@");
}

done_testing;
