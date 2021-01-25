#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2018, 2019, 2021 Kevin Ryde

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
plan tests => 13;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::DiagonalsOctant;
use Math::PlanePath::Diagonals;
use Math::PlanePath::PyramidRows;


#------------------------------------------------------------------------------
# A274427 -- DiagonalsOctant part of Diagonals

MyOEIS::compare_values
  (anum => 'A274427',
   func => sub {
     my ($count) = @_;
     my @got;
     my $oct = Math::PlanePath::DiagonalsOctant->new;
     my $all = Math::PlanePath::Diagonals->new;
     for (my $n = $oct->n_start; @got < $count; $n++) {
       my ($x,$y) = $oct->n_to_xy($n);
       push @got, $all->xy_to_n($x,$y);
     }

     my $path = Math::PlanePath::DiagonalsOctant->new (n_start => 0);

     return \@got;
   });

#------------------------------------------------------------------------------
# A079826 -- concat of rows numbers in diagonals octant order
#            rows numbered alternately left and right

MyOEIS::compare_values
  (anum => q{A079826}, # not xreffed
   max_count => 10,  # various dodginess from a(11)=785753403227

   func => sub {
     my ($count) = @_;
     my @got;
     my $diag = Math::PlanePath::DiagonalsOctant->new;
     my $rows = Math::PlanePath::PyramidRows->new(step=>1);
     my $prev_d = 0;
     my $str = '';
     for (my $n = Math::BigInt->new($diag->n_start); @got < $count; $n++) {
       my ($x,$y) = $diag->n_to_xy($n);
       my $d = $x+$y;
       if ($d != $prev_d) {
         push @got, Math::BigInt->new($str);
         $str = '';
         $prev_d = $d;
       }
       if ($y % 2) {
         $x = $y-$x;
       }
       my $rn = $rows->xy_to_n($x,$y);
       if ($rn >= 73) { $rn -= 2; }
       if ($rn >= 99) { $rn -= 2; }
       if ($rn >= 129) { $rn -= 2; }
       $str .= $rn;
     }
     return \@got;
   });

# foreach my $y (0 .. 21) {
#   foreach my $x (0 .. $y) {
#     # if ($x+$y > 11) {
#     #   print "...";
#     #   last;
#     # }
#     my $n = $rows->xy_to_n(($y % 2 ? $y-$x : $x), $y);
#     printf "%4d", $n;
#   }
#   print "\n";
# }


#------------------------------------------------------------------------------
# A014616 -- N in column X=1

MyOEIS::compare_values
  (anum => 'A014616',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::DiagonalsOctant->new (direction => 'up',
                                                       n_start => 0);
     for (my $y = 1; @got < $count; $y++) {
       push @got, $path->xy_to_n (1,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A079823 -- concat of rows numbers in diagonals octant order

MyOEIS::compare_values
  (anum => q{A079823}, # not xreffed
   func => sub {
     my ($count) = @_;
     my @got;
     my $diag = Math::PlanePath::DiagonalsOctant->new;
     my $rows = Math::PlanePath::PyramidRows->new(step=>1);
     my $prev_d = 0;
     my $str = '';
     for (my $n = $diag->n_start; @got < $count; $n++) {
       my ($x,$y) = $diag->n_to_xy($n);
       my $d = $x+$y;
       if ($d != $prev_d) {
         push @got, $str;
         $str = '';
         $prev_d = $d;
       }
       $str .= $rows->xy_to_n($x,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A091018 -- permutation diagonals octant -> rows, 0 based

MyOEIS::compare_values
  (anum => 'A091018',
   func => sub {
     my ($count) = @_;
     my @got;
     my $diag = Math::PlanePath::DiagonalsOctant->new;
     my $rows = Math::PlanePath::PyramidRows->new(step=>1);
     for (my $n = $diag->n_start; @got < $count; $n++) {
       my ($x,$y) = $diag->n_to_xy($n);
       push @got, $rows->xy_to_n($x,$y) - 1;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A090894 -- permutation diagonals octant -> rows, 0 based, upwards

MyOEIS::compare_values
  (anum => 'A090894',
   func => sub {
     my ($count) = @_;
     my @got;
     my $diag = Math::PlanePath::DiagonalsOctant->new(direction=>'up');
     my $rows = Math::PlanePath::PyramidRows->new(step=>1);
     for (my $n = $diag->n_start; @got < $count; $n++) {
       my ($x,$y) = $diag->n_to_xy($n);
       push @got, $rows->xy_to_n($x,$y) - 1;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A091995 -- permutation diagonals octant -> rows, 1 based, upwards

MyOEIS::compare_values
  (anum => 'A091995',
   func => sub {
     my ($count) = @_;
     my @got;
     my $diag = Math::PlanePath::DiagonalsOctant->new(direction=>'up');
     my $rows = Math::PlanePath::PyramidRows->new(step=>1);
     for (my $n = $diag->n_start; @got < $count; $n++) {
       my ($x,$y) = $diag->n_to_xy($n);
       push @got, $rows->xy_to_n($x,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A056536 -- permutation diagonals octant -> rows

MyOEIS::compare_values
  (anum => 'A056536',
   func => sub {
     my ($count) = @_;
     my @got;
     my $diag = Math::PlanePath::DiagonalsOctant->new;
     my $rows = Math::PlanePath::PyramidRows->new(step=>1);
     for (my $n = $diag->n_start; @got < $count; $n++) {
       my ($x,$y) = $diag->n_to_xy($n);
       push @got, $rows->xy_to_n($x,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A056537 -- permutation rows -> diagonals octant

MyOEIS::compare_values
  (anum => 'A056537',
   func => sub {
     my ($count) = @_;
     my @got;
     my $diag = Math::PlanePath::DiagonalsOctant->new;
     my $rows = Math::PlanePath::PyramidRows->new(step=>1);
     for (my $n = $rows->n_start; @got < $count; $n++) {
       my ($x,$y) = $rows->n_to_xy($n);
       push @got, $diag->xy_to_n($x,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A004652 -- N start,end of even diagonals

MyOEIS::compare_values
  (anum => 'A004652',
   func => sub {
     my ($count) = @_;
     my @got = (0);
     my $path = Math::PlanePath::DiagonalsOctant->new;
     for (my $y = 0; @got < $count; $y += 2) {
       push @got, $path->xy_to_n (0,$y);
       last unless @got < $count;
       push @got, $path->xy_to_n ($y/2,$y/2);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A002620 -- N end each diagonal, extra initial 0s

MyOEIS::compare_values
  (anum => 'A002620',
   func => sub {
     my ($count) = @_;
     my @got = (0,0);
     my $path = Math::PlanePath::DiagonalsOctant->new;
     for (my $x = 0; @got < $count; $x++) {
       push @got, $path->xy_to_n ($x,$x);
       last unless @got < $count;
       push @got, $path->xy_to_n ($x,$x+1);
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A002620',
   func => sub {
     my ($count) = @_;
     my @got = (0,0);
     my $path = Math::PlanePath::DiagonalsOctant->new (direction => 'up');
     for (my $y = 0; @got < $count; $y++) {
       push @got, $path->xy_to_n (0,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A092180 -- primes in rows, traversed by DiagonalOctant

MyOEIS::compare_values
  (anum => q{A092180},  # not cross-reffed in docs
   func => sub {
     my ($count) = @_;
     my @got;
     my $diag = Math::PlanePath::DiagonalsOctant->new(direction=>'up');
     my $rows = Math::PlanePath::PyramidRows->new(step=>1);
     for (my $n = $diag->n_start; @got < $count; $n++) {
       my ($x,$y) = $diag->n_to_xy($n);
       push @got, MyOEIS::ith_prime($rows->xy_to_n($x,$y));
     }
     return \@got;
   });


#------------------------------------------------------------------------------
exit 0;
