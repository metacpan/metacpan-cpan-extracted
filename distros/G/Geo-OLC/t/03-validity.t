#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Geo::OLC qw(is_valid is_short is_full);

my @tests;
open(IN,'t/validityTests.csv') or die "t/validityTests.csv: $!\n";
while (<IN>) {
	chomp;
	next if /^\s*#/;
	push(@tests,$_);
}
close(IN);

plan tests => @tests * 3;

foreach (@tests) {
	my ($code,$is_valid,$is_short,$is_full) = split(/,/);
	$is_valid = $is_valid eq 'true' ? 1 : 0;
	$is_short = $is_short eq 'true' ? 1 : 0;
	$is_full = $is_full eq 'true' ? 1 : 0;
	ok (is_valid($code) eq $is_valid,
		"is_valid($code): $is_valid == " . is_valid($code));
	ok (is_short($code) eq $is_short,
		"is_short($code): $is_short == " . is_short($code));
	ok (is_full($code) eq $is_full,
		"is_full($code): $is_full == " . is_full($code));
}
