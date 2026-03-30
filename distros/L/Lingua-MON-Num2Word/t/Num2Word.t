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
    use_ok('Lingua::MON::Num2Word');
    $tests++;
}

use Lingua::MON::Num2Word           qw(:ALL);

# }}}

# {{{ num2mon_cardinal

 my $n2m = [
     [
         0,
         'тэг',
         '0'
     ],
     [
         7,
         'долоо',
         '7'
     ],
     [
         10,
         'арав',
         '10'
     ],
     [
         11,
         'арван нэг',
         '11'
     ],
     [
         17,
         'арван долоо',
         '17'
     ],
     [
         20,
         'хорь',
         '20'
     ],
     [
         21,
         'хорин нэг',
         '21'
     ],
     [
         53,
         'тавин гурав',
         '53'
     ],
     [
         100,
         'зуу',
         '100'
     ],
     [
         101,
         'зуун нэг',
         '101'
     ],
     [
         200,
         'хоёр зуун',
         '200'
     ],
     [
         1000,
         'мянга',
         '1000'
     ],
     [
         5000,
         'тав мянга',
         '5000'
     ],
 ];

for my $test (@{$n2m}) {
    my $got = num2mon_cardinal($test->[0]);
    my $exp = $test->[1];
    is($got, $exp, $test->[2] . ' in Mongolian');
    $tests++;
}

dies_ok( sub {  num2mon_cardinal(100000000000); }, 'out of range');
$tests++;

dies_ok( sub { num2mon_cardinal(undef); }, 'undef input args' );
$tests++;

# }}}

done_testing($tests);

__END__
