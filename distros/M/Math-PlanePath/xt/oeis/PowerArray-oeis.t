#!/usr/bin/perl -w

# Copyright 2012, 2013, 2018, 2019 Kevin Ryde

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
use Math::BigInt try => 'GMP';
use Test;
plan tests => 18;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::PowerArray;


#------------------------------------------------------------------------------
# A117303 -- permutation, N at transpose (2*x-1)*2^(y-1) <--> (2*y-1)*2^(x-1)

MyOEIS::compare_values
  (anum => 'A117303',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::PowerArray;
     my $path = Math::PlanePath::PowerArray->new;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy($n);
       push @got, $path->xy_to_n ($y, $x);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A151754 -- radix=10, Y at N=2^k starting k=1 N=2, floor(2^k*9/10)

MyOEIS::compare_values
  (anum => 'A151754',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::PowerArray->new (radix => 10);
     my @got;
     for (my $n = Math::BigInt->new(2); @got < $count; $n *= 2) {
       my ($x,$y) = $path->n_to_xy($n);
       $x == 0 or die;
       push @got, $y;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A000975 -- radix=3, Y at N=2^k, being Y=1010101..101 in binary

MyOEIS::compare_values
  (anum => 'A000975',
   max_count => 1000,
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::PowerArray->new (radix => 3);
     my @got;
     for (my $n = Math::BigInt->new(1); @got < $count; $n *= 2) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, $y;
     }
     return \@got;
   });



#------------------------------------------------------------------------------
# A050603 -- radix=2 abs(dX), but OFFSET=0

MyOEIS::compare_values
  (anum => 'A050603',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::PowerArray->new (radix => 2);
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($dx,$dy) = $path->n_to_dxdy($n);
       push @got, abs($dx);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A003159 -- radix=2, N which is in X even

MyOEIS::compare_values
  (anum => 'A003159',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::PowerArray->new (radix => 2);
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy($n);
       if ($x % 2 == 0) {
         push @got, $n;
       }
     }
     return \@got;
   });

# A036554 complement, N which is in X odd
MyOEIS::compare_values
  (anum => 'A036554',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::PowerArray->new (radix => 2);
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy($n);
       if ($x % 2 == 1) {
         push @got, $n;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A007417 -- radix=3, N which is in X even

MyOEIS::compare_values
  (anum => 'A007417',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::PowerArray->new (radix => 3);
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy($n);
       if ($x % 2 == 0) {
         push @got, $n;
       }
     }
     return \@got;
   });

# A145204 complement, N which is in X odd, and extra initial 0
MyOEIS::compare_values
  (anum => 'A145204',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::PowerArray->new (radix => 3);
     my @got = (0);
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy($n);
       if ($x % 2 == 1) {
         push @got, $n;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A141396 -- radix=3, permutation, N by diagonals

MyOEIS::compare_values
  (anum => 'A141396',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::Diagonals;
     my $power = Math::PlanePath::PowerArray->new (radix => 3);
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'down');
     my @got;
     for (my $n = $diagonal->n_start; @got < $count; $n++) {
       my ($x, $y) = $diagonal->n_to_xy($n);
       push @got, $power->xy_to_n ($x, $y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A191449 -- radix=3, permutation, N by diagonals up from X axis

MyOEIS::compare_values
  (anum => 'A191449',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::PlanePath::Diagonals;
     my $diagonals  = Math::PlanePath::Diagonals->new (direction => 'up');
     my $power = Math::PlanePath::PowerArray->new (radix => 3);
     for (my $n = $diagonals->n_start; @got < $count; $n++) {
       my ($x, $y) = $diagonals->n_to_xy ($n);
       push @got, $power->xy_to_n($x,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A135764 -- dispersion traversed by diagonals, down from Y axis

MyOEIS::compare_values
  (anum => 'A135764',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::PlanePath::Diagonals;
     my $diagonals  = Math::PlanePath::Diagonals->new (direction => 'down');
     my $power = Math::PlanePath::PowerArray->new;
     for (my $n = $diagonals->n_start; @got < $count; $n++) {
       my ($x, $y) = $diagonals->n_to_xy ($n);
       push @got, $power->xy_to_n($x,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A075300 -- dispersion traversed by diagonals, minus 1, so starts from 0

MyOEIS::compare_values
  (anum => 'A075300',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::Diagonals;
     my $diagonals  = Math::PlanePath::Diagonals->new (direction => 'up');
     my $power = Math::PlanePath::PowerArray->new;
     my @got;
     for (my $n = $diagonals->n_start; @got < $count; $n++) {
       my ($x, $y) = $diagonals->n_to_xy ($n);
       push @got, $power->xy_to_n($x,$y) - 1;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A001651 -- radix=3, N on Y axis, not divisible by 3

MyOEIS::compare_values
  (anum => 'A001651',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::PowerArray->new (radix => 3);
     for (my $y = 0; @got < $count; $y++) {
       push @got, $path->xy_to_n(0,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A067251 -- radix=10, N on Y axis, no trailing 0 digits

MyOEIS::compare_values
  (anum => 'A067251',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::PowerArray->new (radix => 10);
     for (my $y = 0; @got < $count; $y++) {
       push @got, $path->xy_to_n(0,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A153733 remove trailing 1s
MyOEIS::compare_values
  (anum => 'A153733',
   func => sub {
     my ($count) = @_;
     my @got;
     my $power = Math::PlanePath::PowerArray->new;
     for (my $n = $power->n_start; @got < $count; $n++) {
       my ($x, $y) = $power->n_to_xy ($n);
       push @got, 2*$y;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A000265 -- 2*Y+1, odd part of n dividing out factors of 2

MyOEIS::compare_values
  (anum => 'A000265',
   func => sub {
     my ($count) = @_;
     my @got;
     my $power = Math::PlanePath::PowerArray->new;
     for (my $n = $power->n_start; @got < $count; $n++) {
       my ($x, $y) = $power->n_to_xy ($n);
       push @got, 2*$y+1;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A094267 -- dX, but OFFSET=0

MyOEIS::compare_values
  (anum => 'A094267',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::PowerArray->new (radix => 2);
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($dx,$dy) = $path->n_to_dxdy($n);
       push @got, $dx;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A108715 -- dY

MyOEIS::compare_values
  (anum => 'A108715',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::PowerArray->new (radix => 2);
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($dx,$dy) = $path->n_to_dxdy($n);
       push @got, $dy;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A118417 -- N on X=Y+1 diagonal

MyOEIS::compare_values
  (anum => 'A118417',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::PowerArray->new (radix => 2);
     require Math::BigInt;
     for (my $i = Math::BigInt->new(0); @got < $count; $i++) {
       push @got, $path->xy_to_n($i+1,$i);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A005408 -- N on Y axis, odd numbers

MyOEIS::compare_values
  (anum => 'A005408',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::PowerArray->new;
     for (my $y = 0; @got < $count; $y++) {
       push @got, $path->xy_to_n(0,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A057716 -- N not on X axis, the non 2^X

MyOEIS::compare_values
  (anum => 'A057716',
   func => sub {
     my ($count) = @_;
     my @got = (0); # extra 0
     my $path = Math::PlanePath::PowerArray->new (radix => 2);
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       if ($y != 0) {
         push @got, $n;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A135765 -- odd numbers radix 3, down from Y axis
#
# 0     1 2     3 4      5  6
# 0 . . 3 4 . . 7 8 . . 11 12
# 2*y+($y%2)
#
# math-image --all --wx --path=PowerArray,radix=3 --output=numbers --size=15x20
#
# A135765 odd numbers by factors of 3
# product A000244 3^n, A007310 1or5 mod 6 is LCF>=5
#    1     5     7   11   13   17  19  23  25  29
#    3    15    21   33   39   51  57  69  75
#    9    25    63   99  117  153 171 207
#   27   135   189  297  351  459 513
#   81   405   567  891 1053 1377
#  243  1215  1701 2673 3159
#  729  3645  5103 8019
# 2187 10935 15309
# 6561 32805
#

MyOEIS::compare_values
  (anum => 'A135765',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::PlanePath::Diagonals;
     my $diagonals  = Math::PlanePath::Diagonals->new (direction => 'down');
     my $power = Math::PlanePath::PowerArray->new (radix => 3);
     for (my $n = $diagonals->n_start; @got < $count; $n++) {
       my ($x, $y) = $diagonals->n_to_xy ($n);
       $y = 2*$y+($y%2); # stretch
       push @got, $power->xy_to_n($x,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A006519 -- 2^X coord

MyOEIS::compare_values
  (anum => 'A006519',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::PowerArray->new (radix => 2);
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       push @got, 2**$x;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A025480 -- Y coord

MyOEIS::compare_values
  (anum => 'A025480',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::PowerArray->new (radix => 2);
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       push @got, $y;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A003602 -- Y+1 coord, k for which N=(2k-1)*2^m

MyOEIS::compare_values
  (anum => 'A003602',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::PowerArray->new (radixt => 2);
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       push @got, $y+1;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A054582 -- dispersion traversed by diagonals, up from X axis

MyOEIS::compare_values
  (anum => 'A054582',
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::PlanePath::Diagonals;
     my $diagonals  = Math::PlanePath::Diagonals->new (direction => 'up');
     my $power = Math::PlanePath::PowerArray->new;
     for (my $n = $diagonals->n_start; @got < $count; $n++) {
       my ($x, $y) = $diagonals->n_to_xy ($n);
       push @got, $power->xy_to_n($x,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
