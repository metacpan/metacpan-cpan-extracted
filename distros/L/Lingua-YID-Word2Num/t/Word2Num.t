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
    use_ok('Lingua::YID::Word2Num');
    $tests++;
}

use Lingua::YID::Word2Num          qw(w2n);

# }}}

# {{{ w2n

my $wn = [
    [
        'זיבעצן',
        17,
        '17 in Yiddish'
    ],
    [
        'דרײַ און פופציק',
        53,
        '53 in Yiddish'
    ],
    [
        'אײנס הונדערט אכט און דרײַסיק',
        138,
        '138 in Yiddish'
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
