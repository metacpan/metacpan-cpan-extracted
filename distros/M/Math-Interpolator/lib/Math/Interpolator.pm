=head1 NAME

Math::Interpolator - interpolate between lazily-evaluated points

=head1 SYNOPSIS

	use Math::Interpolator;

	$ipl = Math::Interpolator->new(@points);

	@points = $ipl->nhood_x($x, 1);
	@points = $ipl->nhood_y($y, 1);

=head1 DESCRIPTION

This class supports interpolation of a curve between known points,
known as "knots", with the knots being lazily evaluated.  An object of
this type represents a set of knots on a one-dimensional curve, the knots
possibly not being predetermined.  The methods implemented in this class
extract knots, forcing evaluation as required.  Subclasses implement
interpolation by various algorithms.

This code is neutral as to numeric type.  The coordinate values used
in interpolation may be native Perl numbers, C<Math::BigRat> objects,
or possibly other types.  Mixing types within a single interpolation is
not recommended.

=cut

package Math::Interpolator;

{ use 5.006; }
use warnings;
use strict;

use Carp qw(croak);

our $VERSION = "0.005";

=head1 CONSTRUCTOR

=over

=item Math::Interpolator->new(POINT ...)

A list of zero or more point objects must be supplied.  They are wrapped
up as an interpolator object, which is returned.

The objects in the list must each implement the interface of either
C<Math::Interpolator::Knot> or C<Math::Interpolator::Source>.  It is
not necessary for them to actually be of those classes; reimplementing
the same interfaces is acceptable.  They do not need to all be of the
same class.  A knot-interface object represents a single point on the
curve, whereas a source-interface object represents an undetermined set
of knots within a particular range of x coordinates.

The point objects must be sorted such that their x coordinates are
monotonically non-decreasing.  The range of x coordinates covered by
each source must not include any individual knot nor overlap the range
of any other source.

If reverse interpolation (determining an x coordinate given a y
coordinate) is to be performed, then the y coordinates must be similarly
sorted.

Normally it would not be desired to instantiate this class directly,
because it contains no interpolation methods.  A subclass such as
C<Math::Interpolator::Linear> or C<Math::Interpolator::Robust> should
be instantiated instead.

=cut

sub new {
	my $class = shift;
	return bless(\@_, $class);
}

=back

=head1 METHODS

=over

=item $ipl->nhood_x(X, N)

Returns a list of 2*N consecutive knots (with the
C<Math::Interpolator::Knot> interface) defining the curve in the
neighbourhood of x=X.  There will be N knots on either side of x=X.
If one of the knots has x=X exactly then that knot will be treated as
if it had x<X.  N must be a positive integer.

=item $ipl->nhood_y(Y, N)

Does the same thing as C<nhood_x>, but for y coordinates.  This is
only possible if the y coordinates are monotonically non-decreasing for
increasing x.

=back

=cut

sub _expand {
	my($self, $n) = @_;
	my $exp = $self->[$n]->expand;
	splice @$self, $n, 1, @$exp;
	return @$exp - 1;
}

sub _nhood {
	my($self, $x_method, $x, $n) = @_;
	START:
	if(@$self < 2) {
		while(@$self == 1 && $self->[0]->role eq "SOURCE") {
			$self->_expand(0);
		}
		croak "no useful data" if @$self < 2;
	}
	my $min = 0;
	my $max = @$self - 1;
	BINSEARCH:
	while($max != $min + 1) {
		my $try = do { use integer; ($min + $max) / 2 };
		if($x >= $self->[$try]->$x_method) {
			$min = $try;
		} else {
			$max = $try;
		}
	}
	if($min == 0 && $x < $self->[$min]->$x_method) {
		croak "data does not extend to $x_method=$x"
			unless $self->[0]->role eq "SOURCE";
		$max += $self->_expand(0);
		goto START if $min == $max;
		goto BINSEARCH;
	} elsif($max == @$self-1 && $x > $self->[$max]->$x_method) {
		croak "data does not extend to $x_method=$x"
			unless $self->[$max]->role eq "SOURCE";
		$max += $self->_expand($max);
		goto START if $min == $max;
		goto BINSEARCH;
	}
	if($self->[$min]->role eq "SOURCE") {
		$max += $self->_expand($min);
		goto START if $min == $max;
		$min-- unless $min == 0;
		goto BINSEARCH;
	} elsif($self->[$max]->role eq "SOURCE") {
		$max += $self->_expand($max);
		goto START if $min == $max;
		$max++ unless $max == @$self - 1;
		goto BINSEARCH;
	}
	while(1) {
		croak "non-knot in region"
			unless $self->[$min]->role eq "KNOT" &&
				$self->[$max]->role eq "KNOT";
		last unless --$n;
		while(1) {
			croak "data does not extend to $x_method=$x"
				if $min == 0 || $max == @$self - 1;
			my $expanded;
			if($self->[$min-1]->role eq "SOURCE") {
				my $diff = $self->_expand($min-1);
				$min += $diff;
				$max += $diff;
				$expanded = 1;
			}
			if($self->[$max+1]->role eq "SOURCE") {
				$self->_expand($max+1);
				$expanded = 1;
			}
			last unless $expanded;
		}
		$min--;
		$max++;
	}
	return @{$self}[$min..$max];
}

sub nhood_x {
	my($self, $x, $n) = @_;
	return $self->_nhood("x", $x, $n);
}

sub nhood_y {
	my($self, $y, $n) = @_;
	return $self->_nhood("y", $y, $n);
}

=pod

The following two methods are not implemented in this class, but are
the standard interpolation interface to be implemented by subclasses.

=over

=item $ipl->y(X)

Interpolates a y value for the given x coordinate, and returns it.

=item $ipl->x(Y)

Interpolates an x value for the given y coordinate, and returns it.  This
is only possible if the y coordinates are monotonically non-decreasing
for increasing x.

=back

=head1 SEE ALSO

L<Math::Interpolator::Knot>,
L<Math::Interpolator::Linear>,
L<Math::Interpolator::Robust>,
L<Math::Interpolator::Source>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2006, 2007, 2009, 2010, 2012
Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
