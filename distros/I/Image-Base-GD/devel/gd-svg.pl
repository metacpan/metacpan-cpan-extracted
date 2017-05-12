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

use 5.006;
use strict;
use warnings;

use Smart::Comments;

{
  require GD::SVG;
  my $gd = GD::SVG::Image->new; # (100,50);
  ### gd: ref $gd

  require Image::Base::GD;
  my $image = Image::Base::GD->new (-gd => $gd,
                                    -file_format => 'svg');
  # -width => 100,
  # -height => 50);
  $image->rectangle (0,0, 49,29, 'black');
  #  $image->rectangle (3,3, 7,7, 'white');

  $image->xy (47,2, 'green');
  $image->xy (48,2, 'red');
  $image->xy (47,3, 'blue');
  $image->ellipse (0,0, 11,10, 'white');
  # $gd->setThickness(1);
  # $gd->ellipse (5,5, 6,6, $image->colour_to_index('white'));
  #  $gd->rectangle (10,12, 14,12, $image->colour_to_index('white'));

  $image->save('/dev/stdout');
  $image->save('/tmp/x.svg');
  system('xzgv /tmp/x.svg');

  exit 0;
}
