#!/usr/bin/perl -w

# Copyright 2020, 2021 Kevin Ryde
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
use Test;
plan tests => 4;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }
use MyOEIS;
use MyGraphs;

use Graph::Maker::Hypercube;
$|=1;


#------------------------------------------------------------------------------
# A247181 - totdomnum
# A323515 - num totdomnum sets (ie. minimum sets)

MyOEIS::compare_values
  (anum => 'A247181',
   max_count => 4,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 1; @got < $count; $N++) {
       my $graph = Graph::Maker->new('hypercube', N => $N,
                                     undirected => 1);
       my ($size,$count) = MyGraphs::Graph_sets_minimum_and_count_by_pred
         ($graph, \&MyGraphs::Graph_is_total_domset);
       push @got, $size;
     }
     return \@got;
   });
MyOEIS::compare_values
  (anum => 'A323515',
   max_count => 5,
   func => sub {
     my ($count) = @_;
     my @got = (0);  # A323515 wrongly reckons no sets in the empty graph
     for (my $N = 1; @got < $count; $N++) {
       my $graph = Graph::Maker->new('hypercube', N => $N,
                                     undirected => 1);
       my ($size,$count) = MyGraphs::Graph_sets_minimum_and_count_by_pred
         ($graph, \&MyGraphs::Graph_is_total_domset);
       push @got, $count;
     }
     return \@got;
   });

# ??? - num totdomsets
# 1,1,9,121
# MyOEIS::compare_values
#   (anum => 'A000001',
#    max_count => 4,
#    func => sub {
#      my ($count) = @_;
#      my @got;
#      for (my $N = 0; @got < $count; $N++) {
#        my $graph = Graph::Maker->new('hypercube', N => $N,
#                                      undirected => 1);
#        push @got, MyGraphs::Graph_sets_count_by_pred
#          ($graph, \&MyGraphs::Graph_is_total_domset);
#      }
#      return \@got;
#    });

#------------------------------------------------------------------------------
# A284838 - num edges

MyOEIS::compare_values
  (anum => 'A001787',
   max_count => 4,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 0; @got < $count; $N++) {
       my $graph = Graph::Maker->new('hypercube', N => $N,
                                     undirected => 1);
       push @got, scalar($graph->edges);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A002697 - Wiener index (per Iyer and Reddy)

MyOEIS::compare_values
  (anum => 'A002697',
   max_count => 6,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 0; @got < $count; $N++) {
       my $graph = Graph::Maker->new('hypercube', N => $N,
                                     undirected => 1);
       push @got, MyGraphs::Graph_Wiener_index($graph);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
