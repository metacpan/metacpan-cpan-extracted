#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

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

use 5.010;
use strict;
use Math::PlanePath::TerdragonMidpoint;

# uncomment this to run the ### lines
#use Smart::Comments;


my $path = Math::PlanePath::TerdragonMidpoint->new (arms => 1);
my @yx_to_dxdy;
foreach my $n (0 .. 3**10) {
  my ($x,$y) = $path->n_to_xy($n);

  my $to_n = $n;
  if (($n % 3) == 0) {
    $to_n = $n + 1;
  } elsif (($n % 3) == 2) {
    $to_n = $n - 1;
  }

  my ($to_x,$to_y) = $path->n_to_xy($to_n);
  my $dx = $to_x - $x;
  my $dy = $to_y - $y;

  my $k = 2*(12*($y%12) + ($x%12));
  $yx_to_dxdy[$k+0] = $dx;
  $yx_to_dxdy[$k+1] = $dy;
}
print_72(\@yx_to_dxdy);

sub print_72 {
  my ($aref) = @_;
  print "(";
  for (my $i = 0; $i < @$aref; ) {
    my $v1 = $aref->[$i++] // 'undef';
    my $v2 = $aref->[$i++] // 'undef';
    my $str = "$v1,$v2";
    if ($i != $#$aref) { $str .= ", " }
    my $width = (($i % 4) == 2 ? 6 : 6);
    printf "%-*s", $width, $str;
    if (($i % 12) == 0) { print "\n " }
  }
  print ");\n";
}

exit 0;
