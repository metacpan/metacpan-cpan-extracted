#!/usr/bin/perl -w
use strict;
use Test;
use bignum;
BEGIN { plan tests => 152 }
use Lingua::FR::Numbers;
use vars qw(@numbers);
do 't/numbers';

while (@numbers){
	my ($number, $test_string) = splice(@numbers, 0, 2);
	my $num = Lingua::FR::Numbers->new($number);
	ok( defined $num );
	ok( $num->get_string, $test_string, "'$test_string'" );
}

