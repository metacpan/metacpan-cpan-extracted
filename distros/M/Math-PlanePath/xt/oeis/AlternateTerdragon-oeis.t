#!/usr/bin/perl -w

# Copyright 2018 Kevin Ryde

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

use Math::PlanePath::AlternateTerdragon;
my $path = Math::PlanePath::AlternateTerdragon->new;

sub ternary_digit_above_low_zeros {
  my ($n) = @_;
  if ($n == 0) {
    return 0;
  }
  while (($n % 3) == 0) {
    $n = int($n/3);
  }
  return ($n % 3);
}

#------------------------------------------------------------------------------
# A189715 - N of left turns

MyOEIS::compare_values
  (anum => 'A189715',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'Left');
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value == 1) { push @got, $i; }
     }
     return \@got;
   });

# A189716 - N of right turns

MyOEIS::compare_values
  (anum => 'A189716',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'Right');
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       if ($value == 1) { push @got, $i; }
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A156595 - turn 0=left, 1=right

MyOEIS::compare_values
  (anum => 'A156595',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'Right');
     my @got;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       push @got, $value;
     }
     return \@got;
   });

# A189717 - cumulative A156595 = num right turns
MyOEIS::compare_values
  (anum => 'A189717',
   func => sub {
     my ($count) = @_;
     require Math::NumSeq::PlanePathTurn;
     my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                 turn_type => 'Right');
     my @got;
     my $total = 0;
     while (@got < $count) {
       my ($i, $value) = $seq->next;
       $total += $value;
       push @got, $total;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
exit 0;
