#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::MKD::Word2Num');
    $tests++;
}

use Lingua::MKD::Word2Num qw(w2n);

my @cases = (
    [ 'нула',                                0 ],
    [ 'еден',                                1 ],
    [ 'една',                                1 ],
    [ 'два',                                 2 ],
    [ 'две',                                 2 ],
    [ 'пет',                                 5 ],
    [ 'десет',                               10 ],
    [ 'единаесет',                           11 ],
    [ 'дванаесет',                           12 ],
    [ 'деветнаесет',                         19 ],
    [ 'дваесет',                             20 ],
    [ 'дваесет и три',                       23 ],
    [ 'педесет',                             50 ],
    [ 'деведесет',                           90 ],
    [ 'сто',                                 100 ],
    [ 'сто и еден',                          101 ],
    [ 'сто и дваесет',                       120 ],
    [ 'сто дваесет и три',                   123 ],
    [ 'двесте',                              200 ],
    [ 'триста',                              300 ],
    [ 'четиристотини',                       400 ],
    [ 'илјада',                              1000 ],
    [ 'две илјади',                          2000 ],
    [ 'илјада и еден',                       1001 ],
    [ 'илјада и дваесет и три',              1023 ],
    [ 'илјада и сто',                        1100 ],
    [ 'илјада двесте триесет и четири',      1234 ],
    [ 'еден милион',                         1000000 ],
    [ 'два милиони',                         2000000 ],
    [ 'еден милион илјада и еден',           1001001 ],
);

for my $case (@cases) {
    my ($word, $expected) = @$case;
    my $result = w2n($word);
    is($result, $expected, "'$word' => $expected");
    $tests++;
}

# undef input returns undef
my $result = w2n(undef);
ok(!defined $result, 'undef input');
$tests++;

done_testing($tests);
