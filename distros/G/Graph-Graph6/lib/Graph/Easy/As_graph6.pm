# Copyright 2015, 2016, 2017, 2018 Kevin Ryde
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

package Graph::Easy::As_graph6;
use 5.006;  # Graph::Easy is 5.008 anyway
use strict;
use warnings;
use Graph::Graph6;

# uncomment this to run the ### lines
# use Smart::Comments;

our $VERSION = 9;


package Graph::Easy;

# In Graph::Easy 0.75 and 0.76, an undirected graph has_edge($v1,$v2) is
# true only of $v1,$v2 passed in the original edge order, not as $v2,$v1.
# That's probably a bug.
#
# To get the right result, _has_edge_either() is always used for undirected
# graphs.
#
#     output       $graph        method
#     ------       ------        ------
#     graph6       undirected    _has_edge_either() due to has_edge()
#     graph6       directed      _has_edge_either() write either way
#     digraph6     undirected    _has_edge_either() to write both ways
#     digraph6     directed      has_edge()
#
# For graph6 output, maybe some sort of Graph::Easy ->has_neighbour() could
# answer $v1,$v2 either way round for both directed and undirected graphs.
# Name has_neighbour() would correspond to Graph.pm neighbours(), so
# has_neighbour() would be whether a given $v2 is among the neighbours of
# $v1.  (neighbours() are all adjacent vertices, for edges in either
# direction.)

sub _has_edge_either {
  my ($graph, $from, $to) = @_;
  return $graph->has_edge($from,$to) || $graph->has_edge($to,$from);
}

sub as_graph6 {
  my ($graph, %options) = @_;
  ### Graph-Easy as_graph6() ...

  my @vertices = $graph->sorted_nodes('name');
  my $format = $options{'format'} || 'graph6';
  ### $format

  my @edge_options;
  if ($format eq 'sparse6') {
    my @edges = $graph->edges;  # Graph::Easy::Edge objects
    my %name_to_num = map { $vertices[$_]->name => $_ } 0 .. $#vertices;
    @edges = map { [map{$name_to_num{$_->name}} $_->nodes] } @edges;
    ### @edges
    @edge_options = (edge_aref => \@edges)

  } else {
    my $has_edge_method = ($graph->is_directed && $format eq 'digraph6'
                           ? 'has_edge'
                           : \&_has_edge_either);
    @edge_options
      = (edge_predicate
         => sub {
           my ($from, $to) = @_;
           return $graph->$has_edge_method($vertices[$from], $vertices[$to]);
         });
  }

  Graph::Graph6::write_graph
      (format         => $format,
       header         => $options{'header'},
       str_ref        => \my $str,
       num_vertices   => scalar(@vertices),
       @edge_options);
  ### $str
  return $str;
}

1;
__END__

=for stopwords Ryde ascii undirected multi-edges stringize

=head1 NAME

Graph::Easy::As_graph6 - stringize Graph::Easy in graph6 format

=head1 SYNOPSIS

 use Graph::Easy;
 my $graph = Graph::Easy->new;
 $graph->add_edge('foo','bar');

 use Graph::Easy::As_graph6;
 print $graph->as_graph6;

=head1 DESCRIPTION

C<Graph::Easy::As_graph6> adds an C<as_graph6()> method to C<Graph::Easy> to
give a graph as a string of graph6, sparse6 or digraph6.  These formats are
per

=over 4

L<http://cs.anu.edu.au/~bdm/data/formats.txt>

=back

graph6 format is an undirected graph without self-loops or multi-edges.  Any
self-loops in C<$graph> are ignored.  Multi-edges are written just once and
if C<$graph> is directed then an edge of either direction is written.

sparse6 format is an undirected graph possibly with multi-edges and self
loops.  If C<$graph> is directed then an edge in either direction is
written.  If there's edges both ways then a multi-edge is written.

digraph6 format is a directed graph, possibly with self-loops but no
multi-edges.  Any multi-edges in C<$graph> are written just once.  If
C<$graph> is undirected then an edge in written in both directions (though
usually graph6 or sparse6 would be preferred in that case).

The formats have no vertex names and no attributes.  In the current
implementation nodes are sorted alphabetically
(C<$graph-E<gt>sorted_nodes('name')>) to give a consistent (though slightly
arbitrary) vertex numbering.

See L<Graph::Graph6> for further notes on the formats.

=head1 FUNCTIONS

The following new method is added to C<Graph::Easy>.

=over

=item C<$str = $graph-E<gt>as_graph6 (key =E<gt> value, ...)>

Return a string which is the graph6, sparse6 or digraph6 representation of
C<$graph>.

The string returned is printable ASCII.  It includes a final newline C<"\n">
so is suitable for writing directly to a file or similar.  The only
key/value options are

    format   => "graph6", "sparse6" or "digraph6",
                  string, default "graph6"
    header   => boolean (default false)

If C<header> is true then write a header C<E<gt>E<gt>graph6E<lt>E<lt>>,
C<E<gt>E<gt>sparse6E<lt>E<lt>> or C<E<gt>E<gt>digraph6E<lt>E<lt>> as
appropriate.

=back

=head1 SEE ALSO

L<Graph::Easy>,
L<Graph::Easy::As_sparse6>,
L<Graph::Easy::Parser::Graph6>

L<Graph::Graph6>,
L<nauty-showg(1)>,
L<nauty-copyg(1)>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/graph-graph6/index.html>

=head1 LICENSE

Copyright 2015, 2016, 2017, 2018 Kevin Ryde

Graph-Graph6 is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Graph-Graph6 is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Graph-Graph6.  If not, see L<http://www.gnu.org/licenses/>.

=cut
