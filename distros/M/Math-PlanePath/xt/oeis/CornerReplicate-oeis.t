#!/usr/bin/perl -w

# Copyright 2012, 2013, 2015 Kevin Ryde

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
plan tests => 3;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::CornerReplicate;
use Math::PlanePath::Base::Digits 'bit_split_lowtohigh';

# uncomment this to run the ### lines
#use Smart::Comments '###';

my $crep = Math::PlanePath::CornerReplicate->new;

#------------------------------------------------------------------------------
# A139351 - HammingDist(X,Y) = count 1-bits at even bit positions in N    

MyOEIS::compare_values
  (name => 'HammingDist(X,Y)',
   anum => 'A139351',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my ($x, $y) = $crep->n_to_xy($n);
       push @got, HammingDist($x,$y);
     }
     return \@got;
   });

sub HammingDist {
  my ($x,$y) = @_;
  my @xbits = bit_split_lowtohigh($x);
  my @ybits = bit_split_lowtohigh($y);
  my $ret = 0;
  while (@xbits || @ybits) {
    $ret += (shift @xbits ? 1 : 0) ^ (shift @ybits ? 1 : 0);
  }
  return $ret;
}

#------------------------------------------------------------------------------
# A048647 -- permutation N at transpose Y,X

MyOEIS::compare_values
  (anum => 'A048647',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $crep->n_start; @got < $count; $n++) {
       my ($x, $y) = $crep->n_to_xy ($n);
       ($x, $y) = ($y, $x);
       my $n = $crep->xy_to_n ($x, $y);
       push @got, $n;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163241 -- flip base-4 digits 2,3 maps to ZOrderCurve

MyOEIS::compare_values
  (anum => 'A163241',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::ZOrderCurve;
     my $zorder = Math::PlanePath::ZOrderCurve->new;
     my @got;
     for (my $n = $crep->n_start; @got < $count; $n++) {
       my ($x, $y) = $crep->n_to_xy ($n);
       my $n = $zorder->xy_to_n ($x, $y);
       push @got, $n;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
