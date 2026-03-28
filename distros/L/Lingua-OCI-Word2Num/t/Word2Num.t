#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::OCI::Word2Num');
    $tests++;
}

use Lingua::OCI::Word2Num qw(w2n);

my @pairs = (
    [ 'zèro',                              0 ],
    [ 'un',                                 1 ],
    [ 'cinc',                               5 ],
    [ 'sèt',                                7 ],
    [ 'uèch',                               8 ],
    [ 'nòu',                                9 ],
    [ 'dètz',                              10 ],
    [ 'onze',                              11 ],
    [ 'catòrze',                           14 ],
    [ 'setze',                             16 ],
    [ 'dètz-e-sèt',                       17 ],
    [ 'dètz-e-uèch',                      18 ],
    [ 'dètz-e-nòu',                       19 ],
    [ 'vint',                              20 ],
    [ 'vint-e-un',                         21 ],
    [ 'vint-e-cinc',                       25 ],
    [ 'trenta',                            30 ],
    [ 'trenta-e-un',                       31 ],
    [ 'quaranta-e-dos',                    42 ],
    [ 'cinquanta',                         50 ],
    [ 'seissanta-e-sèt',                   67 ],
    [ 'setanta',                           70 ],
    [ 'ochanta',                           80 ],
    [ 'nonanta',                           90 ],
    [ 'nonanta-e-nòu',                     99 ],
    [ 'cent',                             100 ],
    [ 'cent vint-e-tres',                 123 ],
    [ 'dos cents',                        200 ],
    [ 'cinc cents',                       500 ],
    [ 'nòu cents nonanta-e-nòu',          999 ],
    [ 'mila',                            1000 ],
    [ 'mila un',                         1001 ],
    [ 'dos mila',                        2000 ],
    [ 'un milion',                    1000000 ],
    [ 'dos milions',                  2000000 ],
);

for my $pair (@pairs) {
    my ($word, $expected) = @$pair;
    my $result = w2n($word);
    is($result, $expected, "'$word' => $expected");
    $tests++;
}

# undef input
my $result = w2n(undef);
ok(!defined $result, 'undef input');
$tests++;

done_testing($tests);
