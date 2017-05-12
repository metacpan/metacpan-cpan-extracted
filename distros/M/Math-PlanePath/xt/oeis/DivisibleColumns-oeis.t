#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013 Kevin Ryde

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

use Math::PlanePath::DivisibleColumns;

# uncomment this to run the ### lines
#use Smart::Comments '###';


#------------------------------------------------------------------------------
# A077597 - N on X=Y diagonal, being cumulative count divisors - 1

MyOEIS::compare_values
  (anum => 'A077597',
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::DivisibleColumns->new;
     for (my $x = 1; @got < $count; $x++) {
       push @got, $path->xy_to_n($x,$x);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A027751 - Y coord, proper divisors, extra initial 1

MyOEIS::compare_values
  (anum => 'A027751',
   func => sub {
     my ($count) = @_;
     my @got = (1);
     my $path = Math::PlanePath::DivisibleColumns->new
       (divisor_type => 'proper');
     for (my $n = $path->n_start; @got < $count; $n++) {
       my ($x,$y) = $path->n_to_xy($n);
       push @got, $y;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A006218 - cumulative count of divisors

{
  my $anum = 'A006218';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my $good = 1;
  my $count = 0;
  if ($bvalues) {
    my $path = Math::PlanePath::DivisibleColumns->new;
    for (my $i = 0; $i < @$bvalues; $i++) {
      my $x = $i+1;
      my $want = $bvalues->[$i];
      my $got = $path->xy_to_n($x,1);
      if ($got != $want) {
        MyTestHelpers::diag ("wrong totient sum xy_to_n($x,1)=$got want=$want at i=$i of $filename");
        $good = 0;
      }
      $count++;
    }
  }
  ok ($good, 1, "$anum count $count");
}


#------------------------------------------------------------------------------
exit 0;
