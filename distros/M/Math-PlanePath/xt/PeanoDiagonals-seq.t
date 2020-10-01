#!/usr/bin/perl -w

# Copyright 2019, 2020 Kevin Ryde

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
use Carp 'croak';

use Test;
plan tests => 1;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::NumSeq::PlanePathTurn;

use File::Spec;
use lib File::Spec->catdir('devel','lib');

use Math::PlanePath::PeanoDiagonals;


#------------------------------------------------------------------------------
# Turn Sequence - per POD

sub turn {
  my ($n, $radix) = @_;
  $n >= 1 or croak "turn is for n>=1";

  my $v = $n;
  until ($v % $radix) {
    $v >= 1 or die;
    $n++;
    $v = int($v/$radix);
  }
  (-1)**$n;
}

{
  my $bad = 0;
  foreach my $radix (3,5,7) {
    my $path = Math::PlanePath::PeanoDiagonals->new (radix => $radix);
    my $seq = Math::NumSeq::PlanePathTurn->new (planepath_object => $path,
                                                turn_type => 'LSR');
    foreach my $n (1 .. $radix**6) {
      my ($seq_i, $seq_turn) = $seq->next;
      my $turn = turn($n,$radix);
      unless ($n == $seq_i) { $bad++; }
      unless ($turn == $seq_turn) { $bad++; }
    }
  }
  ok ($bad, 0);
}

#------------------------------------------------------------------------------
exit 0;
