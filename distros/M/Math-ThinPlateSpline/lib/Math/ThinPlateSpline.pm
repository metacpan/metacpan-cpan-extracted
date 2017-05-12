package Math::ThinPlateSpline;

use 5.008;
use strict;
use warnings;
use Carp 'croak';

our $VERSION = '0.06';

require XSLoader;
XSLoader::load('Math::ThinPlateSpline', $VERSION);


1;
__END__

=head1 NAME

Math::ThinPlateSpline - Calculate and evaluate thin plate splines

=head1 SYNOPSIS

  my @control_points = (
      [$x, $y, $z],
      [$x2, $y2, $z2],
      ...
  );
  my $regularization = 0.; # default, follow control points slavishly
  
  my $tps = Math::ThinPlateSpline->new(
    \@control_points,
    $regularization
  );
  
  my $height = $tps->evaluate($x, $y);
  my $bending_energy = $tps->get_bending_energy();

  my $heights = $tps->evaluate_many([$x1, $x2, $x3...], [$y1, $y2, $y3...]);
  # $heights is now [$z1, $z2, $z3...]

=head1 DESCRIPTION

This is a small Perl/XS module for calculating and evaluating thin plate splines.
If you don't know what thin plate splines are, check out the links in the L</SEE ALSO>
section. In a nutshell, it's ordinary splines generalized to two dimensions.

The module includes a copy of the C<tpsfit> C++ library that was created on the basis
of the C<tpsdemo> program by Jarno Elonen.

=head1 METHODS

=head2 new

(class method)

Creates a new thin plate spline. Takes one mandatory parameter: A reference
to an array of control points (at least three). Each control point has to be
a reference to an array of three numbers (X, Y, Z coordinates). See SYNOPSIS.

The second parameter is optional: A measure for the regularization.
See Jarno Elonen's page for details.

=head2 evaluate

Takes an x and y coordinate as arguments. Returns the z coordinate of the
thin plate spline at the specified point.

=head2 get_bending_energy

Calculates and returns the thin plate spline's bending energy. Again, Jarno Elonen
explains this well on his C<tpsdemo> page.

=head1 DEPENDENCIES

Apart from Perl modules (see F<META.yml> or F<Makefile.PL>), this module needs
the boost:ublas library to build (including headers).

=head1 SEE ALSO

Jarno Elonen's page about thin plate splines: L<http://elonen.iki.fi/code/tpsdemo/>

Wikipedia on thin plate splines: L<http://en.wikipedia.org/wiki/Thin_plate_spline>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

The Math::ThinPlateSpline module is

Copyright (C) 2010, 2011 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

The included tpsfit library is

Copyright (C) 2001-2003,2005 Jarno Elonen

Copyright (C) 2010 by Steffen Mueller

This library is Free Software / Open Source with a very permissive
license:

Permission to use, copy, modify, distribute and sell this software
and its documentation for any purpose is hereby granted without fee,
provided that the above copyright notice appear in all copies and
that both that copyright notice and this permission notice appear
in supporting documentation.  The authors make no representations
about the suitability of this software for any purpose.
It is provided "as is" without express or implied warranty.

=cut
