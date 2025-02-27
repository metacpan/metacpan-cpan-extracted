#!/usr/bin/perl

use strict;
use warnings;
use Math::Symbolic qw/:all/;
use Math::Symbolic::Custom::Factor;

use Test::Simple 'no_plan';

my %factor_tests = (
	"Test 001"	=>	{ 'expr' => '3*x + 12*y', 'factors' => 2 },
	"Test 002"	=>	{ 'expr' => '3 * x^2 * y', 'factors' => 3 },
	"Test 003"	=>	{ 'expr' => 'V1*x + V1*y', 'factors' => 2 },
	"Test 004"	=>	{ 'expr' => '6*y^2 + 12*x + 3', 'factors' => 2 },
	"Test 005"	=>	{ 'expr' => '3*x*V1^2 + 6*V1*y', 'factors' => 3 },
	"Test 006"	=>	{ 'expr' => '4*x^2 - 16', 'factors' => 3 },
	"Test 007"	=>	{ 'expr' => '4*x^2 - 16*y^2', 'factors' => 3 },
	"Test 008"	=>	{ 'expr' => 'x^3 - 27', 'factors' => 2 },
	"Test 009"	=>	{ 'expr' => 'x^3 + y^3', 'factors' => 2 },
	"Test 010"	=>	{ 'expr' => 'x^3 + 27*y^3', 'factors' => 2 },
	"Test 011"	=>	{ 'expr' => '27*x^3 + y^3', 'factors' => 2 },
	"Test 012"	=>	{ 'expr' => '27*x^3 + 8*y^3', 'factors' => 2 },
	"Test 013"	=>	{ 'expr' => 'x^3 - y^3', 'factors' => 2 },
	"Test 014"	=>	{ 'expr' => 'x^3 - 27*y^3', 'factors' => 2 },
	"Test 015"	=>	{ 'expr' => '27*x^3 - y^3', 'factors' => 2 },
	"Test 016"	=>	{ 'expr' => '27*x^3 - 8*y^3', 'factors' => 2 },
	"Test 017"	=>	{ 'expr' => '-x^3 + y^3', 'factors' => 2 },
	"Test 018"	=>	{ 'expr' => '-x^3 + 27*y^3', 'factors' => 2 },
	"Test 019"	=>	{ 'expr' => '-27*x^3 + y^3', 'factors' => 2 },
	"Test 020"	=>	{ 'expr' => '-27*x^3 + 8*y^3', 'factors' => 2 },
	"Test 021"	=>	{ 'expr' => 'y^2 + 2*y + 1', 'factors' => 2 },
	"Test 022"	=>	{ 'expr' => 'x^2 + 5*x + 6', 'factors' => 2 },
	"Test 023"	=>	{ 'expr' => 'x^2 + 6*x + 9', 'factors' => 2 },
	"Test 024"	=>	{ 'expr' => 'x^3 + 6*x^2 + 12*x + 8', 'factors' => 3 },
	"Test 025"	=>	{ 'expr' => 'x^4 + 4*x^3 + 6*x^2 + 4*x + 1', 'factors' => 4 },
	"Test 026"	=>	{ 'expr' => 'x^4 - 4*x^3 + 6*x^2 - 4*x + 1', 'factors' => 4 },
	"Test 027"	=>	{ 'expr' => 'x^3 - 6*x^2 + 12*x - 8', 'factors' => 3 },
	"Test 028"	=>	{ 'expr' => 'x^2 + 8*x + 15', 'factors' => 2 },
	"Test 029"	=>	{ 'expr' => '6*x^2 + 37*x + 6', 'factors' => 2 },
	"Test 030"	=>	{ 'expr' => 'x^2 - x - 42', 'factors' => 2 },
	"Test 031"	=>	{ 'expr' => 'y^2 - 6*y + 8', 'factors' => 2 },
	"Test 032"	=>	{ 'expr' => 'x^2 - 10*x', 'factors' => 2 },
	"Test 033"	=>	{ 'expr' => '3*x^2 + 15*x', 'factors' => 3 },
	"Test 034"	=>	{ 'expr' => '-8*x^2 - 12*x', 'factors' => 3 },
	"Test 035"	=>	{ 'expr' => 'x^2 - 81', 'factors' => 2 },
	"Test 036"	=>	{ 'expr' => '7*x^2 - 63', 'factors' => 3 },
	"Test 037"	=>	{ 'expr' => '9*x^2 - 25', 'factors' => 2 },
	"Test 038"	=>	{ 'expr' => 'x^2 + 11*x + 24', 'factors' => 2 },
	"Test 039"	=>	{ 'expr' => 'x^2 - 5*x - 36', 'factors' => 2 },
	"Test 040"	=>	{ 'expr' => '3*t^2 - 27*t + 60', 'factors' => 3 },
	"Test 041"	=>	{ 'expr' => '5*z^2 + 18*z + 9', 'factors' => 2 },
	"Test 042"	=>	{ 'expr' => '18*rho^2 - 43*rho - 5', 'factors' => 2 },
	"Test 043"	=>	{ 'expr' => 'y^4 - 9', 'factors' => 2 },
	"Test 044"	=>	{ 'expr' => '4*z^6 - 25', 'factors' => 2 },
	"Test 045"	=>	{ 'expr' => '6*x^3 + 8*x^2 - 7*x - 3', 'factors' => 2 },
	"Test 046"	=>	{ 'expr' => '5*x^3 - 11*x^2 + 7*x - 1', 'factors' => 3 },
	"Test 047"	=>	{ 'expr' => '3*x^3 + 11*x^2 + 5*x -3', 'factors' => 3 },
	"Test 048"	=>	{ 'expr' => '2*x^3 + 9*x^2 - 2*x -33', 'factors' => 2 },
	"Test 049"	=>	{ 'expr' => '2*x^3 - 23*x^2 - 16*x - 2', 'factors' => 2 },
	"Test 050"	=>	{ 'expr' => '2*x^5 - 4*x^4 - 7*x^3 + 14*x^2 + 6*x - 12', 'factors' => 2 },
	"Test 051"	=>	{ 'expr' => 'y^4 - 5*y^3 - 5*y^2 + 23*y + 10', 'factors' => 3 },
	"Test 052"	=>	{ 'expr' => '-(x^2) + 49', 'factors' => 2 },
	"Test 053"	=>	{ 'expr' => '-(x^2) - 11*x + 42', 'factors' => 2 },
    "Test 054"  =>  { 'expr' => 'y - 4', 'factors' => 1 },
    "Test 055"  =>  { 'expr' => 'y^2 - 4', 'factors' => 2 },
    "Test 056"  =>  { 'expr' => 'y^3 - 4', 'factors' => 1 },
    "Test 057"  =>  { 'expr' => 'y^4 - 4', 'factors' => 2 },
    "Test 058"  =>  { 'expr' => '2*y - 4', 'factors' => 2 },
    "Test 059"  =>  { 'expr' => '2*y^2 - 4', 'factors' => 2 },
    "Test 060"  =>  { 'expr' => '2*y^3 - 4', 'factors' => 2 },
    "Test 061"  =>  { 'expr' => '2*y^4 - 4', 'factors' => 2 },
    "Test 062"  =>  { 'expr' => '3*y - 4', 'factors' => 1 },
    "Test 063"  =>  { 'expr' => '3*y^2 - 4', 'factors' => 1 },
    "Test 064"  =>  { 'expr' => '3*y^3 - 4', 'factors' => 1 },
    "Test 065"  =>  { 'expr' => '3*y^4 - 4', 'factors' => 1 },
    "Test 066"  =>  { 'expr' => 'm*y - 4', 'factors' => 1 },
);

while ( my ($test_num, $test) = each %factor_tests ) {
		
	my $f1 = parse_from_string($test->{expr});
    
	my ($rs, $factors) = $f1->to_factored();
	
	my $len1 = length($f1->to_string());
	my $len2 = length($rs->to_string());
	ok( $f1->test_num_equiv($rs), "$test_num: Equivalent ($len1|$len2) [$f1] vs [$rs]" );

    my $num_factors = @{$factors};
    ok( $num_factors == $test->{factors}, "$test_num: Expression has factored ($num_factors)" );
}

