#!/usr/bin/perl -w

# Copyright 2013, 2014, 2015, 2018, 2019, 2020 Kevin Ryde

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
use Math::BigInt;
use Test;
plan tests => 3;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::QuintetReplicate;


#------------------------------------------------------------------------------
# A316657 -- X
# A316658 -- Y
# A316707 -- norm

MyOEIS::compare_values
  (anum => 'A316657',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::QuintetReplicate->new;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy ($n);
       push @got, $x;
     }
     return \@got;
   });
MyOEIS::compare_values
  (anum => 'A316658',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::QuintetReplicate->new;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy ($n);
       push @got, $y;
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A316707',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::QuintetReplicate->new;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy ($n);
       push @got, $x**2 + $y**2;
     }
     return \@got;
   });



#------------------------------------------------------------------------------

exit 0;
