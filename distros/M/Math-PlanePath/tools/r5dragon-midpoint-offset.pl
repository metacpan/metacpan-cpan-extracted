#!/usr/bin/perl -w

# Copyright 2012, 2013, 2017 Kevin Ryde

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
use Math::PlanePath::R5DragonMidpoint;


my $path = Math::PlanePath::R5DragonMidpoint->new (arms => 1);
my @yx_to_digdxdy;
foreach my $n (0 .. 5**10) {
  my ($x,$y) = $path->n_to_xy($n);

  my $digit = $n % 5;

  my $to_n = ($n-$digit)/5;
  my ($to_x,$to_y) = $path->n_to_xy($to_n);

  # (x+iy)*(1+2i) = x-2y + 2x+y
  ($to_x,$to_y) = ($to_x-2*$to_y, 2*$to_x+$to_y);

  my $dx = $to_x - $x;
  my $dy = $to_y - $y;

  my $k = 3*(10*($y%10) + ($x%10));

  my $v0 = $digit;
  my $v1 = $dx;
  my $v2 = $dy;
  if (defined $yx_to_digdxdy[$k+0] && $yx_to_digdxdy[$k+0] != $v0) {
    die "diff v0 $yx_to_digdxdy[$k+0] $v0  k=$k n=$n";
  }
  if (defined $yx_to_digdxdy[$k+1] && $yx_to_digdxdy[$k+1] != $v1) {
    die "diff v1 $yx_to_digdxdy[$k+1] $v1  k=$k n=$n";
  }
  if (defined $yx_to_digdxdy[$k+2] && $yx_to_digdxdy[$k+2] != $v2) {
    die "diff v2 $yx_to_digdxdy[$k+2] $v2  k=$k n=$n";
  }
  $yx_to_digdxdy[$k+0] = $v0;
  $yx_to_digdxdy[$k+1] = $v1;
  $yx_to_digdxdy[$k+2] = $v2;
}
print_table(\@yx_to_digdxdy);

sub print_table {
  my ($aref) = @_;
  print "(";
  for (my $i = 0; $i < @$aref; ) {
    my $v0 = $aref->[$i++] // 'undef';
    my $v1 = $aref->[$i++] // 'undef';
    my $v2 = $aref->[$i++] // 'undef';
    my $str = "$v0,$v1,$v2";
    if ($i != $#$aref) { $str .= ", " }
    printf "%-9s", $str;
    if (($i % (3*5)) == 0) { print "\n " }
  }
  print ");\n";
}

exit 0;
