#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2015, 2016, 2018 Kevin Ryde

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
plan tests => 11;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::Flowsnake;
my $path = Math::PlanePath::Flowsnake->new;


#------------------------------------------------------------------------------
# centres of successive hexagons which approach the centre
#
# centre is 3/8
# centre of first hexagon in set of 7 is 3/56
# then next is a reverse so 2/7-3/56 == 13/56
# then in centre of set of 7 and is a reverse so go through 4 to reach centre
# etc

# A262147  numerators
#          3, 13, 115, 125, 19, 141, 1011, 1021, 7171, 7181, 1027, 7197, 50403,
#          a(n) = 50*a(n-6)-49*a(n-12) for n>12
# A262148  denominators
#          56, 56, 392, 392, 56, 392  then a(n) = 49*a(n-6)
# 56==8*7
# 392==8*7^2
# 


#------------------------------------------------------------------------------
# A261180 - direction 0 to 5
#
#   *---*---*    
#    \       \     /
#     *---*   *---*
#        /
#   *---*              
#     0, 1, 3, 2, 0, 0, 5, 0, 1
{
  my %dxdy_to_dirpn3 = ('2,0' => 0,     #      2   1
                        '1,1' => 1,     #       \ /
                        '-1,1' => 2,    #   3 ---*--- 0
                        '-2,0' => 3,    #       / \
                        '-1,-1' => 4,   #      4   5
                        '1,-1' => 5);
  MyOEIS::compare_values
      (anum => 'A261180',
       func => sub {
         my ($count) = @_;
         my @got;
         for (my $n = $path->n_start; @got < $count; $n++) {
           my ($dx,$dy) = $path->n_to_dxdy($n);
           my $dir = $dxdy_to_dirpn3{"$dx,$dy"};
           die if ! defined $dir;
           push @got, $dir;
         }
         return \@got;
       });

  # same, mod 2
  MyOEIS::compare_values
      (anum => 'A261185',
       func => sub {
         my ($count) = @_;
         my @got;
         for (my $n = $path->n_start; @got < $count; $n++) {
           my ($dx,$dy) = $path->n_to_dxdy($n);
           my $dir = $dxdy_to_dirpn3{"$dx,$dy"};
           die if ! defined $dir;
           push @got, $dir % 2;
         }
         return \@got;
       });
}

#------------------------------------------------------------------------------
# A229214 - direction 1,2,3,-1,-2,-3
#
#   *---*---*    
#    \       \     /
#     *---*   *---*
#        /
#   *---*              
#     1, 2, -1, 3, 1, 1
{
  my %dxdy_to_dirpn3 = ('2,0' => 1,      #       3   2
                        '1,1' => 2,      #        \ /
                        '-1,1' => 3,     #   -1 ---*--- 1
                        '-2,0' => -1,    #        / \
                        '-1,-1' => -2,   #      -2   -3
                        '1,-1' => -3);
  MyOEIS::compare_values
      (anum => 'A229214',
       func => sub {
         my ($count) = @_;
         my @got;
         for (my $n = $path->n_start; @got < $count; $n++) {
           my ($dx,$dy) = $path->n_to_dxdy($n);
           my $dir = $dxdy_to_dirpn3{"$dx,$dy"};
           die if ! defined $dir;
           push @got, $dir;
         }
         return \@got;
       });
}

#------------------------------------------------------------------------------
exit 0;
