#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2018 Kevin Ryde

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
plan tests => 7;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::Corner;


#------------------------------------------------------------------------------
# A027709 -- unit squares figure boundary

MyOEIS::compare_values
  (anum => 'A027709',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::Corner->new;
     my @got = (0);
     for (my $n = $path->n_start; @got < $count; $n++) {
       push @got, $path->_NOTDOCUMENTED_n_to_figure_boundary($n);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A078633 -- grid sticks

{
  my @dir4_to_dx = (1,0,-1,0);
  my @dir4_to_dy = (0,1,0,-1);

  sub path_n_to_dsticks {
    my ($path, $n) = @_;
    my ($x,$y) = $path->n_to_xy($n);
    my $dsticks = 4;
    foreach my $i (0 .. $#dir4_to_dx) {
      my $an = $path->xy_to_n($x+$dir4_to_dx[$i], $y+$dir4_to_dy[$i]);
      $dsticks -= (defined $an && $an < $n);
    }
    return $dsticks;
  }
}

MyOEIS::compare_values
  (anum => 'A078633',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::Corner->new;
     my @got;
     my $boundary = 0;
     for (my $n = $path->n_start; @got < $count; $n++) {
       $boundary += path_n_to_dsticks($path,$n);
       push @got, $boundary;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A000290 -- N on X axis, perfect squares starting from 1

MyOEIS::compare_values
  (anum => 'A000290',
   func => sub {
     my ($count) = @_;
     my @got = (0);
     my $path = Math::PlanePath::Corner->new;
     for (my $x = 0; @got < $count; $x++) {
       push @got, $path->xy_to_n ($x, 0);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A002061 -- N on X=Y diagonal, extra initial 1

MyOEIS::compare_values
  (anum => 'A002061',
   func => sub {
     my ($count) = @_;
     my @got = (1);
     my $path = Math::PlanePath::Corner->new;
     for (my $i = 0; @got < $count; $i++) {
       push @got, $path->xy_to_n ($i, $i);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A060736 -- permutation, N by diagonals down

MyOEIS::compare_values
  (anum => 'A060736',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::Diagonals;
     my $corner = Math::PlanePath::Corner->new;
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'down');
     my @got;
     for (my $n = $diagonal->n_start; @got < $count; $n++) {
       my ($x, $y) = $diagonal->n_to_xy($n);
       push @got, $corner->xy_to_n ($x, $y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A064788 -- permutation, inverse of N by diagonals down

MyOEIS::compare_values
  (anum => 'A064788',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::Diagonals;
     my $corner = Math::PlanePath::Corner->new;
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'down');
     my @got;
     for (my $n = $corner->n_start; @got < $count; $n++) {
       my ($x, $y) = $corner->n_to_xy($n);
       push @got, $diagonal->xy_to_n ($x, $y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A060734 -- permutation, N by diagonals upwards

MyOEIS::compare_values
  (anum => 'A060734',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::Diagonals;
     my $corner = Math::PlanePath::Corner->new;
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'up');
     my @got;
     for (my $n = $diagonal->n_start; @got < $count; $n++) {
       my ($x, $y) = $diagonal->n_to_xy($n);
       push @got, $corner->xy_to_n ($x, $y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A064790 -- permutation, inverse of N by diagonals upwards

MyOEIS::compare_values
  (anum => 'A064790',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::Diagonals;
     my $corner = Math::PlanePath::Corner->new;
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'up');
     my @got;
     for (my $n = $corner->n_start; @got < $count; $n++) {
       my ($x, $y) = $corner->n_to_xy($n);
       push @got, $diagonal->xy_to_n ($x, $y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A004201 -- N for which Y<=X, half below diagonal

MyOEIS::compare_values
  (anum => 'A004201',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::Corner->new;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       if ($x >= $y) {
         push @got, $n;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A020703 -- permutation transpose Y,X

MyOEIS::compare_values
  (anum => 'A020703',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::Corner->new;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       push @got, $path->xy_to_n ($y, $x);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A053188 -- abs(X-Y), distance to next higher pronic, wider=1, extra 0

MyOEIS::compare_values
  (anum => 'A053188',
   func => sub {
     my ($count) = @_;
     my @got = (0);  # extra initial 0
     my $path = Math::PlanePath::Corner->new (wider => 1);
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       push @got, abs($x-$y);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
exit 0;
