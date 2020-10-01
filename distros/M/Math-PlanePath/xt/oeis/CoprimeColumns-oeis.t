#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2020 Kevin Ryde

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
plan tests => 8;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::CoprimeColumns;

# uncomment this to run the ### lines
# use Smart::Comments '###';

my $path = Math::PlanePath::CoprimeColumns->new;


#------------------------------------------------------------------------------
# A127368 - Y coordinate of coprimes, 0 for non-coprimes

MyOEIS::compare_values
  (anum => 'A127368',
   func => sub {
     my ($count) = @_;
     my @got;
   OUTER: for (my $x = 1; ; $x++) {
       foreach my $y (1 .. $x) {
         push @got, ($path->xy_is_visited($x,$y) ? $y : 0);
         last OUTER if @got >= $count;
       }
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A179594 - column of nxn unvisited block
#   is X here but Y in A179594 since it goes as rows of coprimes rather than
#   columns

MyOEIS::compare_values
  (anum => 'A179594',
   max_count => 3,
   func => sub {
     my ($count) = @_;
     my @got;
     my $x = 1;
     for (my $size = 1; @got < $count; $size++) {
       for ( ; ! have_unvisited_square($x,$size); $x++) {
       }
       push @got, $x;
     }
     return \@got;
   });

# return true if there's a $size by $size unvisited square somewhere in
# column $x
sub have_unvisited_square {
  my ($x, $size) = @_;
  ### have_unvisited_square(): $x,$size
  my $count = 0;
  foreach my $y (2 .. $x) {
    if (have_unvisited_line($x,$y,$size)) {
      $count++;
      if ($count >= $size) {
        ### found at: "x=$x, y=$y  count=$count"
        return 1;
      }
    } else {
      $count = 0;
    }
  }
  return 0;
}

# return true if $x,$y is the start (the leftmost point) of a $size length
# line of unvisited points
sub have_unvisited_line {
  my ($x,$y, $size) = @_;
  foreach my $i (0 .. $size-1) {
    if ($path->xy_is_visited($x,$y)) {
      return 0;
    }
    $x++;
  }
  return 1;
}

#------------------------------------------------------------------------------
# A002088 - totient sum along X axis, or diagonal of n_start=1

MyOEIS::compare_values
  (anum => 'A002088',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::CoprimeColumns->new (n_start => 1);
     my @got = (0, 1);
     for (my $x = 2; @got < $count; $x++) {
       push @got, $path->xy_to_n($x,$x-1);
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => q{A002088},
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $x = 1; @got < $count; $x++) {
       push @got, $path->xy_to_n($x,1);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A054428 - inverse, permutation SB N -> coprime columns N

MyOEIS::compare_values
  (anum => 'A054428',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::PlanePath::RationalsTree;
     my $sb = Math::PlanePath::RationalsTree->new (tree_type => 'SB');
     for (my $n = 0; @got < $count; $n++) {
       my $sn = insert_second_highest_bit_one($n);
       my ($x,$y) = $sb->n_to_xy ($sn);
       ### sb: "$x/$y"
       my $cn = $path->xy_to_n($x,$y);
       if (! defined $cn) {
         die "oops, SB $x,$y";
       }
       push @got, $cn+1;
     }
     return \@got;
   });

sub insert_second_highest_bit_one {
  my ($n) = @_;
  my $str = sprintf ('%b', $n);
  substr($str,1,0) = '1';
  return oct("0b$str");
}
# # ### assert: delete_second_highest_bit(1) == 1
# # ### assert: delete_second_highest_bit(2) == 1
# ### assert: delete_second_highest_bit(4) == 2
# ### assert: delete_second_highest_bit(5) == 3


#------------------------------------------------------------------------------
# A054427 - permutation coprime columns N -> SB N

MyOEIS::compare_values
  (anum => 'A054427',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::PlanePath::RationalsTree;
     my $sb = Math::PlanePath::RationalsTree->new (tree_type => 'SB');
     my $n = 0;
     while (@got < $count) {
       my ($x,$y) = $path->n_to_xy ($n++);
       ### frac: "$x/$y"
       my $sn = $sb->xy_to_n($x,$y);
       push @got, delete_second_highest_bit($sn) + 1;
     }
     return \@got;
   });

sub delete_second_highest_bit {
  my ($n) = @_;
  my $bit = 1;
  my $ret = 0;
  while ($bit <= $n) {
    $ret |= ($n & $bit);
    $bit <<= 1;
  }
  $bit >>= 1;
  $ret &= ~$bit;
  $bit >>= 1;
  $ret |= $bit;
  # ### $ret
  # ### $bit
  return $ret;
}
# ### assert: delete_second_highest_bit(1) == 1
# ### assert: delete_second_highest_bit(2) == 1
### assert: delete_second_highest_bit(4) == 2
### assert: delete_second_highest_bit(5) == 3

#------------------------------------------------------------------------------
# A121998 - list of <=k with a common factor

MyOEIS::compare_values
  (anum => 'A121998',
   func => sub {
     my ($count) = @_;
     my @got;
   OUTER: for (my $x = 2; ; $x++) {
       for (my $y = 1; $y <= $x; $y++) {
         if (! $path->xy_is_visited($x,$y)) {
           push @got, $y;
           last OUTER unless @got < $count;
         }
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A054521 - by columns 1 if coprimes, 0 if not

MyOEIS::compare_values
  (anum => 'A054521',
   func => sub {
     my ($count) = @_;
     my @got;
   OUTER: for (my $x = 1; ; $x++) {
       foreach my $y (1 .. $x) {
         if ($path->xy_is_visited($x,$y)) {
           push @got, 1;
         } else {
           push @got, 0;
         }
         last OUTER if @got >= $count;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
