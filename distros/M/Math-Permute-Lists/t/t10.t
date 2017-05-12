use Test::More qw(no_plan);

use Math::Permute::Lists;

# ok 10*9*8*7*6*5*4*3*2 == permute {} 1..10;
ok  6*5*4*3*2 == permute {} 1..6;
