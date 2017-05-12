#!/usr/bin/perl -w

# Copyright 2012, 2013 Kevin Ryde

# This file is part of Math-PlanePath-Toothpick.
#
# Math-PlanePath-Toothpick is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Math-PlanePath-Toothpick is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath-Toothpick.  If not, see <http://www.gnu.org/licenses/>.


use 5.004;
use strict;
use Test;
plan tests => 27;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;
use List::Util 'min', 'max';

use Math::PlanePath::Base::Digits 'round_down_pow';

# uncomment this to run the ### lines
# use Smart::Comments '###';


my $class = 'Math::PlanePath::OneOfEight';
# my $class = 'Math::PlanePath::OneOfEightByCells';
eval "require $class" or die;

my $max_count = ($class eq 'Math::PlanePath::OneOfEightByCells'
                 ? 100   # small when ByCells
                 : undef);

my %make_path;
sub make_path {
  my ($parts) = @_;
  return ($make_path{$parts} ||= $class->new (parts => $parts));
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
sub log2_floor {
  my ($n) = @_;
  if ($n < 2) { return 0; }
  my ($pow,$exp) = round_down_pow ($n, 2);
  return $exp;
}


#------------------------------------------------------------------------------
# A151727 parts=4 added endless row
# 4,20,20,44,28,60,76,92,28,60,84,116
# 4,24,44,88,116

# add power-of-2 to start from 2^k corner
MyOEIS::compare_values
  (anum => 'A151727',
   func => sub {
     my ($count) = @_;
     my $path = make_path('4');
     my @got;
     my ($depth,$exp) = round_down_pow($count,2);
     $depth *= 4;
     for ( ; @got < $count; $depth++) {
       push @got, $path->tree_depth_to_width($depth);
     }
     return \@got;
   });

# is also 4 * 3mid added
MyOEIS::compare_values
  (anum => q{A151727},
   func => sub {
     my ($count) = @_;
     my $path = make_path('3mid');
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, 4 * $path->tree_depth_to_width($depth);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A151729 "v2", added endless row, div 8

MyOEIS::compare_values
  (anum => 'A151729',
   func => sub {
     my ($count) = @_;
     my $path = make_path('4');
     my @got;
     my ($depth,$exp) = round_down_pow($count,2);
     $depth *= 4;
     for ( ; @got < $count; $depth++) {
       push @got, ($path->tree_depth_to_width($depth)-4) / 8;
     }
     return \@got;
   });

# is also 3mid (added-1)/2
MyOEIS::compare_values
  (anum => q{A151729},
   func => sub {
     my ($count) = @_;
     my $path = make_path('3mid');
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, ($path->tree_depth_to_width($depth) - 1) / 2;
     }
     return \@got;
   });



#------------------------------------------------------------------------------

# V1(n) = oct(n+1) + 3*oct(n) + 2*oct(n-1)
#          - 3n - 2*floor(log(n+1) - (ispow2(n+1) ? 3 : 4)
#
sub my_3side_from_octant {
  my ($depth) = @_;
  ### my_3side_from_octant(): $depth
  if ($depth == 0) { return 0; }
  if ($depth == 1) { return 1; }
  if ($depth == 2) { return 4; }

  return my_octant($depth+1) + 3*my_octant($depth) + 2*my_octant($depth-1)
    - 3*$depth
      - log2_floor($depth+1)
        - log2_floor($depth)
          - 4;

  # return my_octant($depth+1) + 3*my_octant($depth) + 2*my_octant($depth-1)
  #   - 3*$depth - 2*log2_floor($depth+1)
  #     - (is_pow2($depth+1) ? 3 : 4);
}

MyOEIS::compare_values
  (anum => 'A170879',
   name => 'my_3side_from_octant()',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, my_3side_from_octant($depth);
     }
     return \@got;
   });

#------------------------------------------------------------------------------

# V2(n) = 2*oct(n+1) + 4*oct(n) - 3n - 2*floor(log(n+1)) - 6
# V2(n)/2 = oct(n+1) + 2*oct(n) - 3n/2 - 2*floor(log(n+1))/2 - 3
#         = oct(n+1) + 2*oct(n) - 3n/2 - floor(log(n+1)) - 3
# (V2(n) + V2(n-1) - 1)/2
#   = oct(n+1) + 2*oct(n) - 3n/2 - 2*floor(log(n+1))/2 - 3
#     +            oct(n) + 2*oct(n-1) - 3(n-1)/2 - 2*floor(log(n))/2 - 3 - 1/2
#   = oct(n+1) + 3*oct(n) + 2*oct(n-1) - 3n/2 - 3n/2 + 1/2
#     - 2*floor(log(n+1))/2 - 3 - 2*floor(log(n))/2 - 3 - 1/2
#   = oct(n+1) + 3*oct(n) + 2*oct(n-1) - 3n - 6
#     - floor(log(n+1)) - floor(log(n))
#   = oct(n+1) + 3*oct(n) + 2*oct(n-1) - 3n - 7
#     - 2*floor(log(n+1)) + (ispow2(n+1) ? 1 : 0)
#
# V1=A170879 from V2=A170880
# V1(n) = (V2(n) + V2(n-1) + 1)/2

{
  # eg V2 (44+63+1)/2=54
  require Math::NumSeq::OEIS::File;
  my $V1seq = Math::NumSeq::OEIS::File->new(anum=>'A170879');
  my $V2seq = Math::NumSeq::OEIS::File->new(anum=>'A170880');
  my $V1_count = 0; while ($V1seq->next) { $V1_count++ }
  my $V2_count = 0; while ($V2seq->next) { $V2_count++ }
  my $max_count = min($V1_count,$V2_count);

  MyOEIS::compare_values
      (anum => 'A170879',
       name => 'V2=A170880 formula',
       func => sub {
         my ($count) = @_;
         my @got = (0);
         my $prev = 0;
         for (my $n = 1; @got < $count; $n++) {
           my ($i, $value) = $V2seq->next;
           push @got, ($value + $prev + 1) / 2;
           $prev = $value;
         }
         return \@got;
       });
}

sub my_V1_from_V2 {
  my ($n) = @_;
  if ($n == 0) { return 0; }
  my $path = make_path('3mid');  # V2=3mid
  return ($path->tree_depth_to_n($n)
          + $path->tree_depth_to_n($n-1)
          + 1) / 2;
  # return (formula_V2($n) + formula_V2($n-1) + 5)/2;
}
{
  # my_V1_from_V2() vs 3side
  my $path = make_path('3side');
  for (my $depth = 0; $depth < 1024; $depth++) {
    my $f = my_V1_from_V2($depth);
    my $p = $path->tree_depth_to_n($depth);
    if ($f != $p) {
      warn "depth=$depth f=$f 3side=$p";
    }
  }
  ok (1,1,'my_octant() vs my_total()');
}


#------------------------------------------------------------------------------

# V2(n) = 2*oct(n+1) + 4*oct(n) - 3n - 2*floor(log(n+1)) - 6
#
sub my_3mid_from_octant {
  my ($depth) = @_;
  if ($depth == 0) { return 0; }
  if ($depth == 1) { return 1; }
  return 2*my_octant($depth+1) + 4*my_octant($depth)
    - 3*$depth - 2*log2_floor($depth+1) - 6;
}

MyOEIS::compare_values
  (anum => 'A170880',
   name => 'my_3mid_from_octant()',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, my_3mid_from_octant($depth);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# my_total()  A151725

# total(n) = 8*octant(n)-4n-7
# oct(n) = (total(n)+4n+7)/8
# total(pow+rem)
#   = 8*octant(pow+rem)-4n-7
#   = 8* (oct(pow) + 2*oct(rem) + oct(rem+1)
#         - rem - log2_floor(rem+1) - 3) - 4n - 7
#   = 8* ((total(pow)+4pow+7)/8 + 2*(total(rem)+4rem+7)/8 + (total(rem+1)+4rem+4+7)/8
#         - rem - log2_floor(rem+1) - 3) - 4n - 7
#   = (total(pow)+4pow+7) + 2*(total(rem)+4rem+7) + (total(rem+1)+4rem+7)
#     - 8*rem - 8*log2_floor(rem+1) - 12 - 4n - 7
#   = total(pow)+4pow+7 + 2*total(rem)+8rem+14 + total(rem+1)+4rem+7
#     - 8*rem - 8*log2_floor(rem+1) - 8*3 - 4n - 7
#   = total(pow)+4pow+7 + 2*total(rem)+8rem+14 + total(rem+1)+4rem+4+7
#     - 8*rem - 8*log2_floor(rem+1) - 8*3 - 4n - 7
#   = total(pow) + 2*total(rem) + total(rem+1)
#     +4pow+7 +8rem+14 +4rem+4+7 -8*rem -8*log2_floor(rem+1) -8*3 -4pow-4rem-7
#   = total(pow) + 2*total(rem) + total(rem+1)
#     -8*log2_floor(rem+1) +7 +14 +4+7  -8*3 - 7
#   = total(pow) + 2*total(rem) + total(rem+1)
#     -8*log2_floor(rem+1) + 1
# log2(n)=log(n)/log(2) 
#
# V(0)       = 0
# V(2^k)     = (16*4^k + 24*k - 7) / 9
# V(2^k + r) = V(2^k) + 2*V(r) + V(r+1) - 8*floor(log2(r+1)) + 1
# for k>=0 and 2^k > r >= 1
#
# eg. V(11) = V(8) + 2*V(3) + V(4) - 8*floor(log2(4)) + 1
#           = 121 + 2*13 + 33 - 8*2 + 1 = 165
# eg. V(13) = V(8) + 2*V(5) + V(6) - 8*floor(log2(6)) + 1
#           = 121 + 2*37 + 57 - 8*2 + 1 = 237
#
sub my_total {
  my ($depth) = @_;
  ### my_total(): $depth
  die if $depth < 0;
  if ($depth == 0) { return 0; }

  # return 8*octant($depth) - 4*$depth - 7;

  my ($pow,$exp) = round_down_pow ($depth, 2);
  my $rem = $depth - $pow;

  my $f = (16*$pow*$pow + 24*$exp - 7) / 9;
  if ($rem == 0) {
    return $f;
  }
  # if ($rem == 1) {
  #   # V(2^k + 1) = V(2^k) + 4;
  #   return $f + 4;
  # }
  return ($f
          + 2 * my_total($rem)
          + my_total($rem+1)
          - 8*log2_floor($rem+1)
          + 1
         );
}
BEGIN {
  use Memoize;
  Memoize::memoize('my_total');
}

MyOEIS::compare_values
  (anum => 'A151725',
   name => 'my_total()',
   max_count => $max_count,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, my_total($depth);
     }
     return \@got;
   });

#------------------------------------------------------------------------------

# oct(0)       = 0
# oct(2^k)     = (4*4^k + 9*2^k + 6*k + 14) / 18
# oct(2^k + r) = oct(2^k) + 2*oct(r) + oct(r+1) - floor(log2(r+1)) - r - 3
# for k >= 0, 2^k > r >= 0
#
sub my_octant {
  my ($depth) = @_;
  ### my_octant(): $depth
  die if $depth < 0;
  if ($depth == 0) { return 0; }
  # if ($depth == 1) { return 1; }

  my ($pow,$exp) = round_down_pow ($depth, 2);
  my $rem = $depth - $pow;
  my $f = ((4*$pow+9)*$pow + 6*$exp + 14)/18;
  if ($rem == 0) {
    return $f;
  }
  # if ($rem == 1) {
  #   return $f + 1;
  # }
  # if ($rem == 2) {
  #   return $f + 4;
  # }
  return ($f                  # pow
          + 2 * my_octant($rem)  # extend+upper
          + my_octant($rem+1)    # lower
          - log2_floor($rem+1)   # lower no log2_extras
          - $rem - 1          # upper,lower overlap diagonal
          - 2                 # upper,extend overlap initials
         );
}
BEGIN {
  use Memoize;
  Memoize::memoize('my_octant');
}

#------------------------------------------------------------------------------
# total from octant

# V(n) = 8*oct(n) - 4*n - 7   for n>=2
#
sub my_total_from_octant {
  my ($depth) = @_;
  if ($depth == 0) { return 0; }
  if ($depth == 1) { return 1; }
  my $o = my_octant($depth);
  return 8*$o - 4*$depth - 7;
}
{
  # my_total_from_octant() vs my_total()
  for (my $depth = 0; $depth < 1024; $depth++) {
    my $t = my_total($depth);
    my $ot = my_total_from_octant($depth);
    if ($ot != $t) {
      die "depth=$depth t=$t ot=$ot";
    }
  }
  ok (1,1,'my_octant() vs my_total()');
}

#------------------------------------------------------------------------------
# "v2" added by toothpick paper formula
# 0 1 5 5 11 7 15 19 23 7

# n=0 v2=0 so first depth to depth+1 at n=1 v2=1
sub v2_formula {
  my ($n) = @_;
  ### v2_formula(): $n
  if ($n <= 0) {
    return 0;
  }
  if ($n == 1) {
    return 1;
  }
  my ($pow,$k) = round_down_pow($n,2);
  my $i = $n - $pow;
  if ($i == 0) {
    return 3*$pow - 1;
  }
  if ($i == $pow-1) {
    return 2*v2_formula($i) + v2_formula($i+1) - 2;
  }
  return 2*v2_formula($i) + v2_formula($i+1);
}
BEGIN {
  use Memoize;
  Memoize::memoize('v2_formula');
}

MyOEIS::compare_values
  (anum => 'A151728',
   name => 'v2_formula()',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 1; @got < $count; $n++) {
       push @got, v2_formula($n);
     }
     return \@got;
   });

{
  # v2_formula() vs path parts=3mid width
  my $limit = ($class eq 'Math::PlanePath::OneOfEightByCells'
               ? 64   # small when ByCells
               : 32768);
  my $path = make_path('3mid');
  for (my $depth = 0; $depth < $limit; $depth++) {
    my $n = $depth+1;
    my $v2 = v2_formula($n);
    my $added = $path->tree_depth_to_width($depth);
    if ($added != $v2) {
      die "depth=$depth n=$n added=$added v2=$v2";
    }
  }
  ok (1,1,'v2 against path parts=3mid');
}
{
  # v2_formula() vs path parts=1 width at 2^k offset
  my $limit = ($class eq 'Math::PlanePath::OneOfEightByCells'
               ? 64   # small when ByCells
               : 32768);
  my $offset = $limit;
  my $path = make_path('1');
  for (my $n = 0; $n < $limit; $n++) {
    my $v2 = v2_formula($n+1);
    my $added = $path->tree_depth_to_width($n+$offset);
    if ($added != $v2) {
      die "n=$n added=$added v2=$v2";
    }
  }
  ok (1,1,'v2 against path parts=1');
}

#------------------------------------------------------------------------------
# A170880 "V2", 3mid total

MyOEIS::compare_values
  (anum => 'A170880',
   name => 'by path parts=3mid tree_depth_to_n()',
   func => sub {
     my ($count) = @_;
     my $path = make_path('3mid');
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, $path->tree_depth_to_n($depth);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A151728 "v2", 3mid added
# 1, 5, 5, 11, 7, 15, 19, 23, 7, 15, 21, 29, 29, 49, 59, 47, 7, 15, 21
# 1,6,11,22,29,44,

MyOEIS::compare_values
  (anum => 'A151728',
   name => 'by path parts=3mid tree_depth_to_n() width',
   func => sub {
     my ($count) = @_;
     my $path = make_path('3mid');
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, $path->tree_depth_to_width($depth);
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A151728',
   name => 'by path parts=4 at offset tree_depth_to_n() width, div 4',
   func => sub {
     my ($count) = @_;
     my $path = make_path('4');
     my @got;
     my ($offset,$exp) = round_down_pow(2*$count,2);
     for (my $n = 0; @got < $count; $n++) {
       push @got, $path->tree_depth_to_width($offset+$n) / 4;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A151747 v1 3side added
# 0, 1, 3, 5, 8, 9, 11, 17, 21, 15
# [1]  1,
# [2]  3,  5,
# [4]  8,  9,  11, 17,
# [8]  21, 15, 11, 18, 25, 29, 39, 54,
# [16] 53, 27, 11, 18, 25, 29, 39, 55, ...
#
# cf A170881 (3*n+1)*2^(n-2)+1 first column  1, 3, 8, 21, 53, 129, ...

MyOEIS::compare_values
  (anum => 'A151747',
   name => 'by 3side tree_depth_to_n() width',
   func => sub {
     my ($count) = @_;
     my $path = make_path('3side');
     my @got = (0);
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, $path->tree_depth_to_width($depth);
     }
     return \@got;
   });

# MyOEIS::compare_values
#   (anum => 'A151747',
#    name => 'by parts=side at offset tree_depth_to_n() width',
#    func => sub {
#      my ($count) = @_;
#      my $path = make_path('side');
#      my ($offset,$exp) = round_down_pow(2*$count+1,2);
#      my $n_base = $path->tree_depth_to_n($offset);
#      my @got = (0,1);
#      for (my $depth = $offset; @got < $count; $depth++) {
#        push @got, $path->tree_depth_to_width($depth);
#      }
#      return \@got;
#    });

# sub v1_from_sides {
#   my ($n) = @_;
#   die;
#   my $added = Math::PlanePath::OneOfEight::_depth_to_added
#     (-1,[$n-1,$n-2],[1,2],0);
#   if (is_pow2($n)) {
#     $added += 1;  # log2_extras in block2
#   }
#   return $added;
# }
# MyOEIS::compare_values
#   (anum => 'A151747',
#    func => sub {
#      my ($count) = @_;
#      my @got = (0,1,3,5);
#      for (my $depth = scalar(@got); @got < $count; $depth++) {
#        push @got, v1_from_sides($depth);
#      }
#      return \@got;
#    });
# foreach my $n (4 .. 30000) {
#   my $sides   = v1_formula($n);
#   my $formula = v1_from_sides($n);
#   if ($sides != $formula) {
#     die "n=$n sides=$sides formula=$formula";
#   }
# }

#------------------------------------------------------------------------------
# A170879 V1 total, 3side total
# cumulative A151747 "v1"

MyOEIS::compare_values
  (anum => 'A170879',
   name => 'by 3side tree_depth_to_n()',
   func => sub {
     my ($count) = @_;
     my $path = make_path('3side');
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, $path->tree_depth_to_n($depth);
     }
     return \@got;
   });

# MyOEIS::compare_values
#   (anum => 'A170879',
#    name => 'by parts=side at offset'
#    func => sub {
#      my ($count) = @_;
#      my @got;
#      my ($depth,$exp) = round_down_pow(2*$count+1,2);
#      $depth--;
#      my $n_base = $path_side->tree_depth_to_n($depth);
#      for ( ; @got < $count; $depth++) {
#        push @got, $path_side->tree_depth_to_n($depth) - $n_base;
#      }
#      return \@got;
#    });


#------------------------------------------------------------------------------
# A151748 v1 3side added endless

MyOEIS::compare_values
  (anum => 'A151748',
   name => 'by parts=3side at offset tree_depth_to_n() width',
   func => sub {
     my ($count) = @_;
     my $path = make_path('3side');
     my ($offset,$exp) = round_down_pow(2*$count+1,2);
     my $n_base = $path->tree_depth_to_n($offset);
     my @got;
     for (my $depth = $offset+1; @got < $count; $depth++) {
       push @got, $path->tree_depth_to_width($depth);
     }
     return \@got;
   });

# MyOEIS::compare_values
#   (anum => 'A151748',
#    func => sub {
#      my ($count) = @_;
#      my @got;
#      my ($depth,$exp) = round_down_pow($count,2);
#      $depth *= 2;
#      for ( ; @got < $count; $depth++) {
#        push @got, Math::PlanePath::OneOfEight::_depth_to_added(-1,[$depth+1,$depth],[1,2],0);
#      }
#      return \@got;
#    });

#------------------------------------------------------------------------------
# A151725 - parts=4 total cells

MyOEIS::compare_values
  (anum => 'A151725',
   name => 'by path parts=4 tree_depth_to_n()',
   max_count => $max_count,
   func => sub {
     my ($count) = @_;
     my $path = make_path('4');
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, $path->tree_depth_to_n($depth);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# "v1" 3side added
# 0 1 3 5 8 9 11 17 21 15
#
# A151747
# except n<=3    a(n) = 2n-1
#        j=0
# a(2^k + 0) = (3*k+1)*2^(k-2) + 1
# a(2^k + 1) = 3*2^(k-1) + 3        = (3*2^k + 6)/2
# a(2^k + j) = 2*a(j) + a(j+1)           2 <= j <= 2^k-1
# a(2^k + j) = 2*a(j) + a(j+1) - 1       if j=2^k-1

# n=0 v1=0 so first depth to depth+1 at n=1 v1=1
sub v1_formula {
  my ($n) = @_;
  if ($n <= 0) {
    return 0;
  }
  if ($n <= 3) {
    return 2*$n-1;
  }
  my ($pow,$k) = round_down_pow($n,2);
  my $j = $n - $pow;
  if ($j == 0) {
    return 1+(3*$k+1)*2**($k-2);
  }
  if ($j == 1) {
    return 3+ 3*2**($k-1);
  }
  if ($j == $pow-1) {
    return 2*v1_formula($j) + v1_formula($j+1) - 1;
  }
  return 2*v1_formula($j) + v1_formula($j+1)
}
BEGIN {
  use Memoize;
  Memoize::memoize('v1_formula');
}

MyOEIS::compare_values
  (anum => 'A151747',
   name => 'v1_formula()',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       push @got, v1_formula($n);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# "v" total added by formula

# n=0 v=0 so first depth to depth+1 at n=1 v=1
sub v_formula {
  my ($n) = @_;
  if ($n == 0) {
    return 0;
  }
  if ($n == 1) {
    return 1;
  }
  my ($pow,$k) = round_down_pow($n,2);
  my $i = $n - $pow;
  if ($i == 0) {
    return 6*$pow - 4;
  }
  return 4*v2_formula($i);
}

MyOEIS::compare_values
  (anum => 'A151726',
   name => 'v_formula()',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       push @got, v_formula($n);
     }
     return \@got;
   });

{
  # v_formula() vs path parts=4 width at 2^k offset
  my $limit = ($class eq 'Math::PlanePath::OneOfEightByCells'
               ? 64   # small when ByCells
               : 32768);
  my $offset = $limit;
  my $path = make_path('4');
  for (my $n = 1; $n < $limit; $n++) {
    my $v = v_formula($n+1);
    my $added = $path->tree_depth_to_width($n);
    if ($added != $v) {
      die "n=$n added=$added v=$v";
    }
  }
  ok (1,1,'v against ByCells');
}


#------------------------------------------------------------------------------
# A151735 - parts=1 total

MyOEIS::compare_values
  (anum => 'A151735',
   name => 'path parts=1 tree_depth_to_n()',
   func => sub {
     my ($count) = @_;
     my $path = make_path('1');
     my @got;
     my $total = 0;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, $path->tree_depth_to_n($depth);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A151737 - parts=1 added
#
# A151735: 0,1,4,5,10,11,16,21,32,33,38,43,54,61,76,95,118,119,
# A151737:   1,2,1, 5, 1, 5, 5,11, 1, 5, 5,11, 7,15,19, 23,  1,
# for some reason A151737(2)=2 rather than 3=A151735(3)-A151735(2)

MyOEIS::compare_values
  (anum => 'A151737',
   name => 'path parts=1 tree_depth_to_n() width',
   func => sub {
     my ($count) = @_;
     my $path = make_path('1');
     my @got = (1,2);;
     for (my $depth = 2; @got < $count; $depth++) {
       push @got, $path->tree_depth_to_width($depth);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# 151726 - "v" total parts=4 added

MyOEIS::compare_values
  (anum => 'A151726',
   name => 'path parts=4 width',
   func => sub {
     my ($count) = @_;
     my $path = make_path('4');
     my @got = (0);   # extra initial 0
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, $path->tree_depth_to_width($depth);
     }
     return \@got;
   });

if ($class eq 'Math::PlanePath::OneOfEight') {
  MyOEIS::compare_values
      (anum => 'A151726',
       name => '_depth_to_octant_added() * 8 - 4',
       func => sub {
         my ($count) = @_;
         my @got = (0,1,8);
         for (my $depth = 2; @got < $count; $depth++) {
           my $oadd = Math::PlanePath::OneOfEight::_depth_to_octant_added([$depth],[1],0);
           push @got, 8*$oadd - 4;
         }
         return \@got;
       });
}


#------------------------------------------------------------------------------
exit 0;
