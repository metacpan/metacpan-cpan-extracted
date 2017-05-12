#!/usr/bin/perl -w

# Copyright 2013 Kevin Ryde

# This file is part of Math-PlanePath-Toothpick.
#
# Math-PlanePath-Toothpick is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Math-PlanePath-Toothpick is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath-Toothpick.  If not, see <http://www.gnu.org/licenses/>.


use 5.004;
use strict;
use Test;
plan tests => 16;

use lib 't','xt','devel/lib';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::PlanePath::ToothpickTreeByCells;
use Math::Prime::XS 0.23 'is_prime'; # version 0.23 fix for 1928099

# uncomment this to run the ### lines
#use Smart::Comments '###';

my $max_count = undef;


#------------------------------------------------------------------------------
# A153003 - 3w total
# A153004 - 3w added    +1, 3, 3, 3, 6

MyOEIS::compare_values
  (anum => 'A153003',
   max_count => $max_count,
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::ToothpickTreeByCells->new (parts => '3w');
     my @got;
     my $total = 0;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, $path->tree_depth_to_n($depth);
     }
     return \@got;
   });

# added
MyOEIS::compare_values
  (anum => 'A153004',
   max_count => $max_count,
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::ToothpickTreeByCells->new (parts => '3w');
     my @got;
     my $total = 0;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, $path->tree_depth_to_width($depth);
     }
     return \@got;
   });

# A153005 parts=3w total cells which are primes
MyOEIS::compare_values
  (anum => 'A153005',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::ToothpickTreeByCells->new (parts => '3w');
     my @got;
     my $total = 0;
     for (my $depth = 0; @got < $count; $depth++) {
       my $n = $path->tree_depth_to_n($depth);
       if (is_prime ($n)) {
         push @got, $n;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A160158 - two toothpicks end-to-end

MyOEIS::compare_values
  (anum => 'A160158',
   max_count => $max_count,
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::ToothpickTreeByCells->new (parts => 'two_horiz');
     my @got;
     my $total = 0;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, $path->tree_depth_to_n($depth);
     }
     return \@got;
   });

# added
MyOEIS::compare_values
  (anum => 'A160159',
   max_count => $max_count,
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::ToothpickTreeByCells->new (parts => 'two_horiz');
     my @got;
     my $total = 0;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, $path->tree_depth_to_width($depth);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A160406 - wedge total cells
# http://www.polprimos.com/imagenespub/poltp406.jpg

MyOEIS::compare_values
  (anum => 'A160406',
   max_count => $max_count,
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::ToothpickTreeByCells->new (parts => 'wedge');
     my @got;
     my $total = 0;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, $path->tree_depth_to_n($depth);
     }
     return \@got;
   });

# sub full_from_wedge {
#   my ($n) = @_;
#   return 2*wedge(n) + 2*a(n+1) - 4n - 1 for n>0. - N. J. A.      
# 
# }
# use Memoize;
# BEGIN { Memoize::memoize('wedge_formula'); }

#------------------------------------------------------------------------------
# A170890 - unwedge_down_W total cells

MyOEIS::compare_values
  (anum => 'A170890',
   max_count => $max_count,
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::ToothpickTreeByCells->new (parts => 'unwedge_down_W');
     my @got;
     my $total = 0;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, $path->tree_depth_to_n($depth);
     }
     return \@got;
   });

# A170891 - unwedge_down_W added
MyOEIS::compare_values
  (anum => 'A170891',
   max_count => $max_count,
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::ToothpickTreeByCells->new (parts => 'unwedge_down_W');
     my @got = (0);
     for (my $depth = 0; @got < $count; $depth++) {
       my $added = ($path->tree_depth_to_n($depth+1)
                    - $path->tree_depth_to_n($depth));
       push @got, $added;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A170894 - unwedge_left_S total cells

MyOEIS::compare_values
  (anum => 'A170894',
   max_count => $max_count,
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::ToothpickTreeByCells->new (parts => 'unwedge_left_S');
     my @got;
     my $total = 0;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, $path->tree_depth_to_n($depth);
     }
     return \@got;
   });

# A170895 - unwedge_left_S added
MyOEIS::compare_values
  (anum => 'A170895',
   max_count => $max_count,
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::ToothpickTreeByCells->new (parts => 'unwedge_left_S');
     my @got = (0);
     for (my $depth = 0; @got < $count; $depth++) {
       my $added = ($path->tree_depth_to_n($depth+1)
                    - $path->tree_depth_to_n($depth));
       push @got, $added;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A170892 - unwedge_down total cells

MyOEIS::compare_values
  (anum => 'A170892',
   max_count => $max_count,
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::ToothpickTreeByCells->new (parts => 'unwedge_down');
     my @got;
     my $total = 0;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, $path->tree_depth_to_n($depth);
     }
     return \@got;
   });

# A170893 - unwedge_down added
MyOEIS::compare_values
  (anum => 'A170893',
   max_count => $max_count,
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::ToothpickTreeByCells->new (parts => 'unwedge_down');
     my @got = (0);
     for (my $depth = 0; @got < $count; $depth++) {
       my $added = ($path->tree_depth_to_n($depth+1)
                    - $path->tree_depth_to_n($depth));
       push @got, $added;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A170888 - unwedge_left+1 total cells

MyOEIS::compare_values
  (anum => 'A170888',
   max_count => $max_count,
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::ToothpickTreeByCells->new (parts => 'unwedge_left+1');
     my @got;
     my $total = 0;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, $path->tree_depth_to_n($depth);
     }
     return \@got;
   });

# A170889 - unwedge_left+1 added
MyOEIS::compare_values
  (anum => 'A170889',
   max_count => $max_count,
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::ToothpickTreeByCells->new (parts => 'unwedge_left+1');
     my @got = (0);
     for (my $depth = 0; @got < $count; $depth++) {
       my $added = ($path->tree_depth_to_n($depth+1)
                    - $path->tree_depth_to_n($depth));
       push @got, $added;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A170886 - unwedge_left total cells

MyOEIS::compare_values
  (anum => 'A170886',
   max_count => $max_count,
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::ToothpickTreeByCells->new (parts => 'unwedge_left');
     my @got;
     my $total = 0;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, $path->tree_depth_to_n($depth);
     }
     return \@got;
   });

# A170887 - unwedge_left added
MyOEIS::compare_values
  (anum => 'A170887',
   max_count => $max_count,
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::ToothpickTreeByCells->new (parts => 'unwedge_left');
     my @got = (0);
     for (my $depth = 0; @got < $count; $depth++) {
       my $added = ($path->tree_depth_to_n($depth+1)
                    - $path->tree_depth_to_n($depth));
       push @got, $added;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
