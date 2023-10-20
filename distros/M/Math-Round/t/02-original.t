#!perl

use strict;
use warnings;
use Test::More;

use Math::Round qw(:all);


ok(   round(2.4) == 2
   && round(2.5) == 3
   && round(2.6) == 3
   && eq2(round(-3.9, -2.5), -4, -3), "round");

ok(   round_even(2.4) == 2
   && round_even(2.5) == 2
   && eq2(round_even(-2.6, 3.5), -3, 4), "round_even");

ok(   round_odd(16.4) == 16
   && round_odd(16.5) == 17
   && round_odd(16.6) == 17
   && eq2(round_odd(-16.7, 17.5), -17, 17), "round_odd");

ok(   round_rand(16.4) == 16
   && round_rand(16.6) == 17
   && eq2(round_rand(-17.8, -29.2), -18, -29), "round_rand");

ok(   nearest(20, 9) == 0
   && nearest(20, 10) == 20
   && nearest(20, 11) == 20
   && sprintf("%.2f", nearest(0.01, 16.575)) eq "16.58"
   && eq2(nearest(20, -98, -110), -100, -120), "nearest");

ok(   nearest_ceil(20, 9) == 0
   && nearest_ceil(20, 10) == 20
   && nearest_ceil(20, 11) == 20
   && eq2(nearest_ceil(20, -98, -110), -100, -100), "nearest_ceil");

ok(   nearest_floor(20, 9) == 0
   && nearest_floor(20, 10) == 0
   && nearest_floor(20, 11) == 20
   && eq2(nearest_floor(20, -98, -110), -100, -120), "nearest_floor");

ok(   nearest_rand(30, 44) == 30
   && nearest_rand(30, 46) == 60
   && eq2(nearest_rand(30, -76, -112), -90, -120), "nearest_rand");

ok(   nlowmult(10, 44) == 40
   && nlowmult(10, 46) == 40
   && eq2(nlowmult(30, -76, -91), -90, -120), "nlowmult");

ok(   nhimult(10, 41) == 50
   && nhimult(10, 49) == 50
   && eq2(nhimult(30, -74, -119), -60, -90), "nhimult");

done_testing();


#--- Compare two lists with 2 elements each for equality.
sub eq2 {
 my ($a0, $a1, $b0, $b1) = @_;
 return ($a0 == $b0 && $a1 == $b1) ? 1 : 0;
}

