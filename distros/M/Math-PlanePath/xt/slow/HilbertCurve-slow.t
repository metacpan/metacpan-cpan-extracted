#!/usr/bin/perl -w

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

use 5.004;
use strict;
use List::Util 'min','max';
use Test;
plan tests => 87;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use lib 'xt';
use MyOEIS;
use Memoize;

# uncomment this to run the ### lines
# use Smart::Comments;

use Math::PlanePath::HilbertCurve;

my $path = Math::PlanePath::HilbertCurve->new;

#------------------------------------------------------------------------------
# count of segments by direction claimed in the POD

{
  my %want = ('0,1'  => [ 0, 1, 4, 19, 64, 271, 1024, 4159, 16384, ], # dir=1=N
              '1,0'  => [ 0, 1, 5, 16, 71, 256, 1055, 4096, 16511, ], # dir=2=E
              '0,-1' => [ 0, 0, 4, 12, 64, 240, 1024, 4032, 16384, ], # dir=3=S
              '-1,0' => [ 0, 1, 2, 16, 56, 256,  992, 4096, 16256, ], # dir=4=W
             );
  my %count = ('0,1'  => 0,
               '1,0'  => 0,
               '0,-1' => 0,
               '-1,0' => 0);
  my $n = 0;
  
  foreach my $k (0 .. $#{$want{'0,1'}}) {
    my $n_end = 4**$k-1;
    while ($n < $n_end) {
      my ($dx,$dy) = $path->n_to_dxdy($n++);
      $count{"$dx,$dy"}++;
      ### count: "n=$n  $dx,$dy"
    }
    ### count now: "$count{'0,1'}, $count{'1,0'} $count{'0,-1'} $count{'-1,0'}"

    foreach my $dxdy (keys %want) {
      my $pod = $want{$dxdy}->[$k];
      my $count = $count{$dxdy};
      ok ($pod, $count, "$dxdy samples");
      my $func = c_func($dxdy,$k);
      ok ($func, $count, "$dxdy func=$func count=$count");
    }
  }
}
sub c_func {
  my ($dxdy, $k) = @_;
  if ($dxdy eq '0,1') {  # dir=1=N
    if ($k == 0) { return 0; }
    if ($k % 2) { return 4**($k-1) + 2**($k-1) - 1; }
    return               4**($k-1);
  }
  if ($dxdy eq '1,0') {  # dir=2=E
    if ($k == 0) { return 0; }
    if ($k % 2) { return 4**($k-1); }
    return               4**($k-1) + 2**($k-1) - 1;
  }
  if ($dxdy eq '0,-1') {  # dir=3=S
    if ($k == 0) { return 0; }
    if ($k % 2) { return 4**($k-1) - 2**($k-1); }
    return               4**($k-1);
  }
  if ($dxdy eq '-1,0') {  # dir=4=W
    if ($k == 0) { return 0; }
    if ($k % 2) { return 4**($k-1); }
    return               4**($k-1) - 2**($k-1);
  }
}

#------------------------------------------------------------------------------
exit 0;
