#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Test::More;
use Lingua::EN::Alphabet::Shaw qw(transliterate);

my $tests = [
        [ 'very basic test',
        'test Shavian', '𐑑𐑧𐑕𐑑 𐑖𐑱𐑝𐑾𐑯', 'test SEvWn'],
        [ 'test that we can ignore variables',
         'My name is %s.  I am %d years old.',
        '𐑥𐑲 𐑯𐑱𐑥 𐑦𐑟 %s.  𐑲 𐑨𐑥 %d 𐑘𐑽𐑟 𐑴𐑤𐑛.',
        undef],
        [ 'homonyms test',
        'I live near a live wire.',
        '𐑲 𐑤𐑦𐑝 𐑯𐑽 𐑩 𐑤𐑲𐑝 𐑢𐑲𐑼.',
        'F liv nC a lFv wFD.'],
        [ 'apostrophes test',
         "I don't like it.",
        "𐑲 𐑛𐑴𐑯𐑑 𐑤𐑲𐑒 𐑦𐑑.",
        "F dOnt lFk it."],
        [ 'test for proper nouns',
         'I took some china to China.',
        '𐑲 𐑑𐑫𐑒 𐑕𐑳𐑥 𐑗𐑲𐑯𐑩 𐑑 ·𐑗𐑲𐑯𐑩.',
        'F tUk sum cFna t GcFna.'],
        [ 'test for q/Q/y/Y mixup',
         'Ah, we are out of oil.',
        '𐑭, 𐑢𐑰 𐑸 𐑬𐑑 𐑝 𐑶𐑤.',
        'y, wI R Qt v ql.'],
        [ 'test for unknown words',
         'My most enthusiastic contrafibulations!',
        '𐑥𐑲 𐑥𐑴𐑕𐑑 𐑦𐑯𐑔𐑵𐑟𐑰𐑨𐑕𐑑𐑦𐑒 contrafibulations!',
        undef],
];

plan tests => (scalar(@$tests)*2);

use Data::Dumper;

my $shavian = Lingua::EN::Alphabet::Shaw->new();

for (@$tests) {
    my $desc = $_->[0];
    my $latn = $_->[1];
    my $shaw = $_->[2];
    my $mapp = $_->[3];

    is($shavian->transliterate($latn), $shaw, $desc);
    if (defined $mapp) {
        is($shavian->mapping($shaw), $mapp, "$desc - mapping");
    } else {
        ok("nonsensical test");
    }
}
