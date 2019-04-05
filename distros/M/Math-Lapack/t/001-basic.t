#!perl

use Test2::V0;

use Math::Lapack;
use Math::Lapack::Matrix;


Math::Lapack->seed_rng(10);

my $M = Math::Lapack::Matrix->random(1,1);

my $val = $M->get_element(0,0);

# set same seed again    
Math::Lapack->seed_rng(10);
my $N = Math::Lapack::Matrix->random(1,1);
is $val, $N->get_element(0,0);

done_testing();        
