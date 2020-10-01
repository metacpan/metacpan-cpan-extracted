#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2017, 2018, 2019, 2020 Kevin Ryde

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
use Math::BigInt try => 'GMP';
plan tests => 16;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::Diagonals;
use Math::NumSeq::PlanePathTurn;
use Math::NumSeq::PlanePathCoord;


#------------------------------------------------------------------------------
# A097806 - Riordan 1,1,x-1 zeros

foreach my $direction ('down','up') {
  MyOEIS::compare_values
      (anum => 'A097806',
       func => sub {
         my ($count) = @_;
         my $path = Math::PlanePath::Diagonals->new(direction => $direction);
         my $seq = Math::NumSeq::PlanePathTurn->new(planepath_object => $path,
                                                    turn_type => 'NotStraight');
         my @got;
         while (@got < $count) {
           my ($i,$value) = $seq->next;
           push @got, $value;
         }
         return \@got;
       });
}

#------------------------------------------------------------------------------

# A057554 -- X,Y successively
MyOEIS::compare_values
  (anum => 'A057554',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::Diagonals->new;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, $x;
       if (@got < $count) {
         push @got, $y;
       }
     }
     return \@got;
   });

# A057555 -- X,Y successively, x_start=1,y_start=1
MyOEIS::compare_values
  (anum => 'A057555',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::Diagonals->new (x_start=>1, y_start=>1);
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
                                                 push @got, $x;
                                                 if (@got < $count) {
                                                   push @got, $y;
                                                 }
                                               }
       return \@got;
   });

#------------------------------------------------------------------------------
# A057046 -- X at N=2^k

{
  my $path = Math::PlanePath::Diagonals->new (x_start=>1, y_start=>1);

  MyOEIS::compare_values
    (anum => 'A057046',
     func => sub {
       my ($count) = @_;
                                              my @got;
                                              for (my $n = Math::BigInt->new(1); @got < $count; $n *= 2) {
                                                my ($x,$y) = $path->n_to_xy($n);
                                                push @got, $x;
                                              }
                                              return \@got;
                                            });

# A057047 -- Y at N=2^k
MyOEIS::compare_values
  (anum => 'A057047',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = Math::BigInt->new(1); @got < $count; $n *= 2) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, $y;
     }
     return \@got;
   });
}

#------------------------------------------------------------------------------
# A185787 -- total N in row up to Y=X diagonal

MyOEIS::compare_values
  (anum => 'A185787',
   max_count => 1000,
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::Diagonals->new;
     my @got;
     for (my $y = 0; @got < $count; $y++) {
       push @got, path_rect_to_accumulation ($path, 0,$y, $y,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A100182 -- total N in column to X=Y leading diagonal
#  tetragonal anti-prism numbers (7*n^3 - 3*n^2 + 2*n)/6

MyOEIS::compare_values
  (anum => 'A100182',
   max_count => 1000,
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::Diagonals->new;
     my @got;
     for (my $x = 0; @got < $count; $x++) {
       push @got, path_rect_to_accumulation ($path, $x,0, $x,$x);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A185788 -- total N in row to X=Y-1 before leading diagonal

MyOEIS::compare_values
  (anum => 'A185788',
   max_count => 1000,
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::Diagonals->new;
     my @got = (0);
     for (my $y = 1; @got < $count; $y++) {
       push @got, path_rect_to_accumulation ($path, 0,$y, $y-1,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A101165 -- total N in column up to Y=X-1 before leading diagonal

MyOEIS::compare_values
  (anum => 'A101165',
   max_count => 1000,
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::Diagonals->new;
     my @got = (0);
     for (my $x = 1; @got < $count; $x++) {
       push @got, path_rect_to_accumulation ($path, $x,0, $x,$x-1);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A185506 -- accumulation array, by antidiagonals
# accumulation being total sum N in rectangle 0,0 to X,Y

MyOEIS::compare_values
  (anum => 'A185506',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::Diagonals->new;
     my @got;
     for (my $d = $path->n_start; @got < $count; $d++) {
       my ($x,$y) = $path->n_to_xy($d);  # by anti-diagonals
       push @got, path_rect_to_accumulation($path, 0,0, $x,$y);
     }
     return \@got;
   });

sub path_rect_to_accumulation {
  my ($path, $x1,$y1, $x2,$y2) = @_;
  # $x1 = round_nearest ($x1);
  # $y1 = round_nearest ($y1);
  # $x2 = round_nearest ($x2);
  # $y2 = round_nearest ($y2);

  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;

  my $accumulation = 0;
  foreach my $x ($x1 .. $x2) {
    foreach my $y ($y1 .. $y2) {
      $accumulation += $path->xy_to_n($x,$y);
    }
  }
  return $accumulation;
}

#------------------------------------------------------------------------------
# A103451 -- turn 1=left or right, 0=straight
# but has extra n=1 whereas path first turn at starts N=2

MyOEIS::compare_values
  (anum => 'A103451',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'Diagonals',
                                                 turn_type => 'LSR');
     my @got = (1);
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, abs($value);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A103452 -- turn 1=left,0=straight,-1=right
# but has extra n=1 whereas path first turn at starts N=2

MyOEIS::compare_values
  (anum => 'A103452',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'Diagonals',
                                                 turn_type => 'LSR');
     my @got = (1);
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A215200 -- Kronecker(n-k,k) by rows, n>=1   1<=k<=n
# for n=6 runs n-k=5,4,3,2,1,0      for n=1 runs n-k=0
#                k=1,2,3,4,5,6                     k=1
# x=n-k  y=k  is diagonal up from X axis

MyOEIS::compare_values
  (anum => q{A215200},
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::Diagonals->new (direction => 'up',
                                                 x_start => 0,
                                                 y_start => 1);
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy ($n);
                                                 push @got, Math::NumSeq::PlanePathCoord::_kronecker_symbol($x,$y);
                                               }
       return \@got;
   });

#------------------------------------------------------------------------------
# A038722 -- permutation N at transpose Y,X, n_start=1

MyOEIS::compare_values
  (anum => 'A038722',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::Diagonals->new;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       push @got, $path->xy_to_n ($y, $x);
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A038722',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::Diagonals->new (direction => 'up');
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       push @got, $path->xy_to_n ($y, $x);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A061579 -- permutation N at transpose Y,X

MyOEIS::compare_values
  (anum => 'A061579',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::Diagonals->new (n_start => 0);
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       push @got, $path->xy_to_n ($y, $x);
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A061579',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::Diagonals->new (n_start => 0,
                                                 direction => 'up');
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       push @got, $path->xy_to_n ($y, $x);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
