use Test2::V0 -no_srand => 1;
use Math::GSL::Alien;
use Test::Alien::Diag qw( alien_diag );

alien_diag 'Math::GSL::Alien';
ok 1;

done_testing;
