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
    use_ok('Lingua::SQI::Word2Num');
    $tests++;
}

use Lingua::SQI::Word2Num          qw(w2n);

# }}}

# {{{ w2n

my $wn = [
    [
        'njëqind e tridhjetë e tetë',
        138,
        '138 in Albanian'
    ],
    [
        'nëntëqind e nëntëdhjetë e nëntë',
        999,
        '999 in Albanian'
    ],
    [
        'njëzet e tre',
        23,
        '23 in Albanian'
    ],
    [
        'shtatëmbëdhjetë',
        17,
        '17 in Albanian'
    ],
    [
        'një mijë',
        1000,
        '1000 in Albanian'
    ],
    [
        'dy mijë e pesëqind',
        2500,
        '2500 in Albanian'
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
