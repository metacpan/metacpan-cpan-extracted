#!/usr/bin/env perl
# ABSTRACT: DeepSeek V3 vs V4 reasoning_effort wire dispatch (karr #20, #25, #150)

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::Engine::DeepSeek;

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

plan(17);

# --- Default model is the current V4.1 flash line (karr #25, #150) ---
# deepseek-v4-flash was retired 2026-09-10 and is only temporarily routed to
# V4.1-Flash; deepseek-flash is the stable id DeepSeek tells callers to pin,
# so the engine default must be deepseek-flash (not the deprecated alias).

is(Langertha::Engine::DeepSeek->new(api_key => 'k')->default_model,
  'deepseek-flash', 'DeepSeek default_model is deepseek-flash (V4.1-Flash)');

# --- V4 generation: flat reasoning_effort, no per-model difference ---
# api-docs.deepseek.com/api/create-chat-completion (verified 2026-09-14): the
# endpoint serving deepseek-flash + deepseek-v4-pro accepts none|low|high|max
# with NO per-model difference. The engine default model must pass low through.
my $v4_default = Langertha::Engine::DeepSeek->new(
  api_key => 'k', reasoning_effort => 'low',
);
my $dd = $json->decode($v4_default->chat('hi')->content);
is($dd->{model}, 'deepseek-flash',
  'default engine sends deepseek-flash in the request body');
is($dd->{reasoning_effort}, 'low',
  'deepseek-flash (default) emits flat reasoning_effort low');
ok(!exists $dd->{thinking},
  'deepseek-flash does NOT emit legacy V3.2 thinking:{type:enabled}');

# none is a valid documented value that disables thinking — emitted flat.
my $v41_none = Langertha::Engine::DeepSeek->new(
  api_key => 'k', model => 'deepseek-flash', reasoning_effort => 'none',
);
my $d4n = $json->decode($v41_none->chat('hi')->content);
is($d4n->{reasoning_effort}, 'none',
  'deepseek-flash emits flat reasoning_effort none (thinking off)');

# The retired deepseek-v4-flash id still routes to V4.1-Flash today and stays
# on the flat V4 path (not the V3.2 thinking toggle).
my $v4_flash = Langertha::Engine::DeepSeek->new(
  api_key => 'k', model => 'deepseek-v4-flash', reasoning_effort => 'max',
);
my $d4f = $json->decode($v4_flash->chat('hi')->content);
is($d4f->{reasoning_effort}, 'max',
  'deepseek-v4-flash (routed alias) emits flat reasoning_effort max');
ok(!exists $d4f->{thinking},
  'deepseek-v4-flash does NOT emit legacy V3.2 thinking');

my $v4_pro = Langertha::Engine::DeepSeek->new(
  api_key => 'k', model => 'deepseek-v4-pro', reasoning_effort => 'high',
);
my $d4p = $json->decode($v4_pro->chat('hi')->content);
is($d4p->{reasoning_effort}, 'high',
  'deepseek-v4-pro emits flat reasoning_effort high');
ok(!exists $d4p->{thinking},
  'deepseek-v4-pro does NOT emit legacy V3.2 thinking');

# deepseek-v4-pro accepts low (no per-model difference) — the old high|max-only
# clamp was reversed by DeepSeek (V4 Pro service continues unchanged), so low
# must now pass through rather than being dropped.
my $v4_pro_low = Langertha::Engine::DeepSeek->new(
  api_key => 'k', model => 'deepseek-v4-pro', reasoning_effort => 'low',
);
my $d4pl = $json->decode($v4_pro_low->chat('hi')->content);
is($d4pl->{reasoning_effort}, 'low',
  'deepseek-v4-pro emits flat reasoning_effort low (no per-model clamp)');
ok(!exists $d4pl->{thinking},
  'deepseek-v4-pro with low does NOT emit legacy V3.2 thinking either');

# --- V3.2 line: legacy thinking:{type:enabled} ---

my $v3_explicit = Langertha::Engine::DeepSeek->new(
  api_key => 'k', model => 'deepseek-v3', reasoning_effort => 'high',
);
my $d3 = $json->decode($v3_explicit->chat('hi')->content);
is_deeply($d3->{thinking}, { type => 'enabled' },
  'deepseek-v3 emits legacy thinking:{type:enabled}');
ok(!exists $d3->{reasoning_effort},
  'deepseek-v3 does NOT emit flat reasoning_effort');

my $v3_32 = Langertha::Engine::DeepSeek->new(
  api_key => 'k', model => 'deepseek-v3.2-exp', reasoning_effort => 'high',
);
my $d32 = $json->decode($v3_32->chat('hi')->content);
is_deeply($d32->{thinking}, { type => 'enabled' },
  'deepseek-v3.2-exp emits legacy thinking:{type:enabled}');
ok(!exists $d32->{reasoning_effort},
  'deepseek-v3.2-exp does NOT emit flat reasoning_effort');

# --- Unknown / future model id: default to V4 (safe current default) ---
# Unknown ids take the flat V4 set (none|low|high|max), the same as the known
# V4 models — there is no per-model difference to be conservative about.

my $unknown = Langertha::Engine::DeepSeek->new(
  api_key => 'k', model => 'deepseek-v99-ultra', reasoning_effort => 'high',
);
my $du = $json->decode($unknown->chat('hi')->content);
is($du->{reasoning_effort}, 'high',
  'unknown model id defaults to V4 flat reasoning_effort (not V3.2 thinking)');

my $unknown_low = Langertha::Engine::DeepSeek->new(
  api_key => 'k', model => 'deepseek-v99-ultra', reasoning_effort => 'low',
);
my $dul = $json->decode($unknown_low->chat('hi')->content);
is($dul->{reasoning_effort}, 'low',
  'unknown model id emits flat reasoning_effort low (V4 flat set)');

done_testing;