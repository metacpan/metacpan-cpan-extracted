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
    use_ok('Lingua::NLD::Num2Word');
    $tests++;
}

use Lingua::NLD::Num2Word           qw(:ALL);

# }}}

# {{{ num2nld_cardinal

my $n2w = [
    [
        123,
        'eenhonderddrieentwintig',
        '123',
    ],
    [
        456789,
        'vierhonderdzesenvijftigduizend zevenhonderdnegenentachtig',
        '456789',
    ],
];

for my $test (@{$n2w}) {
    my $got = num2nld_cardinal($test->[0]);
    my $exp = $test->[1];
    is($got, $exp, $test->[2] . ' in NLD');
    $tests++;
}

# }}}

done_testing($tests);

__END__
