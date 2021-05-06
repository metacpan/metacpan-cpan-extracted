#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Faster::Maths;

# Use some lexicals to avoid constfolding
my $one  = 1;
my $__dummy1; # to defeat OP_PADRANGE
my $two  = 2;
my $__dummy2;
my $four = 4;

is( $one + $two + $four, 7, '1+2+4 is 7' );

is( $four - $two - $one, 1, '4-2-1 is 1' );

is( $one * $four * $two, 8, '1*4*2 is 8' );

is( $two * $four + $one, 9, '2*4+1 is 9' );
is( $two * ( $four + $one ), 10, '2*(4+1) is 10' );

# A single iteration of Julia
{
   my ($zr, $zi) = (0.125, 0.125);
   my ($cr, $ci) = (-0.8, 0.156);

   ($zr, $zi) = ( ($zr*$zr - $zi*$zi + $cr), 2*($zr*$zi) + $ci );

   is_deeply( [$zr, $zi], [-0.8, 0.18725], 'Julia iteration' );
}

done_testing;
