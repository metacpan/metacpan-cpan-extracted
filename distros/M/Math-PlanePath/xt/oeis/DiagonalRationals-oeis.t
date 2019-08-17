#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2019 Kevin Ryde

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

use Math::PlanePath::DiagonalRationals;
my $diagrat = Math::PlanePath::DiagonalRationals->new;

# uncomment this to run the ### lines
#use Smart::Comments '###';


#------------------------------------------------------------------------------
# A038567 -- X+Y except no 0/1 in path

MyOEIS::compare_values
  (anum => 'A038567',
   max_count => 10000,
   func => sub {
     my ($count) = @_;
     my @got = (1);
     for (my $n = $diagrat->n_start; @got < $count; $n++) {
       my ($x, $y) = $diagrat->n_to_xy ($n);
       push @got, $x+$y;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A054430 -- N at transpose Y,X

MyOEIS::compare_values
  (anum => 'A054430',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $diagrat->n_start; @got < $count; $n++) {
       my ($x, $y) = $diagrat->n_to_xy ($n);
       ($x, $y) = ($y, $x);
       my $n = $diagrat->xy_to_n ($x, $y);
       push @got, $n;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A054431 - by anti-diagonals 1 if coprime, 0 if not

MyOEIS::compare_values
  (anum => 'A054431',
   func => sub {
     my ($count) = @_;
     my @got;
     my $prev_n = $diagrat->n_start - 1;
   OUTER: for (my $y = 1; ; $y ++) {
       foreach my $x (1 .. $y-1) {
         my $n = $diagrat->xy_to_n($x,$y-$x);
         if (defined $n) {
           push @got, 1;
           if ($n != $prev_n + 1) {
             die "oops, not n+1";
           }
           $prev_n = $n;
         } else {
           push @got, 0;
         }
         last OUTER if @got >= $count;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A054424 - permutation diagonal N -> SB N
# A054426 - inverse SB N -> Cantor N

MyOEIS::compare_values
  (anum => 'A054424',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::RationalsTree;
     my $sb = Math::PlanePath::RationalsTree->new (tree_type => 'SB');
     my @got;
     foreach my $n (1 .. $count) {
       my ($x,$y) = $diagrat->n_to_xy ($n);
       push @got, $sb->xy_to_n($x,$y);
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A054426',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::RationalsTree;
     my $sb = Math::PlanePath::RationalsTree->new (tree_type => 'SB');
     my @got;
     foreach my $n (1 .. $count) {
       my ($x,$y) = $sb->n_to_xy ($n);
       push @got, $diagrat->xy_to_n($x,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A054425 - A054424 mapping expanded out to 0s at common-factor X,Y

MyOEIS::compare_values
  (anum => 'A054425',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::Diagonals;
     require Math::PlanePath::RationalsTree;
     my $diag = Math::PlanePath::Diagonals->new (x_start=>1, y_start=>1);
     my $sb = Math::PlanePath::RationalsTree->new (tree_type => 'SB');
     my @got;
     for (my $n = $diag->n_start; @got < $count; $n++) {
       my ($x,$y) = $diag->n_to_xy($n);
       ### frac: "$x/$y"
       my $cn = $diagrat->xy_to_n ($x,$y);
       if (defined $cn) {
         push @got, $sb->xy_to_n($x,$y);
       } else {
         push @got, 0;
       }
     }
     return \@got;
   });


exit 0;
