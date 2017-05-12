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

my $expected_list = +[
    +{
        1 => ["foo", "bar", 3, "baz", 5, $ref_1, "hoge", $ref_2, "huga", 1, "K", $ref_3]
    },
    +{
        1 => ["foo", "bar", 3, "baz", 5, [$ref_1, "hoge", [$ref_2, "huga", [1, "K", $ref_3]]]],
        2 => ["foo", "bar", 3, "baz", 5, $ref_1, "hoge", [$ref_2, "huga", [1, "K", $ref_3]]],
        3 => ["foo", "bar", 3, "baz", 5, $ref_1, "hoge", $ref_2, "huga", [1, "K", $ref_3]],
        4 => ["foo", "bar", 3, "baz", 5, $ref_1, "hoge", $ref_2, "huga", 1, "K", $ref_3]
    },
    +{
        1 => [["foo", "bar", 3], "baz", 5, $ref_1, "hoge", $ref_2, ["huga", [1], "K"], $ref_3],
        2 => ["foo", "bar", 3, "baz", 5, $ref_1, "hoge", $ref_2, "huga", [1], "K", $ref_3],
        3 => ["foo", "bar", 3, "baz", 5, $ref_1, "hoge", $ref_2, "huga", 1, "K", $ref_3]
    },
    +{
        1  => ["foo", "bar", [3, ["baz", [5, [$ref_1, ["hoge", [$ref_2, ["huga", [1, ["K", [$ref_3]]]]]]]]]]],
        5  => ["foo", "bar", 3, "baz", 5, $ref_1, ["hoge", [$ref_2, ["huga", [1, ["K", [$ref_3]]]]]]],
        9  => ["foo", "bar", 3, "baz", 5, $ref_1, "hoge", $ref_2, "huga", 1, ["K", [$ref_3]]],
        11 => ["foo", "bar", 3, "baz", 5, $ref_1, "hoge", $ref_2, "huga", 1, "K", $ref_3]
    },
    +{
        1  => [[[[[[[[[[["foo"], "bar"], 3], "baz"], 5], $ref_1], "hoge"], $ref_2], "huga"], 1], "K", $ref_3],
        5  => [[[[[[["foo"], "bar"], 3], "baz"], 5], $ref_1], "hoge", $ref_2, "huga", 1, "K", $ref_3],
        9  => [[["foo"], "bar"], 3, "baz", 5, $ref_1, "hoge", $ref_2, "huga", 1, "K", $ref_3],
        11 => ["foo", "bar", 3, "baz", 5, $ref_1, "hoge", $ref_2, "huga", 1, "K", $ref_3]
    }
];

for my $i (0 .. $#$pattern) {
    while (my ($level, $expected) = each %{$expected_list->[$i]}) {
        my $got = flatten($pattern->[$i], $level);
        is_deeply($got, $expected, 'Passed array ref, want scalar');
    }
    # wantarray
    while (my ($level, $expected) = each %{$expected_list->[$i]}) {
        my @got = flatten($pattern->[$i], $level);
        is_deeply(\@got, $expected, 'Passed array ref, want scalar');
    }
}

done_testing;

