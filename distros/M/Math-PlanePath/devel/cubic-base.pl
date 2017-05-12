#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

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
use warnings;
use List::MoreUtils;
use POSIX 'floor';
use Math::Libm 'M_PI', 'hypot';
use List::Util 'min', 'max';
use Math::BaseCnv 'cnv';

use lib 'xt';

# uncomment this to run the ### lines
use Smart::Comments;


{
  # smallest hypot in each level
  require Math::PlanePath::CubicBase;
  require Math::NumSeq::PlanePathDelta;
  my $tdir6_func = \&Math::NumSeq::PlanePathDelta::_delta_func_TDir6;

  my $radix = 2;
  my $path = Math::PlanePath::CubicBase->new (radix => $radix);
  foreach my $level (1 .. 30) {
    my $n_lo = $radix ** ($level-1);
    my $n_hi = $radix ** $level - 1;
    my $n = $n_lo;
    my $min_h = $path->n_to_rsquared($n);
    my @min_n = ($n);
    for ($n++; $n < $n_hi; $n++) {
      my $h = $path->n_to_rsquared($n);
      if ($h < $min_h) {
        @min_n = ($n);
        $min_h = $h;
      } elsif ($h == $min_h) {
        push @min_n, $n;
      }
    }
    print "level=$level\n";
    # print "  n=${n_lo}to$n_hi\n";
    print "  min_h=$min_h\n";
    foreach my $n (@min_n) {
      my $nr = cnv($n,10,$radix);
      my ($x,$y) = $path->n_to_xy($n);
      my $xr = cnv($x,10,$radix);
      my $yr = cnv($y,10,$radix);
      my $tdir6 = $tdir6_func->(0,0,$x,$y);
      print "  n=$n  $nr  xy=$x,$y $xr,$yr  tdir6=$tdir6 \n";
      
    }
  }
  exit 0;

  sub path_n_to_trsquared {
    my ($path,$n) = @_;
    my ($x,$y) = $path->n_to_xy($n);
    return $x*$x+3*$y*$y;
  }
}

{
  # Dir4 maximum
  require Math::PlanePath::CubicBase;
  require Math::NumSeq::PlanePathDelta;
  require Math::BigInt;
  my $path = Math::PlanePath::CubicBase->new;
  my $seq = Math::NumSeq::PlanePathDelta->new (planepath => 'CubicBase',
                                               delta_type => 'Dir4');
  my $dir4_max = 0;
  foreach my $level (0 .. 600) {
    my $n = Math::BigInt->new(2)**$level - 1;
    my $dir4 = $seq->ith($n);
    if (1 || $dir4 > $dir4_max) {
      $dir4_max = $dir4;
      my ($dx,$dy) = $path->n_to_dxdy($n);
      printf "%3d  %2b,\n    %2b %8.6f\n", $n, abs($dx),abs($dy), $dir4;
    }
  }
  exit 0;
}
