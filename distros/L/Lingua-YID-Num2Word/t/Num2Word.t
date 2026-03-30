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
    use_ok('Lingua::YID::Num2Word');
    $tests++;
}

use Lingua::YID::Num2Word           qw(:ALL);

# }}}

# {{{ num2yid_cardinal

 my $n2y = [
     [
         0,
         'נול',
         '0'
     ],
     [
         7,
         'זיבן',
         '7'
     ],
     [
         11,
         'עלף',
         '11'
     ],
     [
         17,
         'זיבעצן',
         '17'
     ],
     [
         21,
         'אײנס און צוואַנציק',
         '21'
     ],
     [
         100,
         'הונדערט',
         '100'
     ],
     [
         186,
         'אײנס הונדערט זעקס און אַכציק',
         '186'
     ],
     [
         1000,
         'אײנס טויזנט',
         '1000'
     ],
     [
         5000,
         'פֿינף טויזנט',
         '5000'
     ],
 ];

for my $test (@{$n2y}) {
    my $got = num2yid_cardinal($test->[0]);
    my $exp = $test->[1];
    is($got, $exp, $test->[2] . ' in Yiddish');
    $tests++;
}

dies_ok( sub {  num2yid_cardinal(100000000000); }, 'out of range');
$tests++;

dies_ok( sub { num2yid_cardinal(undef); }, 'undef input args' );
$tests++;

# }}}

done_testing($tests);

__END__
