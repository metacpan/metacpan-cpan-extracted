#!/usr/bin/perl -w

# Copyright 2016, 2017 Kevin Ryde
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
plan tests => 7;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use lib
  'devel/lib';
use MyGraphs 'Graph_Wiener_index';
require Graph::Maker::FibonacciTree;


#------------------------------------------------------------------------------
# series_reduced=>1

# A178522  num nodes at depth
MyOEIS::compare_values
  (anum => 'A178522',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k = 0; @got < $count; $k++) {
       my $graph = Graph::Maker->new('fibonacci_tree',
                                     series_reduced=>1,
                                     height=>$k,
                                     undirected=>1);
       my @pending = (1);
       while (@pending) {
         last unless @got < $count;
         push @got, scalar(@pending);
         @pending = map {
           my $v = $_;
           my @neighbours = $graph->neighbours($v);
           grep {$_ > $v} @neighbours;
         } @pending;
       }
     }
     return \@got;
   });

# A178523 distance root down to all
MyOEIS::compare_values
  (anum => 'A178523',
   max_count => 8,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k = 0; @got < $count; $k++) {
       my $graph = Graph::Maker->new('fibonacci_tree',
                                     series_reduced=>1,
                                     height=>$k,
                                     undirected=>1);
       push @got, Graph_path_length_to_all($graph, 1);
     }
     return \@got;
   });

# A180567  Wiener index of series_reduced=>1
MyOEIS::compare_values
  (anum => 'A180567',
   max_count => 9,
   func => sub {
     my ($count) = @_;
     my @got;

     for (my $k = 0; @got < $count; $k++) {
       my $graph = Graph::Maker->new('fibonacci_tree',
                                     series_reduced=>1,
                                     height=>$k,
                                     undirected=>1);
       push @got, Graph_Wiener_index($graph);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# series_reduced=>1, leaf_reduced=>1

# A192018  count pairs at distances
MyOEIS::compare_values
  (anum => 'A192018',
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k = 2; @got < $count; $k++) {
       my $graph = Graph::Maker->new('fibonacci_tree',
                                     series_reduced=>1,
                                     leaf_reduced=>1,
                                     height=>$k,
                                     undirected=>1);
       my @num_at_distance;
       $graph->for_shortest_paths(sub {
                                    my ($trans, $u,$v) = @_;
                                    if ($u >= $v) { return; } # not both ways
                                    my $distance = $trans->path_length($u,$v);
                                    $num_at_distance[$distance]++;
                                  });
       shift @num_at_distance;  # excluding distance 0

       # the tree diameter, for k>=2
       @num_at_distance == 2*$k-3 or die "Oops";

       @num_at_distance = map {$_||0} @num_at_distance;
       while (@got < $count) {
         last unless @num_at_distance;
         push @got, shift @num_at_distance;
       }
     }
     return \@got;
   });

# also: A029907 is further first differences of A023610
#
# A023610  increment DTb distance root down to all
MyOEIS::compare_values
  (anum => 'A023610',
   max_count => 8,
   func => sub {
     my ($count) = @_;
     my @got;
     my $prev = 0;
     for (my $k = 2; @got < $count; $k++) {
       my $graph = Graph::Maker->new('fibonacci_tree',
                                     series_reduced=>1,
                                     leaf_reduced=>1,
                                     height=>$k,
                                     undirected=>1);
       my $dtb = Graph_path_length_to_all($graph, 1);
       push @got, $dtb-$prev;
       $prev = $dtb;
     }
     return \@got;
   });

# A002940  DTb distance root down to all
MyOEIS::compare_values
  (anum => 'A002940',
   max_count => 8,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k = 2; @got < $count; $k++) {
       my $graph = Graph::Maker->new('fibonacci_tree',
                                     series_reduced=>1,
                                     leaf_reduced=>1,
                                     height=>$k,
                                     undirected=>1);
       push @got, Graph_path_length_to_all($graph, 1);
     }
     return \@got;
   });

sub Graph_path_length_to_all {
  my ($graph, $v) = @_;
  my $total = 0;
  foreach my $u ($graph->vertices) {
    $total += $graph->path_length($u,$v);
  }
  return $total;
}

# A192019  Wiener index of series_reduced=>1, leaf_reduced=>1
MyOEIS::compare_values
  (anum => 'A192019',
   max_count => 8,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k = 2; @got < $count; $k++) {
       my $graph = Graph::Maker->new('fibonacci_tree',
                                     series_reduced=>1,
                                     leaf_reduced=>1,
                                     height=>$k,
                                     undirected=>1);
       push @got, Graph_Wiener_index($graph);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
