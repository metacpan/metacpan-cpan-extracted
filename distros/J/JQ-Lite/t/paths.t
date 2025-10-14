use strict;
use warnings;
use Test::More tests => 5;
use JSON::PP;
use JQ::Lite;

my $jq = JQ::Lite->new;

# --- 1. Nested object with arrays and booleans
my $json1 = '{"user":{"name":"Alice","tags":["perl","json"],"active":true}}';
my @result1 = $jq->run_query($json1, 'paths');
is_deeply(
    $result1[0],
    [
        [ 'user' ],
        [ 'user', 'active' ],
        [ 'user', 'name' ],
        [ 'user', 'tags' ],
        [ 'user', 'tags', 0 ],
        [ 'user', 'tags', 1 ],
    ],
    'paths() lists every nested key/index in order',
);

# --- 2. Mixed array contents
my $json2 = '[1,{"foo":[2,null]}]';
my @result2 = $jq->run_query($json2, 'paths');
is_deeply(
    $result2[0],
    [
        [ 0 ],
        [ 1 ],
        [ 1, 'foo' ],
        [ 1, 'foo', 0 ],
        [ 1, 'foo', 1 ],
    ],
    'paths() traverses arrays and nested objects',
);

# --- 3. Scalar input returns the empty path
my $json3 = '"hello"';
my @result3 = $jq->run_query($json3, 'paths');
is_deeply($result3[0], [ [] ], 'paths() returns empty path for scalars');

# --- 4. Null input returns the empty path
my $json4 = 'null';
my @result4 = $jq->run_query($json4, 'paths');
is_deeply($result4[0], [ [] ], 'paths() returns empty path for null values');

# --- 5. Empty containers yield no paths
my $json5 = '{"items":[]}';
my @result5 = $jq->run_query($json5, 'paths');
is_deeply($result5[0], [ ['items'] ], 'paths() reports empty arrays as leaves');

