#!/usr/bin/perl -w

# Copyright 2019 Kevin Ryde
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
use List::Util 'max';
use Test;

# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use File::Spec;
use lib File::Spec->catdir('devel','lib');
use MyGraphs;

use Graph::Maker::BinomialBoth;

# uncomment this to run the ### lines
# use Smart::Comments;

plan tests => 47;


#------------------------------------------------------------------------------
# POD HOG Shown

{
  my %shown;
  {
    my $content = File::Slurp::read_file
      (File::Spec->catfile($FindBin::Bin,
                           File::Spec->updir,
                           'devel','lib','Graph','Maker','BinomialBoth.pm'));
    $content =~ /=head1 HOUSE OF GRAPHS.*?=head1/s or die;
    $content = $&;
    my $count = 0;
    while ($content =~ /^ +(?<id>\d+) +order=(?<order>\d+)/mg) {
      $count++;
      my $id    = $+{'id'};
      my $order = $+{'order'};
      $shown{"order=$order"} = $+{'id'};
    }
    ok ($count, 3, 'HOG ID number lines');
  }
  ok (scalar(keys %shown), 3);
  ### %shown

  my $extras = 0;
  my $compared = 0;
  my $others = 0;
  my $try = sub {
    my @params = @_;
    my $graph = Graph::Maker->new('binomial_both', undirected => 1, @params);
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
  foreach my $order (0 .. 7) {
    $try->(order => $order);
  }
  MyTestHelpers::diag ("POD HOG $compared compares, $others others");
  ok ($extras, 0);
}


#------------------------------------------------------------------------------
# Top-Down Two Halves

foreach my $k (1 .. 8) {
  my $graph = Graph::Maker->new('binomial_both',
                                order => $k,
                                undirected => 1);

  my $half = Graph::Maker->new('binomial_both',
                               order => $k-1,
                               undirected => 1);
  my $max = max($half->vertices);
  foreach my $edge ($half->edges) {
    my ($from,$to) = @$edge;
    $half->add_edge ("B$from","B$to");
  }
  $half->add_edge (0, "B0");
  $half->add_edge ($max, "B$max");

  ok (!! MyGraphs::Graph_is_isomorphic($graph,$half), 1,
      "lattice by two halves k=$k");
}


#------------------------------------------------------------------------------
# Num Intervals Etc

sub want_num_complementary {
  my ($k) = @_;
  return ($k == 0 ? 1 : (2**($k-1) - 1)**2 + 1),
}

foreach my $k (0 .. 8) {
  my $graph = Graph::Maker->new('binomial_both',
                                order => $k,
                                direction_type => 'bigger');
  ok (scalar($graph->vertices), 2**$k);

  ok (MyGraphs::Graph_num_maximal_paths($graph),
      ($k == 0 ? 1 : 2**($k-1)),
      "num maximal chains k=$k");

  ok (MyGraphs::Graph_num_intervals($graph),
      $k*2**$k + 1,
      "num intervals k=$k");

  my $minmax = MyGraphs::Graph_lattice_minmax_hash($graph);
  ok(MyGraphs::lattice_minmax_num_complementary_pairs($graph,$minmax),
     want_num_complementary($k),
     "num complementary pairs k=$k");
}


#------------------------------------------------------------------------------
exit 0;
