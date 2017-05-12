#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Image-Base-GD.
#
# Image-Base-GD is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-GD is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-GD.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use GD::SVG;
use Smart::Comments;

{
  my $gd = GD::SVG::Image->new (100, 100);
  my $index = $gd->colorAllocate(255,0,255);
  printf "index %X\n", $index;

  $gd->ellipse (5,5, 6,6, 1);

  print $gd->svg;
}
