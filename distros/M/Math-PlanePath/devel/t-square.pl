#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013 Kevin Ryde

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


use 5.004;
use strict;
use Math::PlanePath::Base::Digits 'round_down_pow';

{
  require Image::Base::GD;
  my $width = 810;
  my $height = 810;
  my $image = Image::Base::GD->new (-width => $width, -height => $height);
  $image->rectangle (0,0, $width-1,$height-1, 'black');
  my $foreground = 'white';

  #       *---------*
  #       |         |
  #  *----*    .    |
  #                 |
  #  *----*    *----*
  #       |    |
  #       *    *

  my $recurse;
  $recurse = sub {
    my ($x,$y, $dx,$dy, $level) = @_;
    if (--$level < 0) {
      $image->line($x,$y, $x+$dx,$y+$dy, $foreground);
      $x += $dx;
      $y += $dy;

      ($dx,$dy) = (-$dy,$dx); # rotate +90
      $image->line($x,$y, $x+$dx,$y+$dy, $foreground);

    } else {
      $dx /= 2;
      $dy /= 2;

      $image->line($x,$y, $x+$dx,$y+$dy, $foreground);
      $x += $dx;
      $y += $dy;

      ($dx,$dy) = ($dy,-$dx); # rotate -90
      $recurse->($x,$y, $dx,$dy, $level);
      $x += $dx;
      $y += $dy;
      ($dx,$dy) = (-$dy,$dx); # rotate +90
      $x += $dx;
      $y += $dy;

      $recurse->($x,$y, $dx,$dy, $level);
      $x += $dx;
      $y += $dy;
      ($dx,$dy) = (-$dy,$dx); # rotate +90
      $x += $dx;
      $y += $dy;

      $recurse->($x,$y, $dx,$dy, $level);
      $x += $dx;
      $y += $dy;
      ($dx,$dy) = (-$dy,$dx); # rotate +90
      $x += $dx;
      $y += $dy;

      ($dx,$dy) = ($dy,-$dx); # rotate -90
      $image->line($x,$y, $x+$dx,$y+$dy, $foreground);
    }
  };

  my $scale = 2;
  my ($pow,$exp) = round_down_pow($height/$scale, 2);

  foreach my $level (0 .. $exp) {
    my $len = 2**$level * $scale;
    $recurse->(0, $height-1 - $len, $len,0, $level);
  }

  $image->save('/tmp/x.png');
  system('xzgv /tmp/x.png');

  exit 0;
}
