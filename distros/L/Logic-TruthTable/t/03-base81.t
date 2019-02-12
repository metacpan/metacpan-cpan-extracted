#!perl -T
use 5.010001;
use strict;
use warnings;
use Test::More tests => 8;

use Logic::TruthTable::Convert81 qw(:all);

#
# Encode tri-value ((0, 1, 2) == (false, true, don't-care)) contents
# of arrays that are powers of two (because that's how long truth table
# columns are) into base-81 strings.
#
# The length of the resulting string should be 2**(width-2), as we are
# taking four base-3 values at a time and combining them into a single
# base-81 character.
#
my $width = 5;
my(@minterms);
my(@maxterms);
my(@dcterms);
my($b81str, $mintermsref, $maxtermsref, $dcsref);

#
# Test 1 (four parts):
# 'MG0_Blue' translates to '0-1101-10000--11010-1-0--00-1111'
# which breaks down to:
#
@minterms = (2, 3, 5, 7, 14, 15, 17, 20, 28 .. 31);
@maxterms = (0, 4, 8 .. 11, 16, 18, 22, 25, 26);
@dcterms = (1, 6, 12, 13, 19, 21, 23, 24, 27);

$b81str = terms_to_base81($width, 1, \@minterms, \@dcterms);
ok($b81str eq "MG0_Blue", "1a: Base81 string should be 'MG0_Blue', but is '$b81str'");
$b81str = terms_to_base81($width, 0, \@maxterms, \@dcterms);
ok($b81str eq "MG0_Blue", "1b: Base81 string should be 'MG0_Blue', but is '$b81str'");

($mintermsref, $maxtermsref, $dcsref) = terms_from_base81($width, $b81str);

is_deeply($mintermsref, \@minterms,
	"1c: minterms: [" . join(",", @{$mintermsref}) . "]");

is_deeply($dcsref, \@dcterms,
	"1d: don't-cares: [" . join(",", @{$dcsref}) . "]");

#
# Test 2 (four parts):
#
# 'Purdu3!!' translates to '0--1-00-1---1110-00-0010-0---0--'
# which breaks down to:
#
@minterms = (3, 8, 12, 13, 14, 22);
@maxterms = (0, 5, 6, 15, 17, 18, 20, 21, 23, 25, 29);
@dcterms = (1, 2, 4, 7, 9, 10, 11, 16, 19, 24, 26, 27, 28, 30, 31);

$b81str = terms_to_base81($width, 1, \@minterms, \@dcterms);
ok($b81str eq "Purdu3!!", "2a: Base81 string should be 'Purdu3!!', but is '$b81str'");

$b81str = terms_to_base81($width, 0, \@maxterms, \@dcterms);
ok($b81str eq "Purdu3!!", "2b: Base81 string should be 'Purdu3!!', but is '$b81str'");

($mintermsref, $maxtermsref, $dcsref) = terms_from_base81($width, $b81str);
is_deeply($mintermsref, \@minterms,
	"2c: minterms: [" . join(",", @{$mintermsref}) . "]");

is_deeply($dcsref, \@dcterms,
	"2d: don't-cares: [" . join(",", @{$dcsref}) . "]");

