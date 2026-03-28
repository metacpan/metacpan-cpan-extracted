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

# }}}

# {{{ basic tests

my $tests;

BEGIN {
    use_ok('Lingua::SQI::Num2Word');
    $tests++;
}

use Lingua::SQI::Num2Word           qw(:ALL);

# }}}

# {{{ num2sqi_cardinal

 my $n2s = [
     [
         0,
         'zero',
         '0'
     ],
     [
         1,
         'një',
         '1'
     ],
     [
         7,
         'shtatë',
         '7'
     ],
     [
         10,
         'dhjetë',
         '10'
     ],
     [
         11,
         'njëmbëdhjetë',
         '11'
     ],
     [
         17,
         'shtatëmbëdhjetë',
         '17'
     ],
     [
         20,
         'njëzet',
         '20'
     ],
     [
         23,
         'njëzet e tre',
         '23'
     ],
     [
         40,
         'dyzet',
         '40'
     ],
     [
         99,
         'nëntëdhjetë e nëntë',
         '99'
     ],
     [
         100,
         'njëqind',
         '100'
     ],
     [
         186,
         'njëqind e tetëdhjetë e gjashtë',
         '186'
     ],
     [
         300,
         'treqind',
         '300'
     ],
     [
         1000,
         'një mijë',
         '1000'
     ],
     [
         1234,
         'një mijë e dyqind e tridhjetë e katër',
         '1234'
     ],
     [
         2000,
         'dy mijë',
         '2000'
     ],
     [
         1000000,
         'një milion',
         '1000000'
     ],
     [
         2000000,
         'dy milionë',
         '2000000'
     ],
     [
         5123456,
         'pesë milionë e njëqind e njëzet e tre mijë e katërqind e pesëdhjetë e gjashtë',
         '5123456'
     ],
 ];

for my $test (@{$n2s}) {
    my $got = num2sqi_cardinal($test->[0]);
    my $exp = $test->[1];
    is($got, $exp, $test->[2] . ' in Albanian');
    $tests++;
}

dies_ok( sub {  num2sqi_cardinal(100000000000); }, 'out of range');
$tests++;

dies_ok( sub { num2sqi_cardinal(undef); }, 'undef input args' );
$tests++;

# }}}

done_testing($tests);

__END__
