#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2018 Kevin Ryde

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

use Math::PlanePath::CellularRule190;


#------------------------------------------------------------------------------
# A071039 - 0/1 by rows rule 190

MyOEIS::compare_values
  (anum => 'A071039',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::CellularRule190->new;
     my @got;
     my $x = 0;
     my $y = 0;
     while (@got < $count) {
       push @got, ($path->xy_is_visited($x,$y) ? 1 : 0);
       $x++;
       if ($x > $y) {
         $y++;
         $x = -$y;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A118111 - 0/1 by rows rule 190 (duplicate)

MyOEIS::compare_values
  (anum => 'A118111',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::CellularRule190->new;
     my @got;
     my $x = 0;
     my $y = 0;
     while (@got < $count) {
       push @got, ($path->xy_is_visited($x,$y) ? 1 : 0);
       $x++;
       if ($x > $y) {
         $y++;
         $x = -$y;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A037576 - rows as rule 190 binary bignums (base 4 periodic ...)

MyOEIS::compare_values
  (anum => 'A037576',
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my $path = Math::PlanePath::CellularRule190->new;
     my @got;
     my $y = 0;
     while (@got < $count) {
       my $b = 0;
       foreach my $i (0 .. 2*$y+1) {
         if ($path->xy_is_visited ($y-$i, $y)) {
           $b += Math::BigInt->new(2) ** $i;
         }
       }
       push @got, "$b";
       $y++;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A071041 - 0/1 rule 246

MyOEIS::compare_values
  (anum => 'A071041',
   func => sub {
     my ($count) = @_;
     my $path = Math::PlanePath::CellularRule190->new (mirror => 1);
     my @got;
     my $x = 0;
     my $y = 0;
     while (@got < $count) {
       push @got, ($path->xy_is_visited($x,$y) ? 1 : 0);
       $x++;
       if ($x > $y) {
         $y++;
         $x = -$y;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
