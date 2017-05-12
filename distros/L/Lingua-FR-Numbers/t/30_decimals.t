#!/usr/bin/perl -w
use strict;
use Test;
BEGIN { plan tests => 9 }
use Lingua::FR::Numbers qw( number_to_fr );
use bignum;

use vars qw(@numbers);
do 't/decimals';

use vars qw(@numbers);
while (@numbers){
	my ($number, $test_string) = splice(@numbers, 0, 2);
	#skip('decimals not yet supported', number_to_fr($number), $test_string );
	ok(number_to_fr($number), $test_string );
}


