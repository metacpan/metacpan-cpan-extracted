use strict;
use Test::More;
use Test::Number::Delta within => 1e-14;
BEGIN {
   use_ok('Math::Random::MT');
}


# Check that we can use an array to seed the generator.

my $gen;

ok $gen = Math::Random::MT->new(1, 2, 3, 4);
delta_ok $gen->rand(1), 0.67886575916782;
delta_ok $gen->irand, 1022996879;

done_testing();
