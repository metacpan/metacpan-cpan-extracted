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

use 5.004;
use strict;
use List::Util 'max';
use Test;
plan tests => 2;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::WunderlichSerpentine;
use Math::PlanePath::Base::Digits
  'digit_split_lowtohigh', 'digit_join_lowtohigh';
use Math::PlanePath;
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;
use Math::NumSeq::PlanePathTurn;

# GP-DEFINE  read("my-oeis.gp");


#------------------------------------------------------------------------------
# A323258 -- X coordinate
# A323259 -- Y coordinate
# Robert Dickau's variation.
#
# Wunderlich serpentine "alternating", but the least significant digit of N
# which 9 points in 3x3 has a transpose along its diagonal.
#
# Occurs since the base figure is an S orientation but then it and
# subsequent bigger 3^k x 3^k blocks are assembled in N orientation.
# In all cases rotations to make the ends join up.
#
# So in an "even" block which is leading diagonal, transpose lowest ternary
# digit of x,y.  Or in odd block which is opposite diagonal, complement
# 2-y,2-x.

sub xy_low_transpose {
  my ($x,$y) = @_;
  my $xr = _divrem_mutate($x,3);
  my $yr = _divrem_mutate($y,3);
  if (($x+$y)&1) {
    ($xr,$yr) = (2-$yr,2-$xr);
  } else {
    ($xr,$yr) = ($yr,$xr);
  }
  return (3*$x+$xr, 3*$y+$yr);
}

MyOEIS::compare_values
  (anum => 'A323258',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::WunderlichSerpentine->new;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       ($x,$y) = xy_low_transpose($x,$y);
       push @got, $y;
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A323259',
   func => sub {
     my ($count) = @_;
     my $path  = Math::PlanePath::WunderlichSerpentine->new;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       ($x,$y) = xy_low_transpose($x,$y);
       push @got, $x;
     }
     return \@got;
   });

# without low transpose:
# not in OEIS: 0,1,2,2,1,0,0,1,2,3,3,3,4,4,4,5,5,5,6,7,8,8,7,6,6,7,8,8,8,8,7,7,7,6,6,6,5,4,3
# not in OEIS: 0,0,0,1,1,1,2,2,2,2,1,0,0,1,2,2,1,0,0,0,0,1,1,1,2,2,2,3,4,5,5,4,3,3,4,5,5,5,5,4,4,4,3,3,3,3,4,5,5,4,3


# ~/OEIS/a323258.png
# ~/OEIS/b323258.txt
# http://robertdickau.com/wunderlich.html
# my(g=OEIS_bfile_gf("A323258")); x(n) = polcoeff(g,n);
# my(g=OEIS_bfile_gf("A323259")); y(n) = polcoeff(g,n);
# plothraw(vector(9^3+10,n,n--; x(n)), \
#          vector(9^3+10,n,n--; y(n)), 1+8+16+32)
# plothraw(vector(9^4+1,n,n--; x(n)), \
#          vector(9^4+1,n,n--; y(n)), 1+8+16+32)
# plothraw(vector(9^3,n, y(9*n-4)), \
#          vector(9^3,n, x(9*n-4)), 1+8+16+32)


#------------------------------------------------------------------------------
# Wunderlich Serpentine Diagonals, alternating 
# A332380  diagonals across, segment replacement
# A332381

# my(g=OEIS_bfile_gf("A332380")); x(n) = polcoeff(g,n);
# my(g=OEIS_bfile_gf("A332381")); y(n) = polcoeff(g,n);
# plothraw(vector(3^6,n,n--; x(n)), \
#          vector(3^6,n,n--; y(n)), 1+8+16+32)
#
# midx(n) = (x(n+1) + x(n))/2;
# midy(n) = (y(n+1) + y(n))/2;
# plothraw(vector(3^6,n,n--; midx(n)), \
#          vector(3^6,n,n--; midy(n)), 1+8+16+32)

# plothraw(vector(3^6,n,n--; midx(n) - midy(n)), \
#          vector(3^6,n,n--; midx(n) + midy(n)), 1+8+16+32)


# poldegree(OEIS_bfile_gf("A332380"))
# poldegree(OEIS_bfile_gf("A332381"))
# GP-DEFINE  my(gx=OEIS_bfile_gf("A332380"),gy=OEIS_bfile_gf("A332381")); \
# GP-DEFINE  z(n) = polcoeff(gx,n) + I*polcoeff(gy,n);
# vector(18,n,n--; z(n))
# GP-DEFINE  mid(n) = (z(n+1) + z(n))/2;
# my(v=vector(9^3,n,n--; (1+I)*mid(n))); \
# plothraw(real(v),imag(v),1+32);

# GP-DEFINE  dz(n) = z(n+1) - z(n);
# GP-DEFINE  midfrac(n,f) = z(n) + dz(n)*f;
# my(l=List([])); for(n=0,9^2-1, listput(l,midfrac(n,.1)); listput(l,midfrac(n,.9))); \
# l=Vec(l);\
# plothraw(real(l),imag(l),1+8+16+32);

# [R, U, L, D]=[0..3];
# p = [R, U, R, D, L, D, R, U, R];
# l=List([]); z=0; for (n=0, 9^3, listput(l,z); z += I^vecsum(apply(d -> p[1+d], digits(n, #p))));
# l=Vec(l);
# l=vector(#l-1,n, (1+I) * (l[n+1]+l[n])/2);
# plothraw(real(l),imag(l),1+32);

# 1, -1,-1,-1, 1,1,1, -1
# GP-DEFINE  alt_turn(n) = {
# GP-DEFINE    n>=1 || error();
# GP-DEFINE    while(n%9==0, n/=9);
# GP-DEFINE    [1, -1,-1,-1, 1,1,1, -1][n%9];
# GP-DEFINE  }
# vector(35,n,alt_turn(n))
# vector(27,n,alt_turn(n)>0)
# vector(27,n,alt_turn(n)<0)
# not in OEIS: 1,-1,-1,-1,1,1,1,-1,1,1,-1,-1,-1,1,1,1,-1,-1,1,-1,-1,-1,1,1,1,-1,-1
# not A216430 parity num 2s
# not in OEIS: 1,0,0,0,1,1,1,0,1,1,0,0,0,1,1,1,0,0,1,0,0,0,1,1,1,0,0
# not in OEIS: 0,1,1,1,0,0,0,1,0,0,1,1,1,0,0,0,1,1,0,1,1,1,0,0,0,1,1

# No, this is for diagonals.
# {
#   my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'WunderlichSerpentine',
#                                               turn_type => 'Right');
#   my @want = (undef, 1,0,0,0,1,1,1,0,1,1,0,0,0,1,1,1,0,0,1,0,0,0,1,1,1,0,0);
#   foreach my $n (1..$#want) {
#     ok($seq->ith($n), $want[$n]);
#   }
# }


#------------------------------------------------------------------------------
exit 0;



__END__

# my $xr = $x % 3;
# my $yr = $y % 3;
# return ($x - $xr + $yr,
#         $y - $yr + $xr);
# sub xy_high_transpose {
#   my ($x,$y) = @_;
#   my @x = digit_split_lowtohigh($x,3);
#   my @y = digit_split_lowtohigh($y,3);
#   my $max = max($#x,$#y);
#   if ($max >= 0) {
#     push @x, (0) x ($max - $#x);
#     push @y, (0) x ($max - $#y);
#     ($x[$max],$y[$max]) = ($y[$max],$x[$max]);
#   }
#   return (digit_join_lowtohigh(\@y,3),
#           digit_join_lowtohigh(\@x,3));
# }
