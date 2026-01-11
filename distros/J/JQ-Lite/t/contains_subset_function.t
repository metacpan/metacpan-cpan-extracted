use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = q({
  "array": [1, 2, 3],
  "nested": {"x": 10, "y": [1, 2, 3]},
  "dupes": [1, 2, 2, 3],
  "config": {"theme": "dark", "size": "m", "layout": {"columns": 2}},
  "members": [{"id": 1, "name": "Ana"}, {"id": 2, "name": "Bao"}],
  "title": "jq-lite in perl"
});

my $jq = JQ::Lite->new;

my @subset_in_order      = $jq->run_query($json, '.array | contains_subset([2,3])');
my @subset_out_of_order  = $jq->run_query($json, '.array | contains_subset([3,2])');
my @subset_missing       = $jq->run_query($json, '.array | contains_subset([4])');
my @nested_subset        = $jq->run_query($json, '.nested | contains_subset({"y": [2]})');
my @dupe_true            = $jq->run_query($json, '.dupes | contains_subset([2,2])');
my @dupe_false           = $jq->run_query($json, '.array | contains_subset([2,2])');
my @config_subset        = $jq->run_query($json, '.config | contains_subset({"layout": {"columns": 2}})');
my @config_missing       = $jq->run_query($json, '.config | contains_subset({"layout": {"columns": 3}})');
my @member_subset        = $jq->run_query($json, '.members | contains_subset([{"id": 2}])');
my @member_missing       = $jq->run_query($json, '.members | contains_subset([{"id": 3}])');
my @null_on_string       = $jq->run_query($json, '.title | contains_subset(null)');

ok($subset_in_order[0], 'array subset in order is true');
ok($subset_out_of_order[0], 'array subset out of order is true');
ok(!$subset_missing[0], 'array subset missing element is false');
ok($nested_subset[0], 'nested array subset is true');
ok($dupe_true[0], 'duplicate elements are counted');
ok(!$dupe_false[0], 'insufficient duplicates returns false');
ok($config_subset[0], 'object subset matches nested keys');
ok(!$config_missing[0], 'object subset fails when nested keys do not match');
ok($member_subset[0], 'array subset matches nested objects');
ok(!$member_missing[0], 'array subset fails when nested object is missing');
ok(!$null_on_string[0], 'string does not contain subset null');

done_testing;
