#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-PlanePath is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use warnings;
use Smart::Comments;
use Math::Libm 'M_PI', 'hypot';
use Math::Trig 'cartesian_to_cylindrical', 'cylindrical_to_cartesian';
use Math::PlanePath::Flowsnake;

my $path = Math::PlanePath::Flowsnake->new;

my $width = 300;
my $height = 300;

print <<"HERE";
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.0//EN" "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd" [
	<!ENTITY ns_svg "http://www.w3.org/2000/svg">
]>
<svg width="$width" height="$height">
<g>
HERE

my $equilateral = sqrt(3);
my $xoffset = $width * .2;
my $yoffset = $height * .5;
my $xsize = $width * .3;
my $yscale = .3;

foreach my $level (4 .. 4) {
  my $linewidth = 1/$level;
  my $n_hi = 7**$level - 1;
  my $n_e = 7**($level-1)*6-1;
  my ($ex, $ey) = $path->n_to_xy($n_e);
  $ey *= $equilateral;
  my $angle = - atan2($ey,$ex);
  my $hypot = hypot ($ex,$ey);
  my $xfactor = $xsize / $hypot;
  my $yfactor = $height * .8 * $yscale / $hypot;
  my $s = sin($angle);
  my $c = cos($angle);

  my $points = '';
  foreach my $n (0 .. $n_hi) {
    my ($x, $y) = $path->n_to_xy($n);
    $y *= $equilateral;

    # my ($r, $theta) = cartesian_to_cylindrical($x, $y, 0);
    # $r += $angle;
    # ($x, $y) = cylindrical_to_cartesian($r, $theta, 0);

    ($x, $y) = ($x * $c - $y * $s,
                $x * $s + $y * $c);
    $x = $x * $xfactor + $xoffset;
    $y = $y * $yfactor + $yoffset;
    $points .= "$x,$y ";
  }

  print "<polyline fill=\"none\" stroke=\"#FF00FF\" stroke-width=\"$linewidth\" points=\"$points\"/>";
}

print <<'HERE';
	</g>
</svg>
HERE
