use strict;
use warnings;
use Test::More;
use JSON::PP;
use JQ::Lite;

my $encoder = JSON::PP->new->allow_nonref;

my $input = {
    raw => $encoder->encode({
        name   => 'Bob',
        active => JSON::PP::true,
        tags   => ['jq', 'perl'],
    }),
    list => [
        $encoder->encode('hi'),
        $encoder->encode(42),
        $encoder->encode(JSON::PP::true),
        $encoder->encode(undef),
        $encoder->encode([1, 2]),
        $encoder->encode({ nested => 1 }),
    ],
    invalid => 'not-json',
    nested  => [
        [ $encoder->encode('a'), $encoder->encode('b') ],
        $encoder->encode(5),
    ],
};

my $json = JSON::PP->new->encode($input);

my $jq = JQ::Lite->new;

my @decoded = $jq->run_query($json, '.raw | fromjson');
is_deeply(
    $decoded[0],
    { name => 'Bob', active => JSON::PP::true, tags => ['jq', 'perl'] },
    'fromjson decodes JSON objects from strings'
);

my @list = $jq->run_query($json, '.list | fromjson');
is_deeply(
    $list[0],
    ['hi', 42, JSON::PP::true, undef, [1, 2], { nested => 1 }],
    'fromjson processes arrays element-wise'
);

my @invalid = $jq->run_query($json, '.invalid | fromjson');
is(
    $invalid[0],
    'not-json',
    'fromjson leaves invalid JSON text unchanged'
);

my @nested = $jq->run_query($json, '.nested | fromjson');
is_deeply(
    $nested[0],
    [ ['a', 'b'], 5 ],
    'fromjson decodes nested array values recursively'
);

my @null = $jq->run_query('null', 'fromjson');
ok(!defined $null[0], 'fromjson propagates null inputs');

done_testing;
