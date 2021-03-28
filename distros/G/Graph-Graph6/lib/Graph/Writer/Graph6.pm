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


# ENHANCE-ME: Maybe an append option to append to a $filename instead of
# re-write it.  Perhaps 


package Graph::Writer::Graph6;
use 5.004;
use strict;
use Graph::Graph6;
use Graph::Writer;

use vars '@ISA','$VERSION';
@ISA = ('Graph::Writer');
$VERSION = 9;


sub _init  {
  my ($self,%param) = @_;
  $self->SUPER::_init();
  %$self = (format => 'graph6',
            %$self,
            %param);
}

# $graph is a Graph.pm object
# return true if there is an edge either direction between $v1 and $v2
sub _has_edge_either_directed {
  my ($graph, $v1, $v2) = @_;
  return ($graph->has_edge($v1,$v2) || $graph->has_edge($v2,$v1));
}

sub _write_graph {
  my ($self, $graph, $fh) = @_;

  my @vertices = sort $graph->vertices;
  my @edge_options;
  my $format = $self->{'format'};
  if ($format eq 'sparse6') {
    my @edges = $graph->edges;  # [ $from_name, $to_name ]
    ### @edges

    # as [$from,$to] numbers
    my %vertex_to_num = map { $vertices[$_] => $_ } 0 .. $#vertices;
    @edges = map { my $from = $vertex_to_num{$_->[0]};
                   my $to   = $vertex_to_num{$_->[1]};
                   [$from, $to]
                 } @edges;
    @edge_options = (edge_aref => \@edges);
  } else {
    my $has_edge_either = ($graph->is_directed && $format ne 'digraph6'
                           ? \&_has_edge_either_directed

                           # graph undirected, or directed and format digraph
                           : 'has_edge');
    @edge_options
      = (edge_predicate => sub {
           my ($from, $to) = @_;
           return $graph->$has_edge_either($vertices[$from], $vertices[$to]);
         });
  }

  Graph::Graph6::write_graph
      (format => $format,
       header => $self->{'header'},
       fh     => $fh,
       num_vertices => scalar(@vertices),
       @edge_options);
  return 1;
}

1;
__END__

=for stopwords Ryde ascii undirected multi-edges multiedged countedged ok

=head1 NAME

Graph::Writer::Graph6 - write Graph.pm in graph6, sparse6 or digraph6 format

=for test_synopsis my ($graph, $filehandle)

=head1 SYNOPSIS

 use Graph::Writer::Graph6;
 my $writer = Graph::Writer::Graph6->new;
 $writer->write_graph($graph, 'filename.txt');
 $writer->write_graph($graph, $filehandle);

 # or one-off create and use
 Graph::Writer::Graph6->new->write_graph($graph,'filename.txt');

=head1 CLASS HIERARCHY

C<Graph::Writer::Graph6> is a subclass of C<Graph::Writer>.

    Graph::Writer
      Graph::Writer::Graph6

=head1 DESCRIPTION

C<Graph::Writer::Graph6> writes a C<Graph.pm> graph to a file or file handle
in graph6, sparse6 or digraph6 format.  These formats are per

=over 4

L<http://cs.anu.edu.au/~bdm/data/formats.txt>

=back

graph6 represents an undirected graph with no self-loops or multi-edges.
Any self-loops in C<$graph> are ignored.  Multi-edges are written just once,
and if C<$graph> is directed then an edge of either direction is written.

sparse6 represents an undirected graph possibly with multi-edges and
self-loops.  If C<$graph> is directed then an edge in either direction is
written.  If there's edges both ways then a multi-edge is written.

digraph6 represents a directed graph, possibly with self-loops but no
multi-edges.  Any multi-edges in C<$graph> are written just once.  If
C<$graph> is undirected then an edge in written in both directions (though
usually graph6 or sparse6 would be preferred for undirected).

The formats have no vertex names and no attributes.  In the current
implementation C<$graph-E<gt>vertices()> is sorted alphabetically (C<sort>)
to give a consistent (though slightly arbitrary) vertex numbering.

See L<Graph::Graph6> for further notes on the formats.  See
F<examples/graph-random.pl> for a complete sample program.

=head1 FUNCTIONS

=over

=item C<$writer = Graph::Writer::Graph6-E<gt>new (key =E<gt> value, ...)>

Create and return a new writer object.  The key/value options are

    format   => "graph6", "sparse6" or "digraph6",
                  string, default "graph6"
    header   => boolean, default false

If C<header> is true then write a header C<E<gt>E<gt>graph6E<lt>E<lt>>,
C<E<gt>E<gt>sparse6E<lt>E<lt>> or C<E<gt>E<gt>digraph6E<lt>E<lt>> as
appropriate.

=item C<$writer-E<gt>write_graph($graph, $filename_or_fh)>

Write C<$graph> to C<$filename_or_fh> in the selected C<format>.

C<$graph> is either a C<Graph.pm> object or something sufficiently
compatible.  There's no check on the actual class of C<$graph>.  (Don't
mistakenly pass a C<Graph::Easy> here.  It's close enough that it runs, but
doesn't give a consistent vertex order and might miss edges on undirected
graphs.)

C<$filename_or_fh> can be a string filename.  The file is replaced with the
graph.

C<$filename_or_fh> can be a reference which is taken to be a file handle and
the graph is written to it.  Multiple graphs can be written to a handle one
after the other to make a file or other output of several graphs.  The
format includes a final newline "\n" terminator in all cases.

    my $writer = Graph::Writer::Graph6->new;
    $writer->write_graph($graph1, \*STDOUT);
    $writer->write_graph($graph2, \*STDOUT);

=back

=head1 BUGS

Writing a big graph in graph6 and digraph6 format is not particularly fast.
The current implementation uses C<Graph.pm> method C<has_edge()> and makes
O(N^2) calls to it for a graph of N vertices.  The overhead of this becomes
significant for big graphs.  For a graph of relatively few edges getting all
C<edges()> at once would be faster, but in that case writing sparse6 would
be both smaller and faster, if that format is suitable for a given
application.

C<Graph.pm> 0.96 had a bug on multiedged undirected graphs where its
C<edges()> method sometimes did not return all the edges of the graph,
causing sparse6 output to miss some edges.  This likely affects other things
too so use version 0.97 for such a graph (or countedged undirected was ok if
that suits).

=head1 SEE ALSO

L<Graph>,
L<Graph::Writer>,
L<Graph::Writer::Sparse6>

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
