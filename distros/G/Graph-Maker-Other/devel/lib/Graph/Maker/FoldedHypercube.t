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
use List::Util 'sum';
use Test;
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

plan tests => 577;

use FindBin;
use lib "$FindBin::Bin/../..";

require Graph::Maker::FoldedHypercube;


#------------------------------------------------------------------------------
{
  my $want_version = 14;
  ok ($Graph::Maker::FoldedHypercube::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::FoldedHypercube->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::FoldedHypercube->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::FoldedHypercube->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# Properties

# As shown in the POD.
sub want_num_edges {
  my ($N) = @_;
  return ($N==0 || $N==1 ? 0 : $N==2 ? 1 : $N * 2**($N-2));
}

{
  foreach my $N (0 .. 6) {
    my $graph = Graph::Maker->new('folded_hypercube',
                                  undirected => 1,
                                  N => $N);
    # FIXME: is this right
    ok ($graph->diameter || 0,  int($N/2),
        "diameter N=$N");
  }
}

#------------------------------------------------------------------------------
# No Duplicate Edges

# As shown in the POD.
sub want_degree {
  my ($N) = @_;
  return ($N==1||$N==2 ? $N-1 : $N);
}

foreach my $multiedged (0, 1) {
  foreach my $N (0 .. 8) {
    my $graph = Graph::Maker->new('folded_hypercube',
                                  undirected => 1,
                                  N => $N,
                                  multiedged => $multiedged);
    ok ($graph->is_multiedged ? 1 : 0, $multiedged);

    my $num_vertices = $graph->vertices;
    ok ($num_vertices,  $N==0 ? 1 : 2**($N-1),
        "num vertices N=$N multiedged=$multiedged");

    my $num_edges = $graph->edges;
    ok ($num_edges, want_num_edges($N),
        "num edges N=$N multiedged=$multiedged");

    # degree regular
    foreach my $v ($graph->vertices) {
      ok ($graph->degree($v), want_degree($N),
          "degree v=$v in N=$N multiedged=$multiedged");
    }
  }
}

#------------------------------------------------------------------------------
exit 0;
