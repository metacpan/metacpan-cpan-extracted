use strict;
use warnings;

use Test::More;
use JQ::Lite;
use JSON::PP;

my $jq = JQ::Lite->new;

my $json = encode_json({ numbers => [1, 2, 3, 4, 5] });
my $decoded = decode_json($json);
my @result = $jq->run_query($json, '.numbers | chunks(2)');
my $expected = [ [1, 2], [3, 4], [5] ];
is_deeply($result[0], $expected, 'chunks(2) splits array into pairs');

@result = $jq->run_query($json, '.numbers | chunks(3) | map(length)');
$expected = [3, 2];
is_deeply($result[0], $expected, 'chunks(3) works with map pipeline');

my $empty_json = encode_json({ items => [] });
@result = $jq->run_query($empty_json, '.items | chunks(4)');
$expected = [];
is_deeply($result[0], $expected, 'chunks handles empty arrays');

@result = $jq->run_query($json, '.numbers | chunks(0)');
$expected = [ [1], [2], [3], [4], [5] ];
is_deeply($result[0], $expected, 'chunks(0) falls back to size 1');

my $negative_ok = eval { $jq->run_query($json, '.numbers | chunks(-2)') };
ok(!$negative_ok && $@ =~ /chunks\(\): size must be a non-negative integer/,
   'chunks() rejects negative sizes');

my $non_numeric_ok = eval { $jq->run_query($json, '.numbers | chunks(foo)') };
ok(!$non_numeric_ok && $@ =~ /chunks\(\): size must be a non-negative integer/,
   'chunks() rejects non-numeric sizes');

@result = $jq->run_query($json, 'chunks(2)');
is_deeply($result[0], $decoded, 'chunks leaves non-array values unchanged');


done_testing();
