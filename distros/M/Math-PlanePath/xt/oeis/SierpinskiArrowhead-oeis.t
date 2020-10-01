#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2018, 2020 Kevin Ryde

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
plan tests => 7;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::PlanePath::SierpinskiArrowhead;
use Math::NumSeq::PlanePathTurn;
use MyOEIS;


#------------------------------------------------------------------------------
# A334483 -- X coordinate of "diagonal"
# A334484 -- Y coordinate of "diagonal"
# catalogued

# my(g=OEIS_bfile_gf("A334483")); x(n) = polcoeff(g,n);
# my(g=OEIS_bfile_gf("A334484")); y(n) = polcoeff(g,n);
# plothraw(vector(3^5,n,n--; x(n)), \
#          vector(3^5,n,n--; y(n)), 1+8+16+32)
#


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

# A189706 = lowest non-1 and its position
MyOEIS::compare_values
  (anum => q{A189706},
   func => sub {
     my ($count) = @_;
     my @got;
     foreach my $i (0 .. $count-1) {
       push @got, lowest_non_1_xor_position($i);
     }
     return \@got;
   });
sub lowest_non_1_xor_position {
  my ($n) = @_;
  my $ret = 1;
  while (($n % 3) == 1) {
    $ret ^= 1;             # flip for trailing 1s
    $n = int($n/3);
  }
  if (($n % 3) == 0) {
    $ret ^= 1;
  }
  return $ret;
}

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

# A156595 = lowest non-2 and its position starting at n=0
MyOEIS::compare_values
  (anum => q{A156595},
   name => 'A156595 by lowest non-2 and position',
   func => sub {
     my ($count) = @_;
     my @got;
     foreach my $i (0 .. $count-1) {
       push @got, lowest_non_2_xor_position($i);
     }
     return \@got;
   });
sub lowest_non_2_xor_position {
  my ($n) = @_;
  my $ret = 1;
  while (($n % 3) == 2) {
    $ret ^= 1;             # flip for trailing 1s
    $n = int($n/3);
  }
  if (($n % 3) == 0) {
    $ret ^= 1;
  }
  return $ret;
}

# A156595 = lowest non-0 and its position starting at n=1 (per seq OFFSET)
MyOEIS::compare_values
  (anum => q{A156595},
   name => 'A156595 by lowest non-0 and position',
   func => sub {
     my ($count) = @_;
     my @got;
     foreach my $i (0 .. $count-1) {
       push @got, lowest_non_0_xor_position($i);
     }
     return \@got;
   });
sub lowest_non_0_xor_position {
  my ($n) = @_;
  my $ret = 0;
  while (($n % 3) == 2) {
    $ret ^= 1;             # flip for trailing 1s
    $n = int($n/3);
  }
  $ret ^= ($n % 3);
  return $ret & 1;
}

#------------------------------------------------------------------------------

exit 0;
