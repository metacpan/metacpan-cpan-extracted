#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2018, 2019 Kevin Ryde

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

use List::Util 'min', 'max';
use Math::PlanePath::HypotOctant;


# #------------------------------------------------------------------------------
# # A001844
#
# {
#   my $anum = 'A001844';
#   my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
#
#   my $diff;
#   if ($bvalues) {
#     my @got;
#     my $path = Math::PlanePath::HypotOctant->new;
#     my $i = 0;
#     for (my $i = 0; @got < $count; $i++) {
#       push @got, $i*$i + ($i+1)*($i+1);
#     }
#
#     return \@got;
#     if ($diff) {
#       MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
#       MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
#     }
#   }
#   skip (! $bvalues,
#         $diff,
#         undef,
#         "$anum");
# }


#------------------------------------------------------------------------------
# A057653

MyOEIS::compare_values
  (anum => 'A057653',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::HypotOctant->new (points => 'odd');
     my $prev = 0;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my $rsquared = $path->n_to_rsquared($n);
       if ($rsquared != $prev) {
         $prev = $rsquared;
         push @got, $rsquared;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A024507

MyOEIS::compare_values
  (anum => 'A024507',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::HypotOctant->new;
     my $i = 0;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       if ($y != 0 && $x != $y) {
         push @got, $path->n_to_rsquared($n);
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A024509

MyOEIS::compare_values
  (anum => 'A024509',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::HypotOctant->new;
     my $i = 0;
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       if ($y != 0) {
         push @got, $path->n_to_rsquared($n);
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
