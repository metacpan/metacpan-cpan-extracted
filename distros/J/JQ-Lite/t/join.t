use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = '{"users":[{"name":"Alice"},{"name":"Bob"},{"name":"Carol"}]}';

my $jq = JQ::Lite->new;

my @result = $jq->run_query($json, '.users | map(.name) | join(", ")');
is_deeply(\@result, ['Alice, Bob, Carol'], 'join() works correctly');

my @joined_with_null = $jq->run_query('["foo", null, "bar"]', 'join("-")');
is_deeply(\@joined_with_null, ['foo--bar'], 'join() treats null elements as empty strings');

my $non_array_ok = eval { $jq->run_query('"oops"', 'join(",")'); 1 };
ok(!$non_array_ok, 'join() throws on non-array input');
like(
    $@,
    qr/^join\(\): input must be an array/,
    'join() reports that input must be an array'
);

done_testing();

