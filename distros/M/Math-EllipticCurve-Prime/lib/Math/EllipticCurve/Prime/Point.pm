use 5.006002;
use strict;
use warnings;

package Math::EllipticCurve::Prime::Point;
{
  $Math::EllipticCurve::Prime::Point::VERSION = '0.003';
}
# ABSTRACT: points for elliptic curve operations over prime fields

use Math::BigInt 1.78 try => 'GMP,FastCalc';
use List::Util;


sub new {
	my ($class, %args) = @_;

	if (!defined $args{x} && !defined $args{y} && !defined $args{infinity}) {
		$args{infinity} = 1;
	}
	$args{infinity} ||= 0;
	delete @args{qw/x y/} if $args{infinity};

	$args{curve} = Math::EllipticCurve::Prime->from_name($args{curve})
		if $args{curve} && !ref $args{curve};

	my $self = \%args;
	$class = ref($class) || $class;
	return bless $self, $class;
}


sub from_hex {
	my ($class, $hex) = @_;

	return $class->new if substr($hex, 0, 2) eq "00";
	return unless substr($hex, 0, 2) eq "04";
	$hex = substr($hex, 2);
	my $len = length $hex;
	return if $len & 4;
	my ($x, $y) = map {
		Math::BigInt->new("0x$_")
	} (substr($hex, 0, $len / 2), substr($hex, $len / 2));
	return $class->new(x => $x, y => $y);
}


sub from_bytes {
	my ($class, $bytes) = @_;
	return $class->from_hex(unpack "H*", $bytes);
}


sub to_hex {
	my $self = shift;

	return "00" if $self->infinity;
	my $x = $self->x->as_hex;
	my $y = $self->y->as_hex;
	$x =~ s/^0x//;
	$y =~ s/^0x//;
	my $length = List::Util::max(length $x, length $y);
	$length++ if $length & 1;

	my $result = "04";
	$result .= ("0" x ($length - length $x)) . $x;
	$result .= ("0" x ($length - length $y)) . $y;

	return $result;
}


sub to_bytes {
	my $self = shift;

	return pack "H*", $self->to_hex;
}


sub copy {
	my $self = shift;
	return $self->new(x => $self->{x}->copy, y => $self->{y}->copy,
		curve => $self->{curve});
}


*clone = \&copy;

sub _set_infinity {
	my $self = shift;

	$self->{infinity} = 1;
	delete @{$self}{qw/x y/};

	return $self;
}


sub bmul {
	my ($self, $k) = @_;

	my $bits = $k->copy->blog(2);
	my $mask = Math::BigInt->bone->blsft($bits);
	my $pt = $self->copy;

	$self->_set_infinity;

	for (reverse 0..$bits) {
		$self->bdbl;
		if ($k->copy->band($mask)) {
			$self->badd($pt);
		}
		$mask->brsft(1);
	}
	return $self;
}

# A helper to do the boring and repetitive parts of point addition.
sub _add_points {
	my ($self, $x1, $x2, $y1, $lambda, $p) = @_;

	my $x = $lambda->copy->bmodpow(2, $p);
	$x->bsub($x1);
	$x->bsub($x2);
	$x->bmod($p);

	my $y = $x1->copy->bsub($x);
	$y->bmul($lambda);
	$y->bsub($y1);
	$y->bmod($p);

	@{$self}{qw/x y/} = ($x, $y);
	return $self;
}


# The algorithm used here is specified in SEC 1, page 7.
sub badd {
	my ($self, $other) = @_;

	die "Can't add a point without a curve" unless $self->curve;

	if ($self->infinity && $other->infinity) {
		return $self;
	}
	elsif ($other->infinity) {
		return $self;
	}
	elsif ($self->infinity) {
		$self->{infinity} = 0;
		@{$self}{qw/x y/} = map { $_->copy } @{$other}{qw/x y/};
		return $self;
	}
	elsif ($self->{x}->bcmp($other->{x})) {
		my $p = $self->curve->p;
		my $lambda = $other->y->copy->bsub($self->y);
		my $bottom = $other->x->copy->bsub($self->x)->bmodinv($p);
		$lambda->bmul($bottom)->bmod($p);

		return $self->_add_points($self->x, $other->x, $self->y, $lambda, $p);
	}
	elsif ($self->{y}->is_zero || $other->{y}->is_zero ||
		$self->{y}->bcmp($other->{y})) {

		return $self->_set_infinity;
	}
	else {
		return $self->bdbl;
	}
}


# The algorithm used here is specified in SEC 1, page 7.
sub bdbl {
	my $self = shift;

	return $self if $self->infinity;

	die "Can't multiply or double a point without a curve"
		unless defined $self->{curve};
	
	my $p = $self->curve->p;
	my $lambda = $self->x->copy->bmodpow(2, $p);
	$lambda->bmul(3);
	$lambda->badd($self->curve->a);
	my $bottom = $self->y->copy->bmul(2)->bmodinv($p);
	$lambda->bmul($bottom)->bmod($p);

	return $self->_add_points($self->x, $self->x, $self->y, $lambda, $p);
}


sub multiply {
	my ($self, $k) = @_;
	return $self->copy->bmul($k);
}


sub add {
	my ($self, $other) = @_;
	return $self->copy->badd($other);
}


sub double {
	my $self = shift;
	return $self->copy->bdbl;
}


sub infinity {
	my $self = shift;
	return $self->{infinity};
}


sub x {
	my $self = shift;
	return $self->{x};
}


sub y {
	my $self = shift;
	return $self->{y};
}


sub curve {
	my ($self, $curve) = @_;

	$self->{curve} = $curve if defined $curve;
	return $self->{curve};
}

1;

__END__
=pod

=head1 NAME

Math::EllipticCurve::Prime::Point - points for elliptic curve operations over prime fields

=head1 VERSION

version 0.003

=head1 SYNOPSIS

	use Math::EllipticCurve::Prime::Point;

	my $p = Math::EllipticCurve::Prime::Point->new(curve => 'secp256r1',
		x => Math::BigInt->new('0x01ff'),
		y => Math::BigInt->new('0x03bc')); # not real points on the curve
	my $p2 = $p->double;
	print "(" . $p2->x . ", " . $p2->y . ")\n";

	# Creates a point at infinity.
	my $p3 = Math::EllipticCurve::Prime::Point->new(curve => 'secp256r1');

	# Creates a point from a hexadecimal SEC representation.
	my $p4 = Math::EllipticCurve::Prime::Point->from_hex("0401ff03bc");
	$p4->curve(Math::EllipticCurve::Prime->new(name => 'secp256r1'));

=head1 DESCRIPTION

This class represents a point on a given elliptic curve.  Using the methods
provided, arithmetic operations can be performed, including point addition and
scalar multiplication.  Currently the operations are limited to these, as these
are the operations most commonly used in cryptography.

=head1 METHODS

=head2 new

Create a new point.  This constructor takes a hash as its sole argument.  If the
arguments x and y are both provided, assumes that these are instances of
Math::BigInt.  If x and y are not both provided, creates a new point at
infinity.

=head2 from_hex

This method takes a hexadecimal-encoded representation of a point in the SEC
format and creates a new Math::EllipticCurve::Prime::Point object.  Currently
this only understands uncompressed points (first byte 0x04) and the point at
infinity.

=head2 from_bytes

This method takes a representation of a point in the SEC format and creates a
new Math::EllipticCurve::Prime::Point object.  Calls from_hex under the
hood.

=head2 to_hex

This method produces a hexadecimal string representing a point in the
uncompressed SEC format.

=head2 to_bytes

This method produces a byte string representing a point in the uncompressed SEC
format.

=head2 copy

Makes a copy of the current point.

=head2 clone

A synonym for copy.

=head2 bmul

Multiplies this point by a scalar.  The scalar should be a Math::BigInt.  Like
Math::BigInt, this modifies the present point.  If you want to preserve this
point, use the copy method to create a clone of the current point.

Requires that a curve has been set.

=head2 badd

Adds this point to another point.  Like Math::BigInt, this modifies the present
point.  If you want to preserve this point, use the copy method to create a
clone of the current point.

Requires that a curve has been set.

=head2 bdbl

Doubles the current point.  Like Math::BigInt, this modifies the present point.
If you want to preserve this point, use the copy method to create a clone of the
current point.

Requires that a curve has been set.

=head2 multiply

Multiplies this point by a scalar.  Returns a new point object.

Requires that a curve has been set.

=head2 add

Adds this point to another point.  Returns a new point object.

Requires that a curve has been set.

=head2 double

Doubles this point.  Returns a new point object.

Requires that a curve has been set.

=head2 infinity

Returns true if this point is the point at infinity, false otherwise.

=head2 x

Returns a Math::BigInt representing the x-coordinate of the point.  Returns
undef if this is the point at infinity.  You should make a copy of the returned
object; otherwise, you will modify the point.

=head2 y

Returns a Math::BigInt representing the y-coordinate of the point.  Returns
undef if this is the point at infinity.  You should make a copy of the returned
object; otherwise, you will modify the point.

=head2 curve

Returns the Math::EllipticCurve::Prime curve associated with this point, if any.
Optionally takes an argument to set the curve.

=head1 AUTHOR

brian m. carlson <sandals@crustytoothpaste.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by brian m. carlson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

