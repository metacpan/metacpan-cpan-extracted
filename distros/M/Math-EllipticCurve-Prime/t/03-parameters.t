#!/usr/bin/perl

use warnings;
use strict;

use Test::More;
use Test::NoWarnings;

use Math::BigInt try => 'GMP,FastCalc';
use Math::EllipticCurve::Prime;

# These are the SHA-512 values of "a", "b", and "c" respectively.
my $dhash = Math::BigInt->new("0x1f40fc92da241694750979ee6cf582f2d5d7d28e18335de05abc54d0560e0f5302860c652bf08d560252aa5e74210546f369fbbbce8c12cfc7957b2652fe9a75");
my $dk = Math::BigInt->new("0x5267768822ee624d48fce15ec5ca79cbd602cb7f4c2157a516556991f22ef8c7b5ef7b18d1ff41c59370efb0858651d44a936c11b7b144c48fe04df3c6a3e8da");
my $dprivate = Math::BigInt->new("0xacc28db2beb7b42baa1cb0243d401ccb4e3fce44d7b02879a52799aadff541522d8822598b2fa664f9d5156c00c924805d75c3868bd56c2acb81d37e98e35adc");

plan tests => scalar keys(%Math::EllipticCurve::Prime::predefined) * 3 + 1;

foreach my $name (sort keys %Math::EllipticCurve::Prime::predefined) {
	my $curve = Math::EllipticCurve::Prime->new(name => $name);

	isa_ok($curve, "Math::EllipticCurve::Prime");

	# Test that the base point is on the curve.  This ensures that the values of
	# p, a, b, and g are correct.
	my $g = $curve->g;
	my $x = $g->x;
	my $y = $g->y;
	my $left = $y->copy->bmodpow(2, $curve->p);
	my $right = $x->copy->bmodpow(3, $curve->p);
	$right->badd($x->copy->bmul($curve->a));
	$right->badd($curve->b);
	$right->bmod($curve->p);

	is($left, $right, "base point for $name is on the curve");

	# Test that ECDSA signature verification succeeds.  This validates n.
	my $n = $curve->n;
	my $hash = $dhash->copy->bmod($n);
	my $k = $dk->copy->bmod($n);
	my $private = $dprivate->copy->bmod($n);
	my $public = $curve->g->copy->bmul($private);

	my $kg = $curve->g->copy->bmul($k);
	my $r = $kg->x->copy->bmod($n);
	my $s = $hash->copy->badd($r->copy->bmul($private)->bmod($n));
	$s->bmul($k->copy->bmodinv($n))->bmod($n);

	my $w = $s->copy->bmodinv($n);
	my $u1 = $hash->copy->bmul($w)->bmod($n);
	my $u2 = $r->copy->bmul($w)->bmod($n);
	my $point = $g->copy->bmul($u1);
	$point->badd($public->copy->bmul($u2));

	is($r, $point->x, "value for n for curve $name is correct");
}
