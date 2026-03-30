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
    use_ok('Lingua::HYE::Num2Word');
    $tests++;
}

use Lingua::HYE::Num2Word           qw(:ALL);

# }}}

# {{{ num2hye_cardinal

my $n2h = [
    [
        0,
        'զրո',
        '0'
    ],
    [
        1,
        'մեկ',
        '1'
    ],
    [
        7,
        'յոթ',
        '7'
    ],
    [
        10,
        'տաս',
        '10'
    ],
    [
        11,
        'տասնմեկ',
        '11'
    ],
    [
        15,
        'տասնհինգ',
        '15'
    ],
    [
        20,
        'քսան',
        '20'
    ],
    [
        25,
        'քսան հինգ',
        '25'
    ],
    [
        99,
        'իննսուն ինը',
        '99'
    ],
    [
        100,
        'հարյուր',
        '100'
    ],
    [
        186,
        'հարյուր ութսուն վեց',
        '186'
    ],
    [
        200,
        'երկու հարյուր',
        '200'
    ],
    [
        1000,
        'հազար',
        '1000'
    ],
    [
        1001,
        'հազար մեկ',
        '1001'
    ],
    [
        5630,
        'հինգ հազար վեց հարյուր երեսուն',
        '5630'
    ],
    [
        1000000,
        'մեկ միլիոն',
        '1000000'
    ],
    [
        2000000,
        'երկու միլիոն',
        '2000000'
    ],
];

for my $test (@{$n2h}) {
    my $got = num2hye_cardinal($test->[0]);
    my $exp = $test->[1];
    is($got, $exp, $test->[2] . ' in Armenian');
    $tests++;
}

dies_ok( sub {  num2hye_cardinal(100000000000); }, 'out of range');
$tests++;

dies_ok( sub { num2hye_cardinal(undef); }, 'undef input args' );
$tests++;

# }}}

done_testing($tests);

__END__
