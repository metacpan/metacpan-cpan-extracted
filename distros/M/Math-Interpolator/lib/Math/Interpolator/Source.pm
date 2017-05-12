=head1 NAME

Math::Interpolator::Source - source of points for use in interpolation

=head1 SYNOPSIS

	use Math::Interpolator::Source;

	$pt = Math::Interpolator::Source->new(sub { ... }, $x);
	$pt = Math::Interpolator::Source->new(sub { ... }, $x, $y);

	$x = $pt->x;
	$y = $pt->y;

	$role = $pt->role;

	$points = $pt->expand;

=head1 DESCRIPTION

An object of this type represents a potential to generate some number of
adjacent knots on a one-dimensional curve.  It is intended for use with
C<Math::Interpolator>, which will interpolate a curve between knots.
A source is expanded into knots only if required for an attempted
interpolation.

For interpolation in a particular part of a curve, a number of known knots
are required, each one consisting of an x/y coordinate pair.  It is not
necessary to know all knot coordinates, or even the number of knots,
elsewhere on the curve.  A source stands in for a group of knots that
has not yet been examined in detail.

A source covers a contiguous range of x coordinates.  It is not necessary
to know precisely what that range is; the whole range is represented
by a single x coordinate that lies within it.  When that range of x
coordinates needs to be examined, the source is expanded, replacing it
with the entire group of knots that lies within the range.  If reverse
interpolation is to be performed then the same goes for y coordinates too.

The expansion of a source may include more sources for subranges.

=cut

package Math::Interpolator::Source;

{ use 5.006; }
use warnings;
use strict;

use Carp qw(croak);

our $VERSION = "0.005";

=head1 CONSTRUCTOR

=over

=item Math::Interpolator::Source->new(EXPANDER, X[, Y])

Creates and returns a new source object.  EXPANDER must be a reference
to a function, which will be called to implement the C<expand> method.

A representative x coordinate must be supplied which is within the range
of x coordinates that is covered by the source.  It is not required
for the x coordinate to match any of the knots that will be generated,
nor even for it to be between generated knots.

If x values are to be interpolated as well as y values, then a
representative y coordinate must also be supplied.  This works in exactly
the same way as the representative x coordinate.  If interpolation is
only to be performed in one direction then a y coordinate is not required.

=cut

sub new {
	my($class, $expander, $x, $y) = @_;
	return bless({
		expander => $expander,
		x => $x,
		y => $y,
	}, $class);
}

=back

=head1 METHODS

=over

=item $pt->x

Returns the representative x coordinate of the source.

=cut

sub x { $_[0]->{x} }

=item $pt->y

Returns the representative y coordinate of the source, if there is one.
C<die>s if not.

=cut

sub y {
	my($self) = @_;
	my $y = $self->{y};
	croak "no y coordinate for this source" unless defined $y;
	return $y;
}

=item $pt->role

Returns the string "SOURCE".  This is used to distinguish sources from
other types of entity that could appear in an interpolator's point list.

=cut

sub role { "SOURCE" }

=item $pt->expand

Returns a reference to an array of point objects represented by this
source.  The types of objects permitted to be returned are the same
as permitted when constructing an interpolator: knots and sources.
The array may be empty.  If non-empty, the resulting points are sorted
in monotonically non-decreasing order of x coordinates.

C<die>s if expansion is presently impossible.

=cut

sub expand { $_[0]->{expander}->() }

=back

=head1 SUBCLASSING

The interpolator uses only this public interface, so it is acceptable
to substitute any other class that implements this interface.  This may
be done by subclassing this class, or by reimplementing all four methods
independently.  This is useful, for example, to avoid having to package
all the data necessary for expansion into a closure.

=head1 SEE ALSO

L<Math::Interpolator>,
L<Math::Interpolator::Knot>

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
