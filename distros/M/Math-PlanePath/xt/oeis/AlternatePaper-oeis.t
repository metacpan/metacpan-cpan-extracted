#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
use Math::PlanePath::AlternatePaper 124;  # v.124 for n_to_n_list()
use List::Util 'min';
use Test;
plan tests => 16;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

# uncomment this to run the ### lines
# use Smart::Comments '###';

my $paper = Math::PlanePath::AlternatePaper->new;

require Math::NumSeq::PlanePathN;
my $bigclass = Math::NumSeq::PlanePathN::_bigint();


#------------------------------------------------------------------------------

# A068915   Y when N even, X when N odd
MyOEIS::compare_values
  (anum => 'A068915',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my ($x, $y) = $paper->n_to_xy ($n);
       push @got, ($n%2==0 ? $y : $x);
     }
     return \@got;
   });

# also equivalent to X when N even, Y when N odd, starting from N=1
MyOEIS::compare_values
  (anum => q{A068915},
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 1; @got < $count; $n++) {
       my ($x, $y) = $paper->n_to_xy ($n);
       push @got, ($n%2==0 ? $x : $y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------

# A080079   X-Y of last time on X+Y=s anti-diagonal
MyOEIS::compare_values
  (anum => 'A080079',
   func => sub {
     my ($count) = @_;
     my @got;
     my @occur;
     my $target = 1;
     for (my $n = $paper->n_start + 1; @got < $count; $n++) {
       my ($x, $y) = $paper->n_to_xy ($n);
       my $s = $x + $y;
       $occur[$s]++;
       if ($occur[$s] == $s) {
         push @got, $x-$y;
         $target++;
       }
     }
     return \@got;
   });

# A020991  N-1 of last time on X+Y=s anti-diagonal
MyOEIS::compare_values
  (anum => 'A020991',
   func => sub {
     my ($count) = @_;
     my @got;
     my @occur;
     my $target = 1;
     for (my $n = $paper->n_start + 1; @got < $count; $n++) {
       my ($x, $y) = $paper->n_to_xy ($n);
       my $s = $x + $y;
       $occur[$s]++;
       if ($occur[$s] == $s) {
         push @got, $n-1;
         $target++;
       }
     }
     return \@got;
   });

# A053645  Y of last time on X+Y=s anti-diagonal
MyOEIS::compare_values
  (anum => 'A053645',
   max_count => 500,    # because simple linear search
   func => sub {
     my ($count) = @_;
     my @got;
     my @occur;
     my $target = 1;
     for (my $n = $paper->n_start + 1; @got < $count; $n++) {
       my ($x, $y) = $paper->n_to_xy ($n);
       my $s = $x + $y;
       $occur[$s]++;
       if ($occur[$s] == $s) {
         push @got, $y;
         $target++;
       }
     }
     return \@got;
   });

# A053644  X of last time on X+Y=s anti-diagonal
MyOEIS::compare_values
  (anum => 'A053644',
   max_count => 500,    # because simple linear search
   func => sub {
     my ($count) = @_;
     my @got;
     my @occur = (-1);  # hack for s=0 occurring 1 time
     my $target = 0;
     for (my $n = $paper->n_start; @got < $count; $n++) {
       my ($x, $y) = $paper->n_to_xy ($n);
       my $s = $x + $y;
       $occur[$s]++;
       if ($occur[$s] == $s) {
         push @got, $x;
         $target++;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------

# A212591  N-1 of first time on X+Y=s anti-diagonal
# seq    0, 1, 2, 5, 8,  9, 10, 21, 32, 33, 34, 37, 40, 41, 42, 85
# N   0  1  2  3  6, 9, 10, 11, 22, ...
MyOEIS::compare_values
  (anum => 'A212591',
   max_count => 1000,    # because simple linear search
   func => sub {
     my ($count) = @_;
     my @got;
     my $target = 1;
     for (my $n = $paper->n_start + 1; @got < $count; $n++) {
       my ($x, $y) = $paper->n_to_xy ($n);
       my $s = $x + $y;
       if ($s == $target) {
         push @got, $n-1;
         $target++;
       }
     }
     return \@got;
   });

# A047849  N of first time on X+Y=2^k anti-diagonal
MyOEIS::compare_values
  (anum => 'A047849',
   max_count => 10,    # because simple linear search
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k=0; @got < $count; $k++) {
       my $s = 2**$k;
       my $min;
       foreach my $y (0 .. $s) {
         my $x = $s - $y;   # so x+y=s
         my @n_list = $paper->xy_to_n_list($x,$y);
         $min //= $n_list[0];
         $min = min(@n_list, $min);
       }
       push @got, $min;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# Skd segments in direction

foreach my $elem (['A005418',  1,0, 1],  # East
                  ['A051437',  0,1, 2],  # North
                  ['A122746', -1,0, 3],  # West
                  ['A007179', 0,-1, 1],  # South
                 ) {
  my ($anum, $want_dx,$want_dy, $initial_k) = @$elem;
  MyOEIS::compare_values
      (anum => $anum,
       max_count => 14,
       func => sub {
         my ($count) = @_;
         my $path = Math::PlanePath::AlternatePaper->new;
         my @got;
         for (my $k = $initial_k||0; @got < $count; $k++) {
           my ($n_lo,$n_hi) = $path->level_to_n_range($k);
           push @got, scalar(grep {
             my ($dx,$dy) = $path->n_to_dxdy($_);
             $dx==$want_dx && $dy==$want_dy
           } $n_lo .. $n_hi-1);
         }
         return \@got;
       });
}

#------------------------------------------------------------------------------
# A126684 - N single-visited points

MyOEIS::compare_values
  (anum => 'A126684',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::AlternatePaper->new;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my @n_list = $path->n_to_n_list($n);
       if (@n_list == 1) {
         push @got, $n;
       }
     }
     return \@got;
   });

# A176237 - N double-visited points
MyOEIS::compare_values
  (anum => 'A176237',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::AlternatePaper->new;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my @n_list = $path->n_to_n_list($n);
       if (@n_list == 2) {
         push @got, $n;
       }
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A274230 - area = doubles to N=2^k

MyOEIS::compare_values
  (anum => 'A274230',
   max_count => 14,
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::AlternatePaper->new;
     my @got;
     for (my $k = 0; @got < $count; $k++) {
       my ($n_lo,$n_hi) = $path->level_to_n_range($k);
       push @got, scalar(grep {
         my @n_list = $path->n_to_n_list($_);
         @n_list == 2;  # double-visited
       } $n_lo .. $n_hi);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A181666 - n XOR other(n) occurring

MyOEIS::compare_values
  (anum => 'A181666',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::Base::Digits;
     my $path = Math::PlanePath::AlternatePaper->new;
     my %seen;
     my @got;
     my $target_n = 256;
     for (my $n = 0; @got < $count || $n < $target_n; $n++) {
       my @n_list = $path->n_to_n_list($n);
       @n_list >= 2 or next;
       my $xor = $n_list[0] ^ $n_list[1];
       next if $seen{$xor}++;
       push @got, $xor/4;
       ($target_n) = Math::PlanePath::Base::Digits::round_up_pow($n,2);
     }
     @got = sort {$a<=>$b} @got;
     $#got = $count-1;
     return \@got;
   });


#------------------------------------------------------------------------------
# A001196 - N on X axis, base 4 digits 0,3 only

MyOEIS::compare_values
  (anum => 'A001196',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::AlternatePaper->new (arms => 3);
     my @got;
     for (my $x = $bigclass->new(0); @got < $count; $x++) {
       my $n = $path->xy_to_n($x,0);
       push @got, $n;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A077957 -- Y at N=2^k, being alternately 0 and 2^(k/2)

MyOEIS::compare_values
  (anum => 'A077957',
   max_count => 200,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $bigclass->new(2); @got < $count; $n *= 2) {
       my ($x,$y) = $paper->n_to_xy($n);
       push @got, $y;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A052955 single-visited points  to N=2^k
MyOEIS::compare_values
  (anum => 'A052955',
   max_value => 10_000,
   func => sub {
     my ($count) = @_;
     my @got = (1);  # extra initial 1
     for (my $k = 0; @got < $count; $k++) {
       push @got, MyOEIS::path_n_to_singles ($paper, 2**$k);
     }
     return \@got;
   });

# A052940 single-visited points  to N=4^k
MyOEIS::compare_values
  (anum => 'A052940',
   max_value => 10_000,
   func => sub {
     my ($count) = @_;
     my @got = (1);    # initial 1 instead of 2
     for (my $k = 1; @got < $count; $k++) {
       push @got, MyOEIS::path_n_to_singles ($paper, 4**$k);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A122746  area increment  to N=2^k
MyOEIS::compare_values
  (anum => 'A122746',
   max_value => 10_000,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k = 2; @got < $count; $k++) {
       push @got, (MyOEIS::path_enclosed_area($paper, 2**($k+1))
                   - MyOEIS::path_enclosed_area($paper, 2**$k));
     }
     return \@got;
   });


#------------------------------------------------------------------------------

# A028399  boundary to N=2*4^k
MyOEIS::compare_values
  (anum => 'A028399',
   max_value => 10_000,
   func => sub {
     my ($count) = @_;
     my @got = (0);
     for (my $k = 0; @got < $count; $k++) {
       push @got, MyOEIS::path_boundary_length($paper, 2*4**$k);
     }
     return \@got;
   });

# A131128  boundary to N=4^k
MyOEIS::compare_values
  (anum => 'A131128',
   max_value => 10_000,
   func => sub {
     my ($count) = @_;
     my @got = (1);
     for (my $k = 0; @got < $count; $k++) {
       push @got, MyOEIS::path_boundary_length($paper, 4**$k);
     }
     return \@got;
   });

# A027383  boundary/2 to N=2^k
# is also boundary length verticals or horizontals since boundary is half
# verticals and half horizontals
MyOEIS::compare_values
  (anum => 'A027383',
   max_value => 10_000,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k = 0; @got < $count; $k++) {
       push @got, MyOEIS::path_boundary_length($paper, 2**$k) / 2;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A060867  area  to N=2*4^k
MyOEIS::compare_values
  (anum => 'A060867',
   max_value => 10_000,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k = 1; @got < $count; $k++) {
       push @got, MyOEIS::path_enclosed_area($paper, 2*4**$k);
     }
     return \@got;
   });

# A134057  area  to N=4^k
MyOEIS::compare_values
  (anum => 'A134057',
   max_value => 10_000,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k = 0; @got < $count; $k++) {
       push @got, MyOEIS::path_enclosed_area($paper, 4**$k);
     }
     return \@got;
   });

# A027556  area*2  to N=2^k
MyOEIS::compare_values
  (anum => 'A027556',
   max_value => 10_000,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k = 0; @got < $count; $k++) {
       push @got, MyOEIS::path_enclosed_area($paper, 2**$k) * 2;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A106665 -- turn 1=left, 0=right
#   OFFSET=0 cf first turn at N=1 here

MyOEIS::compare_values
  (anum => 'A106665',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'AlternatePaper',
                                                 turn_type => 'Left');
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A090678 "non-squashing partitions" A088567 mod 2
# and A121241 which is 1,-1
# almost but not quite arms=2 turn_type=Left
# A121241 1,-1
# A110036 2,0,-2
# A110037 1,0,-1


# MyOEIS::compare_values
#   (anum => 'A090678',
#    func => sub {
#      my ($count) = @_;
#      require Math::NumSeq::PlanePathTurn;
#      my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'AlternatePaper,arms=2',
#                                                  turn_type => 'Left');
#      my @got = (1,1,1,0,0,1,0,1,0,1,1,0,1,0,0,1,0,1);
#      while (@got < $count) {
#        my ($i,$value) = $seq->next;
#        push @got, $value;
#      }
#      return \@got;
#    });

#------------------------------------------------------------------------------
# A020985 - Golay/Rudin/Shapiro is dX and dY alternately
# also is dSum in Math::NumSeq::PlanePathDelta

MyOEIS::compare_values
  (anum => q{A020985},
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $paper->n_start; @got < $count; ) {
       {
         my ($dx, $dy) = $paper->n_to_dxdy ($n++);
         push @got, $dx;
       }
       last unless @got < $count;
       {
         my ($dx, $dy) = $paper->n_to_dxdy ($n++);
         push @got, $dy;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A093573+1 - triangle of positions where cumulative=k
#   cumulative A020986 starts n=0 for GRS(0)=0  (A020985)
# 0,
# 1,  3,
# 2,  4,  6,
# 5,  7, 13, 15,
# 8, 12, 14, 16, 26,
# 9, 11, 17, 19, 25, 27
#
# cf diagonals
# 0
# 1
# 2, 4
# 3,7, 5
# 8, 6,14, 16
# 9,13, 15,27, 17

MyOEIS::compare_values
  (anum => 'A093573',
   func => sub {
     my ($count) = @_;
     my @got;
   OUTER: for (my $sum = 1; ; $sum++) {
       my @n_list;
       foreach my $y (0 .. $sum) {
         my $x = $sum - $y;
         push @n_list, $paper->xy_to_n_list($x,$y);;
       }
       @n_list = sort {$a<=>$b} @n_list;
       foreach my $n (@n_list) {
         last OUTER if @got >= $count;
         push @got, $n-1;
       }
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A020986 - GRS cumulative

# X+Y, starting from N=1 (doesn't have X+Y=0 for N=0)
MyOEIS::compare_values
  (anum => 'A020986',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $paper->n_start + 1; @got < $count; $n++) {
       my ($x, $y) = $paper->n_to_xy ($n);
       push @got, $x+$y;
     }
     return \@got;
   });

# is X coord undoubled, starting from N=2 (doesn't have X=0 for N=0)
MyOEIS::compare_values
  (anum => q{A020986},
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 2; @got < $count; $n += 2) {
       my ($x, $y) = $paper->n_to_xy ($n);
       push @got, $x;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A022155 - positions of -1, is S,W steps

MyOEIS::compare_values
  (anum => 'A022155',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $paper->n_start; @got < $count; $n++) {
       my ($dx,$dy) = $paper->n_to_dxdy($n);
       if ($dx < 0 || $dy < 0) {
         push @got, $n;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A203463 - positions of 1, is N,E steps

MyOEIS::compare_values
  (anum => 'A203463',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $paper->n_start; @got < $count; $n++) {
       my ($dx,$dy) = $paper->n_to_dxdy($n);
       if ($dx > 0 || $dy > 0) {
         push @got, $n;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A020990 - Golay/Rudin/Shapiro * (-1)^k cumulative, is Y coord undoubled,
# except N=0

MyOEIS::compare_values
  (anum => 'A020990',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 2; @got < $count; $n += 2) {
       my ($x, $y) = $paper->n_to_xy ($n);
       push @got, $y;
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => q{A020990},  # checking again
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $paper->n_start + 1; @got < $count; $n++) {
       my ($x, $y) = $paper->n_to_xy ($n);
       push @got, $x-$y;
     }
     return \@got;
   });

#------------------------------------------------------------------------------

exit 0;
