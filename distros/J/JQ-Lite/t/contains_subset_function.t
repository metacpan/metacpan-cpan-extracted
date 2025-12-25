use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = q({
  "array": [1, 2, 3],
  "nested": {"x": 10, "y": [1, 2, 3]},
  "dupes": [1, 2, 2, 3]
});

my $jq = JQ::Lite->new;

my @subset_in_order      = $jq->run_query($json, '.array | contains_subset([2,3])');
my @subset_out_of_order  = $jq->run_query($json, '.array | contains_subset([3,2])');
my @subset_missing       = $jq->run_query($json, '.array | contains_subset([4])');
my @nested_subset        = $jq->run_query($json, '.nested | contains_subset({"y": [2]})');
my @dupe_true            = $jq->run_query($json, '.dupes | contains_subset([2,2])');
my @dupe_false           = $jq->run_query($json, '.array | contains_subset([2,2])');

ok($subset_in_order[0], 'array subset in order is true');
ok($subset_out_of_order[0], 'array subset out of order is true');
ok(!$subset_missing[0], 'array subset missing element is false');
ok($nested_subset[0], 'nested array subset is true');
ok($dupe_true[0], 'duplicate elements are counted');
ok(!$dupe_false[0], 'insufficient duplicates returns false');

done_testing;
