#!/usr/bin/perl -w

# Copyright 2012, 2013, 2020 Kevin Ryde

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
plan tests => 2;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::KochSquareflakes;
my $path = Math::PlanePath::KochSquareflakes->new;


#------------------------------------------------------------------------------
# A332204 -- X coordinate
# A332205 -- Y coordinate
# ~/OEIS/a332204.gp.txt
#         *       
#       /  \          0, 45, -45, 0 degrees
#      /    \
# *---*      *---*
# my(x=OEIS_bfile_func("A332204"), \
#    y=OEIS_bfile_func("A332205")); \
# plothraw(vector(3^3,n,n--; x(n)), \
#          vector(3^3,n,n--; y(n)), 1+8+16+32)


MyOEIS::compare_values
  (anum => 'A332204',
   func => sub {
     my ($count) = @_;
     my @got;
     my $k = 0;
     while ($count > 4**$k) { $k++; }
     my $lo = (4**($k+1) - 1) / 3;
     my ($x_lo,$y_lo) = $path->n_to_xy($lo);
     for (my $n = $lo; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, $x - $x_lo;
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A332205',
   func => sub {
     my ($count) = @_;
     my @got;
     my $k = 0;
     while ($count > 4**$k) { $k++; }
     my $lo = (4**($k+1) - 1) / 3;
     my ($x_lo,$y_lo) = $path->n_to_xy($lo);
     for (my $n = $lo; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, - ($y - $y_lo);
     }
     return \@got;
   });

# A332204, A332205 segments unit horizontally, sqrt(2) diagonally, 45 degrees
#
#  3                      *
#                        /
#                       /
#  2                *--*
#         -90       |
#  1       *        *
#         / \      /
#        /   \    /
#  0 *--*     *--*
#     +45  +45
#    0  1  2  3  4  5  6  7

# my(g=OEIS_bfile_gf("A332204")); x(n) = polcoeff(g,n);
# my(g=OEIS_bfile_gf("A332205")); y(n) = polcoeff(g,n);
# plothraw(vector(4^3,n,n--; x(n)), \
#          vector(4^3,n,n--; y(n)), 1+8+16+32)
#
# midx(n) = (x(n+1) + x(n))/2;
# midy(n) = (y(n+1) + y(n))/2;
# plothraw(vector(3^6,n,n--; midx(n)), \
#          vector(3^6,n,n--; midy(n)), 1+8+16+32)

# plothraw(vector(3^6,n,n--; midx(n) - midy(n)), \
#          vector(3^6,n,n--; midx(n) + midy(n)), 1+8+16+32)

#------------------------------------------------------------------------------
exit 0;
