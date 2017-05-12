#!/usr/bin/perl -w
use strict;
use Test;
BEGIN { plan tests => 76 }
use Lingua::FR::Numbers qw( number_to_fr );
use bignum;

use vars qw(@numbers);
do 't/numbers';

while (@numbers){
	my ($number, $test_string) = splice(@numbers, 0, 2);
	ok( number_to_fr( $number ), $test_string );
}

