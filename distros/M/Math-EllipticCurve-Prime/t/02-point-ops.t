#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 11 + 1;
use Test::NoWarnings;

use Math::BigInt try => 'GMP,FastCalc';
use Math::EllipticCurve::Prime;
use Math::EllipticCurve::Prime::Point;

{
	my $point = Math::EllipticCurve::Prime::Point->new;

	isa_ok($point, "Math::EllipticCurve::Prime::Point");
	ok($point->infinity, "point without coordinates is point at infinity");
	ok(!defined $point->x, "point at infinity has no x coordinate");
	ok(!defined $point->y, "point at infinity has no y coordinate");

	$point->bdbl;
	ok($point->infinity, "doubled point at infinity is point at infinity");
	ok(!defined $point->x, "doubled point at infinity has no x coordinate");
	ok(!defined $point->y, "doubled point at infinity has no y coordinate");
}

{
	my $curve = Math::EllipticCurve::Prime->new(name => "secp256r1");
	die unless $curve;
	
	my $g = $curve->g->copy;
	is($g->x->as_hex,
		"0x6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296",
		"initial point x coordinate matches");
	is($g->y->as_hex,
		"0x4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5",
		"initial point y coordinate matches");

	$g->bdbl;
	is($g->x->as_hex,
		"0x7cf27b188d034f7e8a52380304b51ac3c08969e277f21b35a60b48fc47669978",
		"doubled point x coordinate matches");
	is($g->y->as_hex,
		"0x7775510db8ed040293d9ac69f7430dbba7dade63ce982299e04b79d227873d1",
		"doubled point y coordinate matches");
}
