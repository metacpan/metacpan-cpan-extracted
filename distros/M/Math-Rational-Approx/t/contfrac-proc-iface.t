#!perl

use strict;
use warnings;

use Math::Rational::Approx qw[ contfrac contfrac_nd ] ;

use Test::More;
use Test::Exception;


throws_ok { contfrac( -2, 1 ) } qr/positive number/, '$x < 0 ';
throws_ok { contfrac( 0, 1 ) } qr/positive number/, '$x == 0 ';

throws_ok { contfrac( 2, -1 ) } qr/positive integer/, '$contfrac < 0 ';
throws_ok { contfrac( 2, 1.3 ) } qr/positive integer/, '$contfrac ! integer ';

dies_ok { contfrac( 2, 1, 3 ) } "terms != ARRAYREF";

throws_ok { contfrac_nd( ) } qr/0 parameters/, "no parameters";

throws_ok { contfrac_nd( 1 ) } qr/not one of the allowed types/, "terms != ARRAYREF";

lives_ok { contfrac_nd( contfrac( 0.0625, 2 ) ) } "contfrac_nd( contfrac( ... ) )";

done_testing;


