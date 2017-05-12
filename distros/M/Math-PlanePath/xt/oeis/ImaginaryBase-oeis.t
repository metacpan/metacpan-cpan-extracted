#!/usr/bin/perl -w

# Copyright 2012, 2013 Kevin Ryde

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
plan tests => 4;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::ImaginaryBase;
use Math::PlanePath::Diagonals;
use Math::PlanePath::Base::Digits
  'bit_split_lowtohigh';

# uncomment this to run the ### lines
# use Smart::Comments '###';


#------------------------------------------------------------------------------
# A057300 -- N at transpose Y,X, radix=2

MyOEIS::compare_values
  (anum => 'A057300',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::ImaginaryBase->new;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       ($x, $y) = ($y, $x);
       my $n = $path->xy_to_n ($x, $y);
       push @got, $n;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163327 -- N at transpose Y,X, radix=3

MyOEIS::compare_values
  (anum => 'A163327',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::ImaginaryBase->new (radix => 3);
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       ($x, $y) = ($y, $x);
       my $n = $path->xy_to_n ($x, $y);
       push @got, $n;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A126006 -- N at transpose Y,X, radix=4

MyOEIS::compare_values
  (anum => 'A126006',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::ImaginaryBase->new (radix => 4);
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       ($x, $y) = ($y, $x);
       my $n = $path->xy_to_n ($x, $y);
       push @got, $n;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A217558 -- N at transpose Y,X, radix=16

MyOEIS::compare_values
  (anum => 'A217558',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::ImaginaryBase->new (radix => 16);
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x, $y) = $path->n_to_xy ($n);
       ($x, $y) = ($y, $x);
       my $n = $path->xy_to_n ($x, $y);
       push @got, $n;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A039724 -- negabinary positives -> index, written in binary

MyOEIS::compare_values
  (anum => q{A039724},
   func => sub {
     my ($count) = @_;
     my @got;
     require Math::PlanePath::ZOrderCurve;
     my $path = Math::PlanePath::ImaginaryBase->new;
     my $zorder = Math::PlanePath::ZOrderCurve->new;

     for (my $nega = 0; @got < $count; $nega++) {
       my $n = $path->xy_to_n ($nega,0);
       $n = delete_odd_bits($n);
       push @got, to_binary($n);
     }

     return \@got;
   });

sub delete_odd_bits {
  my ($n) = @_;
  my @bits = bit_split_lowtohigh($n);
  my $bit = 1;
  my $ret = 0;
  while (@bits) {
    if (shift @bits) {
      $ret |= $bit;
    }
    shift @bits;
    $bit <<= 1;
  }
  return $ret;
}
# or by string ...
# if (length($str) & 1) { $str = "0$str" }
# $str =~ s/.(.)/$1/g;

sub to_binary {
  my ($n) = @_;
  return ($n < 0 ? '-' : '') . sprintf('%b', abs($n));
}

#------------------------------------------------------------------------------

exit 0;
