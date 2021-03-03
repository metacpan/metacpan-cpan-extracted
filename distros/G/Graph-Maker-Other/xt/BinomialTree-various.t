#!/usr/bin/perl -w

# Copyright 2017, 2018, 2019, 2020 Kevin Ryde
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

use strict;
use 5.004;
use FindBin;
use File::Slurp;
use POSIX 'ceil';
use Test;

# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use Graph::Maker::BinomialTree;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use File::Spec;
use lib File::Spec->catdir('devel','lib');
use MyGraphs;

# uncomment this to run the ### lines
# use Smart::Comments;

plan tests => 151;


#------------------------------------------------------------------------------
# independence and domination

foreach my $N (0 .. 32) {
  my $graph = Graph::Maker->new('binomial_tree',
                                N => $N,
                                undirected => 1);
  ok (MyGraphs::Graph_tree_indnum($graph),
      ceil($N/2),
      "indnum N=$N");
  ok (MyGraphs::Graph_tree_domnum($graph),
      $N==1 ? 1 : int($N/2),
      "domnum N=$N");

  ok ($graph->has_vertex(0) ? 1 : 0,  $N>=1 ? 1 : 0,
      "have vertex 0 in N=$N");
  # my $total_depths = 0;
  # foreach my $v ($graph->vertices) {
  #   $total_depths += $graph->path_length(0,$v);
  # }
  # ok ($total_depths, 0,
  #     "total depths N=$N");
}


#------------------------------------------------------------------------------
# POD HOG Shown

{
  # my %shown = ('N=1' => 1310,   'order=0' => 1310,
  #              'N=2' => 19655,  'order=1' => 19655,
  #              'N=3' => 32234,
  #              'N=4' => 594,    'order=2' => 594,
  #              'N=5' => 30,
  #              'N=6' => 496,
  #              'N=7' => 714,
  #              'N=8' => 700,    'order=3' => 700,
  #              'N=16'  => 28507, 'order=4' => 28507,
  #              'N=32'  => 21088, 'order=5' => 21088,
  #              'N=64'  => 33543, 'order=6' => 33543,
  #              'N=128' => 33545, 'order=7' => 33545,
  #             );

  my %shown;
  {
    my $content = File::Slurp::read_file
      (File::Spec->catfile($FindBin::Bin,
                           File::Spec->updir,
                           'lib','Graph','Maker','BinomialTree.pm'));
    $content =~ /=head1 HOUSE OF GRAPHS.*?=head1/s or die;
    $content = $&;
    my $count = 0;
    while ($content =~ /^ +(?<ids>(\d+, )*\d+) +N=(?<Nlo>\d+)( to N=(?<Nhi>[0-9]+))?( +\(order=(?<order>\d+)\))?/mg) {
      $count++;
      my $ids = $+{'ids'};
      my $Nlo = $+{'Nlo'};
      my $Nhi = $+{'Nhi'} // $Nlo;
      my $order = $+{'order'};
      ### $ids
      ### $Nlo
      ### $Nhi
      my @ids = split /, /, $ids;
      if (defined $order) {
        ok (scalar(@ids), 1, 'one id only for order=X');
        $shown{"order=$order"} = $ids[0];
      }
      for (my $N = $Nlo; $N <= $Nhi; $N++) {
        @ids or die;
        my $id = shift @ids;
        my $key = "N=$N";
        ok (! exists $shown{$key}, 1);
        $shown{"N=$N"} = $id;
      }
      ok (scalar(@ids), 0,
          "oops, number of ids doesn't match N range");
    }
    ok ($count, 14, 'HOG ID number lines');
  }
  ok (scalar(keys %shown), 27);
  ### %shown

  my $extras = 0;
  my $compared = 0;
  my $others = 0;
  my $try = sub {
    my @params = @_;
    my $graph = Graph::Maker->new('binomial_tree', undirected => 1, @params);
    my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
    $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
    my $key = join('=',@params);
    if (my $id = $shown{$key}) {
      MyGraphs::hog_compare($id, $g6_str);
      $compared++;
    } else {
      $others++;
      if (MyGraphs::hog_grep($g6_str)) {
        my $name = $graph->get_graph_attribute('name');
        MyTestHelpers::diag ("HOG $key not shown in POD");
        MyTestHelpers::diag ($name);
        MyTestHelpers::diag ($g6_str);
        MyGraphs::Graph_view($graph);
        $extras++;
      }
    }
  };
  foreach my $n (1 .. 40) {
    $try->(N=>$n);
  }
  foreach my $order (0 .. 7) {
    $try->(order=>$order);
  }
  MyTestHelpers::diag ("POD HOG $compared compares, $others others");
  ok ($extras, 0);
}


#------------------------------------------------------------------------------
# k+1 is k with a new leaf on every existing vertex

foreach my $k (0 .. 7) {
  my $tree_k = Graph::Maker->new('binomial_tree',
                                 order => $k,
                                 undirected => 1);
  my $tree_k_plus_1 = Graph::Maker->new('binomial_tree',
                                        order => $k+1,
                                        undirected => 1);
  foreach my $v ($tree_k->vertices) {
    $tree_k->add_edge($v, "$v-extra");
  }
  ok (!! MyGraphs::Graph_is_isomorphic($tree_k,$tree_k_plus_1), 1);
}


#------------------------------------------------------------------------------
exit 0;
