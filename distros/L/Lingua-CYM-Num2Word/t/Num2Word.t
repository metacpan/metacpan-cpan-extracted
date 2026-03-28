#!/usr/bin/env perl
# For Emacs: -*- mode:cperl; eval: (folding-mode 1) -*-
#
# Copyright (c) PetaMem, s.r.o. 2009-present
#

# {{{ use block

use strict;
use warnings;
use utf8;

use Test::Exception;
use Test::More;

# }}}

# {{{ basic tests

my $tests;

BEGIN {
    use_ok('Lingua::CYM::Num2Word');
    $tests++;
}

use Lingua::CYM::Num2Word           qw(:ALL);

# }}}

# {{{ num2cym_cardinal

my $n2c = [
    [
        0,
        'dim',
        '0'
    ],
    [
        1,
        'un',
        '1'
    ],
    [
        5,
        'pump',
        '5'
    ],
    [
        10,
        'deg',
        '10'
    ],
    [
        11,
        'un deg un',
        '11'
    ],
    [
        15,
        'un deg pump',
        '15'
    ],
    [
        20,
        'dau ddeg',
        '20'
    ],
    [
        34,
        'tri deg pedwar',
        '34'
    ],
    [
        56,
        'pum deg chwech',
        '56'
    ],
    [
        99,
        'naw deg naw',
        '99'
    ],
    [
        100,
        'cant',
        '100'
    ],
    [
        200,
        'dau gant',
        '200'
    ],
    [
        300,
        'tri chant',
        '300'
    ],
    [
        421,
        'pedwar cant dau ddeg un',
        '421'
    ],
    [
        1000,
        'mil',
        '1000'
    ],
    [
        2500,
        'dau mil pum cant',
        '2500'
    ],
    [
        1000000,
        'un miliwn',
        '1000000'
    ],
];

for my $test (@{$n2c}) {
    my $got = num2cym_cardinal($test->[0]);
    my $exp = $test->[1];
    is($got, $exp, $test->[2] . ' in Welsh');
    $tests++;
}

dies_ok( sub { num2cym_cardinal(100000000000); }, 'out of range');
$tests++;

dies_ok( sub { num2cym_cardinal(undef); }, 'undef input args' );
$tests++;

# }}}

done_testing($tests);

__END__
