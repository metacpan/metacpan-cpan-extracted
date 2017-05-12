#!/usr/bin/env perl
# For Emacs: -*- mode:cperl; mode:folding -*-
#
# Copyright (C) PetaMem, s.r.o. 2009-present
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
    use_ok('Lingua::ZHO::Numbers');
    $tests++;
}

# }}}
# {{{ number_to_zh

my $nw = [
    [
        12345,
        'YiWanErQianSanBaiSiShiWu',
        '12345 in PinYin',
    ],
    [
        0,
        'Ling',
        '0 in PinYin',
    ],
 ];

for my $test (@{$nw}) {
    my $got = Lingua::ZHO::Numbers::number_to_zh($test->[0]);
    my $exp = $test->[1];
    is($got, $exp, $test->[2]);
    $tests++;
}

dies_ok( sub { Lingua::ZHO::Numbers::number_to_zh(undef); }, 'undef args (like 0)' );
$tests++;

Lingua::ZHO::Numbers->charset('big5');

my $nw_b5 = [
    [
        12345,
        "\xA4\@\xB8U\xA4G\xA4d\xA4T\xA6\xCA\xA5|\xA4Q\xA4\xAD",
        '12345 in Big5',
    ],
    [
        0,
        "\xB9s",
        '0 in Big5',
    ],
];

for my $test (@{$nw_b5}) {
    my $got = Lingua::ZHO::Numbers::number_to_zh($test->[0]);
    my $exp = $test->[1];
    is($got, $exp, $test->[2]);
    $tests++;
}

dies_ok( sub { Lingua::ZHO::Numbers::number_to_zh(undef); }, 'undef args' );
$tests++;

Lingua::ZHO::Numbers->charset('simplified');

my $nw_s = [
    [
        12345,
        "\x{4e00}\x{4e07}\x{4e8c}\x{5343}\x{4e09}\x{767e}\x{56db}\x{5341}\x{4e94}",
        '12345 in Simplified script',
    ],
    [
        0,
        "\x{96f6}",
        '0 in Simplified script',
    ],
];

for my $test (@{$nw_s}) {
    my $got = Lingua::ZHO::Numbers::number_to_zh($test->[0]);
    my $exp = $test->[1];
    is($got, $exp, $test->[2]);
    $tests++;
}

dies_ok( sub { Lingua::ZHO::Numbers::number_to_zh(undef); }, 'undef args' );
$tests++;

Lingua::ZHO::Numbers->charset('traditional');

my $nw_t = [
    [
        12345,
        "\x{4e00}\x{842c}\x{4e8c}\x{5343}\x{4e09}\x{767e}\x{56db}\x{5341}\x{4e94}",
        '12345 in Traditional script',
    ],
    [
        0,
        "\x{96f6}",
        '0 in Traditional script',
    ],
];

for my $test (@{$nw_t}) {
    my $got = Lingua::ZHO::Numbers::number_to_zh($test->[0]);
    my $exp = $test->[1];
    is($got, $exp, $test->[2]);
    $tests++;
}

dies_ok( sub { Lingua::ZHO::Numbers::number_to_zh(undef) }, 'undef args' );
$tests++;

# }}}

done_testing($tests);

__END__
