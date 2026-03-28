#!/usr/bin/env perl
# For Emacs: -*- mode:cperl; eval: (folding-mode 1) -*-
#
# Copyright (c) PetaMem, s.r.o. 2009-present
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
   use_ok('Lingua::GLE::Word2Num');
   $tests++;
}

use Lingua::GLE::Word2Num          qw(w2n);

# }}}

# {{{ w2n

my $wn = [
    [
        'náid',
        0,
        '0 in Irish'
    ],
    [
        'a haon',
        1,
        '1 in Irish'
    ],
    [
        'a deich',
        10,
        '10 in Irish'
    ],
    [
        'a dó dhéag',
        12,
        '12 in Irish'
    ],
    [
        'a naoi déag',
        19,
        '19 in Irish'
    ],
    [
        'fiche',
        20,
        '20 in Irish'
    ],
    [
        'tríocha a trí',
        33,
        '33 in Irish'
    ],
    [
        'daichead a cúig',
        45,
        '45 in Irish'
    ],
    [
        'céad',
        100,
        '100 in Irish'
    ],
    [
        'a dó céad fiche a trí',
        223,
        '223 in Irish'
    ],
    [
        'míle',
        1000,
        '1 000 in Irish'
    ],
    [
        'míle a naoi céad ochtó a ceathair',
        1984,
        '1984 in Irish'
    ],
    [
        'milliún',
        1000000,
        '1 000 000 in Irish'
    ],
    [
        'a haon milliún míle',
        1001000,
        '1 001 000 in Irish'
    ],
    [
        'nonexisting',
        undef,
        'nonexisting char -> undef'
    ],
    [
        undef,
        undef,
        'undef args'
    ],
];

for my $test (@{$wn}) {
    my $got = w2n($test->[0]);
    my $exp = $test->[1];
    is($got, $exp, $test->[2]);
    $tests++;
}

# }}}

done_testing($tests);

__END__
