#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2015, 2018, 2020 Kevin Ryde

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
plan tests => 9;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::FractionsTree;

# GP-DEFINE  read("my-oeis.gp");


#------------------------------------------------------------------------------
# A093873 -- Kepler numerators
# starting from 1/1 is duplicate tree halves, so repeat each row

#           1
#           -
#           1
#
#         1   1        i/(i+j) and j/(i+j)
#         -   -
#         2   2
#
#       1 2   1 2
#       - -   - -
#       3 3   3 3
#
#    1 3 2 3  1 3 2 3
#    - - - -  - - - -
#    4 4 5 5  4 4 5 5
#
# 1 4 3 4 2 5 3 5  1 4 3 4 2 5 3
# - - - - - - - -  - - - - - - -
# 5 5 7 7 7 7 8 8  5 5 7 7 7 7 8

#           1
#       /       \
#      1         1        i/(i+j) and j/(i+j)
#     / \       / \
#    1   2     1   2
#   / \ / \   / \ / \
#   1 3 2 3   1 3 2 3

#                 1/1
#       1/2                1/2
#    1/3     2/3       1/3     2/3
#  1/4 3/4 2/5 3/4   1/4 3/4 2/5 3/5


# GP-DEFINE  A093873_pq(n) = {
# GP-DEFINE    my(p=1,q=1);
# GP-DEFINE    forstep(i=logint(n,2)-1,0,-1,
# GP-DEFINE      [p,q] = [if(bittest(n,i),q,p), p+q]);
# GP-DEFINE    [p,q];
# GP-DEFINE  }
# GP-Test  my(v=OEIS_samples("A093873"));  /* OFFSET=1 */ \
# GP-Test    vector(#v,n, A093873_pq(n)[1]) == v
# GP-Test  my(v=OEIS_samples("A093875"));  /* OFFSET=1 */ \
# GP-Test    vector(#v,n, A093873_pq(n)[2]) == v

MyOEIS::compare_values
  (anum => 'A093873',
   func => sub {
     my ($count) = @_;
     my $path  = Math::PlanePath::FractionsTree->new (tree_type => 'Kepler');
     my @got;
     for (my $n = 1; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy(sans_second_highest_bit($n));
       push @got, $x;
     }
     return \@got;
   });

# denominators
MyOEIS::compare_values
  (anum => 'A093875',
   func => sub {
     my ($count) = @_;
     my $path  = Math::PlanePath::FractionsTree->new (tree_type => 'Kepler');
     my @got = (1);
     for (my $n = 2; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy(sans_second_highest_bit($n));
       push @got, $y;
     }
     return \@got;
   });

sub sans_second_highest_bit {
  my ($n) = @_;
  my $h = high_bit($n);
  $h >>= 1;
  return $h + ($n & ($h-1));
}
ok (sans_second_highest_bit(7),  3);
ok (sans_second_highest_bit(9),  5);
ok (sans_second_highest_bit(13), 5);
MyOEIS::compare_values
  (anum => 'A162751',
   name => 'sans_second_highest_bit()',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 1; @got < $count; $n++) {
       push @got, sans_second_highest_bit($n+1);
     }
     return \@got;
   });

sub high_bit {
  my ($n) = @_;
  my $bit = 1;
  while ($bit <= $n) { $bit <<= 1; }
  return $bit >> 1;
}
MyOEIS::compare_values
  (anum => 'A053644',  # OFFSET=0
   name => 'high_bit()',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       push @got, high_bit($n);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A086593 -- Kepler half-tree denominators, every second value

MyOEIS::compare_values
  (anum => 'A086593',
   name => 'Kepler half-tree denominators every second value',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path  = Math::PlanePath::FractionsTree->new (tree_type => 'Kepler');
     for (my $n = $path->n_start; @got < $count; $n += 2) {
       my ($x, $y) = $path->n_to_xy ($n);
       push @got, $y;
     }
     return \@got;
   });

# is also the sum X+Y, skipping initial 2
MyOEIS::compare_values
  (anum => q{A086593},
   name => 'as sum X+Y',
   func => sub {
     my ($count) = @_;
     my $path  = Math::PlanePath::FractionsTree->new (tree_type => 'Kepler');
     my @got = (2);
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       push @got, $x+$y;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
