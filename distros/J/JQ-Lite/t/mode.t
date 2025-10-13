use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json_numbers = q([1, 2, 2, 3, 3, 3]);
my $json_tie     = q(["apple", "banana", "apple", "banana"]);
my $json_objects = q([
  { "id": 1, "value": "x" },
  { "id": 1, "value": "x" },
  { "id": 2, "value": "y" }
]);
my $json_sparse = q([null, "keep", "keep", null]);
my $json_empty  = q([]);

my $jq = JQ::Lite->new;

my ($mode_numbers) = $jq->run_query($json_numbers, 'mode');
is($mode_numbers, 3, 'mode picks most frequent numeric value');

my ($mode_tie) = $jq->run_query($json_tie, 'mode');
is($mode_tie, 'apple', 'mode resolves ties using first occurrence');

my ($mode_objects) = $jq->run_query($json_objects, 'mode | .id');
is($mode_objects, 1, 'mode returns first matching object when structures repeat');

my ($mode_sparse) = $jq->run_query($json_sparse, 'mode');
is($mode_sparse, 'keep', 'mode skips undefined/null values');

my ($mode_empty) = $jq->run_query($json_empty, 'mode');
ok(!defined $mode_empty, 'mode returns undef for empty arrays');

done_testing;
