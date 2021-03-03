#!/usr/bin/perl -w

# Copyright 2018, 2019, 2021 Kevin Ryde
#
# This file is part of Graph-Maker-Other.
#
# This file is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# This file is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Graph-Maker-Other.  See the file COPYING.  If not, see
# <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use List::Util 'sum';
use Test;

use lib 't','xt';
use MyOEIS;
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use File::Spec;
use lib File::Spec->catdir('devel','lib');
use MyGraphs;
use Graph::Maker::FibonacciLattice;

plan tests => 2;

sub binomial {
  my ($n,$k) = @_;
  if ($n < 0 || $k < 0) { return 0; }
  my $ret = 1;
  foreach my $i (1 .. $k) {
    $ret *= $n-$k+$i;
    ### assert: $ret % $i == 0
    $ret /= $i;
  }
  return $ret;
}


#------------------------------------------------------------------------------
# num intervals
# not in OEIS: 1,3,9,22,52,116,253,539,1133,2354,4852,9936,20249
# vector(10,n,  1/3 *(2^(n+3) + 1 + (n%2))  - fibonacci(n+4))

# MyOEIS::compare_values
#   (anum => 'A000000',
#    max_count => 13,
#    func => sub {
#      my ($count) = @_;
#      my @got;
#      for (my $N = 0; @got < $count; $N++) {
#        my $graph = Graph::Maker->new('Fibonacci_lattice', N => $N);
#        push @got, MyGraphs::Graph_num_intervals($graph);
#      }
#      return \@got;
#    });


#------------------------------------------------------------------------------
# A000085 num maximal paths
# involutions
# graphs n degree <=1
# 1,1,2,4,10,26,76,232,764,2620,9496,35696,140152

MyOEIS::compare_values
  (anum => 'A000085',
   max_count => 13,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 0; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Fibonacci_lattice', N => $N);
       push @got, MyGraphs::Graph_num_maximal_paths($graph);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A000071 num vertices Fibonacci-1

MyOEIS::compare_values
  (anum => 'A000071',
   max_count => 10,
   func => sub {
     my ($count) = @_;
     my @got = (0,0);
     for (my $N = 0; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Fibonacci_lattice', N => $N);
       push @got, scalar($graph->vertices);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A023610 num edges
# 1, 3, 7, 15, 30, 58, 109, 201, 365, 655, 1164

MyOEIS::compare_values
  (anum => 'A023610',
   max_count => 10,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 1; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Fibonacci_lattice', N => $N);
       push @got, scalar($graph->edges);
     }
     return \@got;
   });

# A029907 num edges leaving vertices of sum k
MyOEIS::compare_values
  (anum => 'A029907',
   max_count => 10,
   func => sub {
     my ($count) = @_;
     $count--;
     my $graph = Graph::Maker->new('Fibonacci_lattice', N => $count);
     my @count_by_k = (0) x $count;
     foreach my $v ($graph->vertices) {
       my $k = sum(0, split //, $v);
       if ($k <= $#count_by_k) {
         $count_by_k[$k] += $graph->out_degree($v);
       }
     }
     return [0, @count_by_k];
   });


#------------------------------------------------------------------------------
exit 0;
