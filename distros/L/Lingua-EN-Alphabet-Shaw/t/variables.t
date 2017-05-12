#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Test::More;
use Lingua::EN::Alphabet::Shaw qw(transliterate);

my $tests = [
        [ 'C-style',
        '%d test',
        '%d 𐑑𐑧𐑕𐑑'],
#        [ 'Python-style',
#	  '%(number)d test',
#	  '%(number)d 𐑑𐑧𐑕𐑑'],
];

plan tests => (scalar(@$tests));

my $shavian = Lingua::EN::Alphabet::Shaw->new();

for (@$tests) {
    my $desc = $_->[0];
    my $latn = $_->[1];
    my $shaw = $_->[2];

    is($shavian->transliterate($latn), $shaw, $desc);
}
