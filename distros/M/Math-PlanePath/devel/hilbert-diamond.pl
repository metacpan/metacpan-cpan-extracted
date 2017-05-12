#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
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
use Image::Base::PNGwriter;
use Math::PlanePath::HilbertCurve;

#use Smart::Comments;

my $width = 500;
my $height = 500;
my $image = Image::Base::PNGwriter->new (-width => $width,
                                         -height => $height);
my $scale = 20;
sub rotate {
  my ($x, $y) = @_;
  return ($scale * ($x + $y) + $scale, $scale * ($x - $y) + int($height/2));
}

my $path = Math::PlanePath::HilbertCurve->new;
my ($prev_x, $prev_y) = $path->n_to_xy(0);
my ($prev_rx, $prev_ry) = rotate($prev_x, $prev_y);

foreach my $n (1 .. 64) {
  my ($x, $y) = $path->n_to_xy($n);
  ### xy: "$x,$y"

  my ($rx, $ry) = rotate($x,$y);
  $image->line ($rx,$ry, $prev_rx,$prev_ry, 'white');
  ### line: "$rx,$ry, $prev_rx,$prev_ry"

  ($prev_x, $prev_y) = ($x, $y);
  ($prev_rx, $prev_ry) = ($rx, $ry);
}

$image->save ('/tmp/x.png');
system ('xzgv /tmp/x.png');

exit 0;
