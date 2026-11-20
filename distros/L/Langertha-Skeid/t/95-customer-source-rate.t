#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Langertha::Skeid;
use Langertha::Skeid::CustomerSource;
use Langertha::Skeid::Rate;

# A rate per customer-source row (skeid k126): an application that issues keys (one per agent)
# sets each key's own request rate in its relation. The operator's policy is the ceiling: a row
# may only tighten it, and a row that asks for more is rejected -- reason, never value.

my $CS = 'Langertha::Skeid::CustomerSource';
my ($A, $B, $C, $D, $E, $F) = map { 'k_' . ($_ x 40) } qw( a b c d e f );

# --- within: the ceiling and the row ---
{
  my $ceiling = Langertha::Skeid::Rate->normalize({ per_s => 10, burst => 4, per_min => 300 });
  is_deeply(Langertha::Skeid::Rate->within({ per_s => 2 }, $ceiling), { per_s => 2, burst => 2, per_min => 300 },
    'a slower per_s keeps the ceiling\'s per_min');
  is_deeply(Langertha::Skeid::Rate->within({ per_s => 8 }, $ceiling), { per_s => 8, burst => 4, per_min => 300 },
    'a burst the row leaves out is capped at the ceiling\'s');
  is(Langertha::Skeid::Rate->within({ per_s => 11 }, $ceiling), undef, 'a faster per_s is looser');
  is(Langertha::Skeid::Rate->within({ per_s => 5, burst => 5 }, $ceiling), undef, 'a larger burst is looser');
  is(Langertha::Skeid::Rate->within({ per_min => 301 }, $ceiling), undef, 'a larger per_min is looser');
  is_deeply(Langertha::Skeid::Rate->within({ per_min => 60 }, undef), { per_min => 60 },
    'without a ceiling any rate is within it');
  is_deeply(Langertha::Skeid::Rate->within({ per_min => 60 }, { per_s => 1, burst => 1 }),
    { per_s => 1, burst => 1, per_min => 60 }, 'a part only the row has is added');
}

# --- the statement reads the column only when asked ---
is $CS->statement('skeid.customer_keys'), 'SELECT key_id, name, policy, models FROM "skeid"."customer_keys"',
  'without rate_column the statement is as before';
is $CS->statement('skeid.customer_keys', rate => 1), 'SELECT key_id, name, policy, models, rate FROM "skeid"."customer_keys"',
  'with it, rate is read too';
is $CS->normalize_config({ dsn => 'dbi:Pg:dbname=x', relation => 'k', rate_column => 'true' })->{rate_column}, 1,
  'rate_column is a config key';

# --- rows: within, looser, malformed, JSON text ---
my $cfg = {
  policies       => { agents => { rate => { per_s => 5, burst => 10 } }, open => {} },
  default_policy => 'agents',
};
my $merge = $CS->merge_into($cfg, [
  { key_id => $A, name => 'slow',   policy => 'agents', models => undef, rate => { per_s => 1 } },
  { key_id => $B, name => 'greedy', policy => 'agents', models => undef, rate => { per_s => 50 } },
  { key_id => $C, name => 'json',   policy => undef,    models => undef, rate => '{"per_s": 2, "burst": 2}' },
  { key_id => $D, name => 'broken', policy => 'agents', models => undef, rate => '{"per_s": "fast"}' },
  { key_id => $E, name => 'free',   policy => 'open',   models => undef, rate => { per_min => 30 } },
  { key_id => $F, name => 'plain',  policy => 'agents', models => undef },
]);
is $merge->{accepted}, 4, 'four rows accepted';
is_deeply [ sort map { "$_->{row}: $_->{reason}" } @{$merge->{rejected}} ], [
  q{'broken': rate is not a rate of per_s, burst, per_min},
  q{'greedy': rate is looser than the rate of the row's policy},
], 'a looser and a malformed rate are rejected by reason';
unlike join(' ', map { $_->{reason} } @{$merge->{rejected}}), qr/50|fast/, 'no value in a reason';
is_deeply $merge->{config}{keys}{$A}, { policy => 'agents', rate => { per_s => 1, burst => 1 } }, 'a row\'s rate goes into its keys entry';
is_deeply $merge->{config}{keys}{$C}{rate}, { per_s => 2, burst => 2 }, 'JSON text is read, the default policy is the ceiling';
is_deeply $merge->{config}{keys}{$E}{rate}, { per_min => 30 }, 'a policy without a rate is no ceiling';
ok !exists $merge->{config}{keys}{$F}{rate}, 'a row without a rate keeps its policy\'s';

# --- end to end: the merged config limits the key ---
{
  my $skeid = Langertha::Skeid->new(config_loader => sub { $merge->{config} });
  ok $skeid->rate_admit($A)->{ok}, 'the slow key gets its first request';
  ok !$skeid->rate_admit($A)->{ok}, 'and its own rate stops the second';
  ok !grep({ !$skeid->rate_admit($F)->{ok} } 1 .. 10), 'the plain key has its policy\'s burst of 10';
}

done_testing;
