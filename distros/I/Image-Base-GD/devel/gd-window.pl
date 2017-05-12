#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012 Kevin Ryde

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
  require GD;
  my $outer_gd = GD::Image->new (40,20);
  {
    my $index = $outer_gd->colorAllocate (0,0,0);
    ### $index
  }
#   sub $name {
#     my $s = shift;
#     my $res = $s->{im}->$name(@_);
#     $s->postRenderAdjustment();
#     return $res;
# }
#    return $name(\@_);");


  require GD::Window;
  my $gd = GD::Window->new ($outer_gd,
                            10,10, 20,15,
                            0,0, 10,5,
                            passThrough => 1);
  ### gd: ref $gd


  {
    my $index = $gd->colorAllocate (0,0,0);
    ### $index
  }
  {
    my $index = $gd->colorAllocate (0,0,0);
    ### $index
  }

  require Image::Base::GD;
  my $image = Image::Base::GD->new (-gd => $gd,
                                    -file_format => 'xpm');
  # -width => 100,
  # -height => 50);
  $image->rectangle (0,0, 10,5, 'black',1);
  #  $image->rectangle (3,3, 7,7, 'white');

  $image->ellipse (1,1, 9,4, 'white');

  # $image->xy (47,2, 'green');
  # $image->xy (48,2, 'red');
  # $image->xy (47,3, 'blue');
  # $gd->setThickness(1);
  # $gd->ellipse (5,5, 6,6, $image->colour_to_index('white'));
  #  $gd->rectangle (10,12, 14,12, $image->colour_to_index('white'));

  $image->save('/dev/stdout');

  exit 0;
}
