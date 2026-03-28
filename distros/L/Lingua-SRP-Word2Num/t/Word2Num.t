#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::SRP::Word2Num');
    $tests++;
}

use Lingua::SRP::Word2Num qw(w2n);

my @pairs = (
    [ 'нула',                           0 ],
    [ 'један',                          1 ],
    [ 'два',                            2 ],
    [ 'пет',                            5 ],
    [ 'десет',                         10 ],
    [ 'једанаест',                     11 ],
    [ 'дванаест',                      12 ],
    [ 'деветнаест',                    19 ],
    [ 'двадесет',                      20 ],
    [ 'двадесет три',                  23 ],
    [ 'четрдесет два',                 42 ],
    [ 'деведесет девет',               99 ],
    [ 'сто',                          100 ],
    [ 'двеста',                       200 ],
    [ 'триста',                       300 ],
    [ 'четиристо',                    400 ],
    [ 'сто двадесет три',             123 ],
    [ 'петсто педесет пет',           555 ],
    [ 'деветсто деведесет девет',     999 ],
    [ 'хиљада',                      1000 ],
    [ 'две хиљаде',                  2000 ],
    [ 'пет хиљада',                  5000 ],
    [ 'двадесет три хиљаде сто',    23100 ],
    [ 'милион',                   1000000 ],
    [ 'два милиона',              2000000 ],
);

for my $pair (@pairs) {
    my ($word, $expected) = @$pair;
    my $got = w2n($word);
    is($got, $expected, "$expected => $word");
    $tests++;
}

my $result = w2n(undef);
ok(!defined $result, 'undef input');
$tests++;

done_testing($tests);
