use strict;
use Test::More;
use Test::Exception;
use List::Flatten::XS 'flatten';

my $ref_1 = +{a => 10, b => 20, c => 'Hello'};
my $ref_2 = bless +{a => 10, b => 20, c => 'Hello'}, 'Nyan';
my $ref_3 = bless $ref_2, 'Waon';
my $ref_4 = bless [1..10];

my $list_ref = ["bar", 3, "baz"];
my $list_ref2 = ["foo", ["bar", [3, ["baz", [5, [$ref_1, ["hoge", [$ref_2, ["huga", [1, ["K", [$ref_3, [$ref_4]]]]]]]]]]]]];
push @$list_ref, $list_ref;
push @$list_ref2, ([['a'..'z'], [$list_ref2]]);

my $patterns = +[
    ["foo", $list_ref, [5, $ref_1, "hoge", $ref_2, "huga", 1, "K", $ref_3], $ref_4],
    [["foo", "bar", 3], ["baz", 5, [$ref_1, $list_ref, "hoge", [$ref_2, "huga", [1, "K", $ref_3]]]], $ref_4],
    [[["foo", "bar", 3], "baz", 5], $ref_1, "hoge", [$ref_2, ["huga", [$list_ref], "K"], $ref_3, $ref_4]],
    $list_ref2,
    [[[[[[[[[[[[$list_ref2], "bar"], 3], "baz"], 5], $ref_1], "hoge"], $ref_2], "huga"], 1], "K"], $ref_3, $ref_4],
];

for my $pattern (@$patterns) {
    throws_ok { flatten($pattern) } qr/tried to flatten recursive list/;
}

for my $pattern (@$patterns) {
    throws_ok { flatten($pattern, 20) } qr/tried to flatten recursive list/;
}

done_testing;

