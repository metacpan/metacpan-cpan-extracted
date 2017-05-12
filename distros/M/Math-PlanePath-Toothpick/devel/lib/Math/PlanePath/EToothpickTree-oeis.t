#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

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
plan tests => 4;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::PlanePath::EToothpickTree;

# uncomment this to run the ### lines
# use Smart::Comments '###';

my $max_count = 20;

my $e_path = Math::PlanePath::EToothpickTree->new;
my $snow_path = Math::PlanePath::EToothpickTree->new (start => 'snowflake');
my $y_path = Math::PlanePath::EToothpickTree->new (shape => 'Y');
my $v_path = Math::PlanePath::EToothpickTree->new (shape => 'V');


#------------------------------------------------------------------------------
# A161206 - total cells V

MyOEIS::compare_values
  (anum => 'A161206',
   max_count => $max_count,
   func => sub {
     my ($count) = @_;
     my @got;
     my $total = 0;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, $v_path->tree_depth_to_n($depth);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A161207 - cells added V

MyOEIS::compare_values
  (anum => 'A161207',
   max_count => $max_count,
   func => sub {
     my ($count) = @_;
     my $v_path = Math::PlanePath::EToothpickTree->new (shape => 'V');
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, ($v_path->tree_depth_to_n($depth+1)
                   - $v_path->tree_depth_to_n($depth));
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A161330 - snowflake total cells

MyOEIS::compare_values
  (anum => 'A161330',
   func => sub {
     my ($count) = @_;
     my @got;
     my $total = 0;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, $snow_path->tree_depth_to_n($depth);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A161331 - snowflake cells added

MyOEIS::compare_values
  (anum => 'A161331',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, ($snow_path->tree_depth_to_n($depth+1)
                   - $snow_path->tree_depth_to_n($depth));
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A161328 - total cells E

MyOEIS::compare_values
  (anum => 'A161328',
   # max_count => $max_count,
   func => sub {
     my ($count) = @_;
     my $e_path = Math::PlanePath::EToothpickTree->new;
     my @got;
     my $total = 0;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, $e_path->tree_depth_to_n($depth);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A161329 - cells added E

MyOEIS::compare_values
  (anum => q{A161329},
   max_count => $max_count,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, ($e_path->tree_depth_to_n($depth+1)
                   - $e_path->tree_depth_to_n($depth));
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A160120 - total cells Y

MyOEIS::compare_values
  (anum => 'A160120',
   max_count => $max_count,
   func => sub {
     my ($count) = @_;
     my $y_path = Math::PlanePath::EToothpickTree->new (shape => 'Y');
     my @got;
     my $total = 0;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, $y_path->tree_depth_to_n($depth);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A160121 - cells added Y

MyOEIS::compare_values
  (anum => 'A160121',
   max_count => $max_count,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $depth = 0; @got < $count; $depth++) {
       push @got, ($y_path->tree_depth_to_n($depth+1)
                   - $y_path->tree_depth_to_n($depth));
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
