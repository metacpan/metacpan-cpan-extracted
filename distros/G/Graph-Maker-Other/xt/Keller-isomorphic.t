#!/usr/bin/perl -w

# Copyright 2017, 2019, 2021 Kevin Ryde
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
use File::Spec;
use File::Slurp;
use Test;
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Graph::Maker::Keller;

use File::Spec;
use lib File::Spec->catdir('devel','lib');
use MyGraphs;

# uncomment this to run the ### lines
# use Smart::Comments;

plan tests => 4;


#------------------------------------------------------------------------------
# POD HOG Shown

{
  my %shown;
  {
    my $content = File::Slurp::read_file
      (File::Spec->catfile($FindBin::Bin,
                           File::Spec->updir,
                           'lib','Graph','Maker','Keller.pm'));
    $content =~ /=head1 HOUSE OF GRAPHS.*?=head1/s or die;
    $content = $&;
    my $count = 0;
    my $subgraph = 0;
    while ($content =~ /^ +(?<id>\d+) +N=(?<N>\d+)|(?<subgraph>subgraph.*?option)/mg) {
      if ($+{'subgraph'}) {
        $subgraph = 1;
        next;
      }
      $count++;
      my $id = $+{'id'};
      my $N  = $+{'N'};
      $shown{"N=$N,subgraph=$subgraph"} = $+{'id'};
    }
    ok ($count, 7, 'HOG ID number lines');
    ok ($subgraph, 1, 'saw subgraph option');
  }
  ok (scalar(keys %shown), 7);
  ### %shown

  my $extras = 0;
  my $compared = 0;
  my $others = 0;
  foreach my $subgraph (0 .. 1) {
    foreach my $N (($subgraph ? 2 : 1) .. 5) {
      my $graph = Graph::Maker->new('Keller', undirected => 1,
                                    N => $N,
                                    subgraph => $subgraph);
      my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
      $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
      my $key = "N=$N,subgraph=$subgraph";
      ### $key
      ### vertices: scalar $graph->vertices
      last if $graph->vertices > 255;
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
    }
  }
  MyTestHelpers::diag ("POD HOG $compared compares, $others others");
  ok ($extras, 0);
}

#------------------------------------------------------------------------------
exit 0;
