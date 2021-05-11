#!/usr/bin/perl

use strict;
use warnings;

use Math::Random::Free qw( random_permutation
                           random_set_seed_from_phrase
                           random_uniform_integer );
use Test::More;

plan tests => 2;

random_set_seed_from_phrase( 'Math::Random::Free' );

is( random_uniform_integer( 1, 1, 123 ), 74 );
is( join( ',', random_permutation( 0..9 ) ), '6,7,9,0,5,4,3,1,2,8' );
