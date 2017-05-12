#!/usr/bin/perl -w

# Copyright 2015 Kevin Ryde
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

use 5.005;
use strict;
use FindBin;
use lib 'devel/lib';

{
  # taint
  require Graph::Graph6;
  require Taint::Util;
  require MyGraphs;
  my @edges;
  my $edge_aref = \@edges;

  my $str = ':Fa@x^';
  Taint::Util::taint($str);
  Graph::Graph6::read_graph
      (# filename => "$MyGraphs::HOG_directory/trees08.g6",
       str => \$str,
       num_vertices_func => sub {
         my ($n) = @_;
         print "num_vertices_func ",
           Taint::Util::tainted($n) ? "taint" : "not","\n";
       },
       num_vertices_ref => \my $num_vertices,
       edge_aref => $edge_aref,
      );
  print "num_vertices ",Taint::Util::tainted($num_vertices) ? "taint" : "not","\n";
  foreach my $i (0 .. $#edges) {
    my $e = $edges[$i];
    print "edge ",Taint::Util::tainted($e) ? "taint" : "not","\n";
    print "  from ",Taint::Util::tainted($e->[0]) ? "taint" : "not","\n";
    print "  to   ",Taint::Util::tainted($e->[1]) ? "taint" : "not","\n";
  }
  exit 0;
}
