use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use JQ::Lite;

my $jq = JQ::Lite->new;

my $json_nested = <<'JSON';
[1, [2, 3], [[4], 5], 6]
JSON

my @nested = $jq->run_query($json_nested, 'flatten_all');

is_deeply($nested[0], [1, 2, 3, 4, 5, 6], 'flatten_all recursively flattens nested arrays');

my $json_mixed = <<'JSON';
[{"values":[1,2]}, [3, [4, [5]]], 6]
JSON

my @mixed = $jq->run_query($json_mixed, 'flatten_all');

is_deeply(
    $mixed[0],
    [ { values => [1, 2] }, 3, 4, 5, 6 ],
    'flatten_all preserves non-array elements'
);

done_testing;
