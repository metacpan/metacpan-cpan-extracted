=head1 NAME

Math::Interpolator::Robust - lazy robust interpolation

=head1 SYNOPSIS

	use Math::Interpolator::Robust;

	$ipl = Math::Interpolator::Robust->new(@points);

	$y = $ipl->y($x);
	$x = $ipl->x($y);

=head1 DESCRIPTION

This is a subclass of the lazy interpolator class C<Math::Interpolator>.
This class implements a robust smooth interpolation.  See
L<Math::Interpolator> for the interface.  The algorithm is the same one
implemented by C<robust_interpolate> in the eager interpolator module
C<Math::Interpolate>.

This code is neutral as to numeric type.  The coordinate values used
in interpolation may be native Perl numbers, C<Math::BigRat> objects,
or possibly other types.  Mixing types within a single interpolation is
not recommended.

Only interior points are handled.  Interpolation will be refused at the
edges of the curve.

=cut

package Math::Interpolator::Robust;

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
	my @points = $self->$nhood_method($x, 2);
	my($xa, $xb, $xc, $xd) = map { $_->$x_method } @points;
	my($ya, $yb, $yc, $yd) = map { $_->$y_method } @points;
	my $hxab = $xb - $xa;
	my $hxbc = $xc - $xb;
	my $hxcd = $xd - $xc;
	my $hyab = $yb - $ya;
	my $hybc = $yc - $yb;
	my $hycd = $yd - $yc;
	my $hab = $hxab*$hxab + $hyab*$hyab;
	my $hbc = $hxbc*$hxbc + $hybc*$hybc;
	my $hcd = $hxcd*$hxcd + $hycd*$hycd;
	my $sb = ($hyab*$hbc + $hybc*$hab) / ($hxab*$hbc + $hxbc*$hab);
	my $sc = ($hybc*$hcd + $hycd*$hbc) / ($hxbc*$hcd + $hxcd*$hbc);
	my $y0 = $yb + ($x - $xb) * ($hybc / $hxbc);
	my $dyb = $yb + $sb * ($x - $xb) - $y0;
	my $dyc = $yc + $sc * ($x - $xc) - $y0;
	my $pdy = $dyb * $dyc;
	if($pdy == 0) {
		return $y0;
	} elsif($pdy > 0) {
		return $y0 + $pdy/($dyb + $dyc);
	} else {
		return $y0 + $pdy * (($x - $xb) + ($x - $xc)) /
				(($dyb - $dyc) * $hxbc);
	}
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

L<Math::Interpolate>,
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
