#!perl

# Perl version of the PLplot C x03c.c example [polar grid]

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

plsdev( "xwin" );
plinit();

# Set up viewport and window but do not draw box
plenv(-1.3,1.3,-1.3,1.3,1,-2);

my $dtr = pi / 180.0;
my @x0 = map { cos( $dtr * $_  ) } (0..360);
my @y0 = map { sin( $dtr * $_  ) } (0..360);

my (@x,@y);
for my $i (1..10) {
  my @x = map { 0.1 * $i * $_ } @x0;
  my @y = map { 0.1 * $i * $_ } @y0;

  # Draw circles for polar grid
  plline( \@x, \@y);

}

plcol0(2);
for my $i ( 0 .. 11 ) {
  my $theta = 30 * $i;
  my $dx = cos ( $dtr * $theta );
  my $dy = sin ( $dtr * $theta );

  # Draw radial spokes for polar grid
  pljoin( 0, 0, $dx, $dy);

  # Write labels for angle
  # Slightly off zero to avoid floating point logic flipts 
  # at 90 and 270 deg
  if ($dx >= -0.00001) {
    plptex($dx, $dy, $dx, $dy, -0.15, int($theta));
  } else {
    plptex($dx, $dy, -$dx, -$dy, 1.15, int($theta));
  }

}

# Draw the graph
for my $i (0 .. $#x0) {
  my $r = sin( $dtr * 5 * $i);
  $x[$i] = $x0[$i] * $r;
  $y[$i] = $y0[$i] * $r;
}

plcol0(3);
plline(\@x, \@y);
plcol0(4);
plmtex("t",2,0.5,0.5,"#frPLplot Example 3 - r(#gh)=sin 5#gh");

plflush();
sleep($sleep);
plspause(0);

plend();

print "# Ending \n";

exit;
