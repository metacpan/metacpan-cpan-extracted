#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2018 Kevin Ryde

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
use List::Util 'min', 'max';
use Test;
plan tests => 47;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::HilbertSides;
my $path  = Math::PlanePath::HilbertSides->new;


#------------------------------------------------------------------------------
# A000975 count segments on X axis to level k
# = 10101010 binary

MyOEIS::compare_values
  (anum => 'A000975',
   max_count => 14,    # bit slow by bare search
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k=1; @got < $count; $k++) {
       my $segs = 0;
       foreach my $y (0 .. 2**$k-1) {
         $segs += defined $path->xyxy_to_n(0,$y, 0,$y+1);
       }
       push @got, $segs;
     }
     return \@got;
   });

# A005578 count segments on X axis to level k
# = 101010...1011 binary
MyOEIS::compare_values
  (anum => 'A005578',
   max_count => 14,    # bit slow by bare search
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k=0; @got < $count; $k++) {
       my $segs = 0;
       foreach my $x (0 .. 2**$k-1) {
         $segs += defined $path->xyxy_to_n($x,0, $x+1,0);
       }
       push @got, $segs;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A096268 - morphism turn 1=straight,0=not-straight
#   but OFFSET=0 is turn at N=1, so "next turn"

MyOEIS::compare_values
  (anum => 'A096268',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'HilbertSides',
                                                 turn_type => 'Straight');
     my @got;
     while (@got < $count) {
       my ($i,$value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
exit 0;
