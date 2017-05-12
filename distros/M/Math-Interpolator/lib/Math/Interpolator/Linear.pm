=head1 NAME

Math::Interpolator::Linear - lazy linear interpolation

=head1 SYNOPSIS

	use Math::Interpolator::Linear;

	$ipl = Math::Interpolator::Linear->new(@points);

	$y = $ipl->y($x);
	$x = $ipl->x($y);

=head1 DESCRIPTION

This is a subclass of the lazy interpolator class C<Math::Interpolator>.
This class implements linear interpolation.  See L<Math::Interpolator>
for the interface.

This code is neutral as to numeric type.  The coordinate values used
in interpolation may be native Perl numbers, C<Math::BigRat> objects,
or possibly other types.  Mixing types within a single interpolation is
not recommended.

=cut

package Math::Interpolator::Linear;

{ use 5.006; }
use warnings;
use strict;

our $VERSION = "0.005";

use parent "Math::Interpolator";

=head1 METHODS

=over

=item $ipl->y(X)

=item $ipl->x(Y)

These methods are part of the standard C<Math::Interpolator> interface.

=cut

sub _conv {
	my($self, $x_method, $y_method, $x) = @_;
	my $nhood_method = "nhood_$x_method";
	my($a, $b) = $self->$nhood_method($x, 1);
	my $xa = $a->$x_method;
	my $xb = $b->$x_method;
	my $ya = $a->$y_method;
	my $yb = $b->$y_method;
	return $ya + ($x - $xa) * (($yb - $ya) / ($xb - $xa));
}

sub y {
	my($self, $x) = @_;
	return $self->_conv("x", "y", $x);
}

sub x {
	my($self, $y) = @_;
	return $self->_conv("y", "x", $y);
}

=back

=head1 SEE ALSO

L<Math::Interpolator>

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
