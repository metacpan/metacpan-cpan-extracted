#!perl -T

use strict;
use warnings;
use Test::More tests => 5+3+6+1+6;
use Lingua::ZH::PinyinConvert::ID;

my $conv = Lingua::ZH::PinyinConvert::ID->new;

my @h2i = (
    ["zhong guo", "cung kuo"],
    ["zhong1 guo2", "cung1 kuo2"],
    ["woaita", "woaitha"],
    ["wo3ai4ta1", "wo3ai4tha1"],
    ["{wo ai ta} means {I love him}", "{wo ai tha} means {I love him}"],
);
is($conv->hanyu2id($_->[0]), $_->[1], "hanyu2id '$_->[0]'") for @h2i;

my @j2i = (
    ["zung gwok", "cung kwok"],
    ["zung1 gwok3", "cung kwok"],
    ["zung1gwok3", "cungkwok"],
);
is($conv->jyutping2id($_->[0], {remove_tones=>1}), $_->[1],
   "jyutping2id (remove_tones=1) '$_->[0]'") for @j2i;

my @i2h = (
    ["cung kuo", undef],
    ["cung kuo", "(zhong|zong) guo", {list_all=>1}],
    ["yuen liau", "yuan liao"],
    ["yuenliau", "yuanliao"],
    ["yuen2 liau4", "yuan2 liao4"],
    ["yuen2liau4", "yuan2liao4"],
);
is($conv->id2hanyu($_->[0], $_->[2]), $_->[1], "id2hanyu '$_->[0]'") for @i2h;

my @i2j = (
    ["cung1 kwok3", "zung gwok"],
);
is($conv->id2jyutping($_->[0], {%{$_->[2] ? $_->[2] : {}}, remove_tones=>1}), $_->[1],
   "id2jyutping (remove_tones=1) '$_->[0]'") for @i2j;

my @d = (
    ["I love You",     []],
    ["wo ai tha",      ["id-mandarin", "id-cantonese"]],
    ["wo ai bei jing", ["hanyu", "jyutping"]],
    ["wo de xin qing", ["hanyu"]],
    ["zung gwok jan",  ["jyutping"]],
    ["wo ai ni",       ["hanyu", "jyutping", "id-mandarin", "id-cantonese"]],
);
is_deeply([$conv->detect($_->[0])], $_->[1], "detect '$_->[0]'") for @d;
