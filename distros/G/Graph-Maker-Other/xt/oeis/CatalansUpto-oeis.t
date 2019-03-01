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
use Graph::Maker::CatalansUpto;

plan tests => 2;

#------------------------------------------------------------------------------
# below

# A006134 num edges
MyOEIS::compare_values
  (anum => 'A006134',
   max_count => 9,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 1; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Catalans_upto', N => $N);
       push @got, scalar($graph->edges);
     }
     return \@got;
   });

# A000142 num maximal paths, N!
MyOEIS::compare_values
  (anum => 'A000142',
   max_count => 8,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 0; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Catalans_upto', N => $N);
       push @got, num_maximal_paths($graph);
     }
     return \@got;
   });

# not in OEIS: 3,9,30,110,432,1780,7594,33268,148834
# MyOEIS::compare_values
#   (anum => 'A006134',
#    max_count => 9,
#    func => sub {
#      my ($count) = @_;
#      my @got;
#      for (my $N = 1; @got < $count; $N++) {
#        my $graph = Graph::Maker->new('Catalans_upto', N => $N);
#        push @got, num_intervals($graph);
#      }
#      return \@got;
#    });


#------------------------------------------------------------------------------
# A014137 num vertices, cumulative Catalan

MyOEIS::compare_values
  (anum => 'A014137',
   max_count => 9,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 0; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Catalans_upto', N => $N);
       push @got, scalar($graph->vertices);
     }
     return \@got;
   });

# row widths, including root as a width=1 row, then $widths[$n] is $n away
# from root
sub row_widths {
  my ($graph, $root) = @_;
  my @widths;
  foreach my $v ($graph->vertices) {
    $widths[$graph->path_length($root,$v) || 0]++;
  }
  return @widths;
}

MyOEIS::compare_values
  (anum => 'A000108',
   max_count => 5,
   func => sub {
     my ($count) = @_;
     my $graph = Graph::Maker->new('Catalans_upto', N => $count-1);
     return [ row_widths($graph, $graph->predecessorless_vertices) ];
   });

#------------------------------------------------------------------------------
# Helper Funcs

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
exit 0;
