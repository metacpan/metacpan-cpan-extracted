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
    use_ok('Lingua::IND::Words2Nums');
    $tests++;
}

use Lingua::IND::Words2Nums        qw(:ALL);

# }}}

# {{{ words2nums

my $wn = [
    [
        'seribu dua ratus tiga puluh empat',
        1234,
        '1234 in IND',
    ],
    [
        'nonexisting',
        undef,
        'nonexisting number',
    ],
    [
        undef,
        0,
        'undef args -> 0',
    ],
];

for my $test (@{$wn}) {
    my $got = words2nums($test->[0]);
    my $exp = $test->[1];
    is($got, $exp, $test->[2]);
    $tests++;
}

# }}}
# {{{ words2nums_simple

my $wns = [
    [
        'satu dua tiga empat lima enam',
        123456,
        '123456',
    ],
    [
        'nonexisting',
        undef,
        'nonexisting number',
    ],
    [
        undef,
        0,
        'undef args -> 0',
    ],
];

for my $test (@{$wn}) {
    my $got = words2nums($test->[0]);
    my $exp = $test->[1];
    is($got, $exp, $test->[2] . ' in IND');
    $tests++;
}

# }}}


done_testing($tests);

__END__
