#!perl

# Perl version of the PLplot C x18c.c example - Demo of 3D plot
#
# This version Copyright (C) 2004 Tim Jenness. All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful,but WITHOUT ANY# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple
# Place,Suite 330, Boston, MA  02111-1307, USA
#

use strict;
use Test::More tests => 2;
use Math::Trig qw/ pi /;
use constant TWO_PI => 2 * pi;
use constant NPTS => 1000;
BEGIN {
  use_ok("Graphics::PLplot");
  Graphics::PLplot->import(qw/ :all /);
}
my $sleep = 0.5;
print "# Version: ". &plgver() ."\n";

# Setup input
my @alt = (20,35,50,65);
my @az = (30,40,50,60);
my @opt = (1,0,1,0);

# Initialize plplot

my $dev = "xwin";
plsdev( $dev );
is(plgdev, $dev, "Check device");

plinit();
plspause(0);
for (0..3) { test_poly($_); plflush(); select undef,undef,undef,$sleep;}

# other test
my (@x,@y,@z);
for my $i (0..NPTS-1) {
  $z[$i] = -1 + ( 2 * $i / NPTS );

# pick one
#  my $r = 1 - ( $i / NPTS );
  my $r = $z[$i];

  $x[$i] = $r * cos( 2 * pi * 6 * $i / NPTS );
  $y[$i] = $r * sin( 2 * pi * 6 * $i / NPTS );

}

for my $k ( 0..3 ) {
  pladv(0);
  plvpor(0.0, 1.0, 0.0, 0.9);
  plwind(-1.0, 1.0, -0.9, 1.1);
  plcol0(1);
  plw3d(1.0, 1.0, 1.0, -1.0, 1.0, -1.0, 1.0, -1.0, 1.0, $alt[$k], $az[$k]);
  plbox3("bnstu", "x axis", 0.0, 0,
	 "bnstu", "y axis", 0.0, 0,
	 "bcdmnstuv", "z axis", 0.0, 0);

  plcol0(2);

  if ($opt[$k]) {
    plline3( \@x, \@y, \@z );
  } else {
    plpoin3( \@x, \@y, \@z, 1 );
  }
  plcol0(3);
  my $title = sprintf("#frPLplot Example 18 - Alt=%.0f, Az=%.0f",
		      $alt[$k], $az[$k]);
  plmtex("t", 1.0, 0.5, 0.5, $title);
  plflush();
  select undef,undef,undef,$sleep;
}


plend();
exit;


sub test_poly {
  my $k = shift;

  my @draw = ( [1,1,1,1],
	       [1,0,1,0],
	       [0,1,0,1],
	       [1,1,0,0]
	     );

  pladv(0);
  plvpor(0.0, 1.0, 0.0, 0.9);
  plwind(-1.0, 1.0, -0.9, 1.1);
  plcol0(1);
  plw3d(1.0, 1.0, 1.0, -1.0, 1.0, -1.0, 1.0, -1.0, 1.0, $alt[$k], $az[$k]);
  plbox3("bnstu", "x axis", 0.0, 0,
	 "bnstu", "y axis", 0.0, 0,
	 "bcdmnstuv", "z axis", 0.0, 0);

  plcol0(2);

  # x = r sin(phi) cos(theta)
  # y = r sin(phi) sin(theta)
  # z = r cos(phi)
  # r = 1 :=)

  for my $i (0..19) {
    for my $j (0 .. 19) {
      my (@x,@y,@z);
      $x[0] = sin( PHI($j) ) * cos( THETA($i) );
      $y[0] = sin( PHI($j) ) * sin( THETA($i) );
      $z[0] = cos( PHI($j) );

      $x[1] = sin( PHI($j+1) ) * cos( THETA($i) );
      $y[1] = sin( PHI($j+1) ) * sin( THETA($i) );
      $z[1] = cos( PHI($j+1) );

      $x[2] = sin( PHI($j+1) ) * cos( THETA($i+1) );
      $y[2] = sin( PHI($j+1) ) * sin( THETA($i+1) );
      $z[2] = cos( PHI($j+1) );

      $x[3] = sin( PHI($j) ) * cos( THETA($i+1) );
      $y[3] = sin( PHI($j) ) * sin( THETA($i+1) );
      $z[3] = cos( PHI($j) );

      $x[4] = sin( PHI($j) ) * cos( THETA($i) );
      $y[4] = sin( PHI($j) ) * sin( THETA($i) );
      $z[4] = cos( PHI($j) );
      plpoly3( \@x, \@y, \@z, $draw[$k], 1 );
    }
  }
  plcol0(3);
  plmtex("t", 1.0, 0.5, 0.5, "unit radius sphere" );

}

sub THETA {
  return (TWO_PI * $_[0] / 20 );
}

sub PHI {
  return ( pi * $_[0] / 20.1 );
}
