#!/usr/bin/perl

use FindBin;

use warnings;
use strict;

use Test::More tests => 520 + 1;
use Test::NoWarnings;

use Math::BigInt try => 'GMP,FastCalc';
use Math::EllipticCurve::Prime;
use Math::EllipticCurve::Prime::Point;

my $test_file = "$FindBin::Bin/data/nisttv";

sub load_tests {
	my %tests;
	my $curve;
	my $collected = {};

	open(my $fh, "<", $test_file);
	while (<$fh>) {
		$curve = $1 if /^\s*Curve:\s*(\S+)/;
		if (/^\s*$/) {
			push @{$tests{$curve}}, $collected
				if defined $curve && scalar keys %$collected;
			$collected = {};
			next;
		}
		$collected->{$1} = $2 if /^([kxy])\s+=\s+([A-Fa-f0-9]+)\s*$/;
	}
	close($fh);

	return \%tests;
}

my $tests = load_tests();

foreach my $curvename (sort keys %$tests) {
	my $curve = Math::EllipticCurve::Prime->new(name => $curvename);
	next unless $curve;

	foreach my $test (@{$tests->{$curvename}}) {
		my $k = Math::BigInt->new($test->{k});
		my $g = $curve->g;
		my $x = Math::BigInt->new("0x$test->{x}");
		my $y = Math::BigInt->new("0x$test->{y}");

		my $point = $g->copy->bmul($k);
		is($point->x->as_hex, $x->as_hex, "curve $curvename k $k x coordinate matches");
		is($point->y->as_hex, $y->as_hex, "curve $curvename k $k y coordinate matches");
	}
}
