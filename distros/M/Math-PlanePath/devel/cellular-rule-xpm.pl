#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

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

use strict;
use Image::Base::PNGwriter;
use List::Util 'min', 'max';

# uncomment this to run the ### lines
#use Devel::Comments;

my $white = '#FFFFFF';
$white = 'white';
my $class = 'Image::Base::PNGwriter';
$class = 'Image::Xpm';
eval "require $class; 1" or die;

my $rule = 30;
my @table = map {($rule & (1<<$_)) ? 1 : 0} 0 .. 7;
print join(',',@table),"\n";

my $height = 500;
my $width = 2*$height;
my $image = $class->new (-width => $width, -height => $height);
$image->rectangle(0,0,$width-1,$height-1, 'black', 1);

# $image->xy($size-2,0,$white);    # right
$image->xy(int(($width-1)/2),0,$white);  # centre

foreach my $y (1..$height-1) {
  foreach my $x (0 .. $width-1) {
    my $p = 0;
    foreach my $o (-1,0,1) {
      $p *= 2;
      ### x: $x+$o
      ### y: $y-1
      ### cell: $image->xy($x+$o,$y-1)
      ### cell: $image->xy($x+$o,$y-1) eq $white
      $p += ($image->xy(min(max($x+$o,0),$width-1),$y-1) eq $white);
    }
    ### $p
    if ($table[$p]) {
      $image->xy($x,$y,'white');
    }
  }
}
$image->save('/tmp/x');
system ('xzgv /tmp/x');
exit 0;

# vec()
