###############################################################################
# calculate points/stripes in the mandelbrot fractal efficient

package Math::Fractal::Mandelbrot;

use 5.005;
use strict;
# use warnings; # dont use warnings for older Perls

require Exporter;
require DynaLoader;

use vars qw/@ISA $VERSION @EXPORT_OK/;
@ISA = qw(Exporter DynaLoader);

@EXPORT_OK = qw/
   point hor_line ver_line
   set_bounds set_limit set_max_iter set_epsilon
   /;

$VERSION = '0.04';

bootstrap Math::Fractal::Mandelbrot $VERSION;

# no Perl code, it's all in the XS code

1;
__END__

=pod

=head1 NAME

Math::Fractal::Mandelbrot - Calculate points in the mandelbrot fractal

=head1 SYNOPSIS

=head1 DESCRIPTION

Calculates points, horizontal/vertical stripes or rectangular areas of the
famous Mandelbrot fractal.

X<fractal>
X<mandelbrot>
X<recursive>

=head1 LICENSE
 
This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself. 

X<license>
X<perl>

=head1 METHODS

=head2 set_max_iter()
	
	Math::Fractal::Mandelbrot->set_max_iter($max_iter);

Set the maximum number of iterations. 600 is the default and quite suitable
for the start image. When zooming in, this value should be increased to
not loose details.

=head2 set_limit()

	Math::Fractal::Mandelbrot->set_limit($limit);

The default value is 5 and should only be changed if you know why.

=head2 set_epsilon()

	Math::Fractal::Mandelbrot->set_epsilon($e);

The default value is 0.001. When the change between two iterations is less
than this number, the point is considered to be on the inside.

=head2 set_bounds()

	Math::Fractal::Mandelbrot->set_bounds($x1,$y1,$x2,$y2,$w,$h);

Set the coordinates from x1, y1 to x2, y2 and the width of the computed image
to w and h. 

The default values are:

	Math::Fractal::Mandelbrot->set_bounds(-2,-1.1, 1,1.1, 640,480);

=head2 point()

	my $iter = Math::Fractal::Mandelbrot->point($x,$y);

Calculates the value at the point C<$x> and C<$y>. The return value 0 means
the point is inside the fractal (typical the black area), any value >0 means
the number of iterations it took to find out that the point is on the outside.

$x and $y should be between 0 and C<w> and 0 and C<h>, respectively (see
L<set_bounds()>).

=head2 hor_line($x1,$y1,$l)

	my $points = Math::Fractal::Mandelbrot->hor_line($x1,$y1,$l);

Calculates the values at a horizontal line and returns them all as a ref to
am array.

The array will contain one extra value, which is the count of values
in the array beeing equal to the first value. Example:


	values		count	explanation
	==============================================================
	1,1,1,1,3,	4 	# 4 are equal
	1,1,3,1,3,	2	# only 2, not 3 since it stops after 2

See L<point()> for details.

=head2 ver_line($x1,$y1,$l)

	my @points = Math::Fractal::Mandelbrot->ver_line($x1,$y1,$l);

Calculates the values at a vertical line and returns them all as array.
The array will contain one extra value, which is the count of values
in the array beeing equal to the first value. See  L<hor_line> for
an explanation of this last value.

See L<point()> for further details.

=head1 AUTHOR

Tels <http://bloodgate.com/> in 2003, 2005, 2006.

X<tels>

=head1 SEE ALSO

L<Math::Fractal::DLA> by Wolfgang Gruber.

=cut
