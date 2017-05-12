#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2016 Kevin Ryde

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
plan tests => 2;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

use Math::BigInt try => 'GMP';
use Math::PlanePath::PythagoreanTree;

# uncomment this to run the ### lines
# use Smart::Comments '###';


#------------------------------------------------------------------------------
# A002315 NSW numbers, sum Pell(2k)-Pell(2k-1), is row P-Q
MyOEIS::compare_values
  (anum => 'A002315',
   max_count => 11,
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'PQ');
     for (my $depth = 0; @got < $count; $depth++) {
       my $x_total = 0;
       foreach my $n ($path->tree_depth_to_n($depth)
                      .. $path->tree_depth_to_n_end($depth)) {
         my ($x,$y) = $path->n_to_xy($n);
         $x_total += $x - $y;
       }
       push @got, $x_total;
     }
     return \@got;
   });

# A001541 is row P+Q   even Pell + odd Pell
#   = A001542 + A001653
# my(s=OEIS_samples("A001541")[^1],e=OEIS_samples("A001542")[^1],o=OEIS_samples("A001653"),len=vecmin([#s,#e,#o]));e[1..len]+o[1..len]==s[1..len]
#
MyOEIS::compare_values
  (anum => 'A001541',
   max_count => 11,
   func => sub {
     my ($count) = @_;
     my @got = (1);
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'PQ');
     for (my $depth = 0; @got < $count; $depth++) {
       my $x_total = 0;
       foreach my $n ($path->tree_depth_to_n($depth)
                      .. $path->tree_depth_to_n_end($depth)) {
         my ($x,$y) = $path->n_to_xy($n);
         $x_total += $x + $y;
       }
       push @got, $x_total;
     }
     return \@got;
   });

# A001653 odd Pells, is row Q total
MyOEIS::compare_values
  (anum => 'A001653',
   max_count => 11,
   func => sub {
     my ($count) = @_;
     my @got;
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'PQ');
     for (my $depth = 0; @got < $count; $depth++) {
       my $x_total = 0;
       foreach my $n ($path->tree_depth_to_n($depth)
                      .. $path->tree_depth_to_n_end($depth)) {
         my ($x,$y) = $path->n_to_xy($n);
         $x_total += $y;
       }
       push @got, $x_total;
     }
     return \@got;
   });

# A001542 even Pell, is row P total
MyOEIS::compare_values
  (anum => 'A001542',
   max_count => 11,
   func => sub {
     my ($count) = @_;
     my @got = (0);
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'PQ');
     for (my $depth = 0; @got < $count; $depth++) {
       my $x_total = 0;
       foreach my $n ($path->tree_depth_to_n($depth)
                      .. $path->tree_depth_to_n_end($depth)) {
         my ($x,$y) = $path->n_to_xy($n);
         $x_total += $x;
       }
       push @got, $x_total;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A000244 = 3^n is N of A repeatedly in middle of row

MyOEIS::compare_values
  (anum => 'A000244',
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my @got;
     my $path = Math::PlanePath::PythagoreanTree->new;
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       push @got, ($path->tree_depth_to_n_end($depth)
                   + $path->tree_depth_to_n($depth) + 1) / 2;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A052940  matrix T repeatedly coordinate P, binary 101111111111 = 3*2^n-1
MyOEIS::compare_values
  (anum => 'A052940',
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my @got = (1);
     my $path = Math::PlanePath::PythagoreanTree->new (tree_type => 'UMT',
                                                       coordinates => 'PQ');
     for (my $depth = Math::BigInt->new(1); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy($path->tree_depth_to_n_end($depth));
       push @got, $x;
     }
     return \@got;
   });
# A055010  same
MyOEIS::compare_values
  (anum => 'A055010',
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my @got = (0);
     my $path = Math::PlanePath::PythagoreanTree->new (tree_type => 'UMT',
                                                       coordinates => 'PQ');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy($path->tree_depth_to_n_end($depth));
       push @got, $x;
     }
     return \@got;
   });
# A083329  same
MyOEIS::compare_values
  (anum => 'A083329',
   # max_count => 100,
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my @got = (1);
     my $path = Math::PlanePath::PythagoreanTree->new (tree_type => 'UMT',
                                                       coordinates => 'PQ');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy($path->tree_depth_to_n_end($depth));
       push @got, $x;
     }
     return \@got;
   });
# A153893  same
MyOEIS::compare_values
  (anum => 'A153893',
   # max_count => 100,
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my @got;
     my $path = Math::PlanePath::PythagoreanTree->new (tree_type => 'UMT',
                                                       coordinates => 'PQ');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy($path->tree_depth_to_n_end($depth));
       push @got, $x;
     }
     return \@got;
   });

# A093357  matrix T repeatedly coordinate B, binary 10111..111000..000
MyOEIS::compare_values
  (anum => 'A093357',
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my @got = (0);
     my $path = Math::PlanePath::PythagoreanTree->new (tree_type => 'UMT',
                                                       coordinates => 'AB');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy($path->tree_depth_to_n_end($depth));
       push @got, $y;
     }
     return \@got;
   });

# A134057  matrix T repeatedly coordinate A, binomial(2^n-1,2)
#   binary 111..11101000..0001
MyOEIS::compare_values
  (anum => 'A134057',
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my @got = (0,0);
     my $path = Math::PlanePath::PythagoreanTree->new (tree_type => 'UMT',
                                                       coordinates => 'AB');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy($path->tree_depth_to_n_end($depth));
       push @got, $x;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A106624  matrix K3 repeatedly P,Q pairs 2^k-1,2^k
MyOEIS::compare_values
  (anum => 'A106624',
   # max_count => 100,
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my @got = (1,0);
     my $path = Math::PlanePath::PythagoreanTree->new (tree_type => 'FB',
                                                       coordinates => 'PQ');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy($path->tree_depth_to_n_end($depth));
       push @got, $x, $y;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A054881  matrix K2 repeatedly "B" coordinate
MyOEIS::compare_values
  (anum => 'A054881',
   # max_count => 100,
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my @got = (1,0);
     my $path = Math::PlanePath::PythagoreanTree->new (tree_type => 'FB',
                                                       coordinates => 'AB');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy(3 ** $depth);
       push @got, $y;
     }
     return \@got;
   });

# A015249  matrix K2 repeatedly "A" coordinate
MyOEIS::compare_values
  (anum => 'A015249',
   # max_count => 100,
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my @got = (1);
     my $path = Math::PlanePath::PythagoreanTree->new (tree_type => 'FB',
                                                       coordinates => 'AB');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy(3 ** $depth);
       push @got, $x;
     }
     return \@got;
   });
# A084152 same
MyOEIS::compare_values
  (anum => 'A084152',
   # max_count => 100,
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my @got = (0,0,1);
     my $path = Math::PlanePath::PythagoreanTree->new (tree_type => 'FB',
                                                       coordinates => 'AB');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy(3 ** $depth);
       push @got, $x;
     }
     return \@got;
   });
# A084175 same
MyOEIS::compare_values
  (anum => 'A084175',
   # max_count => 100,
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my @got = (0,1);
     my $path = Math::PlanePath::PythagoreanTree->new (tree_type => 'FB',
                                                       coordinates => 'AB');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy(3 ** $depth);
       push @got, $x;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A085601 = matrix K1 repeatedly "C" coordinate, binary 10010001
MyOEIS::compare_values
  (anum => 'A085601',
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my @got;
     my $path = Math::PlanePath::PythagoreanTree->new (tree_type => 'FB',
                                                       coordinates => 'AC');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy($path->tree_depth_to_n($depth));
       push @got, $y;
     }
     return \@got;
   });

# A028403 = matrix K1 repeatedly "B" coordinate, binary 10010000
MyOEIS::compare_values
  (anum => 'A028403',
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my @got;
     my $path = Math::PlanePath::PythagoreanTree->new (tree_type => 'FB',
                                                       coordinates => 'AB');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy($path->tree_depth_to_n($depth));
       push @got, $y;
     }
     return \@got;
   });
# A007582 = matrix K1 repeatedly "B/4" coordinate, binary 1001000
MyOEIS::compare_values
  (anum => 'A007582',
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my @got;
     my $path = Math::PlanePath::PythagoreanTree->new (tree_type => 'FB',
                                                       coordinates => 'AB');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy($path->tree_depth_to_n($depth));
       push @got, $y/4;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A084159  matrix A repeatedly "A" coordinate, Pell oblongs
MyOEIS::compare_values
  (anum => 'A084159',
   # max_count => 100,
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my @got = (1);
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'AB');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy(3 ** $depth);
       push @got, $x;
     }
     return \@got;
   });
# A046727  matrix A repeatedly "A" coordinate
MyOEIS::compare_values
  (anum => 'A046727',
   # max_count => 100,
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my @got = (0);
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'AB');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy(3 ** $depth);
       push @got, $x;
     }
     return \@got;
   });

# A046729  matrix A repeatedly "B" coordinate
MyOEIS::compare_values
  (anum => 'A046729',
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my @got = (0);
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'AB');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy(3 ** $depth);
       push @got, $y;
     }
     return \@got;
   });

# A001653  matrix A repeatedly "C" coordinate
MyOEIS::compare_values
  (anum => 'A001653',
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my @got = (1);
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'AC');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy(3 ** $depth);
       push @got, $y;
     }
     return \@got;
   });

# A001652  matrix A repeatedly "S" coordinate
MyOEIS::compare_values
  (anum => 'A001652',
   # max_count => 50,
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my @got = (0);
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'SM');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy(3 ** $depth);
       push @got, $x;
     }
     return \@got;
   });

# A046090  matrix A repeatedly "M" coordinate
MyOEIS::compare_values
  (anum => 'A046090',
   # max_count => 100,
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my @got = (1);
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'SM');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy(3 ** $depth);
       push @got, $y;
     }
     return \@got;
   });

# A000129  matrix A repeatedly "P" coordinate
MyOEIS::compare_values
  (anum => 'A000129',
   # max_count => 100,
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my @got = (0,1);
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'PQ');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy(3 ** $depth);
       push @got, $x;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A099776 = matrix U repeatedly "C" coordinate
MyOEIS::compare_values
  (anum => 'A099776',
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my @got;
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'AC');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy($path->tree_depth_to_n($depth));
       push @got, $y;
     }
     return \@got;
   });
# A001844 centred squares same
MyOEIS::compare_values
  (anum => 'A001844',
   # max_count => 100,
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my @got = (1);
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'AC');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy($path->tree_depth_to_n($depth));
       push @got, $y;
     }
     return \@got;
   });

# A046092  matrix U repeatedly "B" coordinate = 4*triangular
MyOEIS::compare_values
  (anum => 'A046092',
   # max_count => 500,
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my @got = (0);
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'AB');
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy($path->tree_depth_to_n($depth));
       push @got, $y;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A000466 matrix D repeatedly "A" coordinate = 4n^2-1

MyOEIS::compare_values
  (anum => 'A000466',
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my @got = (-1);
     my $path = Math::PlanePath::PythagoreanTree->new;
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       my ($x,$y) = $path->n_to_xy($path->tree_depth_to_n_end($depth));
       push @got, $x;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A058529 - all prime factors == +/-1 mod 8
#   is differences mid-small legs

MyOEIS::compare_values
  (anum => 'A058529',
   max_count => 35,
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'SM');
     my %seen;
     for (my $n = $path->n_start; $n < 100000; $n++) {
       my ($s,$m) = $path->n_to_xy($n);
       my $diff = $m - $s;
       $seen{$diff} = 1;
     }
     my @got = sort {$a<=>$b} keys %seen;
     $#got = $count-1;
     return \@got;
   });

#------------------------------------------------------------------------------
# A003462 = (3^n-1)/2 is tree_depth_to_n_end()

MyOEIS::compare_values
  (anum => 'A003462',
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my @got = (0);
     my $path = Math::PlanePath::PythagoreanTree->new;
     for (my $depth = Math::BigInt->new(0); @got < $count; $depth++) {
       push @got, $path->tree_depth_to_n_end($depth);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
