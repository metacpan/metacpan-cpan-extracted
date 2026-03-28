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
    use_ok('Lingua::GLE::Num2Word');
    $tests++;
}

use Lingua::GLE::Num2Word           qw(:ALL);

# }}}

# {{{ num2gle_cardinal

my $n2g = [
    [
        0,
        'náid',
        '0'
    ],
    [
        1,
        'a haon',
        '1'
    ],
    [
        7,
        'a seacht',
        '7'
    ],
    [
        10,
        'a deich',
        '10'
    ],
    [
        11,
        'a haon déag',
        '11'
    ],
    [
        12,
        'a dó dhéag',
        '12'
    ],
    [
        19,
        'a naoi déag',
        '19'
    ],
    [
        20,
        'fiche',
        '20'
    ],
    [
        33,
        'tríocha a trí',
        '33'
    ],
    [
        40,
        'daichead',
        '40'
    ],
    [
        55,
        'caoga a cúig',
        '55'
    ],
    [
        99,
        'nócha a naoi',
        '99'
    ],
    [
        100,
        'céad',
        '100'
    ],
    [
        123,
        'céad fiche a trí',
        '123'
    ],
    [
        200,
        'a dó céad',
        '200'
    ],
    [
        999,
        'a naoi céad nócha a naoi',
        '999'
    ],
    [
        1000,
        'míle',
        '1000'
    ],
    [
        1984,
        'míle a naoi céad ochtó a ceathair',
        '1984'
    ],
    [
        2025,
        'a dó míle fiche a cúig',
        '2025'
    ],
    [
        1000000,
        'milliún',
        '1000000'
    ],
    [
        5000000,
        'a cúig milliún',
        '5000000'
    ],
];

for my $test (@{$n2g}) {
    my $got = num2gle_cardinal($test->[0]);
    my $exp = $test->[1];
    is($got, $exp, $test->[2] . ' in Irish');
    $tests++;
}

dies_ok( sub { num2gle_cardinal(1000000000); }, 'out of range');
$tests++;

dies_ok( sub { num2gle_cardinal(undef); }, 'undef input args' );
$tests++;

# }}}

done_testing($tests);

__END__
