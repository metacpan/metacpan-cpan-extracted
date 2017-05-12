use strict;
use Test::More;
use Test::Number::Delta within => 1e-14;
BEGIN {
   use_ok('Math::Random::MT');
}


# Test that the OO interface works

ok my $gen = Math::Random::MT->new(5489);
isa_ok $gen, 'Math::Random::MT';

delta_ok $gen->rand(),   0.814723691903055;
delta_ok $gen->rand(),   0.135477004107088;

delta_ok $gen->irand(), 3890346734;
delta_ok $gen->irand(), 3586334585;

delta_ok $gen->rand(10), 1.269868118688464, 'rand() takes a multiplier as argument';
delta_ok $gen->rand(10), 9.688677710946649;

delta_ok $gen->irand(123), 3922919429, 'irand() takes no argument'; # given argument does nothing
delta_ok $gen->irand(123),  949333985;

ok $gen = Math::Random::MT->new(0), '0 is a valid seed';
is $gen->get_seed(), 0;

done_testing();
