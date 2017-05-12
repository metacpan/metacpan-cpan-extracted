#!perl

# Perl version of the PLplot C x08c.c example [3d]
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
my $sleep = 0.5;
print "# Version: ". &plgver() ."\n";

use constant XPTS => 35;
use constant YPTS => 46;
use constant LEVELS => 10;

my @alt = (60,20);
my @az  = (30,60);
my @title = (
	     "#frPLplot Example 8 - Alt=60, Az=30",
	     "#frPLplot Example 8 - Alt=20, Az=60",
	    );

# A series of 3d plots

plParseOpts(\@ARGV,PARSE_FULL);

# Other options that need to be command line driven
my $rosen = 1;

# Initialise plplot
plsdev("xwin");
plinit;

my $z = pl_Alloc2dGrid(XPTS, YPTS);

my (@x);
for my $i (0..(XPTS-1) ) {
  $x[$i] = ($i- XPTS/2) / (XPTS/2);
  $x[$i] *= 1.5 if $rosen;
}

my @y;
for my $i (0..(YPTS-1) ) {
  $y[$i] = ($i - (YPTS/2)) / (YPTS/2);
  $y[$i] += 0.5 if $rosen;
}

for my $i (0..(XPTS-1)) {
  my $xx = $x[$i];
  for my $j (0..(YPTS-1)) {
    my $yy = $y[$j];
    if ($rosen) {
      $z->[$i][$j] = (1-$xx)**2 + (100 * ($yy-($xx*$xx))**2);
      # The log argument may be zero for just the right grid.
      if ($z->[$i][$j] > 0 ) {
	$z->[$i][$j] = log($z->[$i][$j]);
      } else {
	$z->[$i][$j] = -5;
      }
    } else {
      my $r = sqrt( $xx*$xx + $yy * $yy);
      $z->[$i][$j] = exp(-$r * $r) * cos(2 * pi * $r);
    }
  }
}

my ($zmin, $zmax ) = pl_MinMax2dGrid( $z );
my $step = ($zmax-$zmin)/(LEVELS+1);

my @clevel = map { $zmin + $step + ($_*$step) } (0..(LEVELS-1));

pllightsource(1,1,1);

plspause(0);
for my $k (0..1) {
  for my $ifshade ( 0.. 3 ) {
    pladv(0);
    plvpor(0.0, 1.0, 0.0, 0.9);
    plwind(-1.0, 1.0, -0.9, 1.1);
    plcol0(3);
    plmtex("t", 1.0, 0.5, 0.5, $title[$k]);
    plcol0(1);
    if ($rosen) {
      plw3d(1.0, 1.0, 1.0, -1.5, 1.5, -0.5, 1.5, $zmin, $zmax, $alt[$k], $az[$k]);
    } else {
      plw3d(1.0, 1.0, 1.0, -1.0, 1.0, -1.0, 1.0, $zmin, $zmax, $alt[$k], $az[$k]);
    }
    plbox3("bnstu", "x axis", 0.0, 0,
	   "bnstu", "y axis", 0.0, 0,
	   "bcdmnstuv", "z axis", 0.0, 0);
    plcol0(2);

    if ($ifshade == 0) { # diffuse light surface plot
      cmap1_init(1);
      plsurf3d(\@x, \@y, $z, 0, []);
    } elsif ($ifshade == 1) { # magnitude colored plot
      cmap1_init(0);
      plsurf3d(\@x, \@y, $z, MAG_COLOR, []);
    } elsif ($ifshade == 2) { # magnitude colored plot with faceted squares
      plsurf3d(\@x, \@y, $z, MAG_COLOR | FACETED, []);
    } else {                 #  magnitude colored plot with contours
      plsurf3d(\@x, \@y, $z, MAG_COLOR | SURF_CONT | BASE_CONT, \@clevel);
    }
    plflush();
    select undef,undef,undef,$sleep;
  }
}

plend();
exit;


# Initialise color map 1 in HLS space

sub cmap1_init {
  my $gray = shift;

  my (@i,@h,@l,@s);

  $i[0] = 0; # Left boundary
  $i[1] = 1; # Right boundary

  if ($gray) {
    $h[0] = 0.0;         # hue -- low: red (arbitrary if s=0)
    $h[1] = 0.0;         # hue -- high: red (arbitrary if s=0)

    $l[0] = 0.5;         # lightness -- low: half-dark
    $l[1] = 1.0;         # lightness -- high: light

    $s[0] = 0.0;         # minimum saturation
    $s[1] = 0.0;         # minimum saturation
  } else {
    $h[0] = 240;         # blue -> green -> yellow ->
    $h[1] = 0;           #  -> red
    $l[0] = 0.6;
    $l[1] = 0.6;
    $s[0] = 0.8;
    $s[1] = 0.8;
  }

  plscmap1n(256);
  plscmap1l(0, \@i, \@h, \@l, \@s, []);
}
