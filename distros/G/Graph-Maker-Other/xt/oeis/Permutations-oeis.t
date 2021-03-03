#!/usr/bin/perl -w

# Copyright 2019, 2021 Kevin Ryde
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
use Graph::Maker::Permutations;

# uncomment this to run the ### lines
# use Smart::Comments;

plan tests => 9;

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
# transpose_cover

# A002538 num edges, second order Eulerian numbers
# OFFSET=1 starting 1, 8, 58, 444
# but here one less so start N=0 as 0,0,1,8,58
MyOEIS::compare_values
  (anum => 'A002538',
   max_count => 5,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 2; @got < $count; $N++) {
       my $graph = Graph::Maker->new('permutations', N => $N,
                                     rel_type => 'transpose_cover');
       push @got, scalar($graph->edges);
     }
     return \@got;
   });

# transpose_cover intervals, same as transpose intervals
# not in OEIS: 1,3,19,213,3781,98407
# MyOEIS::compare_values
#   (anum => 'A000000',
#    max_count => 6,
#    func => sub {
#      my ($count) = @_;
#      my @got;
#      for (my $N = 1; @got < $count; $N++) {
#        my $graph = Graph::Maker->new('permutations', N => $N,
#                                      rel_type => 'transpose_cover');
#        push @got, MyGraphs::Graph_num_intervals($graph);
#      }
#      return \@got;
#    });

# A061710 Bruhat maximal chains
MyOEIS::compare_values
  (anum => 'A061710',
   max_count => 6,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 1; @got < $count; $N++) {
       my $graph = Graph::Maker->new('permutations', N => $N,
                                     rel_type => 'transpose_cover');
       push @got, MyGraphs::Graph_num_maximal_paths($graph);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# transpose

# num edges   n! * n(n-1)/4
MyOEIS::compare_values
  (anum => 'A001809',
   max_count => 7,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 0; @got < $count; $N++) {
       my $graph = Graph::Maker->new('permutations', N => $N,
                                     rel_type => 'transpose');
       push @got, scalar($graph->edges);
     }
     return \@got;
   });

# transpose intervals
# not in OEIS: 1,3,19,213,3781
# MyOEIS::compare_values
#   (anum => 'A000000',
#    max_count => 6,
#    func => sub {
#      my ($count) = @_;
#      my @got;
#      for (my $N = 1; @got < $count; $N++) {
#        my $graph = Graph::Maker->new('permutations', N => $N,
#                                      rel_type => 'transpose');
#        push @got, MyGraphs::Graph_num_intervals($graph);
#      }
#      return \@got;
#    });

# A165208 Bruhat maximal paths
MyOEIS::compare_values
  (anum => 'A165208',
   max_count => 6,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 1; @got < $count; $N++) {
       my $graph = Graph::Maker->new('permutations', N => $N,
                                     rel_type => 'transpose');
       push @got, MyGraphs::Graph_num_maximal_paths($graph);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# transpose_adjacent

MyOEIS::compare_values
  (anum => 'A001286',
   max_count => 6,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 2; @got < $count; $N++) {
       my $graph = Graph::Maker->new('permutations', N => $N,
                                     rel_type => 'transpose_adjacent');
       push @got, scalar($graph->edges);
     }
     return \@got;
   });

# transpose_adjacent intervals
# 1,3,17,151,1899,31711,672697
# A007767 perm pairs avoiding (12,21)
MyOEIS::compare_values
  (anum => 'A007767',
   max_count => 7,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 0; @got < $count; $N++) {
       my $graph = Graph::Maker->new('permutations', N => $N,
                                     rel_type => 'transpose_adjacent');
       push @got, MyGraphs::Graph_num_intervals($graph);
     }
     return \@got;
   });

# A005118 decompositions of n,n-1,...,1 into generators swap (i,i+1)
# 1,1,2,16,768,292864
MyOEIS::compare_values
  (anum => 'A005118',
   max_count => 6,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 0; @got < $count; $N++) {
       my $graph = Graph::Maker->new('permutations', N => $N,
                                     rel_type => 'transpose_adjacent');
       push @got, MyGraphs::Graph_num_maximal_paths($graph);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# transpose_cyclic

MyOEIS::compare_values
  (anum => 'A074143',
   max_count => 5,
   func => sub {
     my ($count) = @_;
     my @got = (1,2);
     for (my $N = 3; @got < $count; $N++) {
       my $graph = Graph::Maker->new('permutations', N => $N,
                                     rel_type => 'transpose_cyclic');
       push @got, scalar($graph->edges);
     }
     return \@got;
   });


# not in OEIS: 1,3,19,187,2568,46053
# MyOEIS::compare_values
#   (anum => 'A000001',
#    max_count => 6,
#    func => sub {
#      my ($count) = @_;
#      my @got;
#      for (my $N = 1; @got < $count; $N++) {
#        my $graph = Graph::Maker->new('permutations', N => $N,
#                                      rel_type => 'transpose_cyclic');
#        push @got, MyGraphs::Graph_num_intervals($graph);
#      }
#      return \@got;
#    });

# not in OEIS: 1,5,38,1692,622728
# MyOEIS::compare_values
#   (anum => 'A165208',
#    max_count => 6,
#    func => sub {
#      my ($count) = @_;
#      my @got;
#      for (my $N = 1; @got < $count; $N++) {
#        my $graph = Graph::Maker->new('permutations', N => $N,
#                                      rel_type => 'transpose_cyclic');
#        push @got, MyGraphs::Graph_num_maximal_paths($graph);
#      }
#      return \@got;
#    });


#------------------------------------------------------------------------------
# onepos

# total transpositions
MyOEIS::compare_values
  (anum => 'A067318',
   max_count => 7,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 1; @got < $count; $N++) {
       my $graph = Graph::Maker->new('permutations', N => $N);
       push @got, scalar($graph->edges);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
exit 0;
