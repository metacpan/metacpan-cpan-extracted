use strict;
use warnings;

use Test::More;
use JQ::Lite;
use JSON::PP;

my $jq = JQ::Lite->new;

my $json = encode_json({ numbers => [10, 20, 30] });
my $decoded = decode_json($json);

my @result = $jq->run_query($json, '.numbers | enumerate()');
my $expected = [
    { index => 0, value => 10 },
    { index => 1, value => 20 },
    { index => 2, value => 30 },
];

is_deeply($result[0], $expected, 'enumerate() pairs array values with indexes');

@result = $jq->run_query($json, '.numbers | enumerate() | map(.index)');
$expected = [0, 1, 2];
is_deeply($result[0], $expected, 'enumerate() works with map pipelines');

my $empty_json = encode_json({ items => [] });
@result = $jq->run_query($empty_json, '.items | enumerate()');
$expected = [];
is_deeply($result[0], $expected, 'enumerate() handles empty arrays');

@result = $jq->run_query($json, 'enumerate()');
is_deeply($result[0], $decoded, 'enumerate() leaves non-array values unchanged');


done_testing();
