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
    use_ok('Lingua::IND::Nums2Words');
    $tests++;
}

use Lingua::IND::Nums2Words         qw(:ALL);

# }}}

# {{{ nums2words

my $nw = [
    [
        0,
        'nol',
        '0',
    ],
    [
        1,
        'satu ',
        '1',
    ],
    [
        -1,
        'negatif satu ',
        '-1',
    ],
    [
        1234,
        'seribu dua ratus tiga puluh empat ',
        '1234',
    ],
    [
        100,
        'seratus ',
        '100',
    ],
    [
        200,
        'dua ratus ',
        '200',
    ],
    [
        123456,
        'seratus dua puluh tiga ribu empat ratus lima puluh enam ',
        '123456',
    ],
    [
        1_900_450,
        'satu juta sembilan ratus ribu empat ratus lima puluh ',
        '1 900 450',
    ],
    [
        4_000_000_000,
        'empat milyar ',
        '4 000 000 000',
    ],
    [
        98,
        'sembilan puluh delapan ',
        '98',
    ],
    [
        9999,
        'sembilan ribu sembilan ratus sembilan puluh sembilan ',
        '9999',
    ],
    [
        -123,
        'negatif seratus dua puluh tiga ',
        '-123',
    ],
    [
        10_000_000_000_000,
        'sepuluh triliun ',
        '10 trillions',
    ],
    [
        10 ** 500,
        'nol',
        'out of bounds',
    ],
    [
        undef,
        q{},
        'undef args',
    ],
];

for my $test (@{$nw}) {
    my $got = nums2words($test->[0]);
    my $exp = $test->[1];
    is($got, $exp, $test->[2] . ' in IND');
    $tests++;
}

# }}}
# {{{ nums2words_simple

my $nws = [
    [
        0,
        'nol',
        '0',
    ],
    [
        1,
        'satu',
        '1',
    ],
    [
        123456,
        'satu dua tiga empat lima enam',
        '123456',
    ],
    [
        10_000_000_000_000,
        'satu nol nol nol nol nol nol nol nol nol nol nol nol nol',
        '10 trillions',
    ],
    [
        10 ** 500,
        'nol',
        'out of bounds',
    ],
    [
        undef,
        q{},
        'undef args',
    ],
];

for my $test (@{$nws}) {
    my $got = nums2words_simple($test->[0]);
    my $exp = $test->[1];
    is($got, $exp, $test->[2] . ' in IND');
    $tests++;
}

# }}}

done_testing($tests);

__END__
