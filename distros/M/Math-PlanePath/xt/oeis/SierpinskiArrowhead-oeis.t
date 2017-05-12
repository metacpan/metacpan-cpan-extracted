#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013 Kevin Ryde

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
plan tests => 14;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use MyOEIS;
use Math::PlanePath::SierpinskiCurve;
use Math::NumSeq::PlanePathTurn;

# uncomment this to run the ### lines
#use Smart::Comments '###';


#------------------------------------------------------------------------------
# A189706 - turn sequence odd positions

MyOEIS::compare_values
  (anum => 'A189706',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new
       (planepath => 'SierpinskiArrowhead',
        turn_type => 'Right');
     my @got;
     for (my $i = 1; @got < $count; $i+=2) {
       push @got, $seq->ith($i);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A189707 - (N+1)/2 of positions of odd N left turns

MyOEIS::compare_values
  (anum => 'A189707',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new
       (planepath => 'SierpinskiArrowhead',
        turn_type => 'Left');
     my @got;
     for (my $i = 1; @got < $count; $i+=2) {
       my $left = $seq->ith($i);
       if ($left) {
         push @got, ($i+1)/2;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A189708 - (N+1)/2 of positions of odd N right turns

MyOEIS::compare_values
  (anum => 'A189708',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new
       (planepath => 'SierpinskiArrowhead',
        turn_type => 'Right');
     my @got;
     for (my $i = 1; @got < $count; $i+=2) {
       my $right = $seq->ith($i);
       if ($right) {
         push @got, ($i+1)/2;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A156595 - turn sequence even positions

MyOEIS::compare_values
  (anum => 'A156595',
   func => sub {
     my ($count) = @_;
     my $seq = Math::NumSeq::PlanePathTurn->new
       (planepath => 'SierpinskiArrowhead',
        turn_type => 'Right');
     my @got;
     for (my $i = 2; @got < $count; $i+=2) {
       push @got, $seq->ith($i);
     }
     return \@got;
   });

#------------------------------------------------------------------------------

exit 0;
