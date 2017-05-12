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
plan tests => 3;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::DigitGroups;

# uncomment this to run the ### lines
#use Smart::Comments '###';



#------------------------------------------------------------------------------
# parity_bitwise() vs path

# X is low 0111..11 then Y above that, so (X^Y)&1 is
# Parity = lowbit(N) ^ bit_above_lowest_zero(N)
{
  my $path = Math::PlanePath::DigitGroups->new;
  my $bad = 0;
  foreach my $n (0 .. 0xFFFF) {
    my ($x, $y) = $path->n_to_xy ($n);
    my $path_value = ($x + $y) % 2;
    my $a_value = parity_bitwise($n);

    if ($path_value != $a_value) {
      MyTestHelpers::diag ("diff n=$n path=$path_value acalc=$a_value");
      MyTestHelpers::diag ("  xy=$x,$y");
      last if ++$bad > 10;
    }
  }
  ok ($bad, 0, "parity_bitwise()");
}

sub parity_bitwise {
  my ($n) = @_;
  return ($n & 1) ^ bit_above_lowest_zero($n);
}
sub bit_above_lowest_zero {
  my ($n) = @_;
  for (;;) {
    if (($n % 2) == 0) {
      last;
    }
    $n = int($n/2);
  }
  $n = int($n/2);
  return ($n % 2);
}

#------------------------------------------------------------------------------
# A084472 - X axis in binary, excluding 0

MyOEIS::compare_values
  (anum => 'A084472',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::DigitGroups->new;
     for (my $x = 1; @got < $count; $x++) {
       my $n = $path->xy_to_n ($x,0);
       push @got, to_binary($n);
     }
     return \@got;
   });

sub to_binary {
  my ($n) = @_;
  return ($n < 0 ? '-' : '') . sprintf('%b', abs($n));
}

#------------------------------------------------------------------------------
# A060142 - X axis sorted

MyOEIS::compare_values
  (anum => 'A060142',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::DigitGroups->new;
     for (my $x = 0; @got < 16 * $count; $x++) {
       push @got, $path->xy_to_n ($x,0);
     }
     @got = sort {$a<=>$b} @got;
     $#got = $count-1;
     return \@got;
   });


#------------------------------------------------------------------------------

exit 0;
