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

binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

# }}}

# {{{ basic tests

my $tests;

BEGIN {
    use_ok('Lingua::HIN::Num2Word');
    $tests++;
}

use Lingua::HIN::Num2Word           qw(:ALL);

# }}}

# {{{ num2hin_cardinal

my $n2h = [
    [
        0,
        'शून्य',
        '0 (zero)',
    ],
    [
        7,
        'सात',
        '7 (single digit)',
    ],
    [
        25,
        'पच्चीस',
        '25 (irregular 1-99)',
    ],
    [
        99,
        'निन्यानवे',
        '99 (last irregular)',
    ],
    [
        100,
        'एक सौ',
        '100 (one hundred)',
    ],
    [
        125,
        'एक सौ पच्चीस',
        '125 (hundred + irregular)',
    ],
    [
        1_000,
        'एक हज़ार',
        '1000 (one thousand)',
    ],
    [
        1_947,
        'एक हज़ार नौ सौ सैंतालीस',
        '1947 (thousand + hundreds + irregular)',
    ],
    [
        1_00_000,
        'एक लाख',
        '100000 (one lakh)',
    ],
    [
        5_50_000,
        'पाँच लाख पचास हज़ार',
        '550000 (five lakh fifty thousand)',
    ],
    [
        1_00_00_000,
        'एक करोड़',
        '10000000 (one crore)',
    ],
    [
        12_34_56_789,
        'बारह करोड़ चौंतीस लाख छप्पन हज़ार सात सौ नवासी',
        '123456789 (full composition)',
    ],
];

for my $test (@{$n2h}) {
    my $got = num2hin_cardinal($test->[0]);
    my $exp = $test->[1];
    is($got, $exp, $test->[2]);
    $tests++;
}

dies_ok( sub { num2hin_cardinal(100_00_00_000); }, 'out of range');
$tests++;

dies_ok( sub { num2hin_cardinal(undef); }, 'undef input args' );
$tests++;

# }}}

done_testing($tests);

__END__
