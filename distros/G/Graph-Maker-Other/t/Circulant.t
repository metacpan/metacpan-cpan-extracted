#!/usr/bin/perl -w

# Copyright 2018, 2019, 2020, 2021 Kevin Ryde
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

plan tests => 29;

require Graph::Maker::Circulant;


#------------------------------------------------------------------------------
{
  my $want_version = 19;
  ok ($Graph::Maker::Circulant::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::Circulant->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::Circulant->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::Circulant->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# offset_list=>[0] self-loops

{
  my $circulant = Graph::Maker->new('circulant', N=>3, offset_list=>[0],
                                    multiedged => 1);
  ok ($circulant->out_degree(1), 1);
  my $loops = Graph->new (multiedged => 1);
  $loops->add_edges([1,1],[2,2],[3,3]);  
  ok (!! $circulant->is_multiedged, 1);
  ok (!! $loops    ->is_multiedged, 1);
  ok (!! $circulant->eq($loops), 1, "loops N=3");

  $loops->add_edges([1,1],[2,2],[3,3]);  
  ok ($loops->out_degree(1), 2);

  # eq is by stringified, which doesn't double multiedged
  # ok (! $circulant->eq($loops), 1, "loops N=3");
  # print "$circulant\n";
  # print "$loops\n";
}
{
  my $circulant = Graph::Maker->new('circulant', N=>3, offset_list=>[0],
                                   countedged => 1);
  ok (!! $circulant->is_countedged, 1);
  ok ($circulant->get_edge_count(1,1), 1);
  ok ($circulant->get_edge_count(2,2), 1);
  ok ($circulant->get_edge_count(3,3), 1);

  my $loops = Graph->new (countedged => 1);
  $loops->add_edges([1,1],[2,2],[3,3]);  
  ok (!! $loops ->is_countedged, 1);
  ok ($loops    ->get_edge_count(3,3), 1);
  ok(!! $circulant->eq($loops), 1, "loops N=3");

  $loops->add_edges([1,1],[2,2],[3,3]);  
  ok ($loops    ->get_edge_count(3,3), 2);

  # eq is by stringified, which doesn't double countedged
  # ok(! $circulant->eq($loops), 1, "loops N=3");
  # print "$circulant\n";
  # print "$loops\n";
}

#------------------------------------------------------------------------------
# single offset_list=>[1] same as cycle, per POD

require Graph::Maker::Cycle;
foreach my $N (1 .. 6) {
  my $cycle = Graph::Maker->new('cycle', N=>$N);
  my $circulant = Graph::Maker->new('circulant', N=>$N, offset_list=>[1]);
  ok($cycle->eq($circulant)?1:0, 1, "complete circulant N=$N");
}

#------------------------------------------------------------------------------
# full offset_list same as complete, per POD

require Graph::Maker::Complete;
foreach my $N (1 .. 6) {
  my $complete = Graph::Maker->new('complete', N=>$N);
  # Graph::Maker::Complete version 0.1 doesn't put vertex 1 for N=1
  $complete->add_vertex(1);

  my $circulant = Graph::Maker->new('circulant',
                                    N=>$N, offset_list=>[1..int($N/2)]);
  ok($complete->eq($circulant)?1:0, 1, "complete circulant N=$N");
  # print "$complete\n";
  # print "$circulant\n";
}

#------------------------------------------------------------------------------
exit 0;
