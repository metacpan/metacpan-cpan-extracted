#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017, 2018, 2019, 2020, 2021 Kevin Ryde
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

plan tests => 2116;

require Graph::Maker::Crown;


#------------------------------------------------------------------------------
{
  my $want_version = 18;
  ok ($Graph::Maker::Crown::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::Crown->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::Crown->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::Crown->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------

{
  require Graph::Maker::CompleteBipartite;
  foreach my $undirected (0, 1) {
    foreach my $multiedged (0, 1) {
      foreach my $N (0 .. 10) {
        my $crown = Graph::Maker->new ('crown',
                                       N => $N,
                                       undirected => $undirected,
                                       multiedged=>$multiedged);
        my $bipartite = Graph::Maker->new ('complete_bipartite',
                                           N1=>$N, N2=>$N,
                                           undirected => $undirected,
                                           multiedged=>$multiedged);

        ok (join(',', sort {$a<=>$b} $crown->vertices),
            join(',', sort {$a<=>$b} $bipartite->vertices),
            'crown same vertices as complete bipartite');
        foreach my $edge ($crown->edges) {
          ok (!!$bipartite->has_edge(@$edge), 1,
              'crown is edge subset of complete bipartite');
        }

        ok (scalar($crown->vertices), 2*$N);
        ok (scalar($crown->edges),
            ($N*$N - $N) * ($undirected ? 1 : 2));
      }
    }
  }
}

#------------------------------------------------------------------------------
exit 0;
