use strict;
use warnings;

use Test::More;
use JQ::Lite;
use JSON::PP qw(encode_json decode_json);

my $jq = JQ::Lite->new;

my $json = encode_json({ matrix => [ [1, 2, 3], [4, 5, 6] ] });
my @result = $jq->run_query($json, '.matrix | transpose');
my $expected = [ [1, 4], [2, 5], [3, 6] ];
is_deeply($result[0], $expected, 'transpose pivots arrays of arrays');

$json = encode_json({ jagged => [ [1, 2], [3] ] });
@result = $jq->run_query($json, '.jagged | transpose');
$expected = [ [1, 3] ];
is_deeply($result[0], $expected, 'transpose truncates to the shortest row');

$json = encode_json({ numbers => [1, 2, 3] });
my $decoded = decode_json($json);
@result = $jq->run_query($json, '.numbers | transpose');
is_deeply($result[0], $decoded->{numbers}, 'transpose leaves non-nested arrays unchanged');

$json = encode_json({ void => [] });
@result = $jq->run_query($json, '.void | transpose');
$expected = [];
is_deeply($result[0], $expected, 'transpose handles empty arrays');
done_testing();
