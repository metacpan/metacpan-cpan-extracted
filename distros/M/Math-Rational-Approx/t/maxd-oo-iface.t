#!perl

use strict;
use warnings;

use Math::Rational::Approx::MaxD;

use Test::More;
use Test::Exception;


sub maxD { Math::Rational::Approx::MaxD->new( @_ ) }

throws_ok { maxD( x => -2, maxD => 1 ) } qr/positive number/, '$x < 0 ';
throws_ok { maxD( x => 0, maxD => 1 ) } qr/positive number/, '$x == 0 ';

throws_ok { maxD( x => 2, maxD => -1 ) } qr/positive integer/, '$maxD < 0 ';
throws_ok { maxD( x => 2, maxD => 1.3 ) } qr/positive integer/, '$maxD ! integer ';

dies_ok { maxD( x => 2, maxD => 1, bounds => 3 ) } "terms != ARRAYREF";

throws_ok { maxD( x => 2, maxD => 1, bounds => [ 1 ] ) } qr/incorrect number of elements/, "too few terms";
throws_ok { maxD( x => 2, maxD => 1, bounds => [ 1, 1, 0, 1 ] ) } qr/is not less than/, "flipped range";
throws_ok { maxD( x => 2, maxD => 1, bounds => [ 3, 1, 4, 1 ] ) } qr/do not bound/, "bad range";

done_testing;


