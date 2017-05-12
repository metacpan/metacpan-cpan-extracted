#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2015 Kevin Ryde

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
plan tests => 23;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::PlanePath::PeanoCurve;
use Math::PlanePath::Diagonals;
use Math::PlanePath::ZOrderCurve;

# uncomment this to run the ### lines
#use Smart::Comments '###';

my $peano  = Math::PlanePath::PeanoCurve->new;

#------------------------------------------------------------------------------
# A163334 -- diagonals same axis

MyOEIS::compare_values
  (anum => 'A163334',
   func => sub {
     my ($count) = @_;
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'up',
                                                     n_start => 0);
     my @got;
     for (my $n = $diagonal->n_start; @got < $count; $n++) {
       my ($x, $y) = $diagonal->n_to_xy ($n);
       push @got, $peano->xy_to_n ($x, $y);
     }
     return \@got;
   });

# A163335 -- diagonals same axis, inverse
MyOEIS::compare_values
  (anum => 'A163335',
   func => sub {
     my ($count) = @_;
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'up',
                                                     n_start => 0);
     my @got;
     for (my $n = $peano->n_start; @got < $count; $n++) {
       my ($x, $y) = $peano->n_to_xy ($n);
       push @got, $diagonal->xy_to_n($x,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163336 -- diagonals opposite axis
MyOEIS::compare_values
  (anum => 'A163336',
   func => sub {
     my ($count) = @_;
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'down',
                                                     n_start => 0);
     my @got;
     for (my $n = $diagonal->n_start; @got < $count; $n++) {
       my ($x, $y) = $diagonal->n_to_xy ($n);
       push @got, $peano->xy_to_n ($x, $y);
     }
     return \@got;
   });

# A163337 -- diagonals opposite axis, inverse
MyOEIS::compare_values
  (anum => 'A163337',
   func => sub {
     my ($count) = @_;
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'down',
                                                     n_start => 0);
     my @got;
     for (my $n = $peano->n_start; @got < $count; $n++) {
       my ($x, $y) = $peano->n_to_xy ($n);
       push @got, $diagonal->xy_to_n($x,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163338 -- diagonals same axis, 1-based
MyOEIS::compare_values
  (anum => 'A163338',
   func => sub {
     my ($count) = @_;
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'up');
     my @got;
     for (my $n = $diagonal->n_start; @got < $count; $n++) {
       my ($x, $y) = $diagonal->n_to_xy ($n);
       push @got, $peano->xy_to_n ($x, $y) + 1;
     }
     return \@got;
   });

# A163339 -- diagonals same axis, 1-based, inverse
MyOEIS::compare_values
  (anum => 'A163339',
   func => sub {
     my ($count) = @_;
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'up');
     my @got;
     for (my $n = $peano->n_start; @got < $count; $n++) {
       my ($x, $y) = $peano->n_to_xy ($n);
       push @got, $diagonal->xy_to_n ($x, $y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163340 -- diagonals same axis, 1 based
MyOEIS::compare_values
  (anum => 'A163340',
   func => sub {
     my ($count) = @_;
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'down');
     my @got;
     for (my $n = $diagonal->n_start; @got < $count; $n++) {
       my ($x, $y) = $diagonal->n_to_xy ($n);
       push @got, $peano->xy_to_n($x,$y) + 1;
     }
     return \@got;
   });

# A163341 -- diagonals same axis, 1-based, inverse
MyOEIS::compare_values
  (anum => 'A163341',
   func => sub {
     my ($count) = @_;
     my $diagonal = Math::PlanePath::Diagonals->new (direction => 'down');
     my @got;
     for (my $n = $peano->n_start; @got < $count; $n++) {
       my ($x, $y) = $peano->n_to_xy ($n);
       push @got, $diagonal->xy_to_n($x,$y);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163342 -- diagonal sums
# no b-file as of Jan 2011
MyOEIS::compare_values
  (anum => 'A163342',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $d = 0; @got < $count; $d++) {
       my $sum = 0;
       foreach my $x (0 .. $d) {
         my $y = $d - $x;
         $sum += $peano->xy_to_n ($x, $y);
       }
       push @got, $sum;
     }
     return \@got;
   });

# A163479 -- diagonal sums div 6
MyOEIS::compare_values
  (anum => 'A163479',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $d = 0; @got < $count; $d++) {
       my $sum = 0;
       foreach my $x (0 .. $d) {
         my $y = $d - $x;
         $sum += $peano->xy_to_n ($x, $y);
       }
       push @got, int($sum/6);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163344 -- N/4 on X=Y diagonal

MyOEIS::compare_values
  (anum => 'A163344',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $x = 0; @got < $count; $x++) {
       push @got, int($peano->xy_to_n($x,$x) / 4);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163534 -- absolute direction 0=east, 1=south, 2=west, 3=north
# Y coordinates reckoned down the page, so south is Y increasing

MyOEIS::compare_values
  (anum => 'A163534',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $peano->n_start; @got < $count; $n++) {
       my ($dx,$dy) = $peano->n_to_dxdy ($n);
       push @got, MyOEIS::dxdy_to_direction ($dx,$dy);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163535 -- absolute direction transpose 0=east, 1=south, 2=west, 3=north

MyOEIS::compare_values
  (anum => 'A163535',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $peano->n_start; @got < $count; $n++) {
       my ($dx,$dy) = $peano->n_to_dxdy ($n);
       push @got, MyOEIS::dxdy_to_direction ($dy,$dx);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A145204 -- N+1 of positions of verticals
MyOEIS::compare_values
  (anum => 'A145204',
   func => sub {
     my ($count) = @_;
     my @got = (0);
     for (my $n = $peano->n_start; @got < $count; $n++) {
       my ($dx,$dy) = $peano->n_to_dxdy($n);
       if ($dx == 0) {
         push @got, $n+1;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A014578 -- abs(dX), 1=horizontal 0=vertical, extra initial 0
MyOEIS::compare_values
  (anum => 'A014578',
   func => sub {
     my ($count) = @_;
     my @got = (0);
     for (my $n = $peano->n_start; @got < $count; $n++) {
       my ($dx,$dy) = $peano->n_to_dxdy($n);
       push @got, abs($dx);
     }
     return \@got;
   });

# A182581 -- abs(dY), but OFFSET=1
MyOEIS::compare_values
  (anum => 'A182581',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $peano->n_start; @got < $count; $n++) {
       my ($dx,$dy) = $peano->n_to_dxdy($n);
       push @got, abs($dy);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A007417 -- N+1 positions of horizontal step, dY==0, abs(dX)=1
# N+1 has even num trailing ternary 0-digits

MyOEIS::compare_values
  (anum => 'A007417',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = $peano->n_start; @got < $count; $n++) {
       my ($dx,$dy) = $peano->n_to_dxdy($n);
       if ($dy == 0) {
         push @got, $n+1;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163532 -- dX  a(n)-a(n-1) so extra initial 0

MyOEIS::compare_values
  (anum => 'A163532',
   func => sub {
     my ($count) = @_;
     my @got = (0); # extra initial entry N=0 no change
     for (my $n = $peano->n_start; @got < $count; $n++) {
       my ($dx,$dy) = $peano->n_to_dxdy($n);
       push @got, $dx;
     }
     return \@got;
   });

# A163533 -- dY  a(n)-a(n-1)
MyOEIS::compare_values
  (anum => 'A163533',
   func => sub {
     my ($count) = @_;
     my @got = (0); # extra initial entry N=0 no change
     for (my $n = $peano->n_start; @got < $count; $n++) {
       my ($dx,$dy) = $peano->n_to_dxdy($n);
       push @got, $dy;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163333 -- Peano N <-> Z-Order radix=3, with digit swaps

MyOEIS::compare_values
  (anum => 'A163333',
   func => sub {
     my ($count) = @_;
     my $zorder = Math::PlanePath::ZOrderCurve->new (radix => 3);
     my @got;
     for (my $n = $zorder->n_start; @got < $count; $n++) {
       my $nn = $n;
       {
         my ($x,$y) = $zorder->n_to_xy ($nn);
         ($x,$y) = ($y,$x);
         $nn = $zorder->xy_to_n ($x,$y);
       }
       {
         my ($x,$y) = $zorder->n_to_xy ($nn);
         $nn = $peano->xy_to_n ($x, $y);
       }
       {
         my ($x,$y) = $zorder->n_to_xy ($nn);
         ($x,$y) = ($y,$x);
         $nn = $zorder->xy_to_n ($x,$y);
       }
       push @got, $nn;
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => q{A163333},
   func => sub {
     my ($count) = @_;
     my $zorder = Math::PlanePath::ZOrderCurve->new (radix => 3);
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my $nn = $n;
       {
         my ($x,$y) = $zorder->n_to_xy ($nn);
         ($x,$y) = ($y,$x);
         $nn = $zorder->xy_to_n ($x,$y);
       }
       {
         my ($x,$y) = $peano->n_to_xy ($nn);   # other way around
         $nn = $zorder->xy_to_n ($x, $y);
       }
       {
         my ($x,$y) = $zorder->n_to_xy ($nn);
         ($x,$y) = ($y,$x);
         $nn = $zorder->xy_to_n ($x,$y);
       }
       push @got, $nn;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A163332 -- Peano N at points in Z-Order radix=3 sequence

MyOEIS::compare_values
  (anum => 'A163332',
   func => sub {
     my ($count) = @_;
     my $zorder = Math::PlanePath::ZOrderCurve->new (radix => 3);
     my @got;
     for (my $n = $zorder->n_start; @got < $count; $n++) {
       my ($x,$y) = $zorder->n_to_xy ($n);
       push @got, $peano->xy_to_n ($x,$y);
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => q{A163332},
   func => sub {
     my ($count) = @_;
     my $zorder = Math::PlanePath::ZOrderCurve->new (radix => 3);
     my @got;
     for (my $n = $peano->n_start; @got < $count; $n++) {
       my ($x,$y) = $peano->n_to_xy ($n);   # other way around
       push @got, $zorder->xy_to_n ($x,$y);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
exit 0;
