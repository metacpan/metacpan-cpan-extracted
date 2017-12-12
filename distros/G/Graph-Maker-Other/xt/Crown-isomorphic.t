#!/usr/bin/perl -w

# Copyright 2017 Kevin Ryde
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
use Test;
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use lib 'devel/lib';
use MyGraphs;
use Graph::Maker::Crown;

plan tests => 3;


#------------------------------------------------------------------------------

{
  require Graph::Maker::Hypercube;
  my $crown = Graph::Maker->new('crown', N=>4, undirected=>1);
  my $cube  = Graph::Maker->new('hypercube', N=>3, undirected=>1);
  ok (!! MyGraphs::Graph_is_isomorphic($crown, $cube),
      1,
      "Crown 4 = Cube");
}

#------------------------------------------------------------------------------
# POD HOG Shown

{
  my %shown = (0 => 6901,
               1 => 19653,
               2 => 538,
               3 => 670,
               4 => 1022,
              );
  my %unseen = %shown;
  my $extras = 0;
  my %seen;
  foreach my $N (0 .. 10) {
    my $graph = Graph::Maker->new('crown', undirected => 1,
                                  N => $N);
    my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
    $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
    next if $seen{$g6_str}++;
    my $key = "$N";
    if (my $id = $shown{$key}) {
      MyGraphs::hog_compare($id, $g6_str);
      delete $unseen{$key};
    } else {
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
  ok ($extras, 0);
  ok (scalar(keys %unseen), 0);
}

#------------------------------------------------------------------------------
exit 0;
