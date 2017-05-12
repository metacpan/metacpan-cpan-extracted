# This is basically Data::Float 0.009 with everything stripped out that is
# not needed.

# From Data::Float 0.009:
# Copyright (C) 2006, 2007, 2008 Andrew Main (Zefram) <zefram  fysh.org>

use warnings;
use strict;

package JE::Object::Number::_maxvalue;

use Carp 'croak';

#
# mult_pow2() multiplies a specified value by a specified power of two.
# This is done using repeated multiplication, and can cope with cases
# where the power of two cannot be directly represented as a floating
# point value.  (E.g., 0x1.b2p-900 can be multiplied by 2^1500 to get
# to 0x1.b2p+600; the input and output values can be represented in
# IEEE double, but 2^1500 cannot.)  Overflow and underflow can occur.
#
# @powtwo is an array such that powtwo[i] = 2^2^i.  Its elements are
# used in the repeated multiplication in mult_pow2.  Similarly,
# @powhalf is such that powhalf[i] = 2^-2^i.  Reading the exponent
# in binary indicates which elements of @powtwo/@powhalf to multiply
# by, except that it may indicate elements that don't exist, either
# because they're not representable or because the arrays haven't
# been filled yet.  mult_pow2() will use the last element of the array
# repeatedly in this case.  Thus array elements after the first are
# only an optimisation, and do not change behaviour.
#

my @powtwo = (2.0);
my @powhalf = (0.5);

sub mult_pow2($$) {
	my($value, $exp) = @_;
	return $_[0] if $value == 0.0;
	my $powa = \@powtwo;
	if($exp < 0) {
		$powa = \@powhalf;
		$exp = -$exp;
	}
	for(my $i = 0; $i != $#$powa && $exp != 0; $i++) {
		$value *= $powa->[$i] if $exp & 1;
		$exp >>= 1;
	}
	$value *= $powa->[-1] while $exp--;
	return $value;
}

#
# Range of finite exponent values.
#

my $min_finite_exp;
my $max_finite_exp;
my $max_finite_pow2;
my $min_finite;

my @directions = (
	{
		expsign => -1,
		powa => \@powhalf,
		xexp => \$min_finite_exp,
		xpower => \$min_finite,
	},
	{
		expsign => +1,
		powa => \@powtwo,
		xexp => \$max_finite_exp,
		xpower => \$max_finite_pow2,
	},
);

while(!$directions[0]->{done} || !$directions[1]->{done}) {
	foreach my $direction (@directions) {
		next if $direction->{done};
		my $lastpow = $direction->{powa}->[-1];
		my $nextpow = $lastpow * $lastpow;
		unless(mult_pow2($nextpow, -$direction->{expsign} *
					  (1 << (@{$direction->{powa}} - 1)))
				== $lastpow) {
			$direction->{done} = 1;
			next;
		}
		push @{$direction->{powa}}, $nextpow;
	}
}

foreach my $direction (@directions) {
	my $expsign = $direction->{expsign};
	my $xexp = 1 << (@{$direction->{powa}} - 1);
	my $extremum = $direction->{powa}->[-1];
	for(my $addexp = $xexp; $addexp >>= 1; ) {
		my $nx = mult_pow2($extremum, $expsign*$addexp);
		if(mult_pow2($nx, -$expsign*$addexp) == $extremum) {
			$xexp += $addexp;
			$extremum = $nx;
		}
	}
	${$direction->{xexp}} = $expsign * $xexp;
	${$direction->{xpower}} = $extremum;
}

#
# pow2() generates a power of two from scratch.  It complains if given
# an exponent that would make an unrepresentable value.
#

sub pow2($) {
	my($exp) = @_;
	croak "exponent $exp out of range [$min_finite_exp, $max_finite_exp]"
		unless $exp >= $min_finite_exp && $exp <= $max_finite_exp;
	return mult_pow2(1.0, $exp);
}

#
# Significand size.
#

my($significand_bits, $significand_step);
{
	my $i;
	for($i = 1; ; $i++) {
		my $tryeps = $powhalf[$i];
		last unless (1.0 + $tryeps) - 1.0 == $tryeps;
	}
	$i--;
	$significand_bits = 1 << $i;
	$significand_step = $powhalf[$i];
	while($i--) {
		my $tryeps = $significand_step * $powhalf[$i];
		if((1.0 + $tryeps) - 1.0 == $tryeps) {
			$significand_bits += 1 << $i;
			$significand_step = $tryeps;
		}
	}
}

my $max_finite = $max_finite_pow2 -
			pow2($max_finite_exp - $significand_bits - 1);
$max_finite += $max_finite;

$JE::Object::Number::max_finite = $max_finite;
$JE::Object::Number::min_finite = $min_finite;

package main; # Is it safe to delete a package from inside it?

require Symbol;
Symbol::delete_package('JE::Object::Number::_maxvalue');
