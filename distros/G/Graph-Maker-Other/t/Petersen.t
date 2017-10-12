#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017 Kevin Ryde
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

# uncomment this to run the ### lines
# use Smart::Comments;

plan tests => 8;

use Graph::Maker::Petersen;


#------------------------------------------------------------------------------
{
  my $want_version = 8;
  ok ($Graph::Maker::Petersen::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::Petersen->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::Petersen->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::Petersen->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------

{
  my $graph = Graph::Maker->new('Petersen');
  ok($graph->get_graph_attribute('name'),'Petersen');
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 10);
}
{
  my $graph = Graph::Maker->new('Petersen', N=>5, K=>2);
  ok($graph->get_graph_attribute('name'),'Petersen');
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 10);
}


#------------------------------------------------------------------------------
exit 0;
