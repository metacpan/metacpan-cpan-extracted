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
use Graph::Maker::CatalansUpto;

plan tests => 2;


#------------------------------------------------------------------------------
# insert

# num edges
# not in OEIS: 1,3,9,33,127,491,1895,7307,28185
# MyOEIS::compare_values
#   (anum => 'A000000',
#    max_count => 9,
#    func => sub {
#      my ($count) = @_;
#      my @got;
#      for (my $N = 1; @got < $count; $N++) {
#        my $graph = Graph::Maker->new('Catalans_upto', N => $N,
#                                      rel_type => 'insert');
#        push @got, scalar($graph->edges);
#      }
#      return \@got;
#    });

# num maximal paths
# not in OEIS: 1,1,2,6,28,184,1568,16448
# MyOEIS::compare_values
#   (anum => 'A000000',
#    max_count => 8,
#    func => sub {
#      my ($count) = @_;
#      my @got;
#      for (my $N = 0; @got < $count; $N++) {
#        my $graph = Graph::Maker->new('Catalans_upto', N => $N,
#                                      rel_type => 'insert');
#        push @got, MyGraphs::num_maximal_paths($graph);
#      }
#      return \@got;
#    });


#------------------------------------------------------------------------------
# below

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

MyOEIS::compare_values
  (anum => 'A000108',
   max_count => 5,
   func => sub {
     my ($count) = @_;
     my $graph = Graph::Maker->new('Catalans_upto', N => $count-1);
     return [ row_widths($graph, $graph->predecessorless_vertices) ];
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

# A006134 num edges
# 0,1,3,9,29,99,351,1275,4707,17577
MyOEIS::compare_values
  (anum => 'A006134',
   max_count => 9,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 1; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Catalans_upto', N => $N,
                                     rel_type => 'below');
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
       push @got, MyGraphs::Graph_num_maximal_paths($graph);
     }
     return \@got;
   });

# not in OEIS: 3,9,30,110,432,1780,7594,33268,148834
# MyOEIS::compare_values
#   (anum => 'A000000',
#    max_count => 9,
#    func => sub {
#      my ($count) = @_;
#      my @got;
#      for (my $N = 1; @got < $count; $N++) {
#        my $graph = Graph::Maker->new('Catalans_upto', N => $N);
#        push @got, MyGraphs::Graph_num_intervals($graph);
#      }
#      return \@got;
#    });


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

#------------------------------------------------------------------------------
exit 0;
