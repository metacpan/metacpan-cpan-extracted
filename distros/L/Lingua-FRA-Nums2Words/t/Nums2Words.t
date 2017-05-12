#!/usr/bin/env perl
# For Emacs: -*- mode:cperl; mode:folding -*-
#
# Copyright (C) PetaMem, s.r.o. 2009-present
#

# {{{ use block

use strict;
use warnings;
use utf8;

use Test::More;

# }}}

# {{{ basic tests

my $tests;

BEGIN {
    use_ok('Lingua::FRA::Nums2Words');
    $tests++;
}

use Lingua::FRA::Nums2Words         qw(:ALL);

# }}}

# {{{ num2word

my $nw =  [
    [
        0,
        "z\x{E9}ro",
        '0',
    ],
    [
        1,
        'un',
        '1',
    ],
    [
        -1,
        'moins un',
        '13',
    ],
    [
        1234,
        'mille deux cent trente quatre',
        '1234',
    ],
    [
        100,
        'cent',
        '100',
    ],
    [
        200,
        'deux cents',
        '200',
    ],
    [
        123456,
        'cent vingt trois mille quatre cent cinquante six',
        '123456',
    ],
    [
        1_900_450,
        'un million neuf cent mille quatre cent cinquante',
        '1 900 450',
    ],
    [
        4_000_000_000,
        'quatre milliards',
        '4 000 000 000',
    ],
    [
        98,
        'quatre-vingt-dix huit',
        '98',
    ],
    [
        9999,
        'neuf mille neuf cent quatre-vingt-dix neuf',
        '9999',
    ],
    [
        -123,
        'moins cent vingt trois',
        '-123',
    ],
    [
        10_000_000_000_000,
        'dix trillions',
        '10 trillions',
    ],
    [
        10 ** 500,
        undef,
        'out of bounds',
    ],
    [
        undef,
        "z\x{E9}ro",
        'undef args -> 0',
    ],
];

for my $test (@{$nw}) {
    my $got = num2word($test->[0]);
    my $exp = $test->[1];
    is($got, $exp, $test->[2] . ' in French');
    $tests++;
}

# }}}

done_testing($tests);

__END__
