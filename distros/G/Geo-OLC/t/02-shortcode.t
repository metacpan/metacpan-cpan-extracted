#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Geo::OLC qw(shorten recover_nearest);

my @tests;
open(IN,'t/shortCodeTests.csv') or die "t/shortCodeTests.csv: $!\n";
while (<IN>) {
	chomp;
	next if /^\s*#/;
	push(@tests,$_);
}
close(IN);

plan tests => @tests * 2;

foreach (@tests) {
	my ($code,$lat,$lon,$short) = split(/,/);
	my $short2 = shorten($code,$lat,$lon);
	ok ($short eq $short2, "shorten('$code',$lat,$lon): $short == $short2");
	my $code2 = recover_nearest($short,$lat,$lon);
	ok ($code eq $code2,
		"recover_nearest('$code',$lat,$lon): $code == $code2");
}
