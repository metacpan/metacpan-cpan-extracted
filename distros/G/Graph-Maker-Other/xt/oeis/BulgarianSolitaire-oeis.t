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
use Test;
plan tests => 11;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }
use MyOEIS;

use MyGraphs;
use Graph::Maker::BulgarianSolitaire;


#------------------------------------------------------------------------------
# A183110 longest cycle
# or rather the cycle length at the end of 1,1,1,...,1,1

MyOEIS::compare_values
  (anum => 'A183110',
   max_count => 18,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 1; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Bulgarian_solitaire', N=>$N);
       push @got, longest_cycle_length($graph);
     }
     return \@got;
   });
sub longest_cycle_length {
  my ($graph) = @_;
  my $ret = 0;
  foreach my $start ($graph->vertices) {
    my %seen;
    my $v = $start;
    my $len = 0;
    while (! $seen{$v}) {
      $seen{$v} = 1;
      my @successors = $graph->successors($v);
      @successors==1 or die;
      $v = $successors[0];
      $len++;
    }
    if ($v eq $start && $len > $ret) { $ret = $len; }
  }
  return $ret;
}


#------------------------------------------------------------------------------
# A201144 longest non-repeating path

MyOEIS::compare_values
  (anum => 'A201144',
   max_count => 18,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 1; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Bulgarian_solitaire', N=>$N);
       push @got, longest_non_repeating($graph);
     }
     return \@got;
   });
sub longest_non_repeating {
  my ($graph) = @_;
  my $ret = 0;
  foreach my $start ($graph->vertices) {
    my %seen;
    my $v = $start;
    my $len = 0;
    while (! $seen{$v}) {
      $seen{$v} = 1;
      my @successors = $graph->successors($v);
      @successors==1 or die;
      $v = $successors[0];
      $len++;
    }
    if ($len > $ret) { $ret = $len; }
  }
  return $ret;
}


#------------------------------------------------------------------------------
# A054531 n / gcd(n,k)
# A277227 additive order of k mod n
# Girth

MyOEIS::compare_values
  (anum => 'A054531',
   max_count => 18,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 1; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Bulgarian_solitaire', N=>$N);
       push @got, MyGraphs::Graph_girth($graph);
     }
     return \@got;
   });
MyOEIS::compare_values
  (anum => 'A277227',
   max_count => 18,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 0; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Bulgarian_solitaire', N=>$N);
       push @got, MyGraphs::Graph_girth($graph);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A000041 = num partitions = num vertices

MyOEIS::compare_values
  (anum => 'A000041',
   max_value => 800,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 0; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Bulgarian_solitaire', N => $N);
       push @got, scalar($graph->vertices);
     }
     return \@got;
   });

# A066655  num partitions = num vertices, of triangular
MyOEIS::compare_values
  (anum => 'A066655',
   max_value => 800,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $t = 0; @got < $count; $t++) {
       my $graph = Graph::Maker->new('Bulgarian_solitaire', N => $t*($t+1)/2);
       push @got, scalar($graph->vertices);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A011782  compositions num vertices

MyOEIS::compare_values
  (anum => 'A011782',
   max_value => 10,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 0; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Bulgarian_solitaire',
                                     N => $N,
                                     compositions => 'append');
       push @got, scalar $graph->vertices;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A008466  compositions num Garden of Eden

MyOEIS::compare_values
  (anum => 'A008466',
   max_value => 50,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 1; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Bulgarian_solitaire',
                                     N => $N,
                                     compositions => 'append');
       push @got, scalar($graph->predecessorless_vertices);
     }
     return \@got;
   });

# and those with predecessors = Fibonacci
MyOEIS::compare_values
  (anum => 'A000045',
   max_value => 50,
   func => sub {
     my ($count) = @_;
     my @got = (0);
     for (my $N = 0; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Bulgarian_solitaire',
                                     N => $N,
                                     compositions => 'append');
       push @got, scalar($graph->predecessorful_vertices);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A123975  number of Garden of Eden, so predecessorless

MyOEIS::compare_values
  (anum => 'A123975',
   max_value => 200,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 1; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Bulgarian_solitaire', N => $N);
       push @got, scalar($graph->predecessorless_vertices);
     }
     return \@got;
   });

# A260894 not Gardeno of Eden, so predecessorful
MyOEIS::compare_values
  (anum => 'A260894',
   max_value => 500,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 0; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Bulgarian_solitaire',
                                     N => $N);
       push @got, scalar($graph->predecessorful_vertices);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A037306  number of components

MyOEIS::compare_values
  (anum => 'A037306',
   max_count => 20,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 1; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Bulgarian_solitaire', N => $N,
                                     undirected => 1);
       push @got, scalar($graph->connected_components);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A002378  tree height of triangular = pronic

MyOEIS::compare_values
  (anum => 'A002378',
   max_value => 10,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $t = 1; @got < $count; $t++) {
       my $graph = Graph::Maker->new('Bulgarian_solitaire',
                                     N => $t*($t+1)/2,
                                     undirected => 1);
       my $root = join(',', 1..$t);
       push @got,
         $graph->vertices == 1 ? 0 : $graph->vertex_eccentricity($root);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
exit 0;
