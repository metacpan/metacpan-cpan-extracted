use strict;
use Test::More;

use List::Util;
use List::Flatten::XS 'flatten';

my $ref_1 = +{a => 10, b => 20, c => 'Hello'};
my $ref_2 = bless +{a => 10, b => 20, c => 'Hello'}, 'Nyan';
my $ref_3 = bless $ref_2, 'Waon';

my $expected = ["foo", "bar", 3, "baz", 5, $ref_1, "hoge", $ref_2, "huga", 1, "K", $ref_3];
my $pattern = +[
    ["foo", ["bar", 3, "baz"], [5, $ref_1, "hoge", $ref_2, "huga", 1, "K", $ref_3]],
    [["foo", "bar", 3], ["baz", 5, [$ref_1, "hoge", [$ref_2, "huga", [1, "K", $ref_3]]]]],
    [[["foo", "bar", 3], "baz", 5], $ref_1, "hoge", [$ref_2, ["huga", [1], "K"], $ref_3]],
    ["foo", ["bar", [3, ["baz", [5, [$ref_1, ["hoge", [$ref_2, ["huga", [1, ["K", [$ref_3]]]]]]]]]]]],
    [[[[[[[[[[[["foo"], "bar"], 3], "baz"], 5], $ref_1], "hoge"], $ref_2], "huga"], 1], "K"], $ref_3],
];

for my $try (@$pattern) {
    my $got = flatten($try);
    is_deeply($got, $expected, 'Passed array ref, want scalar');
}

for my $try (@$pattern) {
    my @got = flatten($try);
    is_deeply(\@got, $expected, 'Passed array ref, want array');
}

done_testing;

