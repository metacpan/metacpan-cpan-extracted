#!perl

use strict;
use warnings;

use Math::Rational::Approx::ContFrac;

use Test::More;
use Test::Exception;

sub contfrac { Math::Rational::Approx::ContFrac->new( @_ ) }

throws_ok { contfrac( x => -2, n => 1 ) } qr/positive number/, '$x < 0 ';
throws_ok { contfrac( x => 0, n => 1 ) } qr/positive number/, '$x == 0 ';

throws_ok { contfrac( x => 2, n => -1 ) } qr/positive integer/, '$contfrac < 0 ';
throws_ok { contfrac( x => 2, n => 1.3 ) } qr/positive integer/, '$contfrac ! integer ';

done_testing;


