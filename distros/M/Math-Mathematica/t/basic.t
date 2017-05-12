use strict;
use warnings;

use Test::More;
use Math::Mathematica;

my $math = Math::Mathematica->new;
isa_ok( $math, 'Math::Mathematica' );
is( $math->evaluate('3+4'), 7, "Simple math" );
is( $math->evaluate('Integrate[Sin[x],{x,0,Pi}]'), 2, "Higher level math" );

done_testing;

