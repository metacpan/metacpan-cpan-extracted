#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2015, 2019, 2020 Kevin Ryde

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
use List::Util 'sum';
use Math::BigInt try => 'GMP';
use Test;
plan tests => 23;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::NumSeq::BalancedBinary;
use Math::PlanePath::SierpinskiTriangle;

use Math::PlanePath::KochCurve;
*_digit_join_hightolow = \&Math::PlanePath::KochCurve::_digit_join_hightolow;

# uncomment this to run the ### lines
# use Smart::Comments '###';


# {
#   my $path = Math::PlanePath::SierpinskiTriangle->new;
#   print branch_reduced_breadth_bits($path,4);
#   exit 0;
# }

#------------------------------------------------------------------------------
# Helpers
{
  my $bal = Math::NumSeq::BalancedBinary->new;

  # $aref is an arrayref of 1,0 bits.
  sub dyck_bits_to_index {
    my ($aref) = @_;
    my $value = _digit_join_hightolow($aref, 2, Math::BigInt->new(0));
    return $bal->value_to_i($value);
  }
}
sub CountLowZeros {
  my ($n) = @_;
  my $ret = 0;
  until ($n & 1) {
    $n>>=1; $ret++;
    $n or die;
  }
  return $ret;
}
sub CountOnes {
  my ($n) = @_;
  my $ret = 0;
  while ($n) {
    $ret += $n&1; $n>>=1;
  }
  return $ret;
}


#------------------------------------------------------------------------------
# A001316 - Gould's sequence, number of 1s in each row

MyOEIS::compare_values
  (anum => 'A001316',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::SierpinskiTriangle->new;
     my @got;
     my $prev_y = 0;
     my $num = 0;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       if ($y == $prev_y) {
         $num++;
       } else {
         push @got, $num;
         $prev_y = $y;
         $num = 1;
       }
     }
     return \@got;
   });

# cf Sierpinski Graph
# A233775 - num vertices across a row
# each N is a unit triangle
#
#      *-----*-----*
#       \ N / \N+1/        Y
#        \ /   \ /                           any of  X,Y visited,
#         X-----*    <--- row of vertices        or X-1,Y-1   below
#          \ 1 /           Y-1                   or X+1,Y-1   below
#           \ /
#            *
MyOEIS::compare_values
  (anum => 'A233775',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::SierpinskiTriangle->new;
     my @got;
     for (my $y = 0; @got < $count; $y++) {
       my $count = 0;
       for (my $x = -$y; $x <= $y; $x+=2) {
         if ($path->xy_is_visited    ($x,$y)
             || $path->xy_is_visited ($x-1,$y-1)
             || $path->xy_is_visited ($x+1,$y-1)) {
           $count++;
         }
       }
       push @got, $count;
     }
     return \@got;
   });

# Johan Falk has this as (2^CountLowZeros(n) + 1) * 2^(CountOnes(n)-1)
MyOEIS::compare_values
  (anum => q{A233775},
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::SierpinskiTriangle->new;
     my @got = (1);
     for (my $n = 1; @got < $count; $n++) {
       push @got, (2**CountLowZeros($n) + 1) * 2**(CountOnes($n)-1);
     }
     return \@got;
   });
# GP-DEFINE  CountLowZeros(n) = valuation(n,2);
# GP-DEFINE  CountOnes(n) = hammingweight(n);
# GP-DEFINE  A233775(n) = {
# GP-DEFINE    if(n==0,1, (2^CountLowZeros(n) + 1) * 2^(CountOnes(n)-1));
# GP-DEFINE  }
#  my(v=OEIS_samples("A233775")); vector(#v,n,n--;A233775(n)) == v
# GP-Test  vector(8,k, vector(2^k-1,n, A233775(2^k + n))) == \
# GP-Test  vector(8,k, vector(2^k-1,n, 2*A233775(n)))
# GP-Test  vector(8,k, A233775(2^k)) == \
# GP-Test  vector(8,k, 2^k + 1)
# GP-Test  A233775(0) == 0 + 1

# GP-DEFINE  ShuffleVector(v) = {
# GP-DEFINE    forstep(i=#v,1,-1,
# GP-DEFINE      if(v[i],
# GP-DEFINE        v=concat(v[i..#v],select(b->b, v[1..i-1]));
# GP-DEFINE        break));
# GP-DEFINE    v;
# GP-DEFINE  }
# GP-Test  ShuffleVector([1,0,1,0,0]) == [1,0,0, 1]
# GP-Test  ShuffleVector([1,0,1,1,0,0,0]) == [1,0,0,0, 1,1]
# GP-Test  ShuffleVector([1,1,0,1,0,0,1,1]) == [1, 1,1,1,1]
# GP-Test  ShuffleVector([1,0,1,1,0,1,0,0,0]) == [1,0,0,0,1,1,1]
# GP-DEFINE  ShuffleOnes(n) = fromdigits(ShuffleVector(binary(n)),2);
# GP-Test  vector(2^12,n,n--; A233775(n)) == \
# GP-Test  vector(2^12,n,n--; ShuffleOnes(n) + 1)

# vector(15,n, ShuffleOnes(n))
# not in OEIS: 1, 2, 3, 4, 3, 5, 7, 8, 3, 5, 7, 9, 7, 11, 15


#------------------------------------------------------------------------------
# A130047 - left half Pascal mod 2

MyOEIS::compare_values
  (anum => 'A130047',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::SierpinskiTriangle->new;
     my @got;
     for (my $y = 0; @got < $count; $y++) {
       for (my $x = -$y; $x <= 0 && @got < $count; $x += 2) {
         push @got, $path->xy_is_visited($x,$y) ? 1 : 0;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# Branch-reduced breadth-wise
#
# Nodes with just 1 child are collapsed out.
# cf Homeomorphic same if dropping/adding single-child nodes
#
# A080318 decimal
# A080319 binary
# A080320 positions in A014486 list of balanced
#
#         10,  branch reduced
#         111000,
#         11111110000000,
#         1111111-11000011-0000000,
#         11111111100001111111111000000000000000,
#
#  . .
#   *
#  plain 10
#
#  . . . .
#
#   *   *
#    \ /
#     *
#  plain 111000
#
#   . .     . .
#
#    *  . .  *
#     \     /             . . . .
#      *   *               *   *
#       \ /                 \ /
#        *                   *
#  plain 1111001000       reduced 111000
#
#   . . . . . . . .
#    *   *   *   *
#     \ /     \ /         . . .... ..
#      *  . .  *           *  * *  *
#       \     /             \ / \ /
#        *   *               *   *
#         \ /                 \ /
#          *                   *
#  plain                  reduced 11111110000000
#
# . .             . .
#  *               *
#   \ . . . . . . /
#    *   *   *   *
#     \ /     \ /
#      *  . .  *
#       \     /
#        *   *
#         \ /
#          *
#
# . . . .         . . . .
#  *   *           *   *
#   \ /             \ /
#    *               *
#     \ . . . . . . /            . . . . . . . .   7 trailing
#      *   *   *   *              *   *   *   *
#       \ /     \ /                \ / ....\ /
#        *  . .  *                  *  * *  *
#         \     /                    \ / \ /
#          *   *                      *   *
#           \ /                        \ /
#            *                          *
#                               reduced 1111111110000110000000
#
#   *       *       *       *
#    \ . . /         \ . . /
#     *   *           *   *
#      \ /             \ /
#       *               *
#        \ . . . . . . /
#         *   *   *   *
#          \ /     \ /
#           *  . .  *
#            \     /
#             *   *
#              \ /
#               *
#
# *   *   *   *   *   *   *   *
#  \ /     \ /     \ /     \ /
#   *       *       *       *
#    \ . . /         \ . . /
#     *   *           *   *
#      \ /             \ /        .. .. ............   15 trailing
#       *               *          *  * * * * * *  *
#        \ . . . . . . /            \ / \/  \/   \/
#         *   *   *   *              *   *   *   *
#          \ /     \ /                \ / ....\ /
#           *  . .  *                  *  * *  *
#            \     /                    \ / \ /
#             *   *                      *   *
#              \ /                        \ /
#               *                          *
#                       reduced 11111111100001111111111000000000000000
#
# 1111111110000111111111111000000000000110000000
# 11111111100001111111111110000000000001111111111000000000000000
#   [9]     [4]     [12]        [12]      [10]      [15]#
#
# 331698516757016399905370236824584576
# 11111111100001111111111110000000000001111111111110000111100001111111\
# 11111111111110000000000000000000000000000110000000



# 2  0 0 0 0 0 0  2    2  0 0 0 0 0 0  2
# 11   2   2   2   2        2   2   2   2
# 10     2  0 0  2            2  0 0  2
#  9       2   2   0 0   0 0    2   2
##  6        2      2     2       2
#  5            2  0     0    2
#  3               2     2
#  2                  2
#  0

{
  # double-up check
  my ($one) = MyOEIS::read_values('A080268');
  my ($two) = MyOEIS::read_values('A080318');
  my $path = Math::PlanePath::SierpinskiTriangle->new;
  require Math::BigInt;
  for (my $i = 0; $i <= $#$one && $i+1 <= $#$two; $i++) {
    my $o = $one->[$i];
    my $t = $two->[$i+1];
    my $ob = Math::BigInt->new("$o")->as_bin;
    $ob =~ s/^0b//;
    my $o2 = $ob;
    $o2 =~ s/(.)/$1$1/g;  # double
    $o2 = "1".$o2."0";
    my $tb = Math::BigInt->new("$t")->as_bin;
    $tb =~ s/^0b//;
    # print "o  $o\nob $ob\no2 $o2\ntb $tb\n\n";
    $tb eq $o2 or die "x";
  }
}


# decimal, by path
MyOEIS::compare_values
  (anum => 'A080318',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::SierpinskiTriangle->new;
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       ### $depth
       my @bits = branch_reduced_breadth_bits($path, $depth);
       ### @bits
       push @got, _digit_join_hightolow(\@bits, 2, Math::BigInt->new(0));
     }
     return \@got;
   });

# binary, by path
MyOEIS::compare_values
  (anum => 'A080319',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::SierpinskiTriangle->new;

     # foreach my $depth (0 .. 11) {
     #   my @bits = branch_reduced_breadth_bits($path, $depth);
     #   print @bits,"\n";
     # }

     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       my @bits = branch_reduced_breadth_bits($path, $depth);
       push @got, _digit_join_hightolow(\@bits, 10, Math::BigInt->new(0));
     }
     return \@got;
   });

# position in list of all balanced binary (A014486)
MyOEIS::compare_values
  (anum => 'A080320',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::SierpinskiTriangle->new;
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       my @bits = branch_reduced_breadth_bits($path, $depth);
       push @got, dyck_bits_to_index(\@bits);
     }
     return \@got;
   });

# Return a list of 0,1 bits.
#
sub branch_reduced_breadth_bits {
  my ($path, $limit) = @_;
  my @pending_n = ($path->n_start);
  my @ret;
  foreach (0 .. $limit) {
    ### pending_n: join(',',map{$_//'undef'}@pending_n)
    my @new_n;
    foreach my $n (@pending_n) {
      if (! defined $n) {
        push @ret, 0;
        next;
      }
      my ($x,$y) = $path->n_to_xy($n);
      push @ret, 1;

      $y += 1;
      foreach my $dx (-1, 1) {
        my $n_child = $path->xy_to_n($x+$dx,$y);
        if (defined $n_child) {
          $n_child = path_tree_n_branch_reduce($path,$n_child);
        }
        push @new_n, $n_child;
      }
    }
    @pending_n = @new_n;
  }

  ### final ...
  ### pending_n: join(',',map{$_//'undef'}@pending_n)
  ### ret: join('',@ret) . ' ' .('0' x $#pending_n)

  return @ret, ((0) x $#pending_n);
}

# sub path_tree_n_branch_reduced_children {
#   my ($path, $n) = @_;
#   for (;;) {
#     my @n_children = $path->tree_n_children($n);
#     if (@n_children != 1) {
#       return @n_children;
#     }
#     $n = $n_children[0];
#   }
# }

# If $n has only 1 child then descend through it and any further
# 1-child nodes to return an N which has 2 or more children.
# If all the descendents of $n are 1-child then return undef.
sub path_tree_n_branch_reduce {
  my ($path, $n) = @_;
  my @n_children = $path->tree_n_children($n);
  if (@n_children == 1) {
    do {
      $n = $n_children[0];
      @n_children = $path->tree_n_children($n) or return undef;
    } while (@n_children == 1);
  }
  return $n;
}

# Return $x,$y moved down to a "branch reduced" position, if necessary.
# A branch reduced tree has all nodes as either leaves or with 2 or more
# children.  If $x,$y has only 1 child then follow down that child node and
# any 1-child nodes below, until reaching a 0 or 2 or more node.  If $x,$y
# already has 0 or 2 or more then it's returned unchanged.
#
sub path_tree_xy_branch_reduced {
  my ($path, $x,$y) = @_;
  for (;;) {
    my @xy_list = path_tree_xy_children($path, $x,$y);
    if (@xy_list == 2) {
      ($x,$y) = @xy_list;   # single child, descend
    } else {
      last;    # multiple children or nothing, return this $x,$y
    }
  }
  return ($x,$y);
}

# Return a list ($x1,$y1, $x2,$y2, ...) which are the children of $x,$y.
sub path_tree_xy_children {
  my ($path, $x,$y) = @_;
  return map {$path->n_to_xy($_)}
    map {$path->tree_n_children($_)}
      $path->xy_to_n_list($x,$y);
}

# Return the number of children of $x,$y, or undef if $x,$y is not visited.
sub path_tree_xy_num_children {
  my ($path, $x,$y) = @_;
  my $n = $path->xy_to_n($x,$y);
  if (! defined $n) { return undef; }
  return $path->tree_n_num_children($path,$n);
}

# Return true if $x,$y is a leaf node, ie. has no children.
sub path_tree_xy_is_leaf {
  my ($path, $x,$y) = @_;
  my $n = $path->xy_to_n($x,$y);
  if (! defined $n) { return undef; }
  return path_tree_n_is_leaf($path,$n);
}

# Return true if $n is a leaf node, ie. has no children.
sub path_tree_n_is_leaf {
  my ($path, $n) = @_;
  my $num_children = $path->tree_n_num_children($n);
  if (! defined $num_children) { return undef; }
  return $num_children == 0;
}

# Return a list of 0,1 bits.
#
sub DOUBLEUP_branch_reduced_breadth_bits {
  my ($path, $limit) = @_;
  my @pending_x = (0);
  my @pending_y = (0);
  my @ret = (1);
  foreach (1 .. $limit) {
    my @new_x;
    my @new_y;
    foreach my $i (0 .. $#pending_x) {
      my $x = $pending_x[$i];
      my $y = $pending_y[$i];
      if ($path->xy_is_visited($x,$y)) {
        push @ret, 1,1;
        push @new_x, $x-1;
        push @new_y, $y+1;
        push @new_x, $x+1;
        push @new_y, $y+1;
      } else {
        push @ret, 0,0;
      }
    }
    @pending_x = @new_x;
    @pending_y = @new_y;
  }
  return (@ret,
          ((0) x $#pending_x));  # pending open nodes
}

#------------------------------------------------------------------------------
# A001317 - rows as binary bignums, without the skipped (x^y)&1==1 points of
# triangular lattice

MyOEIS::compare_values
  (anum => 'A001317',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::SierpinskiTriangle->new (align => 'right');
     my @got;
     require Math::BigInt;
     for (my $y = 0; @got < $count; $y++) {
       my $b = 0;
       foreach my $x (0 .. $y) {
         if ($path->xy_is_visited($x,$y)) {
           $b += Math::BigInt->new(2) ** $x;
         }
       }
       push @got, "$b";
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# Dyck coded, depth-first

# A080263 sierpinski 2, 50, 906, 247986
# A080264 binary    10, 110010, 1110001010, 111100100010110010
#                       (    )
#
#                                    *   *   *   *
#                                     \ /     \ /
#                    *       *         *       *
#                     \     /           \     /
#        *   *         *   *             *   *
#         \ /           \ /               \ /
#   *      *             *                 *
#  10   110010   1,1100,0101,0   11,110010,0010,110010
#  10,  110010,   1110001010,    111100100010110010
#       (())()
#      [(())()]

# binary
MyOEIS::compare_values
  (anum => 'A080264',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::SierpinskiTriangle->new;
     my @got;
     for (my $depth = 1; @got < $count; $depth++) {
       my @bits = dyck_tree_bits($path, 0,0, $depth);
       push @got, _digit_join_hightolow(\@bits, 10, Math::BigInt->new(0));
     }
     return \@got;
   });

# position in list of all balanced binary (A014486)
MyOEIS::compare_values
  (anum => 'A080265',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::SierpinskiTriangle->new;
     my @got;
     for (my $depth = 1; @got < $count; $depth++) {
       my @bits = dyck_tree_bits($path, 0,0, $depth);
       push @got, dyck_bits_to_index(\@bits);
     }
     return \@got;
   });

# decimal
MyOEIS::compare_values
  (anum => 'A080263',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::SierpinskiTriangle->new;
     my @got;
     for (my $depth = 1; @got < $count; $depth++) {
       my @bits = dyck_tree_bits($path, 0,0, $depth);
       push @got, _digit_join_hightolow(\@bits, 2, Math::BigInt->new(0));
     }
     return \@got;
   });

# No-such node = 0.
# Node = 1,left,right.
# Drop very last 0 at end.
#
sub dyck_tree_bits {
  my ($path, $x,$y, $limit) = @_;
  my @ret = dyck_tree_bits_z ($path, $x,$y, $limit);
  pop @ret;
  return @ret;
}
sub dyck_tree_bits_z {
  my ($path, $x,$y, $limit) = @_;
  if ($limit > 0 && $path->xy_is_visited($x,$y)) {
    return (1,
            dyck_tree_bits_z($path, $x-1,$y+1, $limit-1),  # left
            dyck_tree_bits_z($path, $x+1,$y+1, $limit-1)); # right
  } else {
    return (0);
  }
}

# Doesn't distinguish left and right.
# sub parens_bits_z {
#   my ($path, $x,$y, $limit) = @_;
#   if ($limit > 0 && $path->xy_is_visited($x,$y)) {
#     return (1,
#             parens_bits_z($path, $x-1,$y+1, $limit-1),  # left
#             parens_bits_z($path, $x+1,$y+1, $limit-1),  # right
#             0);
#   } else {
#     return ();
#   }
# }

#------------------------------------------------------------------------------
# breath-wise "level-order"
#
# A080268 decimal 2,  56,     968,        249728,             3996680,
# A080269 binary 10, 111000, 1111001000, 111100111110000000, 1111001111110000001000,
#                            (( (()) () ))
#
# 111100111111000000111111001100111111111000000000000000
#
# cf A057118 permute depth<->breadth
#

# position in list of all balanced binary (A014486)
MyOEIS::compare_values
  (anum => 'A080270',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::SierpinskiTriangle->new;
     my @got;
     for (my $depth = 1; @got < $count; $depth++) {
       my @bits = level_order_bits($path, $depth);
       push @got, dyck_bits_to_index(\@bits);
     }
     return \@got;
    });

# decimal
MyOEIS::compare_values
  (anum => 'A080268',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::SierpinskiTriangle->new;
     my @got;
     for (my $depth = 1; @got < $count; $depth++) {
       my @bits = level_order_bits($path, $depth);
       push @got, Math::BigInt->new("0b".join('',@bits));
     }
     return \@got;
   });

# binary
MyOEIS::compare_values
  (anum => 'A080269',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::SierpinskiTriangle->new;
     my @got;
     for (my $depth = 1; @got < $count; $depth++) {
       my @bits = level_order_bits($path, $depth);
       push @got, _digit_join_hightolow(\@bits, 10, Math::BigInt->new(0));
     }
     return \@got;
   });

# Return a list of 0,1 bits.
# No-such node = 0.
# Node = 1.
# Nodes descend to left,right breadth-wise in next level.
# Drop very last 0 at end.
#
sub level_order_bits {
  my ($path, $limit) = @_;
  my @pending_x = (0);
  my @pending_y = (0);
  my @ret;
  foreach (1 .. $limit) {
    my @new_x;
    my @new_y;
    foreach my $i (0 .. $#pending_x) {
      my $x = $pending_x[$i];
      my $y = $pending_y[$i];
      if ($path->xy_is_visited($x,$y)) {
        push @ret, 1;
        push @new_x, $x-1;
        push @new_y, $y+1;
        push @new_x, $x+1;
        push @new_y, $y+1;
      } else {
        push @ret, 0;
      }
    }
    @pending_x = @new_x;
    @pending_y = @new_y;
  }
  push @ret, (0) x (scalar(@pending_x)-1);
  return @ret;
}

#------------------------------------------------------------------------------
# A106344 - by dX=-3,dY=+1 slopes upwards
# cf A106346 its matrix inverse, or something
#
# 1
# 0, 1
# 0, 1, 1,
# 0, 0, 0, 1,
# 0, 0, 1, 1, 1,
# 0, 0, 0, 1, 0, 1,
# 0, 0, 0, 1, 0, 1, 1,
# 0, 0, 0, 0, 0, 0, 0, 1,
# 0, 0, 0, 0, 1, 0, 1, 1, 1,
# 0, 0, 0, 0, 0, 1, 0, 1, 0, 1,
# 0, 0, 0, 0, 0, 1, 1, 1, 0, 1, 1,
# 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1,
# 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1, 1,
# 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1

# 19  20  21  22  23  24  25  26
#   15      16      17      18
#     11  12          13  14   .
#        9              10   .
#          5   6   7   8   .
#            3   .   4   .
#              1   2    .   .
#                0    .   .   .

# path(x,y) = binomial(y,(x+y)/2)
# T(n,k)=binomial(k,n-k)
# y=k
# (x+y)/2=n-k
# x+k=2n-2k
# x=2n-3k

MyOEIS::compare_values
  (anum => 'A106344',
   func => sub {
     my ($count) = @_;
     # align="left" is dX=1,dY=1 diagonals
     my $path = Math::PlanePath::SierpinskiTriangle->new (align => 'left');
     my @got;
     my $xstart = 0;
     my $x = 0;
     my $y = 0;
     while (@got < $count) {
       my $n = $path->xy_to_n($x,$y);
       push @got, (defined $n ? 1 : 0);

       $x += 1;
       $y += 1;
       if ($x > 0) {
         $xstart--;
         $x = $xstart;
         $y = 0;
       }
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => q{A106344},
   func => sub {
     my ($count) = @_;
     # align="right" is dX=2,dY=1 slopes, chess knight moves
     my $path = Math::PlanePath::SierpinskiTriangle->new (align => 'right');
     my @got;
     my $xstart = 0;
     my $x = 0;
     my $y = 0;
     while (@got < $count) {
       my $n = $path->xy_to_n($x,$y);
       push @got, (defined $n ? 1 : 0);

       $x += 2;
       $y += 1;
       if ($x > $y) {
         $xstart--;
         $x = $xstart;
         $y = 0;
       }
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => q{A106344},
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::SierpinskiTriangle->new;
     my @got;
     my $xstart = 0;
     my $x = 0;
     my $y = 0;
     while (@got < $count) {
       my $n = $path->xy_to_n($x,$y);
       push @got, (defined $n ? 1 : 0);

       $x += 3;
       $y += 1;
       if ($x > $y) {
         $xstart -= 2;
         $x = $xstart;
         $y = 0;
       }
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => q{A106344},
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::SierpinskiTriangle->new;
     my @got;
   OUTER: for (my $n = 0; ; $n++) {
       for (my $k = 0; $k <= $n; $k++) {
         my $n = $path->xy_to_n(2*$n-3*$k,$k);
         push @got, (defined $n ? 1 : 0);
         if (@got >= $count) {
           last OUTER;
         }
       }
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => q{A106344},
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::SierpinskiTriangle->new;
     my @got;
     require Math::BigInt;
   OUTER: for (my $n = 0; ; $n++) {
       for (my $k = 0; $k <= $n; $k++) {

         # my $b = Math::BigInt->new($k);
         # $b->bnok($n-$k);   # binomial(k,k-n)
         # $b->bmod(2);
         # push @got, $b;

         push @got, binomial_mod2 ($k, $n-$k);
         if (@got >= $count) {
           last OUTER;
         }
       }
     }
     return \@got;
   });

# my $b = Math::BigInt->new($k);
# $b->bnok($n-$k);   # binomial(k,k-n)
# $b->bmod(2);
sub binomial_mod2 {
  my ($n, $k) = @_;
  return Math::BigInt->new($n)->bnok($k)->bmod(2)->numify;
}


#------------------------------------------------------------------------------
# A106345 -
# k=0..floor(n/2) of binomial(k, n-2k)
#
# path(x,y) = binomial(y,(x+y)/2)
# T(n,k)=binomial(k,n-2k)
# y=k
# (x+y)/2=n-2k
# x+k=2n-4k
# x=2n-5k

MyOEIS::compare_values
  (anum => 'A106345',
   max_count => 1000, # touch slow, shorten
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::SierpinskiTriangle->new;
     my @got;
     for (my $xstart = 0; @got < $count; $xstart -= 2) {
       my $x = $xstart;
       my $y = 0;
       my $total = 0;
       while ($x <= $y) {
         my $n = $path->xy_to_n($x,$y);
         if (defined $n) {
           $total++;
         }
         $x += 5;
         $y += 1;
       }
       push @got, $total;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A002487 - stern diatomic count along of dX=3,dY=1 slopes

MyOEIS::compare_values
  (anum => 'A002487',
   max_count => 1000, # touch slow, shorten
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::SierpinskiTriangle->new;
     my @got = (0);
     for (my $xstart = 0; @got < $count; $xstart -= 2) {
       my $x = $xstart;
       my $y = 0;
       my $total = 0;
       while ($x <= $y) {
         my $n = $path->xy_to_n($x,$y);
         if (defined $n) {
           $total++;
         }
         $x += 3;
         $y += 1;
       }
       push @got, $total;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A047999 - 1/0 by rows, without the skipped (x^y)&1==1 points of triangular
# lattice

MyOEIS::compare_values
  (anum => 'A047999',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::SierpinskiTriangle->new;
     my @got;
     my $x = 0;
     my $y = 0;
     foreach my $n (1 .. $count) {
       push @got, ($path->xy_is_visited($x,$y) ? 1 : 0);
       $x += 2;
       if ($x > $y) {
         $y++;
         $x = -$y;
       }
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => q{A047999},
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::SierpinskiTriangle->new (align => "right");
     my @got;
     my $x = 0;
     my $y = 0;
     foreach my $n (1 .. $count) {
       push @got, ($path->xy_is_visited($x,$y) ? 1 : 0);
       $x++;
       if ($x > $y) {
         $y++;
         $x = 0;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A075438 - 1/0 by rows of "right", including blank 0s in left of pyramid

MyOEIS::compare_values
  (anum => 'A075438',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::SierpinskiTriangle->new (align => 'right');
     my @got;
     my $x = 0;
     my $y = 0;
     foreach my $n (1 .. $count) {
       push @got, ($path->xy_is_visited($x,$y) ? 1 : 0);
       $x++;
       if ($x > $y) {
         $y++;
         $x = -$y;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------

exit 0;
