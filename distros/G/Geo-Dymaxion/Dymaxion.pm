package Geo::Dymaxion;

=head1 NAME

Geo::Dymaxion - Plot latitude/longitude on a Fuller Dymaxion(tm) map

=head1 SYNOPSIS

  use Geo::Dymaxion;
  
  # Suppose we have a Fuller projection of the Earth's surface that's
  # 800 pixels wide and 600 pixels high.

  my $map = Geo::Dymaxion->new( 800, 600 );

  # Find the x and y coordinates in pixels of Philadelphia, PA, USA.

  my ($x, $y) = $map->plot( 40, -75 );

  # Do the same for Sebastopol, CA, USA.

  ($x, $y) = $map->plot( 38.3993, -122.8259 );

=head1 DESCRIPTION

C<Geo::Dymaxion> allows you to draw points on Dymaxion(tm) maps using
latitude and longitude data, which turns out to be quite difficult and
requires some tricky trigonometry.  This module strives to hide away
all the ugly math and allow you to concentrate on drawing your map.

The Dymaxion(tm), or Fuller, projection was invented by R. Buckminster
Fuller in 1954, and is "the only flat map of the entire surface
of the Earth which reveals our planet as one island in one ocean,
without any visually obvious distortion of the relative shapes and
sizes of the land areas, and without splitting any continents." See
http://www.bfi.org/map.htm for more details.

=head1 METHODS

=over 4

=item new( [WIDTH [, HEIGHT]] )

C<new> takes two arguments: the length and width of your Dymaxion map
in pixels. Be sure when supplying this measure that you have excluded
any margins that may exist around the edges of your map image. If no
arguments are provided, operations with C<Geo::Dymaxion> will return
values expressed in fractions of a unit-sized map.

=item plot( LATITUDE, LONGITUDE )

C<plot> takes a floating-point (lat, long) pair, and returns a list
consisting of floating-point (x, y) coordinates, scaled to the width and
height provided to C<new()>. Latitudes south of the equator and longitudes
west of the prime meridian should be expressed as negative values. These
X and Y values can then be plugged into C<Imager-E<gt>setpixel()> or any
other drawing module you'd care to use.

=back

=head1 FUNCTIONS

=over 4

=item Geo::Dymaxion::dymax( LATITUDE, LONGITUDE )

C<dymax()> provides access to the internal routines used by
C<Geo::Dymaxion>. Takes a (lat, long) pair, returns an (x, y) pair,
scaled in unit triangle edges, with (0, 0) at the I<lower left> corner
of the map. For reference, a Fuller projection of the Earth's surface
is 5.5 by sqrt(7.75) unit triangle edges in size.

=back 

=head1 EXAMPLE

  # This script takes a Dymaxion map and (lat, long) point and
  # outputs a JPEG of the map with a large red dot over that point.
  #
  # For a more elaborate example of the same, see:
  #    http://iconocla.st/hacks/dymax/
  
  use Imager;
  use Imager::Fill;
  use Geo::Dymaxion;
  use strict;
  
  my ($lat, $long) = @ARGV;
  my $map_file = "dymaxion.gif"; # make sure the margins are trimmed!

  my $map = Imager->new;
  $map->open( file => $map_file );
  
  my $dymax = Geo::Dymaxion->new( $map->getwidth, $map->getheight );
  my ($x, $y) = $dymax->plot( $lat, $long );
  
  my $dot  = Imager::Color->new( 255, 0, 0 );
  my $fill = Imager::Fill->new( solid => $dot );
  $map->circle( fill => $fill, r => 5, x => $x, y => $y );
  
  $map->write( type => "jpeg", fd => fileno(STDOUT) )
      or die $map->errstr;
  
=head1 BUGS

It would be really cool if this module could convert (x, y) points on
a Fuller projection back into (lat, long).

=head1 DESIDERATA

"Think of it. We are blessed with technology that would be indescribable
to our forefathers. We have the wherewithal, the know-it-all to feed
everybody, clothe everybody, and give every human on Earth a chance. We
know now what we could never have known before-that we now have the
option for all humanity to "make it" successfully on this planet in this
lifetime. Whether it is to be Utopia or Oblivion will b a touch-and-go
relay race right up to the final moment."
    - R. Buckminster Fuller

"When I am working on a problem,
I never think about beauty.
I only think about how to solve the problem.
But when I have finished,
if the solution is not beautiful,
I know it is wrong."
    - R. Buckminster Fuller

=head1 SEE ALSO

The word "Dymaxion" and the Fuller projection design are trademarks of
the Buckminster Fuller Institute (L<http://www.bfi.org>). The BFI can
be reached at E<lt>info@bfi.orgE<gt>.

This module would not exist without the prior work of Robert W. Gray in
determining the calculations necessary to plot latitude and longitude
on a Fuller map. Gray's notes and original code are available at
L<http://www.rwgrayprojects.com/rbfnotes/maps/graymap1.html>, which is
well worth the read if you're into such things.

Also, see also L<Imager>, L<Inline>.

=head1 AUTHOR

Robert W. Gray E<lt>rwgray@rwgrayprojects.comE<gt> wrote the C code on
which this module is based. 

Schuyler D. Erle E<lt>schuyler@nocat.netE<gt> wrote the Perl API, with
a little help from Inline.pm.

=head1 COPYRIGHT AND LICENSE

The C code that performs the actual conversions is copyright
Robert W. Gray E<lt>rwgray@rwgrayprojects.comE<gt>. His
code is distributed under the following terms taken from
L<http://www.rwgrayprojects.com/rbfnotes/maps/graymap6.html>:

"Usage Note: My work is copyrighted. You may use my work but you may
not include my work, or parts of it, in any for-profit project without
my consent."

This bears reiteration, in case it wasn't clear the first time: According
to Gray's license, B<you must obtain his consent prior to using his
code for commercial or for-profit purposes>. Please contact him, not
me. (But please contact me if you use this module anyway, I'm curious
to know what people might want it for.)

The rest of the module is copyright 2003 by Schuyler D. Erle, and is
free software, distributed under the same terms as Perl itself.

=cut

use 5.006;
use strict;
use warnings;

use Exporter;
use vars qw($VERSION @ISA @EXPORT_OK);

@ISA	   = qw( Exporter );
@EXPORT_OK = qw( &dymax );
$VERSION   = "0.12";

# C code below mostly borrowed from
#	http://www.rwgrayprojects.com/rbfnotes/maps/graymap6.html
# Go there to get an inkling of what this does.

use Inline C => Config => LIBS => "-lm";
use Inline C => "DATA",
    NAME    => "Geo::Dymaxion",
    VERSION => "0.12";
use Exporter;

# Size of Fuller Earth map in unit triangle edges.
#
use constant X_SCALE => 5.5;
use constant Y_SCALE => sqrt(3 ** 2 - 1.5 ** 2);

sub test {
    print join(" ", __PACKAGE__->new->plot(@_)), "\n";
}

# new() takes two arguments, a width and height in pixels
# of the Fuller map on to which lat/long points are to be plotted.
# if no arguments are provided, values are plotted in fractional
# sizes of a unit-sized map.

sub new {
    my ($class, $width, $height) = @_;
    return bless( [$width || 1, $height || 1], ref($class) || $class );
}

sub plot {
    my ($self, $lat, $long) = @_;
    my ($x, $y) = dymax($lat, $long);

    # dymax() returns (x, y) in unit triangle sides
    # with (0,0) at lower left. We want values scaled
    # to an image size with (0,0) at upper left, suitable
    # for plotting onto a raster of a Fuller map.

    return (
	$x / X_SCALE * $self->[0],
	(Y_SCALE - $y) / Y_SCALE * $self->[1]
    );
}

1;

__DATA__
__C__

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

/**************************************************************/
/*                                                            */
/* This C program is copyrighted by  Robert W. Gray and may   */
/* not be used in ANY for-profit project without written      */
/* permission.                                                */
/*                                                            */
/**************************************************************/


/**************************************************************/
/*                                                            */
/* This C program contains the Dymaxion map coordinate        */
/* transformation routines for converting longitude/latitude  */
/* points to (X, Y) points on the Dymaxion map.               */
/*                                                            */
/* This version uses the exact transformation equations.      */
/**************************************************************/

/************************************************************************/
/* NOTE: in C, array indexing starts with element zero (0).  I choose   */
/*       to start my array indexing with elemennt one (1) so all arrays */
/*       are defined one element longer than they need to be.           */
/************************************************************************/

/************************************************************************/
/* global variables accessable to all procedures                        */
/************************************************************************/

/* extern */ double v_x[13], v_y[13], v_z[13];
/* extern */ double center_x[21], center_y[21], center_z[21];
/* extern */ double garc, gt, gdve, gel;

/********************************************/
/*      function pre-definitions            */
/********************************************/

double radians(double degrees);
void rotate(double angle, double *x, double *y);
void r2(int axis, double alpha, double *x, double *y, double *z);
void init_stuff(void);
void convert_s_t_p(double lng, double lat, double *x, double *y);
void s_to_c(double theta, double phi, double *x, double *y, double *z);
void c_to_s(double *theta, double *phi, double x, double y, double z);
void s_tri_info(double x, double y, double z,
		 int *tri, int *lcd);
void dymax_point(int tri, int lcd,
		 double x, double y, double z,
		 double *dx, double *dy);

/***************************************/
/*** glue written by SDE 05 May 2003 ***/

void dymax ( double lat, double lng ) {
    Inline_Stack_Vars;
    double x, y;
    init_stuff();
    convert_s_t_p( lng, lat, &x, &y );
    Inline_Stack_Reset;
    Inline_Stack_Push(sv_2mortal(newSVnv(x)));
    Inline_Stack_Push(sv_2mortal(newSVnv(y)));
    Inline_Stack_Done;
}

/*** glue ends here ********************/
/***************************************/


/****************************************/
/*      function definitions            */
/****************************************/


void convert_s_t_p(double lng, double lat, double *x, double *y)
{
  /***********************************************************/
  /* This is the main control procedure.                     */
  /***********************************************************/

  double theta, phi;
  double hx, hy, hz;
  double px, py;
  int tri, hlcd;

  /* Convert the given (long.,lat.) coordinate into spherical */
  /* polar coordinates (r, theta, phi) with radius=1.         */
  /* Angles are given in radians, NOT degrees.                */

  conv_ll_t_sc(lng, lat, &theta, &phi);

  /* convert the spherical polar coordinates into cartesian   */
  /* (x, y, z) coordinates.                                   */

  s_to_c(theta, phi, &hx, &hy, &hz);

  /* determine which of the 20 spherical icosahedron triangles */
  /* the given point is in and the LCD triangle.               */

  s_tri_info(hx, hy, hz, &tri, &hlcd);

  /* Determine the corresponding Fuller map plane (x, y) point */

  dymax_point(tri, hlcd, hx, hy, hz, &px, &py);
  *x = px;
  *y = py;

} /* end convert_s_t_p */


conv_ll_t_sc(double lng, double lat, double *theta, double *phi)
{
  /* convert (long., lat.) point into spherical polar coordinates */
  /* with r=radius=1.  Angles are given in radians.               */

  double h_theta, h_phi;

  h_theta = 90.0 - lat ;
  h_phi = lng;
  if (lng < 0.0) {h_phi = lng + 360.0;}
  *theta = radians(h_theta);
  *phi = radians(h_phi);

} /* end conv_ll_t_sc */


double radians(double degrees)
{
    /* convert angles in degrees into angles in radians */

    double pi2, c1;

    pi2 = 2 * 3.14159265358979323846;
    c1 = pi2 / 360;
    return(c1 * degrees);

} /* end of radians function */


void init_stuff()
{
   /* initializes the global variables which includes the */
   /* vertix coordinates and mid-face coordinates.        */

   double i, hold_x, hold_y, hold_z, magn;
   double theta, phi;

   /* Cartesian coordinates for the 12 vertices of icosahedron */

   v_x[1] =    0.420152426708710003;
   v_y[1] =    0.078145249402782959;
   v_z[1] =    0.904082550615019298;
   v_x[2] =    0.995009439436241649 ;
   v_y[2] =   -0.091347795276427931 ;
   v_z[2] =    0.040147175877166645 ;
   v_x[3] =    0.518836730327364437 ;
   v_y[3] =    0.835420380378235850 ;
   v_z[3] =    0.181331837557262454 ;
   v_x[4] =   -0.414682225320335218 ;
   v_y[4] =    0.655962405434800777 ;
   v_z[4] =    0.630675807891475371 ;
   v_x[5] =   -0.515455959944041808 ;
   v_y[5] =   -0.381716898287133011 ;
   v_z[5] =    0.767200992517747538 ;
   v_x[6] =    0.355781402532944713 ;
   v_y[6] =   -0.843580002466178147 ;
   v_z[6] =    0.402234226602925571 ;
   v_x[7] =    0.414682225320335218 ;
   v_y[7] =   -0.655962405434800777 ;
   v_z[7] =   -0.630675807891475371 ;
   v_x[8] =    0.515455959944041808 ;
   v_y[8] =    0.381716898287133011 ;
   v_z[8] =   -0.767200992517747538 ;
   v_x[9] =   -0.355781402532944713 ;
   v_y[9] =    0.843580002466178147 ;
   v_z[9] =   -0.402234226602925571 ;
   v_x[10] =   -0.995009439436241649 ;
   v_y[10] =    0.091347795276427931 ;
   v_z[10] =   -0.040147175877166645 ;
   v_x[11] =   -0.518836730327364437  ;
   v_y[11] =   -0.835420380378235850  ;
   v_z[11] =   -0.181331837557262454  ;
   v_x[12] =   -0.420152426708710003 ;
   v_y[12] =   -0.078145249402782959 ;
   v_z[12] =   -0.904082550615019298 ;

   /* now calculate mid face coordinates             */

   hold_x = (v_x[1] + v_x[2] + v_x[3]) / 3.0 ;
   hold_y = (v_y[1] + v_y[2] + v_y[3]) / 3.0 ;
   hold_z = (v_z[1] + v_z[2] + v_z[3]) / 3.0 ;
   magn = sqrt(hold_x * hold_x + hold_y * hold_y + hold_z * hold_z);
   center_x[1] = hold_x / magn;
   center_y[1] = hold_y / magn;
   center_z[1] = hold_z / magn;

   hold_x = (v_x[1] + v_x[3] + v_x[4]) / 3.0 ;
   hold_y = (v_y[1] + v_y[3] + v_y[4]) / 3.0 ;
   hold_z = (v_z[1] + v_z[3] + v_z[4]) / 3.0 ;
   magn = sqrt(hold_x * hold_x + hold_y * hold_y + hold_z * hold_z);
   center_x[2] = hold_x / magn;
   center_y[2] = hold_y / magn;
   center_z[2] = hold_z / magn;

   hold_x = (v_x[1] + v_x[4] + v_x[5]) / 3.0 ;
   hold_y = (v_y[1] + v_y[4] + v_y[5]) / 3.0 ;
   hold_z = (v_z[1] + v_z[4] + v_z[5]) / 3.0 ;
   magn = sqrt(hold_x * hold_x + hold_y * hold_y + hold_z * hold_z);
   center_x[3] = hold_x / magn;
   center_y[3] = hold_y / magn;
   center_z[3] = hold_z / magn;

   hold_x = (v_x[1] + v_x[5] + v_x[6]) / 3.0 ;
   hold_y = (v_y[1] + v_y[5] + v_y[6]) / 3.0 ;
   hold_z = (v_z[1] + v_z[5] + v_z[6]) / 3.0 ;
   magn = sqrt(hold_x * hold_x + hold_y * hold_y + hold_z * hold_z);
   center_x[4] = hold_x / magn;
   center_y[4] = hold_y / magn;
   center_z[4] = hold_z / magn;

   hold_x = (v_x[1] + v_x[2] + v_x[6]) / 3.0 ;
   hold_y = (v_y[1] + v_y[2] + v_y[6]) / 3.0 ;
   hold_z = (v_z[1] + v_z[2] + v_z[6]) / 3.0 ;
   magn = sqrt(hold_x * hold_x + hold_y * hold_y + hold_z * hold_z);
   center_x[5] = hold_x / magn;
   center_y[5] = hold_y / magn;
   center_z[5] = hold_z / magn;

   hold_x = (v_x[2] + v_x[3] + v_x[8]) / 3.0 ;
   hold_y = (v_y[2] + v_y[3] + v_y[8]) / 3.0 ;
   hold_z = (v_z[2] + v_z[3] + v_z[8]) / 3.0 ;
   magn = sqrt(hold_x * hold_x + hold_y * hold_y + hold_z * hold_z);
   center_x[6] = hold_x / magn;
   center_y[6] = hold_y / magn;
   center_z[6] = hold_z / magn;

   hold_x = (v_x[8] + v_x[3] + v_x[9]) / 3.0 ;
   hold_y = (v_y[8] + v_y[3] + v_y[9]) / 3.0 ;
   hold_z = (v_z[8] + v_z[3] + v_z[9]) / 3.0 ;
   magn = sqrt(hold_x * hold_x + hold_y * hold_y + hold_z * hold_z);
   center_x[7] = hold_x / magn;
   center_y[7] = hold_y / magn;
   center_z[7] = hold_z / magn;

   hold_x = (v_x[9] + v_x[3] + v_x[4]) / 3.0 ;
   hold_y = (v_y[9] + v_y[3] + v_y[4]) / 3.0 ;
   hold_z = (v_z[9] + v_z[3] + v_z[4]) / 3.0 ;
   magn = sqrt(hold_x * hold_x + hold_y * hold_y + hold_z * hold_z);
   center_x[8] = hold_x / magn;
   center_y[8] = hold_y / magn;
   center_z[8] = hold_z / magn;

   hold_x = (v_x[10] + v_x[9] + v_x[4]) / 3.0 ;
   hold_y = (v_y[10] + v_y[9] + v_y[4]) / 3.0 ;
   hold_z = (v_z[10] + v_z[9] + v_z[4]) / 3.0 ;
   magn = sqrt(hold_x * hold_x + hold_y * hold_y + hold_z * hold_z);
   center_x[9] = hold_x / magn;
   center_y[9] = hold_y / magn;
   center_z[9] = hold_z / magn;

   hold_x = (v_x[5] + v_x[10] + v_x[4]) / 3.0 ;
   hold_y = (v_y[5] + v_y[10] + v_y[4]) / 3.0 ;
   hold_z = (v_z[5] + v_z[10] + v_z[4]) / 3.0 ;
   magn = sqrt(hold_x * hold_x + hold_y * hold_y + hold_z * hold_z);
   center_x[10] = hold_x / magn;
   center_y[10] = hold_y / magn;
   center_z[10] = hold_z / magn;

   hold_x = (v_x[5] + v_x[11] + v_x[10]) / 3.0 ;
   hold_y = (v_y[5] + v_y[11] + v_y[10]) / 3.0 ;
   hold_z = (v_z[5] + v_z[11] + v_z[10]) / 3.0 ;
   magn = sqrt(hold_x * hold_x + hold_y * hold_y + hold_z * hold_z);
   center_x[11] = hold_x / magn;
   center_y[11] = hold_y / magn;
   center_z[11] = hold_z / magn;

   hold_x = (v_x[5] + v_x[6] + v_x[11]) / 3.0 ;
   hold_y = (v_y[5] + v_y[6] + v_y[11]) / 3.0 ;
   hold_z = (v_z[5] + v_z[6] + v_z[11]) / 3.0 ;
   magn = sqrt(hold_x * hold_x + hold_y * hold_y + hold_z * hold_z);
   center_x[12] = hold_x / magn;
   center_y[12] = hold_y / magn;
   center_z[12] = hold_z / magn;

   hold_x = (v_x[11] + v_x[6] + v_x[7]) / 3.0 ;
   hold_y = (v_y[11] + v_y[6] + v_y[7]) / 3.0 ;
   hold_z = (v_z[11] + v_z[6] + v_z[7]) / 3.0 ;
   magn = sqrt(hold_x * hold_x + hold_y * hold_y + hold_z * hold_z);
   center_x[13] = hold_x / magn;
   center_y[13] = hold_y / magn;
   center_z[13] = hold_z / magn;

   hold_x = (v_x[7] + v_x[6] + v_x[2]) / 3.0 ;
   hold_y = (v_y[7] + v_y[6] + v_y[2]) / 3.0 ;
   hold_z = (v_z[7] + v_z[6] + v_z[2]) / 3.0 ;
   magn = sqrt(hold_x * hold_x + hold_y * hold_y + hold_z * hold_z);
   center_x[14] = hold_x / magn;
   center_y[14] = hold_y / magn;
   center_z[14] = hold_z / magn;

   hold_x = (v_x[8] + v_x[7] + v_x[2]) / 3.0 ;
   hold_y = (v_y[8] + v_y[7] + v_y[2]) / 3.0 ;
   hold_z = (v_z[8] + v_z[7] + v_z[2]) / 3.0 ;
   magn = sqrt(hold_x * hold_x + hold_y * hold_y + hold_z * hold_z);
   center_x[15] = hold_x / magn;
   center_y[15] = hold_y / magn;
   center_z[15] = hold_z / magn;

   hold_x = (v_x[12] + v_x[9] + v_x[8]) / 3.0 ;
   hold_y = (v_y[12] + v_y[9] + v_y[8]) / 3.0 ;
   hold_z = (v_z[12] + v_z[9] + v_z[8]) / 3.0 ;
   magn = sqrt(hold_x * hold_x + hold_y * hold_y + hold_z * hold_z);
   center_x[16] = hold_x / magn;
   center_y[16] = hold_y / magn;
   center_z[16] = hold_z / magn;

   hold_x = (v_x[12] + v_x[9] + v_x[10]) / 3.0 ;
   hold_y = (v_y[12] + v_y[9] + v_y[10]) / 3.0 ;
   hold_z = (v_z[12] + v_z[9] + v_z[10]) / 3.0 ;
   magn = sqrt(hold_x * hold_x + hold_y * hold_y + hold_z * hold_z);
   center_x[17] = hold_x / magn;
   center_y[17] = hold_y / magn;
   center_z[17] = hold_z / magn;

   hold_x = (v_x[12] + v_x[11] + v_x[10]) / 3.0 ;
   hold_y = (v_y[12] + v_y[11] + v_y[10]) / 3.0 ;
   hold_z = (v_z[12] + v_z[11] + v_z[10]) / 3.0 ;
   magn = sqrt(hold_x * hold_x + hold_y * hold_y + hold_z * hold_z);
   center_x[18] = hold_x / magn;
   center_y[18] = hold_y / magn;
   center_z[18] = hold_z / magn;

   hold_x = (v_x[12] + v_x[11] + v_x[7]) / 3.0 ;
   hold_y = (v_y[12] + v_y[11] + v_y[7]) / 3.0 ;
   hold_z = (v_z[12] + v_z[11] + v_z[7]) / 3.0 ;
   magn = sqrt(hold_x * hold_x + hold_y * hold_y + hold_z * hold_z);
   center_x[19] = hold_x / magn;
   center_y[19] = hold_y / magn;
   center_z[19] = hold_z / magn;

   hold_x = (v_x[12] + v_x[8] + v_x[7]) / 3.0 ;
   hold_y = (v_y[12] + v_y[8] + v_y[7]) / 3.0 ;
   hold_z = (v_z[12] + v_z[8] + v_z[7]) / 3.0 ;
   magn = sqrt(hold_x * hold_x + hold_y * hold_y + hold_z * hold_z);
   center_x[20] = hold_x / magn;
   center_y[20] = hold_y / magn;
   center_z[20] = hold_z / magn;

   garc = 2.0 * asin( sqrt( 5 - sqrt(5)) / sqrt(10) );
   gt = garc / 2.0;

   gdve = sqrt( 3 + sqrt(5) ) / sqrt( 5 + sqrt(5) );
   gel = sqrt(8) / sqrt(5 + sqrt(5));

} /* end of int_stuff procedure */


void s_to_c(double theta, double phi, double *x, double *y, double *z)
{
    /* Covert spherical polar coordinates to cartesian coordinates. */
    /* The angles are given in radians.                             */

    *x = sin(theta) * cos(phi);
    *y = sin(theta) * sin(phi);
    *z = cos(theta);

 } /* end s_to_c */


void c_to_s(double *lng, double *lat, double x, double y, double z)
   {
    /* convert cartesian coordinates into spherical polar coordinates. */
    /* The angles are given in radians.                                */

    double a;

    if (x>0.0 && y>0.0){a = radians(0.0);}
    if (x<0.0 && y>0.0){a = radians(180.0);}
    if (x<0.0 && y<0.0){a = radians(180.0);}
    if (x>0.0 && y<0.0){a = radians(360.0);}
    *lat = acos(z);
    if (x==0.0 && y>0.0){*lng = radians(90.0);}
    if (x==0.0 && y<0.0){*lng = radians(270.0);}
    if (x>0.0 && y==0.0){*lng = radians(0.0);}
    if (x<0.0 && y==0.0){*lng = radians(180.0);}
    if (x!=0.0 && y!=0.0){*lng = atan(y/x) + a;}

} /* end c_to_s */


void s_tri_info(double x, double y, double z,
		 int *tri, int *lcd)
{
  /* Determine which triangle and LCD triangle the point is in. */

  double  h_dist1, h_dist2, h_dist3, h1, h2, h3;
  int i, h_tri, h_lcd ;
  int v1, v2, v3;

  h_tri = 0;
  h_dist1 = 9999.0;

  /* Which triangle face center is the closest to the given point */
  /* is the triangle in which the given point is in.              */

  for (i = 1; i <=20; i = i + 1)
   {
     h1 = center_x[i] - x;
     h2 = center_y[i] - y;
     h3 = center_z[i] - z;
     h_dist2 = sqrt(h1 * h1 + h2 * h2 + h3 * h3);
     if (h_dist2 < h_dist1)
      {
        h_tri = i;
        h_dist1 = h_dist2;
      } /* end the if statement */
   }  /* end the for statement */

   *tri = h_tri;

   /* Now the LCD triangle is determined. */

   switch (h_tri)
   {
    case 1:  v1 =  1; v2 =  3; v3 =  2; break;
    case 2:  v1 =  1; v2 =  4; v3 =  3; break;
    case 3:  v1 =  1; v2 =  5; v3 =  4; break;
    case 4:  v1 =  1; v2 =  6; v3 =  5; break;
    case 5:  v1 =  1; v2 =  2; v3 =  6; break;
    case 6:  v1 =  2; v2 =  3; v3 =  8; break;
    case 7:  v1 =  3; v2 =  9; v3 =  8; break;
    case 8:  v1 =  3; v2 =  4; v3 =  9; break;
    case 9:  v1 =  4; v2 = 10; v3 =  9; break;
    case 10: v1 =  4; v2 =  5; v3 = 10; break;
    case 11: v1 =  5; v2 = 11; v3 = 10; break;
    case 12: v1 =  5; v2 =  6; v3 = 11; break;
    case 13: v1 =  6; v2 =  7; v3 = 11; break;
    case 14: v1 =  2; v2 =  7; v3 =  6; break;
    case 15: v1 =  2; v2 =  8; v3 =  7; break;
    case 16: v1 =  8; v2 =  9; v3 = 12; break;
    case 17: v1 =  9; v2 = 10; v3 = 12; break;
    case 18: v1 = 10; v2 = 11; v3 = 12; break;
    case 19: v1 = 11; v2 =  7; v3 = 12; break;
    case 20: v1 =  8; v2 = 12; v3 =  7; break;
   } /* end of switch statement */

   h1 = x - v_x[v1];
   h2 = y - v_y[v1];
   h3 = z - v_z[v1];
   h_dist1 = sqrt(h1 * h1 + h2 * h2 + h3 * h3);

   h1 = x - v_x[v2];
   h2 = y - v_y[v2];
   h3 = z - v_z[v2];
   h_dist2 = sqrt(h1 * h1 + h2 * h2 + h3 * h3);

   h1 = x - v_x[v3];
   h2 = y - v_y[v3];
   h3 = z - v_z[v3];
   h_dist3 = sqrt(h1 * h1 + h2 * h2 + h3 * h3);

   if ( (h_dist1 <= h_dist2) && (h_dist2 <= h_dist3) ) {h_lcd = 1; }
   if ( (h_dist1 <= h_dist3) && (h_dist3 <= h_dist2) ) {h_lcd = 6; }
   if ( (h_dist2 <= h_dist1) && (h_dist1 <= h_dist3) ) {h_lcd = 2; }
   if ( (h_dist2 <= h_dist3) && (h_dist3 <= h_dist1) ) {h_lcd = 3; }
   if ( (h_dist3 <= h_dist1) && (h_dist1 <= h_dist2) ) {h_lcd = 5; }
   if ( (h_dist3 <= h_dist2) && (h_dist2 <= h_dist1) ) {h_lcd = 4; }

   *lcd = h_lcd;

} /* end s_tri_info */


void dymax_point(int tri, int lcd,
		 double x, double y, double z,
                 double *px, double *py)
{
  int axis, v1;
  double hlng, hlat, h0x, h0y, h0z, h1x, h1y, h1z;

  double gs;
  double gx, gy, gz, ga1,ga2,ga3,ga1p,ga2p,ga3p,gxp,gyp,gzp;


  /* In order to rotate the given point into the template spherical */
  /* triangle, we need the spherical polar coordinates of the center */
  /* of the face and one of the face vertices. So set up which vertex */
  /* to use.                                                          */

   switch (tri)
   {
    case 1:  v1 =  1;  break;
    case 2:  v1 =  1;  break;
    case 3:  v1 =  1;  break;
    case 4:  v1 =  1;  break;
    case 5:  v1 =  1;  break;
    case 6:  v1 =  2;  break;
    case 7:  v1 =  3;  break;
    case 8:  v1 =  3;  break;
    case 9:  v1 =  4;  break;
    case 10: v1 =  4;  break;
    case 11: v1 =  5;  break;
    case 12: v1 =  5;  break;
    case 13: v1 =  6;  break;
    case 14: v1 =  2;  break;
    case 15: v1 =  2;  break;
    case 16: v1 =  8;  break;
    case 17: v1 =  9;  break;
    case 18: v1 = 10;  break;
    case 19: v1 = 11;  break;
    case 20: v1 =  8;  break;
   } /* end of switch statement */

   h0x = x;
   h0y = y;
   h0z = z;

   h1x = v_x[v1];
   h1y = v_y[v1];
   h1z = v_z[v1];

   c_to_s(&hlng, &hlat, center_x[tri], center_y[tri], center_z[tri]);

   axis = 3;
   r2(axis,hlng,&h0x,&h0y,&h0z);
   r2(axis,hlng,&h1x,&h1y,&h1z);

   axis = 2;
   r2(axis,hlat,&h0x,&h0y,&h0z);
   r2(axis,hlat,&h1x,&h1y,&h1z);

   c_to_s(&hlng,&hlat,h1x,h1y,h1z);
   hlng = hlng - radians(90.0);

   axis = 3;
   r2(axis,hlng,&h0x,&h0y,&h0z);

   /* exact transformation equations */

   gz = sqrt(1 - h0x * h0x - h0y * h0y);
   gs = sqrt( 5 + 2 * sqrt(5) ) / ( gz * sqrt(15) );

   gxp = h0x * gs ;
   gyp = h0y * gs ;

   ga1p = 2.0 * gyp / sqrt(3.0) + (gel / 3.0) ;
   ga2p = gxp - (gyp / sqrt(3)) +  (gel / 3.0) ;
   ga3p = (gel / 3.0) - gxp - (gyp / sqrt(3));

   ga1 = gt + atan( (ga1p - 0.5 * gel) / gdve);
   ga2 = gt + atan( (ga2p - 0.5 * gel) / gdve);
   ga3 = gt + atan( (ga3p - 0.5 * gel) / gdve);

   gx = 0.5 * (ga2 - ga3) ;

   gy = (1.0 / (2.0 * sqrt(3)) ) * (2 * ga1 - ga2 - ga3);

   /* Re-scale so plane triangle edge length is 1. */

   x = gx / garc;
   y = gy / garc;

  /* rotate and translate to correct position          */

  switch (tri)
   {
     case  1: rotate(240.0,&x, &y);
	      *px = x + 2.0; *py = y + 7.0 / (2.0 * sqrt(3.0)) ; break;
     case  2: rotate(300.0, &x, &y); *px = x + 2.0;
              *py = y + 5.0 / (2.0 * sqrt(3.0)) ; break;
     case  3: rotate(0.0, &x, &y);
             *px = x + 2.5; *py = y + 2.0 / sqrt(3.0); break;
     case  4: rotate(60.0, &x, &y);
              *px = x + 3.0; *py = y + 5.0 / (2.0 * sqrt(3.0)) ; break;
     case  5: rotate(180.0, &x, &y);
	      *px = x + 2.5; *py = y + 4.0 * sqrt(3.0) / 3.0; break;
     case  6: rotate(300.0, &x, &y);
              *px = x + 1.5; *py = y + 4.0 * sqrt(3.0) / 3.0; break;
     case  7: rotate(300.0, &x, &y);
              *px = x + 1.0; *py = y + 5.0 / (2.0 * sqrt(3.0)) ; break;
     case  8: rotate(0.0, &x, &y);
              *px = x + 1.5; *py = y + 2.0 / sqrt(3.0); break;
     case  9: if (lcd > 2)
	      {
	      rotate(300.0, &x, &y);
	      *px = x + 1.5; *py = y + 1.0 / sqrt(3.0);
	      }
	      else
	      {
	      rotate(0.0, &x, &y);
	      *px = x + 2.0; *py = y + 1.0 / (2.0 * sqrt(3.0));
	      }
	      break;

     case 10: rotate(60.0, &x, &y);
              *px = x + 2.5; *py = y + 1.0 / sqrt(3.0); break;
     case 11: rotate(60.0, &x, &y);
              *px = x + 3.5; *py = y + 1.0 / sqrt(3.0); break;
     case 12: rotate(120.0, &x, &y);
              *px = x + 3.5; *py = y + 2.0 / sqrt(3.0); break;
     case 13: rotate(60.0, &x, &y);
              *px = x + 4.0; *py = y + 5.0 / (2.0 * sqrt(3.0)); break;
     case 14: rotate(0.0, &x, &y);
	      *px = x + 4.0; *py = y + 7.0 / (2.0 * sqrt(3.0)) ; break;
     case 15: rotate(0.0, &x, &y);
	      *px = x + 5.0; *py = y + 7.0 / (2.0 * sqrt(3.0)) ; break;
     case 16: if (lcd < 4)
	      {
		rotate(60.0, &x, &y);
		*px = x + 0.5; *py = y + 1.0 / sqrt(3.0);
	       }
	       else
	       {
		rotate(0.0, &x, &y);
		*px = x + 5.5; *py = y + 2.0 / sqrt(3.0);
	       }
	       break;
     case 17: rotate(0.0, &x, &y);
	      *px = x + 1.0; *py = y + 1.0 / (2.0 * sqrt(3.0)); break;
     case 18: rotate(120.0, &x, &y);
              *px = x + 4.0; *py = y + 1.0 / (2.0 * sqrt(3.0)); break;
     case 19: rotate(120.0, &x, &y);
              *px = x + 4.5; *py = y + 2.0 / sqrt(3.0); break;
     case 20: rotate(300.0, &x, &y);
              *px = x + 5.0; *py = y + 5.0 / (2.0 * sqrt(3.0)); break;

   } /* end switch statement */

} /* end of dymax_point */


void rotate(double angle, double *x, double *y)
{
  /* Rotate the point to correct orientation in XY-plane. */

  double ha, hx, hy ;

  ha = radians(angle);
  hx = *x;
  hy = *y;
  *x = hx * cos(ha) - hy * sin(ha);
  *y = hx * sin(ha) + hy * cos(ha);

} /* end rotate procedure */


void r2(int axis, double alpha, double *x, double *y, double *z)
{
  /* Rotate a 3-D point about the specified axis.         */

  double a, b, c;

  a = *x;
  b = *y;
  c = *z;
  if (axis == 1)
  {
   *y = b * cos(alpha) + c * sin(alpha);
   *z = c * cos(alpha) - b * sin(alpha);
  }

  if (axis == 2)
  {
   *x = a * cos(alpha) - c * sin(alpha);
   *z = a * sin(alpha) + c * cos(alpha);
  }

  if (axis == 3)
  {
   *x = a * cos(alpha) + b * sin(alpha);
   *y = b * cos(alpha) - a * sin(alpha);
  }

} /* end of r2 */

