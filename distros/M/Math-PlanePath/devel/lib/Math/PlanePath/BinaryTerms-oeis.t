#!/usr/bin/perl -w

# Copyright 2013 Kevin Ryde

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
use List::Util 'max';
use Test;
plan tests => 46;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::PlanePath::BinaryTerms;

{
  require Math::BaseCnv;
  my $radix = 3;
  my $path = Math::PlanePath::BinaryTerms->new (radix => $radix);
  foreach my $y ($path->y_minimum .. 8) {
    printf '%2d', $y;
    foreach my $x ($path->x_minimum .. 7) {
      my $n = $path->xy_to_n($x,$y);
      my $nr = Math::BaseCnv::cnv($n,10,$radix);
      printf " %10s", $nr;
    }
    print "\n";
  }
}

#------------------------------------------------------------------------------
# A068076 X = num integers <n with same num 1-bits as n

MyOEIS::compare_values
  (anum => 'A068076',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::BinaryTerms->new;
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, $x-1;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A067576 binary by anti-diagonals upwards

MyOEIS::compare_values
  (anum => 'A067576',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::Diagonals;
     my $path = Math::PlanePath::BinaryTerms->new (radix => 2);
     my $diag = Math::PlanePath::Diagonals->new (direction => 'up',
                                                 x_start=>1,y_start=>1);
     my @got;
     for (my $d = $diag->n_start; @got < $count; $d++) {
       my ($x,$y) = $diag->n_to_xy($d);  # by anti-diagonals
       push @got, $path->xy_to_n($x,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A066884 binary diagonals downwards
MyOEIS::compare_values
  (anum => 'A066884',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::Diagonals;
     my $path = Math::PlanePath::BinaryTerms->new;
     my $diag = Math::PlanePath::Diagonals->new (x_start=>1,y_start=>1);
     my @got;
     for (my $d = $diag->n_start; @got < $count; $d++) {
       my ($x,$y) = $diag->n_to_xy($d);  # by anti-diagonals
       push @got, $path->xy_to_n($x,$y);
     }
     return \@got;
   });

# A067587 inverse
MyOEIS::compare_values
  (anum => 'A067587',
   func => sub {
     my ($count) = @_;
     require Math::PlanePath::Diagonals;
     my $path = Math::PlanePath::BinaryTerms->new;
     my $diag = Math::PlanePath::Diagonals->new (x_start=>1,y_start=>1);
     my @got;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, $diag->xy_to_n($x,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
