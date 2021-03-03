#!/usr/bin/perl -w

# Copyright 2017, 2018, 2019, 2020, 2021 Kevin Ryde
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

plan tests => 252;

require Graph::Maker::BiStar;


#------------------------------------------------------------------------------
{
  my $want_version = 18;
  ok ($Graph::Maker::BiStar::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::BiStar->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::BiStar->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::BiStar->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# N=0 or M=0 same as Star
# same vertex numbers, so stringize to same

require Graph::Maker::Star;
foreach my $N (2 .. 5) {
  foreach my $undirected (0, 1) {
    foreach my $multiedged (0, 1) {
      foreach my $NM (0, 1) {
        my $param_N = $NM ? $N : 0;
        my $param_M = $NM ? 0 : $N;
        my $star = Graph::Maker->new('star',
                                     N => $N,
                                     undirected => $undirected,
                                     multiedged => $multiedged);
        my $bistar = Graph::Maker->new('bi_star',
                                       N => $param_N,
                                       M => $param_M,
                                       undirected => $undirected,
                                       multiedged => $multiedged);
        ok ("$bistar","$star");
      }
    }
  }
}

#------------------------------------------------------------------------------

foreach my $N (0 .. 5) {
  foreach my $M (0 .. 5) {
    foreach my $undirected (0, 1) {
      foreach my $multiedged (0, 1) {
        my $graph = Graph::Maker->new('bi_star',
                                      N => $N, M => $M,
                                      undirected => $undirected,
                                      multiedged => $multiedged);
        if ($undirected) {
          ok ($graph->is_connected ? 1 : 0,
              $N||$M ? 1 : 0,            # empty graph is not connected
              "connected N=$N M=$M");
        }
        my $num_vertices = scalar($graph->vertices);
        my $num_edges = $graph->edges;
        ok ($num_edges,
            ($num_vertices==0 ? 0 : $num_vertices-1) * ($undirected ? 1 : 2));
      }
    }
  }
}

#------------------------------------------------------------------------------
exit 0;
