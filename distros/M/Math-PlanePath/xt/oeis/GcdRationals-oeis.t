#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013 Kevin Ryde

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
plan tests => 6;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::GcdRationals;

# uncomment this to run the ### lines
#use Smart::Comments '###';


#------------------------------------------------------------------------------
# A050873 = ceil(X/Y)

MyOEIS::compare_values
  (anum => 'A050873',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::GcdRationals->new
       (pairs_order => 'rows_reverse');
     my @got;
     my $n_start = $path->n_start;
     for (my $n = $n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, div_ceil($x,$y);
     }
     return \@got;
   });

sub div_ceil {
  my ($n,$d) = @_;
  return int (($n+$d-1) / $d);
}

#------------------------------------------------------------------------------
# A050873 = int(X/Y) + A023532
# so int(X/Y) = A050873 - A023532

{
  my ($b2) = MyOEIS::read_values('A023532');

  MyOEIS::compare_values
      (anum => 'A050873',
       max_count => scalar(@$b2),
       func => sub {
         my ($count) = @_;
         my $path = Math::PlanePath::GcdRationals->new;
         my @got;
         my $n_start = $path->n_start;
         for (my $n = $n_start; @got < $count; $n++) {
           my ($x,$y) = $path->n_to_xy($n);
           push @got, int($x/$y) + $b2->[$n-$n_start];
         }
         return \@got;
       });
}

#------------------------------------------------------------------------------
# A178340 Bernoulli denominator = int(X/Y) + 1
# Not quite since A178340 reduced rational.  First different at n=49.
#
# MyOEIS::compare_values
#   (anum => q{A178340},
#    func => sub {
#      my ($count) = @_;
#      my $path = Math::PlanePath::GcdRationals->new;
#      my @got = (1);
#      for (my $n = $path->n_start; @got < $count; $n++) {
#        my ($x,$y) = $path->n_to_xy($n);
#        push @got, int($x/$y) + 1;
#      }
#      return \@got;
#    });

#------------------------------------------------------------------------------
# A033638 - diagonals_down X=1 column, quarter squares + 1, squares+pronic + 1

MyOEIS::compare_values
  (anum => 'A033638',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::GcdRationals->new
       (pairs_order => 'diagonals_down');
     my @got = (1);
     for (my $y = 1; @got < $count; $y++) {
       push @got, $path->xy_to_n(1,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A002061 - X axis pairs_order=diagonals_up,  central polygonals

MyOEIS::compare_values
  (anum => 'A002061',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::GcdRationals->new
       (pairs_order => 'diagonals_up');
     my @got = (1);
     for (my $x = 1; @got < $count; $x++) {
       push @got, $path->xy_to_n($x,1);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A000124 - Y axis pairs_order=rows (the default), triangular+1

MyOEIS::compare_values
  (anum => 'A000124',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::GcdRationals->new;
     my @got;
     for (my $y = 1; @got < $count; $y++) {
       push @got, $path->xy_to_n(1,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A000290 - X axis pairs_order=diagonals_down, perfect squares

MyOEIS::compare_values
  (anum => 'A000290',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::GcdRationals->new (pairs_order =>
                                                    'diagonals_down');
     my @got = (0);
     for (my $x = 1; @got < $count; $x++) {
       push @got, $path->xy_to_n($x,1);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A002620 - Y axis pairs_order=diagonals_up, squares and pronic

MyOEIS::compare_values
  (anum => 'A002620',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::GcdRationals->new
       (pairs_order => 'diagonals_up');
     my @got = (0,0);
     for (my $y = 1; @got < $count; $y++) {
       push @got, $path->xy_to_n(1,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A002522 - Y=X+1 above diagonal pairs_order=diagonals_up, squares+1

MyOEIS::compare_values
  (anum => 'A002522',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::GcdRationals->new (pairs_order =>
                                                    'diagonals_up');
     my @got = (1);
     for (my $i = 1; @got < $count; $i++) {
       push @got, $path->xy_to_n($i,$i+1);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
