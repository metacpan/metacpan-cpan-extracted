#!/usr/bin/perl -w

# Copyright 2018, 2019 Kevin Ryde
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
MyTestHelpers::nowarnings();

use lib 'devel/lib';
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

# vector(10,n,  1/3 *( 2^(n+3) + 1 + (n%2)) - fibonacci(n+4))

# $graph is a directed Graph.pm.
# Return the number of pairs of comparable elements $u,$v, meaning pairs
# where there is a path from $u to $v.  The count includes $u,$u empty path.
# For a lattice graph, this is the number of "intervals" in the lattice.
#
sub num_intervals {
  my ($graph) = @_;
  my $ret = 0;
  foreach my $v ($graph->vertices) {
    $ret += 1 + $graph->all_successors($v);
  }
  return $ret;
}

MyOEIS::compare_values
  (anum => 'A000000',
   max_count => 13,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 0; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Fibonacci_lattice', N => $N);
       push @got, num_maximal_paths($graph);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A000085 num maximal paths
# 1,1,2,4,10,26,76,232,764,2620,9496,35696,140152
#
# X YYYY
# paths YYYY down
# if X=1 then YYYY plus 1 each unappending X=1
# if X=2 then where in the sum=rank to decrease to X=1.

sub num_maximal_paths {
  my ($graph) = @_;
  ### num_maximal_chains() ...
  my @start = $graph->predecessorless_vertices;
  @start==1 or die "no unique start";
  my %ways = ($start[0] => 1);
  my %pending;
  my %indegree;
  foreach my $v ($graph->vertices) {
    $pending{$v} = 1;
    $indegree{$v} = 0;
  }
  while (%pending) {
    ### at pending: scalar(keys %pending)
    my $progress;
    foreach my $v (keys %pending) {
      if ($indegree{$v} != $graph->in_degree($v)) {
        ### not ready: "$v  indegree = $indegree{$v}"
        ### assert: $indegree{$v} < $graph->in_degree($v)
        next;
      }
      delete $pending{$v};
      foreach my $to ($graph->successors($v)) {
        ### edge: "$v to $to"
        $pending{$to} or die "oops, to=$to not pending";
        $ways{$to} += $ways{$v};
        $indegree{$to}++;
        $progress = 1;
      }
    }

    if (%pending && !$progress) {
      die "num_maximal_chains() oops, no progress";
    }
  }
  ### return: $ways{$end[0]}
  return sum(@ways{$graph->successorless_vertices});
}

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
