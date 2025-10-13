use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use JQ::Lite;

my $jq = JQ::Lite->new;

my $json_nested = <<'JSON';
[[1, 2], [3, [4, 5]], 6]
JSON

my @depth_one = $jq->run_query($json_nested, 'flatten_depth(1)');
is_deeply(
    $depth_one[0],
    [1, 2, 3, [4, 5], 6],
    'flatten_depth(1) flattens one level of nesting'
);

my @depth_two = $jq->run_query($json_nested, 'flatten_depth(2)');
is_deeply(
    $depth_two[0],
    [1, 2, 3, 4, 5, 6],
    'flatten_depth(2) flattens two levels of nesting'
);

my @depth_zero = $jq->run_query($json_nested, 'flatten_depth(0)');
is_deeply(
    $depth_zero[0],
    [ [1, 2], [3, [4, 5]], 6 ],
    'flatten_depth(0) leaves the structure unchanged'
);

my @default_depth = $jq->run_query($json_nested, 'flatten_depth');
is_deeply(
    $default_depth[0],
    [1, 2, 3, [4, 5], 6],
    'flatten_depth defaults to a depth of 1 when omitted'
);

my $json_mixed = <<'JSON';
[[{"name":"Alice"}], [{"name":"Bob", "pets":["cat", "dog"]}]]
JSON

my @mixed = $jq->run_query($json_mixed, 'flatten_depth(1)');
is_deeply(
    $mixed[0],
    [
        { name => 'Alice' },
        { name => 'Bob', pets => ['cat', 'dog'] },
    ],
    'flatten_depth preserves non-array elements while flattening arrays'
);

my @non_array = $jq->run_query('"scalar"', 'flatten_depth(3)');
is($non_array[0], 'scalar', 'flatten_depth leaves non-arrays untouched');

done_testing;
