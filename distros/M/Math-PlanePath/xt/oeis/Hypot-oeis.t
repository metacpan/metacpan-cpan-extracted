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
plan tests => 1;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::Hypot;

# uncomment this to run the ### lines
# use Smart::Comments '###';


#------------------------------------------------------------------------------
# A199015 -- partial sums of A008441

MyOEIS::compare_values
  (anum => 'A199015',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::Hypot->new(points=>'square_centred');
     my @got;
     my $n = $path->n_start;
     my $num = 0;
     my $want_norm = 2;
     while (@got < $count) {
       my ($x,$y) = $path->n_to_xy($n);
       my $norm = $x*$x + $y*$y;
       if ($norm > $want_norm) {
         ### push: $num
         push @got, $num/4;
         $want_norm += 8;
       } else {
         ### point: "$n at $x,$y norm=$norm  total num=$num"
         $n++;
         $num++;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A005883 -- count points with norm==4*n+1
#            Theta series of square lattice with respect to deep hole.
#
# same as "odd" turned 45-degrees
#
#    3   .   2   .   2   .   3
#
#    .   .   .   .   .   .   .
#            
#    2   .   1   .   1   .   2
#            
#    .   .   .   o   .   .   .
#
#    2   .   1   .   1   .   2
#            
#    .   .   .   .   .   .   .
#
#    3   .   2   .   2   .   3
#
#   4, 8, 4, 8,8,0,12,8,0,8,8,8,4,8,0,8,16,0,8,0,4


MyOEIS::compare_values
  (anum => 'A005883',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::Hypot->new(points=>'square_centred');
     my @got;
     my $n = $path->n_start;
     my $num = 0;
     my $want_norm = 2;
     while (@got < $count) {
       my ($x,$y) = $path->n_to_xy($n);
       my $norm = $x*$x + $y*$y;
       if ($norm > $want_norm) {
         ### push: $num
         push @got, $num;
         $want_norm += 8;
         $num = 0;
       } else {
         ### point: "$n at $x,$y norm=$norm  total num=$num"
         $n++;
         $num++;
       }
     }
     return \@got;
   });

# A008441 = A005883/4
# how many ways to write n = x(x+1)/2 + y(y+1)/2 sum two triangulars
MyOEIS::compare_values
  (anum => 'A008441',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::Hypot->new(points=>'square_centred');
     my @got;
     my $n = $path->n_start;
     my $num = 0;
     my $want_norm = 2;
     while (@got < $count) {
       my ($x,$y) = $path->n_to_xy($n);
       my $norm = $x*$x + $y*$y;
       if ($norm > $want_norm) {
         ### push: $num
         push @got, $num/4;
         $want_norm += 8;
         $num = 0;
       } else {
         ### point: "$n at $x,$y norm=$norm  total num=$num"
         $n++;
         $num++;
       }
     }
     return \@got;
   });

# MyOEIS::compare_values
#   (anum => 'A005883',
#    func => sub {
#      my ($count) = @_;
#      my @got;
#      my $path = Math::PlanePath::Hypot->new (points => 'square_centred');
#      my $n = $path->n_start;
#      my $i = 0;
#      for (my $i = 0; @got < $count; $i++) {
#        my $points = 0;
#        for (;;) {
#          my $h = $path->n_to_rsquared($n);
#          if ($h > 4*$i+1) {
#            last;
#          }
#          $points++;
#          $n++;
#        }
#        ### $points
#        push @got, $points;
#      }
#      return \@got;
#    });

#------------------------------------------------------------------------------
# A004020 Theta series of square lattice with respect to edge.
#         2,4,2,4,4

#
#         2   .   2   . 
#         
#     .   .   .   .   .   .
#         
#     .   1   o   1   .
#
#     .   .   .   .
#         
#     .   2   .   2   .
#
# Y mod 2 == 0
# X mod 2 == 1
# X+2Y mod 4 == 1

sub xy_is_edge {
  my ($x, $y) = @_;
  return ($y%2 == 0 && $x%2 == 1);
}

MyOEIS::compare_values
  (anum => q{A004020},       # with zeros
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::Hypot->new;
     my @got;
     my $n = $path->n_start;
     my $num = 0;
     my $want_norm = 1;
     while (@got < $count) {
       my ($x,$y) = $path->n_to_xy($n);
       if (! xy_is_edge($x,$y)) {
         $n++;
         next;
       }
       my $norm = $path->n_to_rsquared($n);
       if ($norm > $want_norm) {
         ### push: $num
         push @got, $num;
         $want_norm += 4;
         $num = 0;
       } else {
         ### point: "$n at $x,$y norm=$norm  total num=$num"
         $n++;
         $num++;
       }
     }
     return \@got;
   });



#------------------------------------------------------------------------------
# A093837 - denominators N(r) / r^2

{
  my $path = Math::PlanePath::Hypot->new;
  sub Nr {
    my ($r) = @_;
    my $n = $path->xy_to_n($r,0);
    for (;;) {
      my $m = $n+1;
      my ($x,$y) = $path->n_to_xy($m);
      if ($x*$x+$y*$y > $r*$r) {
        return $n;
      }
      $n = $m;
    }
  }
}
MyOEIS::compare_values
  (anum => q{A093837},
   func => sub {
     my ($count) = @_;
     require Math::BigRat;
     my @got;
     for (my $r = 1; @got < $count; $r++) {
       my $Nr = Nr($r);
       my $rsquared = $r*$r;
       my $frac = Math::BigRat->new("$Nr/$rsquared");
       push @got, $frac->denominator;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A093832 - N(r) / r^2 > pi

use Math::Trig 'pi';

MyOEIS::compare_values
  (anum => q{A093832},
   func => sub {
     my ($count) = @_;
     require Math::BigRat;
     my @got;
     for (my $r = 1; @got < $count; $r++) {
       my $Nr = Nr($r);
       my $rsquared = $r*$r;
       if ($Nr / $rsquared > pi) {
         push @got, $r;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
