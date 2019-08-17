#!/usr/bin/perl -w

# Copyright 2012, 2013, 2015, 2018, 2019 Kevin Ryde

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
use Test;
plan tests => 12;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::KochCurve;


#------------------------------------------------------------------------------
# A016153 - area under the curve, (9^n-4^n)/5

MyOEIS::compare_values
  (anum => 'A016153',
   max_value => 100_000,
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::KochCurve->new;
     my @got;
     for (my $k = 0; @got < $count; $k++) {
       my @points;
       my ($n_lo, $n_hi) = $path->level_to_n_range($k);
       foreach my $n ($n_lo .. $n_hi) {
         my ($x,$y) = $path->n_to_xy($n);
         push @points, [$x,$y];
       }
       push @got, points_to_area(\@points);
     }
     return \@got;
   });

sub points_to_area {
  my ($points) = @_;
  if (@$points < 3) {
    return 0;
  }
  require Math::Geometry::Planar;
  my $polygon = Math::Geometry::Planar->new;
  $polygon->points($points);
  return $polygon->area;
}

#------------------------------------------------------------------------------
# A002450 number of right turns N=1 to N < 4^k
#
#        2
#       / \     /
#  0---1   3---4

# A020988 number of left turns N=1 to N < 4^k  = (2/3)*(4^n-1).
# duplicate A084180
MyOEIS::compare_values
  (anum => 'A020988',
   max_value => 100_000,
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'KochCurve',
                                                 turn_type => 'Left');
     my @got;
     my $total = 0;
     my $target = 1;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       if ($i == $target) {
         push @got, $total;
         $target *= 4;
       }
       $total += $value;
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A002450',
   max_value => 100_000,
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'KochCurve',
                                                 turn_type => 'Right');
     my @got;
     my $total = 0;
     my $target = 1;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       if ($i == $target) {
         push @got, $total;
         $target *= 4;
       }
       $total += $value;
     }
     return \@got;
   });



#------------------------------------------------------------------------------
# A177702 - abs(dX) from N=1 onwards, repeating 1,1,2

MyOEIS::compare_values
  (anum => 'A177702',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::PlanePathDelta;
     my $seq = Math::NumSeq::PlanePathDelta->new (planepath => 'KochCurve',
                                                  delta_type => 'AbsdX');
     $seq->seek_to_i(1);
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A217586
# Not quite turn sequence ...
# differs 0<->1 at n=2^k
#
# a(1) = 1
# if a(n) = 0 then a(2*n) = 1 and a(2*n+1) = 0     # opposite low bit
# if a(n) = 1 then a(2*n) = 0 and a(2*n+1) = 0     # both 0
#
# a(2n+1)=0           # odd always left
# a(2n) = 1-a(n)      # even 0 or 1 as odd or even
# a(4n) = 1-a(2n) = 1-(1-a(n)) = a(n)
# a(4n+2) = 1-a(2n+1) = 1-0 = 1       # 4n+2 always right
# except a(0+2) = 1-a(1) = 1-1 = 0


# A  Right    N    differ
# 1  0         1    *
# 0  1        10    *
# 0  0        11
# 1  0       100    *
# 0  0       101
# 1  1       110
# 0  0       111
# 0  1      1000    *
# 0  0      1001
# 1  1      1010
# 0  0      1011
# 0  0      1100
# 0  0      1101
# 1  1      1110
# 0  0      1111
# 1  0     10000    *
# 0  0
# 1  1
# 0  0
# 0  0
# 0  0
# 1  1
# 0  0
# 1  1

MyOEIS::compare_values
  (anum => q{A217586},
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'KochCurve',
                                                 turn_type => 'Right');
     my @got;
     while (@got < $count) {
       # $seq->next;
       my ($i,$value) = $seq->next;
       if (is_pow2($i)) { $value ^= 1; }
       push @got, $value;
       # push @got, A217586_func($i)
     }
     return \@got;
   });

sub A217586_func {
  my ($n) = @_;
  if ($n < 1) {
    die "A217586_func() must have n>=1";
  }

  {
    while (($n & 3) == 0) {
      $n >>= 2;
    }
    if ($n == 1) {
      return 1;
    }
    if (($n & 3) == 2) {
      if ($n == 2) { return 0; }
      else { return 1; }
    }
    if ($n & 1) {
      return 0;
    }
  }

  # {
  #   if ($n == 1) {
  #     return 1;
  #   }
  #   if (A217586_func($n >> 1)) {
  #     if ($n & 1) {
  #       return 0;
  #     } else {
  #       return 0;
  #     }
  #   } else {
  #     if ($n & 1) {
  #       return 0;
  #     } else {
  #       return 1;
  #     }
  #   }
  # }
  #
  # {
  #   if ($n == 1) {
  #     return 1;
  #   }
  #   my $bit = $n & 1;
  #   if (A217586_func($n >> 1)) {
  #     return 0;
  #   } else {
  #     return $bit ^ 1;
  #   }
  # }
}

sub is_pow2 {
  my ($n) = @_;
  while ($n > 1) {
    if ($n & 1) {
      return 0;
    }
    $n >>= 1;
  }
  return ($n == 1);
}

#------------------------------------------------------------------------------
# A035263 is turn left=1,right=0 at OFFSET=1
# morphism 1 -> 10, 0 -> 11

MyOEIS::compare_values
  (anum => 'A035263',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'KochCurve',
                                                 turn_type => 'Left');
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });

# also left=0,right=1 at even N
MyOEIS::compare_values
  (anum => q{A035263},
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'KochCurve',
                                                 turn_type => 'Right');
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       if (($i & 1) == 0) {
         push @got, $value;
       }
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A073059 a(4k+3)= 1                      ..11       = 1
#         a(4k+2) = a(4k+4) = 0           ..00 ..10  = 0
#         a(16k+13) = 1                   1101
#         a(4n+1) = a(n)                  ..01       = base4 above
# a(n) = 1-A035263(n-1)  is Koch 1=left,0=right by morphism OFFSET=1
# so A073059 is next turn 0=left,1=right

# ???
#
# MyOEIS::compare_values
#   (anum => q{A073059},
#    func => sub {
#      my ($count) = @_;
#      require Math::NumSeq::PlanePathTurn;
#      my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'KochCurve',
#                                                  turn_type => 'Left');
#      my @got = (0);
#      while (@got < $count) {
#        $seq->next;
#        my ($i,$value) = $seq->next;
#        push @got, $value;
#      }
#      return \@got;
#    });


#------------------------------------------------------------------------------
# A096268 - morphism turn 1=right,0=left
#   but OFFSET=0 is turn at N=1

MyOEIS::compare_values
  (anum => 'A096268',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'KochCurve',
                                                 turn_type => 'Right');
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A029883 - Thue-Morse first diffs

MyOEIS::compare_values
  (anum => 'A029883',
   fixup => sub {
     my ($bvalues) = @_;
     @$bvalues = map {abs} @$bvalues;
   },
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'KochCurve',
                                                 turn_type => 'Left');
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A089045 - +/- increment

MyOEIS::compare_values
  (anum => 'A089045',
   fixup => sub {
     my ($bvalues) = @_;
     @$bvalues = map {abs} @$bvalues;
   },
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'KochCurve',
                                                 turn_type => 'Left');
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A003159 - N end in even number of 0 bits, is positions of left turn

MyOEIS::compare_values
  (anum => 'A003159',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'KochCurve',
                                                 turn_type => 'Left');
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       if ($value == 1) {  # left
         push @got, $i;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A036554 - N end in odd number of 0 bits, position of right turns

MyOEIS::compare_values
  (anum => 'A036554',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'KochCurve',
                                                 turn_type => 'Right');
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       if ($value == 1) {  # right
         push @got, $i;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
