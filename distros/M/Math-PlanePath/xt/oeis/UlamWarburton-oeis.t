#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2015, 2020 Kevin Ryde

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
use List::Util 'sum';
use Test;
plan tests => 12;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

# uncomment this to run the ### lines
# use Smart::Comments '###';

use Math::PlanePath::UlamWarburton;


my @dir4_to_dx = (1,0,-1,0);
my @dir4_to_dy = (0,1,0,-1);

#------------------------------------------------------------------------------
# A264768 surrounded
# A264769 surrounded increment
# A264039 num poisoned
# A260490 num newly poisoned

# all surrounded 4
MyOEIS::compare_values
  (anum => 'A264768',
   func => sub {
     my ($count) = @_;
     return poisoned($count, 0, 4);
   });
# newly surrounded 4
MyOEIS::compare_values
  (anum => 'A264769',
   func => sub {
     my ($count) = @_;
     return poisoned($count, 1, 4);
   });

# all poisoned
MyOEIS::compare_values
  (anum => 'A264039',
   func => sub {
     my ($count) = @_;
     return poisoned($count, 0, 2);
   });

# newly poisoned
MyOEIS::compare_values
  (anum => 'A260490',
   func => sub {
     my ($count) = @_;
     return poisoned($count, 1, 2);
   });

sub poisoned {
  my ($count, $newly, $target) = @_;
  my $path = Math::PlanePath::UlamWarburton->new;
  my @got = (0);
  my %seen;
  my %poisoned;
  my $prev = 0;
  for (my $depth = 0; @got < $count; $depth++) {
    foreach my $n ($path->tree_depth_to_n($depth)
                   .. $path->tree_depth_to_n_end($depth)) {
      my ($x,$y) = $path->n_to_xy($n);
      $seen{"$x,$y"}++;
      foreach my $dir4 (0 .. $#dir4_to_dx) {
        my $x2 = $x + $dir4_to_dx[$dir4];
        my $y2 = $y + $dir4_to_dy[$dir4];
        $poisoned{"$x2,$y2"}++;
      }
    }
    my $total = sum(0, map {$poisoned{$_}>=$target && !$seen{$_}} keys %poisoned);
    push @got, $newly ? $total - $prev : $total;
    $prev = $total;
  }
  return \@got;
}


#------------------------------------------------------------------------------
# A255264 - count cells up to A048645(n) = bits with one or two 1-bits

sub A048645_pred {
  my ($n) = @_;
  my $c = 0;
  for ( ; $n; $n>>=1) { $c += ($n&1); }
  return $c==1 || $c==2;
}

MyOEIS::compare_values
  (anum => 'A048645',
   max_count => 12,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       if (A048645_pred($n)) {
         push @got, $n;
       }
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A255264',
   max_count => 10,
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::UlamWarburton->new;
     my @got;
     for (my $depth = 1; @got < $count; $depth++) {
       next unless A048645_pred($depth);
       push @got, $path->tree_depth_to_n_end($depth-1);
     }
     return \@got;
   });

#------------------------------------------------------------------------------

# my @grid;
# my $offset = 30;
# my @n_start;
#
# my $prev = 0;
# $grid[0+$offset][0+$offset] = 0;
# foreach my $n (1 .. 300) {
#   my ($x,$y) = $path->n_to_xy($n);
#   my $l = $grid[$x+$offset-1][$y+$offset]
#     ||  $grid[$x+$offset+1][$y+$offset]
#       || $grid[$x+$offset][$y+$offset-1]
#         ||  $grid[$x+$offset][$y+$offset+1]
#           || 0;
#   if ($l != $prev) {
#     push @n_start, $n;
#     $prev = $l;
#   }
#   $grid[$x+$offset][$y+$offset] = $l+1;
# }
# ### @n_start
# my @n_end = map {$_-1} @n_start;
# ### @n_end
#
# my @levelcells = (1, map {$n_start[$_]-$n_start[$_-1]} 1 .. $#n_start);
# ### @levelcells

# foreach my $y (reverse -$offset .. $offset) {
#   foreach my $x (-$offset .. $offset) {
#     my $c = $grid[$x+$offset][$y+$offset];
#     if (! defined $c) { $c = ' '; }
#     print $c;
#   }
#   print "\n";
# }


#------------------------------------------------------------------------------
# A183060 - count total cells in half plane, including axes

MyOEIS::compare_values
  (anum => 'A183060',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::UlamWarburton->new (parts => '2',
                                                     n_start => 0);
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, $path->tree_depth_to_n($depth);
     }
     return \@got;
   });

# added cells
MyOEIS::compare_values
  (anum => 'A183061',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::UlamWarburton->new (parts => '2');
     my @got = (0);
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, $path->tree_depth_to_width($depth);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A151922 - count total cells in first quadrant, incl X,Y axes

MyOEIS::compare_values
  (anum => 'A151922',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::UlamWarburton->new (parts => '1');
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, $path->tree_depth_to_n_end($depth);
     }
     return \@got;
   });

# added
MyOEIS::compare_values
  (anum => 'A079314',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::UlamWarburton->new (parts => '1');
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, $path->tree_depth_to_width($depth);
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => q{A151922},
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::UlamWarburton->new;
     my $n = $path->n_start;
     my $total = 0;
     for (my $depth = 0; @got < $count; $depth++) {
       my $n_end = $path->tree_depth_to_n_end($depth);
       for ( ; $n <= $n_end; $n++) {
         my ($x,$y) = $path->n_to_xy($n);
         if ($x >= 0 && $y >= 0) {
           $total++;
         }
       }
       push @got, $total;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A079314 - count added cells in first quadrant, incl X,Y axes
#   is added(depth)/4 + 1, the +1 being for two axes
#
MyOEIS::compare_values
  (anum => 'A079314',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::UlamWarburton->new;
     my @got;
     my $n = $path->n_start;
     for (my $depth = 0; @got < $count; $depth++) {
       my $n_end = $path->tree_depth_to_n_end($depth);
       my $added = 0;
       for ( ; $n <= $n_end; $n++) {
         my ($x,$y) = $path->n_to_xy($n);
         if ($x >= 0 && $y >= 0) {
           $added++;
         }
       }
       push @got, $added;
     }
     return \@got;
   });

#------------------------------------------------------------------------------

exit 0;
