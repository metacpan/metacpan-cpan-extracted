use strict;
use Test::More;
use Test::Number::Delta within => 1e-14;
BEGIN {
   use_ok('Math::Random::MT', qw(srand rand irand));
}


# Test that functional interface results are identical to that of OO interface

ok srand(5489);


delta_ok rand(), 0.814723691903055;
delta_ok rand(), 0.135477004107088;

delta_ok irand(), 3890346734;
delta_ok irand(), 3586334585;

delta_ok rand(10), 1.269868118688464, 'rand() takes a multiplier as argument';
delta_ok rand(10), 9.688677710946649;

delta_ok irand(123), 3922919429, 'irand() takes no argument'; # given argument does nothing
delta_ok irand(123),  949333985;

is srand(0), 0, '0 is a valid seed';


done_testing();
