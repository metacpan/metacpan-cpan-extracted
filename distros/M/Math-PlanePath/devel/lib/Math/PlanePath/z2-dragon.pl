# Copyright 2014 Kevin Ryde

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

use strict;
use Math::PlanePath::Z2DragonCurve;

{
  require Image::Base::GD;
  my $width = 1010;
  my $height = 710;
  my $image = Image::Base::GD->new (-width => $width, -height => $height);
  $image->rectangle (0,0, $width-1,$height-1, 'black');

  # -7/3 to +7/3
  my @lines = ([int($width * .29), int($height*.5),
                int($width * .71), int($height*.5)]);

  foreach my $level (1 .. 10) {
    my @new_lines;
    foreach my $line (@lines) {
      my ($x1,$y1, $x2,$y2) = @$line;
      my $dx = ($x2 - $x1) / 4;
      my $dy = ($y2 - $y1) / 4;
      push @new_lines, [ $x1 - $dx + $dy,
                         $y1 - $dy - $dx,
                         $x1 + $dx - $dy,
                         $y1 + $dy + $dx ];

      push @new_lines, [ $x1 + $dx - $dy,
                         $y1 + $dy + $dx,
                         $x2 - $dx + $dy,
                         $y2 - $dy - $dx ];

      push @new_lines, [ $x2 - $dx + $dy,
                         $y2 - $dy - $dx,
                         $x2 + $dx - $dy,
                         $y2 + $dy + $dx ];
    }
    # push @lines, @new_lines;
    @lines = @new_lines;
  }
  foreach my $line (@lines) {
    $image->line (@$line, 'white');
  }

  # $image->ellipse ($x_offset-2,$y_offset-2,
  #                  $x_offset+2,$y_offset+2, 'red');

  $image->save('/tmp/x.png');
  system('xzgv /tmp/x.png');

  exit 0;
}

{
  require Image::Base::GD;
  my $width = 1210;
  my $height = 810;
  my $x_offset = int($width * .3);
  my $y_offset = int($height * .2);
  my $image = Image::Base::GD->new (-width => $width, -height => $height);
  $image->rectangle (0,0, $width-1,$height-1, 'black');
  my $foreground = 'white';
  my $path = Math::PlanePath::Z2DragonCurve->new;

  my $scale = 10;
  foreach my $n (0 .. 100000) {
    next if $n % 4 == 3;
    my ($x1,$y1) = $path->n_to_xy($n);
    my ($x2,$y2) = $path->n_to_xy($n+1);
    $y1 = -$y1;
    $y2 = -$y2;
    $x1 *= $scale;
    $y1 *= $scale;
    $x2 *= $scale;
    $y2 *= $scale;
    $x1 += $x_offset;
    $x2 += $x_offset;
    $y1 += $y_offset;
    $y2 += $y_offset;
    $image->line ($x1,$y1, $x2,$y2, 'white');
  }

  $image->ellipse ($x_offset-2,$y_offset-2,
                   $x_offset+2,$y_offset+2, 'red');

  $image->save('/tmp/x.png');
  system('xzgv /tmp/x.png');

  exit 0;
}
