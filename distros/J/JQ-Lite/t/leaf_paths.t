use strict;
use warnings;
use Test::More tests => 6;
use JSON::PP;
use JQ::Lite;

my $jq = JQ::Lite->new;

# --- 1. Nested object with arrays and booleans
my $json1 = '{"user":{"name":"Alice","tags":["perl","json"],"active":true}}';
my @result1 = $jq->run_query($json1, 'leaf_paths');
is_deeply(
    $result1[0],
    [
        [ 'user', 'active' ],
        [ 'user', 'name' ],
        [ 'user', 'tags', 0 ],
        [ 'user', 'tags', 1 ],
    ],
    'leaf_paths() includes only terminal (non-container) paths',
);

# --- 2. Mixed array contents with nested objects
my $json2 = '[1,{"foo":[2,null]}]';
my @result2 = $jq->run_query($json2, 'leaf_paths');
is_deeply(
    $result2[0],
    [
        [ 0 ],
        [ 1, 'foo', 0 ],
        [ 1, 'foo', 1 ],
    ],
    'leaf_paths() traverses arrays while skipping intermediate containers',
);

# --- 3. Scalar input returns the empty path
my $json3 = '"hello"';
my @result3 = $jq->run_query($json3, 'leaf_paths');
is_deeply($result3[0], [ [] ], 'leaf_paths() returns empty path for scalar root');

# --- 4. Null input returns the empty path
my $json4 = 'null';
my @result4 = $jq->run_query($json4, 'leaf_paths');
is_deeply($result4[0], [ [] ], 'leaf_paths() returns empty path for null root');

# --- 5. Empty containers yield no leaf paths
my $json5 = '{"items":[]}';
my @result5 = $jq->run_query($json5, 'leaf_paths');
is_deeply($result5[0], [], 'leaf_paths() ignores empty arrays and objects');

# --- 6. Boolean values are treated as leaves
my $json6 = '{"flag":false}';
my @result6 = $jq->run_query($json6, 'leaf_paths');
is_deeply($result6[0], [ [ 'flag' ] ], 'leaf_paths() treats booleans as scalars');

