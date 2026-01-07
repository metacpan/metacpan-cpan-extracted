use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = q({
  "price": 19.2,
  "discount": 1.5,
  "debt": -1.7,
  "tiny": -0.2,
  "numbers": [1.49, 1.5, -1.49, -1.5, "n/a", null, [2.6, -2.6, 3]],
  "bools": [true, false, [true]]
});

my $jq = JQ::Lite->new;

my @round_price = $jq->run_query($json, '.price | round');
is($round_price[0], 19, 'round rounds positive scalar down when < .5');

my @round_discount = $jq->run_query($json, '.discount | round');
is($round_discount[0], 2, 'round rounds positive .5 upward');

my @round_debt = $jq->run_query($json, '.debt | round');
is($round_debt[0], -2, 'round rounds negative scalar away from zero when beyond -.5');

my @round_tiny = $jq->run_query($json, '.tiny | round');
is($round_tiny[0], 0, 'round rounds small negative toward zero when greater than -.5');

my @round_values = $jq->run_query($json, '.numbers | round');
is_deeply(
    $round_values[0],
    [1, 2, -1, -2, 'n/a', undef, [3, -3, 3]],
    'round processes arrays recursively and preserves non-numeric values'
);

my @round_bools = $jq->run_query($json, '.bools | round');
is_deeply(
    $round_bools[0],
    [1, 0, [1]],
    'round treats booleans as numeric values'
);

my @round_missing = $jq->run_query($json, '.missing | round');
ok(!defined $round_missing[0], 'round returns undef when target is undef');


done_testing;
