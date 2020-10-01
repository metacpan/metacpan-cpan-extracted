#!/usr/bin/perl -w

# Copyright 2020 Kevin Ryde

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


# Usage: perl peano-diagonal-samples.pl
#
# Print some of the PeanoDiagonals samples.
#

use 5.010;
use strict;
use FindBin;
use File::Spec;
use List::Util 'max';
use Math::NumSeq::Fibbinary;

use lib File::Spec->catdir($FindBin::Bin,
                           File::Spec->updir, 'devel/lib');
use Math::PlanePath::PeanoDiagonals;

# uncomment this to run the ### lines
# use Smart::Comments;


{
  my $path = Math::PlanePath::PeanoDiagonals->new;
  my $x_max = 9;
  foreach my $y (reverse 0 .. 9) {
    printf '    %3s | ', $y==0 ? "Y=0" : $y;
    foreach my $x (0 .. $x_max) {
      my @n_list = $path->xy_to_n_list($x,$y);
      my $width = ($x==0 ? 3 : 6);
      my $half = int($width/2);
      my $str = '';
      if (@n_list == 0) {
      } elsif (@n_list == 1) {
        $str = sprintf "%d%*s", $n_list[0], $half, '';
      } elsif (@n_list == 2) {
        $str = sprintf '%d,%-*d', $n_list[0], $half, $n_list[1];
      } else {
        die;
      }
      ### $x
      ### $y
      ### $str
      if ($x < $x_max) {
        length($str) <= $width or die "length";
      }
      printf '%*s', $width, $str;
    }
    print "\n";
  }
  print "        +", ('-' x (4+$x_max*6)), "\n";
  print "\n";
}

{
  my $path = Math::PlanePath::PeanoDiagonals->new (radix => 4);
  my %seen;
  my $x_max = 9;
  my $y_max = 8;
  foreach my $n (0 .. 4**6) {
    my ($x,$y) = $path->n_to_xy($n);
    next if $x > $x_max;
    next if $y > $y_max;
    push @{$seen{$x,$y}}, $n;
  }
  foreach my $y (reverse 0 .. $y_max) {
    foreach my $x (0 .. $x_max) {
      my $aref = $seen{$x,$y} || [];
      my $str = join(',',@$aref);
      printf ' %8s', $str;
    }
    print "\n";
  }
}
exit 0;
