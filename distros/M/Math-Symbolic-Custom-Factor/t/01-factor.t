#!/usr/bin/perl

use strict;
use warnings;
use Math::Symbolic qw/:all/;
use Math::Symbolic::Custom::Factor;

use Test::Simple 'no_plan';

my @factor_tests = (
    "3*x + 12*y",
	"3 * x^2 * y",
	"V1*x + V1*y",
	"6*y^2 + 12*x + 3",
	"3*x*V1^2 + 6*V1*y",
	"4*x^2 - 16",
	"4*x^2 - 16*y^2",
	"x^3 - 27",
	"x^3 + y^3",
	"x^3 + 27*y^3",
	"27*x^3 + y^3",
	"27*x^3 + 8*y^3",
	"x^3 - y^3",
	"x^3 - 27*y^3",
	"27*x^3 - y^3",
	"27*x^3 - 8*y^3",	
	"-x^3 + y^3",
	"-x^3 + 27*y^3",
	"-27*x^3 + y^3",
	"-27*x^3 + 8*y^3",
	"y^2 + 2*y + 1",
    "x^2 + 5*x + 6",
	"x^2 + 6*x + 9",
	"x^3 + 6*x^2 + 12*x + 8",
	"x^4 + 4*x^3 + 6*x^2 + 4*x + 1",
	"x^4 - 4*x^3 + 6*x^2 - 4*x + 1",
	"x^3 - 6*x^2 + 12*x - 8",
    "x^2 + 8*x + 15",
    "6*x^2 + 37*x + 6",
    "x^2 - x - 42",
    "y^2 - 6*y + 8",
    "x^2 - 10*x",
    "3*x^2 + 15*x",
    "-8*x^2 - 12*x",
    "x^2 - 81",
    "7*x^2 - 63",
    "9*x^2 - 25", 
    "x^2 + 11*x + 24",
    "x^2 - 5*x - 36",
    "3*t^2 - 27*t + 60",
    "5*z^2 + 18*z + 9",
    "18*rho^2 - 43*rho - 5",
    "y^4 - 9",
    "4*z^6 - 25",
    "6*x^3 + 8*x^2 - 7*x - 3",     
    "5*x^3 - 11*x^2 + 7*x - 1",
    "3*x^3 + 11*x^2 + 5*x -3",
    "2*x^3 + 9*x^2 - 2*x -33",
    "2*x^3 - 23*x^2 - 16*x - 2",
    "2*x^5 - 4*x^4 - 7*x^3 + 14*x^2 + 6*x - 12",
    "y^4 - 5*y^3 - 5*y^2 + 23*y + 10",
    "-(x^2) + 49",
    "-(x^2) - 11*x + 42",
);

foreach my $test (@factor_tests) {
		
	my $f1 = parse_from_string($test);
    
	my ($rs, $factors) = $f1->to_factored();
	
	my $len1 = length($f1->to_string());
	my $len2 = length($rs->to_string());
	ok( $f1->test_num_equiv($rs), "Equivalent ($len1|$len2) [$f1] vs [$rs]" );

    my $num_factors = @{$factors};
    ok( $num_factors > 1, "Expression has factored ($num_factors)" );
}

