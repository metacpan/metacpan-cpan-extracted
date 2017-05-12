#!perl

# Perl version of the PLplot C x01c.c example [4 line plots]
#
# This version Copyright (C) 2004 Tim Jenness. All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful,but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple
# Place,Suite 330, Boston, MA  02111-1307, USA
#

use strict;
use Test::More tests => 1;
use Math::Trig qw/ pi /;
BEGIN {
  use_ok("Graphics::PLplot");
  Graphics::PLplot->import(qw/ :all /);
}
my $sleep = 2;
print "# Version: ". &plgver() ."\n";

plssub( 2, 2);
plsdev( "xwin" );
plinit();


print "# Plot 1\n";
&plot1( 6, 1, 0, 0.);

print "# Plot 1 [plsyax]\n";
plsyax( 5, 0 );
&plot1( 1, 0.0014, 0, 0.0185);

print "# Plot 3\n";
&plot2();

print "# Plot 4\n";
&plot3();

sleep($sleep);
plflush();
plspause(0);
plend();

print "# Ending \n";

exit;

# First plot
sub plot1 {
  my ($xscale, $yscale, $xoff, $yoff ) = @_;

  # Setup some arrays for plotting
  my @x;
  my @y;
  for my $i ( 1..60 ) {
    my $x = $xoff + ($xscale * $i / 60.0);
    my $y = $yoff + ($yscale * ( $x ** 2));
    push(@x, $x);
    push(@y, $y);
  }

  my $xmin = $x[0];
  my $xmax = $x[-1];
  my $ymin = $y[0];
  my $ymax = $y[-1];

  print "# xmin xmax ymin ymax $xmin $xmax $ymin $ymax \n";

  my @idx = map { $_ * 10 + 3 } (0..5);
  my @xs = map { $x[$_] } @idx;
  my @ys = map { $y[$_] } @idx;


  # Set up the viewport and window using PLENV. The range in X is
  # 0.0 to 6.0, and the range in Y is 0.0 to 30.0. The axes are
  # scaled separately (just = 0), and we just draw a labelled
  # box (axis = 0).

  plcol0( 1 );
  plenv( $xmin, $xmax, $ymin, $ymax, 0, 0);
  plcol0( 2 );
  pllab( "(x)", "(y)", "#frPLplot Example 1 - y=x#u2");

  # plot the data points

  plcol0( 4 );
  plpoin( \@xs, \@ys, 9 );

  # Draw the line through the data

  plcol0( 3 );
  plline( \@x, \@y );

}

sub plot2 {

  # Set up the viewport and window using PLENV. The range in X is -2.0 to
  # 10.0, and the range in Y is -0.4 to 2.0. The axes are scaled separately
  # (just = 0), and we draw a box with axes (axis = 1).

  plcol0( 1 );
  plenv( -2, 10, -0.4, 1.2, 0, 1);
  plcol0( 2 );
  pllab("(x)","sin(x)/x","#frPLplot Example 1 - Sinc Function");

  # Fill up the arrays
  my @x = map { ($_ - 19.0) / 6.0 } (0..99);
  my @y = map { ($_ == 0 ? 1 : sin($_) / $_) } @x;

  # Draw the line
  plcol0( 3 );
  plwid( 2 );
  plline( \@x, \@y );
  plwid( 1 );

}


sub plot3 {
  my $space1 = 1500;
  my $mark1 = 1500;


  # For the final graph we wish to override the default tick intervals, and
  # so do not use plenv().
  pladv (0);

  # Use standard viewport, and define X range from 0 to 360 degrees, Y range
  # from -1.2 to 1.2.

  plvsta ();
  plwind (0.0, 360.0, -1.2, 1.2);

  # Draw a box with ticks spaced 60 degrees apart in X, and 0.2 in Y.

  plcol0 (1);
  plbox ("bcnst", 60.0, 2, "bcnstv",0.2, 2);

  # Superimpose a dashed line grid, with 1.5 mm marks and spaces.

  plstyl ( [$mark1], [$space1]);
  plcol0 (2);
  plbox ("g",30.0, 0, "g",0.2, 0);
  # Clear styles
  plstyl ([], []);

  plcol0 (3);
  pllab ("Angle (degrees)", "sine", 
			   "#frPLplot Example 1 - Sine function");

  my @x = map { 3.6 * $_ } (0..100);
  my @y = map { sin ($_ * pi / 180.0) } @x;

  plcol0 (4);
  plline (\@x, \@y);

}
