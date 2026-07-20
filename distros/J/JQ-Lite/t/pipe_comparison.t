use strict;
use warnings;

use Test::More;
use JSON::PP ();
use lib 'lib';
use JQ::Lite;

my $jq = JQ::Lite->new;
my $json = '{"devices":[{"mac":"aa"}],"count":3,"s":"x"}';

my @cases = (
    ['.devices | length > 0',       1],
    ['(.devices | length) > 0',     1],
    ['.devices | length >= 1',      1],
    ['.devices | length == 1',      1],
    ['.devices | length != 0',      1],
    ['.count | . > 0',              1],
    ['.count | . == 3',             1],
    ['.s | . == "x"',               1],
    ['.devices | length == 0',      0],
    ['.count | . < 3',              0],
);

for my $case (@cases) {
    my ($query, $expected) = @$case;
    my @results = $jq->run_query($json, $query);
    is(scalar(@results), 1, "$query returns one result");
    is($results[0] ? 1 : 0, $expected, "$query compares the piped value");
}

my $compound_json = '{"a":1,"b":2,"label":"rock and roll"}';
my @compound_cases = (
    ['.a > 0 and .b > 0',          1],
    ['.a > 2 and .b > 0',          0],
    ['.a > 2 or .b > 0',           1],
    ['.a > 2 or .b < 0',           0],
    ['(.a > 0) and (.b > 0)',      1],
    ['.a > 0 and (.b > 0)',        1],
    ['(.a > 2) or (.b > 0)',       1],
    ['(.a > 0 or .b < 0) and (.b > 0)', 1],
    ['.a > 0 or .a > 2 and .b < 0',     1],
    ['.label == "rock and roll"',  1],
    ['.missing == 1',               0],
    ['.missing != 1',               1],
    ['.missing == null',            1],
    ['.missing > 1',                0],
    ['.missing < 1',                1],
    ['.a == .missing',              0],
    ['.missing == .also_missing',   1],
);

for my $case (@compound_cases) {
    my ($query, $expected) = @$case;
    my @results = $jq->run_query($compound_json, $query);
    is(scalar(@results), 1, "$query returns one result");
    is($results[0] ? 1 : 0, $expected, "$query preserves compound comparison semantics");
}

done_testing;
