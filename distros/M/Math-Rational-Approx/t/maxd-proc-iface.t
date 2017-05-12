#!perl

use strict;
use warnings;

use Math::Rational::Approx qw[ maxD ] ;

use Test::More;
use Test::Exception;


throws_ok { maxD( -2, 1 ) } qr/positive number/, '$x < 0 ';
throws_ok { maxD( 0, 1 ) } qr/positive number/, '$x == 0 ';

throws_ok { maxD( 2, -1 ) } qr/positive integer/, '$maxD < 0 ';
throws_ok { maxD( 2, 1.3 ) } qr/positive integer/, '$maxD ! integer ';

dies_ok { maxD( 2, 1, 3 ) } "terms != ARRAYREF";

throws_ok { maxD( 2, 1, [ 1 ] ) } qr/incorrect number of elements/, "too few terms";
throws_ok { maxD( 2, 1, [ 1, 1, 0, 1 ] ) } qr/is not less than/, "flipped range";
throws_ok { maxD( 2, 1, [ 3, 1, 4, 1 ] ) } qr/do not bound/, "bad range";

done_testing;


