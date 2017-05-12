#!/usr/bin/perl

use warnings;
use strict;

use Test::More;
use Test::NoWarnings;

use Math::BigInt try => 'GMP,FastCalc';
use Math::EllipticCurve::Prime;
use Math::EllipticCurve::Prime::Point;

plan tests => scalar keys(%Math::EllipticCurve::Prime::predefined) * 5 + 4 + 1;

{
	my $point = Math::EllipticCurve::Prime::Point->new;
	is($point->to_hex, "00", "hex repr of point at infinity is correct");
	is($point->to_bytes, "\x00", "byte repr of point at infinity is correct");
}

{
	my $point = Math::EllipticCurve::Prime::Point->from_hex("00");
	ok($point->infinity, "hex loading of point at infinity is correct");
	$point = Math::EllipticCurve::Prime::Point->from_bytes("\x00");
	ok($point->infinity, "byte loading of point at infinity is correct");
}

foreach my $curve (sort keys %Math::EllipticCurve::Prime::predefined) {
	my $hex = $Math::EllipticCurve::Prime::predefined{$curve}{g};
	my $point = Math::EllipticCurve::Prime::Point->from_hex($hex);
	ok(!$point->infinity, "base point for $curve is not point at infinity");
	is($hex, $point->to_hex, "base point for $curve round trips in hex");

	my $bytes = $point->to_bytes;
	my $point2 = Math::EllipticCurve::Prime::Point->from_bytes($bytes);
	ok(!$point->infinity, "base point for $curve is not point at infinity");
	is($bytes, $point2->to_bytes, "base point for $curve round trips in bytes");
	cmp_ok(2 * length $bytes, '==', length $hex,
		"byte string for $curve has the right length");
}
