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
    use_ok('Lingua::MON::Word2Num');
    $tests++;
}

use Lingua::MON::Word2Num          qw(w2n);

# }}}

# {{{ w2n

my $wn = [
    [
        'арван долоо',
        17,
        '17 in Mongolian'
    ],
    [
        'тавин гурав',
        53,
        '53 in Mongolian'
    ],
    [
        'зуун гучин найм',
        138,
        '138 in Mongolian'
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
