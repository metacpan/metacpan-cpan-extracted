#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2018, 2019, 2020 Kevin Ryde

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
plan tests => 5;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::Diagonals;
use Math::PlanePath::FibonacciWordFractal;
use Math::NumSeq::PlanePathTurn;

my $path = Math::PlanePath::FibonacciWordFractal->new;


#------------------------------------------------------------------------------
# A265318 - by diagonals, starting 1, with 0s for unvisited points

MyOEIS::compare_values
  (anum => 'A265318',
   func => sub {
     my ($count) = @_;
     my $diag = Math::PlanePath::Diagonals->new (direction => 'up');
     my @got;
     for (my $n = $diag->n_start; @got < $count; $n++) {
       my ($x,$y) = $diag->n_to_xy($n);
       my $n = $path->xy_to_n($x,$y);
       push @got, defined $n ? $n+1 : 0;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A003849 - Fibonacci word 0/1, 0=straight,1=left or right

MyOEIS::compare_values
  (anum => 'A003849',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new
       (planepath_object => $path,
        turn_type => 'Straight');
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });

# A143668 - Fibonacci 0=right,1=straight,2=left
MyOEIS::compare_values
  (anum => 'A143668',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new
       (planepath_object => $path,
        turn_type => 'LSR');
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, $value + 1;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A332298 -- X coordinate
# A332299 -- Y coordinate

MyOEIS::compare_values
  (anum => 'A332298',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $path->n_start + 1; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, $x;
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A332299',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $path->n_start + 1; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, $y - 1;
     }
     return \@got;
   });

# my(g=OEIS_bfile_gf("A332298")); x(n) = polcoeff(g,n);
# my(g=OEIS_bfile_gf("A332299")); y(n) = polcoeff(g,n);
# plothraw(vector(3^6,n,n--; x(n)), \
#          vector(3^6,n,n--; y(n)), 8+16+32+128)
#
# 0, 1, 2, 2, 3, 4, 4, 4, 3, 3, 3, 4, 4, 4, 3, 2, 2, 1, 0, 0, 0, 1, 1, 1,
# 0, 0, 0, -1, -1, -1, 0, 1, 1, 2, 3, 3, 4, 5, 5, 5, 4, 4, 4, 5, 6, 6, 7,

# ~/OEIS/a332298.png
# A003849(n)=my(k=2); while(fibonacci(k)<=n, k++); while(n>1, while(fibonacci(k--)>n, ); n-=fibonacci(k)); n==1;
# vector(10,n,n--; A003849(n))

# 0, 1, 0, 0, 1, 0, 1
# 

#------------------------------------------------------------------------------

exit 0;
