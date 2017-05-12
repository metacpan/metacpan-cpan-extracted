#!/usr/bin/perl -w

# Copyright 2015, 2016 Kevin Ryde
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
use 5.010;
use FindBin;
use File::Slurp;
use List::Util 'max';
use Graph;
use Graph::Writer::Graph6;
use Graph::Easy;
use Graph::Easy::As_graph6;
use Graph::Easy::Parser::Graph6;
use Graph::Graph6;
use List::Util 'min','max';
use MyGraphs;

# uncomment this to run the ### lines
use Smart::Comments;

BEGIN { unshift @INC, '../gmaker/lib'; }


{
  require Graph::DIMACS;
  require Graph::Graph6;
  my $n = 4;
  my $edge_aref = [];
  my $num_vertices;
  Graph::DIMACS::read_graph
      (
       filename => "/so/dimacs/keller$n.clq.b",
       # filename => "/so/dimacs/keller$n.clq",
       edge_aref => $edge_aref,
       num_vertices_ref => \$num_vertices,
      );

  my $num_edges = scalar(@$edge_aref);
  print "$num_vertices vertices\n";
  print "$num_edges edges\n";

  foreach (@$edge_aref) { $_->[0]--; $_->[1]-- }
  my $dimacs_s6;
  Graph::Graph6::write_graph(edge_aref => $edge_aref,
                             num_vertices => $num_vertices,
                             str_ref => \$dimacs_s6);

  require Graph::Maker::Keller;
  my $maker = Graph::Maker->new('Keller', N=>$n, subgraph=>1, undirected=>1);
  my $maker_s6 = Graph_to_graph6_str($maker);

  print "canon\n";
  $dimacs_s6 = graph6_str_to_canonical($dimacs_s6);
  $maker_s6 = graph6_str_to_canonical($maker_s6);

  print $dimacs_s6,"\n";
  print $maker_s6,"\n";

  my $eq = $dimacs_s6 eq $maker_s6 ? 1 : 0;
  print "equal $eq\n";
  exit 0;
}

{
  require Graph::DIMACS;
  my $n = 4;
  my $b_edge_aref = [];
  Graph::DIMACS::read_graph
      (filename => "/so/dimacs/keller$n.clq.b",
       edge_aref => $b_edge_aref);

  my $t_edge_aref = [];
  Graph::DIMACS::read_graph
      (filename => "/so/dimacs/keller$n.clq",
       edge_aref => $t_edge_aref);

  @$b_edge_aref = map {join(',',@$_)} @$b_edge_aref;
  @$t_edge_aref = map {join(',',@$_)} @$t_edge_aref;
  # @$b_edge_aref = sort @$b_edge_aref;
  # @$t_edge_aref = sort @$t_edge_aref;
  my $b = join(' ',@$b_edge_aref);
  my $t = join(' ',@$t_edge_aref);

  my $eq = $b eq $t ? 1 : 0;
  print "equal $eq\n";
  exit 0;
}

{
  require Graph::DIMACS;
  my $n = 4;
  my $edge_aref = [];
  my $num_vertices;
  Graph::DIMACS::read_graph
      (
       filename => "/so/dimacs/keller$n.clq.b",
       # filename => "/so/dimacs/keller$n.clq",
       edge_aref => $edge_aref,
       comments_func => sub { print @_; },
       num_vertices_ref => \$num_vertices,
      );

  my $num_edges = scalar(@$edge_aref);
  print "$num_vertices vertices\n";
  print "$num_edges edges\n";

  my $dimacs = Graph_from_edge_aref($edge_aref);

  require Graph::Maker::Keller;
  my $maker = Graph::Maker->new('Keller', N=>$n, subgraph=>1, undirected=>1);

  my $iso = Graph_is_isomorphic($dimacs, $maker) ? 1 : 0;
  print "iso $iso\n";
  print "d "; Graph_degree_counts($dimacs);
  print "m "; Graph_degree_counts($maker);
  # Graph_view($dimacs);
  exit 0;
}

{
  require Graph::DIMACS;
  foreach my $filename (glob "/so/dimacs/*.b") {
    Graph::DIMACS::read_graph
        (filename => $filename,
         comments_func => sub { print @_; },
        );
  }
  exit 0;
}

sub Graph_degree_counts {
  my ($graph) = @_;
  my @d;
  foreach my $v ($graph->vertices) {
    $d[$graph->degree($v)]++;
  }
  foreach my $d (@d) {
    print $d // '', ',';
  }
  print "\n";
}
