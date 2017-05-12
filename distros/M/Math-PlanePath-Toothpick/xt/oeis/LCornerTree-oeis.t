#!/usr/bin/perl -w

# Copyright 2012, 2013 Kevin Ryde

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
plan tests => 9;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::PlanePath::LCornerTree;

# uncomment this to run the ### lines
#use Smart::Comments '###';

#------------------------------------------------------------------------------
# A162784 - added cells parts=octant
# cf octant+1 would be A162784+1, no such entry

MyOEIS::compare_values
  (anum => 'A162784',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::LCornerTree->new (parts => 'octant');
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, $path->tree_depth_to_width($depth);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A151712 - added cells parts=wedge

MyOEIS::compare_values
  (anum => 'A151712',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::LCornerTree;
     my $path = Math::PlanePath::LCornerTree->new (parts => 'wedge');
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, $path->tree_depth_to_width($depth);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A183149 - added cells parts=diagonal-1

# Half plane, points at boundary Y=0 are considered not exposed and no
# growth from there.
#
#            *       *        
#            |       |        
#            2       3        
#            |       |        
#    *---2---*---2---*---3---*
#            |       |        
#            1       3        
#            |       |         
#            *       *        
#

MyOEIS::compare_values
  (anum => 'A183149',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::LCornerTree;
     my $path = Math::PlanePath::LCornerTree->new (parts => 'diagonal-1');
     my @got = (0);
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, $path->tree_depth_to_width($depth);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A183126 - added cells parts=diagonal-2

# 16 = 2*(3+2+2)
MyOEIS::compare_values
  (anum => 'A183127',  # 0,1,6,16,16,40
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::LCornerTreeByCells;
     my $path = Math::PlanePath::LCornerTreeByCells->new (parts => 'diagonal-2');
     my @got = (0);
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, $path->tree_depth_to_width($depth);
     }
     return \@got;
   });
MyOEIS::compare_values
  (anum => 'A183126',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::LCornerTreeByCells;
     my $path = Math::PlanePath::LCornerTreeByCells->new (parts => 'diagonal-2');
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, $path->tree_depth_to_n($depth);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A161411 - added cells parts=4

MyOEIS::compare_values
  (anum => 'A161411',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::LCornerTree->new;
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, $path->tree_depth_to_width($depth);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A162349 - added cells parts=3

MyOEIS::compare_values
  (anum => 'A162349',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::LCornerTree->new (parts => 3);
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, $path->tree_depth_to_width($depth);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A130665 - total cells parts=1, without initial 0

MyOEIS::compare_values
  (anum => 'A130665',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::LCornerTree->new (parts => 1);
     my @got;
     for (my $depth = 1; @got < $count; $depth++) {
       push @got, $path->tree_depth_to_n($depth);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A048883 - added cells parts=1

MyOEIS::compare_values
  (anum => 'A048883',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::LCornerTree->new (parts => 1);
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, $path->tree_depth_to_width($depth);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
