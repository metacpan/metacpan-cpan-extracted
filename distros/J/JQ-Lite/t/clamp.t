use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = q({
  "score": 87,
  "big": 150,
  "small": -12,
  "mixed": [1, 5, 12, "n/a", null],
  "nested": [[-10, 0], [4, 99]],
  "flag": true
});

my $jq = JQ::Lite->new;

my @score = $jq->run_query($json, '.score | clamp(0, 100)');
is($score[0], 87, 'clamp keeps values already in range');

my @upper = $jq->run_query($json, '.big | clamp(0, 100)');
is($upper[0], 100, 'clamp enforces upper bound');

my @lower = $jq->run_query($json, '.small | clamp(0, 100)');
is($lower[0], 0, 'clamp enforces lower bound');

my @mixed = $jq->run_query($json, '.mixed | clamp(0, 10)');
is_deeply(
    $mixed[0],
    [1, 5, 10, 'n/a', undef],
    'clamp recurses through arrays and preserves non-numeric entries'
);

my @nested = $jq->run_query($json, '.nested | clamp(-2, 5)');
is_deeply(
    $nested[0],
    [[-2, 0], [4, 5]],
    'clamp applies to nested arrays'
);

my @boolean = $jq->run_query($json, '.flag | clamp(0, 1)');
is($boolean[0], 1, 'clamp coerces boolean values to numeric context');

my @upper_only = $jq->run_query($json, '.big | clamp(null, 90)');
is($upper_only[0], 90, 'clamp supports omitting the minimum bound with null');

my @lower_only = $jq->run_query($json, '.small | clamp(5)');
is($lower_only[0], 5, 'clamp supports single-argument lower bounds');

my @swapped = $jq->run_query($json, '.score | clamp(100, 0)');
is($swapped[0], 87, 'clamp normalizes reversed bounds');

my @missing = $jq->run_query($json, '.missing? | clamp(0, 1)');
ok(!defined $missing[0], 'clamp preserves undef for missing optional values');

done_testing;
