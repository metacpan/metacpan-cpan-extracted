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
    use_ok('Lingua::DEU::Num2Word');
    $tests++;
}

use Lingua::DEU::Num2Word           qw(:ALL);

# }}}

# {{{ num2deu_cardinal

 my $n2d = [
     [
         7,
         'sieben',
         '7'
     ],
     [
         186,
         'einhundertsechsundachtzig',
         '186'
     ],
     [
         1000,
         'eintausend',
         '1000'
     ],
 ];

for my $test (@{$n2d}) {
    my $got = num2deu_cardinal($test->[0]);
    my $exp = $test->[1];
    is($got, $exp, $test->[2] . ' in German');
    $tests++;
}

dies_ok( sub {  num2deu_cardinal(100000000000); }, 'out of range');
$tests++;

dies_ok( sub { num2deu_cardinal(undef); }, 'undef input args' );
$tests++;

# }}}

done_testing($tests);

__END__
