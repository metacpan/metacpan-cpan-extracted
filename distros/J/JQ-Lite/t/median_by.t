use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json_objects = q([
  { "value": 10 },
  { "value": 30 },
  { "value": 20 }
]);

my $json_even = q([
  { "score": 1 },
  { "score": 3 },
  { "score": 5 },
  { "score": 7 }
]);

my $json_mixed = q([
  { "score": "9" },
  { "score": "foo" },
  { "score": 3 }
]);

my $json_booleans = q([
  { "flag": true },
  { "flag": false },
  { "flag": true }
]);

my $json_entire_item = q([1, "2", 3, "not a number"]);

my $json_no_numeric = q([
  { "value": "foo" },
  { "value": "bar" }
]);

my $jq = JQ::Lite->new;

my ($median_objects) = $jq->run_query($json_objects, 'median_by(.value)');
is($median_objects, 20, 'median_by over projected values');

my ($median_even) = $jq->run_query($json_even, 'median_by(.score)');
is($median_even, 4, 'median_by averages middle pair for even-length projections');

my ($median_mixed) = $jq->run_query($json_mixed, 'median_by(.score)');
is($median_mixed, 6, 'median_by ignores non-numeric projections');

my ($median_booleans) = $jq->run_query($json_booleans, 'median_by(.flag)');
is($median_booleans, 1, 'median_by treats booleans as 0/1 and returns middle value');

my ($median_entire) = $jq->run_query($json_entire_item, 'median_by(.)');
is($median_entire, 2, 'median_by(.) uses entire item when projecting');

my ($median_missing) = $jq->run_query($json_no_numeric, 'median_by(.value)');
ok(!defined $median_missing, 'median_by returns undef when no numeric projections are found');

done_testing;
