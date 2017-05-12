use strict;
use warnings;
use Test::More;
use Test::Number::Delta within => 1e-14;
BEGIN {
   use_ok('Math::Random::MT::Perl');
}


# Check that we can use an array to seed the generator.

my $gen;

ok $gen = Math::Random::MT::Perl->new(1, 2, 3, 4);
delta_ok $gen->rand(1), 0.67886575916782;
delta_ok $gen->irand, 1022996879;

done_testing();
