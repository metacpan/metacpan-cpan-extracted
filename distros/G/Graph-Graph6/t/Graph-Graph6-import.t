#!/usr/bin/perl -w

# Copyright 2015, 2017 Kevin Ryde
#
# This file is part of Graph-Graph6.
#
# Graph-Graph6 is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Graph-Graph6 is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Graph-Graph6.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Graph::Graph6 'read_graph', 'write_graph',
  'HEADER_GRAPH6','HEADER_SPARSE6','HEADER_DIGRAPH6';
use Test;
plan tests => 7;

#------------------------------------------------------------------------------
# read_graph()

{
  my $num_vertices;
  my $ret = read_graph(str  => chr(68).chr(81).chr(99)."\n",
                       num_vertices_ref => \$num_vertices);
  ok ($ret, 1);
  ok ($num_vertices, 5);
}

#------------------------------------------------------------------------------
# write_graph()

{
  my $str;
  my $ret = write_graph(str_ref      => \$str,
                        num_vertices => 5,
                        edge_aref => [[0,2],[4,0],[1,3],[3,4]]);
  ok ($ret, 1);
  ok ($str, chr(68).chr(81).chr(99)."\n");
}

#------------------------------------------------------------------------------
# headers

ok (HEADER_GRAPH6(), '>>graph6<<');
ok (HEADER_SPARSE6(), '>>sparse6<<');
ok (HEADER_DIGRAPH6(), '>>digraph6<<');

#------------------------------------------------------------------------------
exit 0;
