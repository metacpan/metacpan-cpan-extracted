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

package Graph::Writer::Graph6;
use 5.004;
use strict;
use Graph::Graph6;
use Graph::Writer;

use vars '@ISA','$VERSION';
@ISA = ('Graph::Writer');
$VERSION = 6;

# uncomment this to run the ### lines
# use Smart::Comments;


sub _init  {
  my ($self,%param) = @_;
  $self->SUPER::_init();
  %$self = (%param, %$self);
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
  my $has_edge_either = ($graph->is_directed
                         ? \&_has_edge_either_directed
                         : 'has_edge');

  Graph::Graph6::write_graph
      (format => 'graph6',
       header => $self->{'header'},
       fh     => $fh,
       num_vertices => scalar(@vertices),
       edge_predicate => sub {
         my ($from, $to) = @_;
         return $graph->$has_edge_either($vertices[$from], $vertices[$to]);
       });
  return 1;
}

1;
__END__

=for stopwords Ryde ascii undirected multi-edges

=head1 NAME

Graph::Writer::Graph6 - write Graph.pm in graph6 format

=for test_synopsis my ($graph, $filehandle)

=head1 SYNOPSIS

 use Graph::Writer::Graph6;
 my $writer = Graph::Writer::Graph6->new;
 $writer->write_graph($graph, 'filename.txt');
 $writer->write_graph($graph, $filehandle);

=head1 CLASS HIERARCHY

C<Graph::Writer::Graph6> is a subclass of C<Graph::Writer>.

    Graph::Writer
      Graph::Writer::Graph6

=head1 DESCRIPTION

C<Graph::Writer::Graph6> writes a C<Graph.pm> graph to a file in graph6
format.  This file format is per

=over 4

L<http://cs.anu.edu.au/~bdm/data/formats.txt>

=back

The format represents an undirected graph with no self-loops or multi-edges.
Any self-loops in C<$graph> are ignored.  Multi-edges are written just once,
and if C<$graph> is directed then an edge of either direction is written.

The format has no vertex names and no attributes.  In the current
implementation C<$graph-E<gt>vertices()> is sorted alphabetically (C<sort>)
to give a consistent (though slightly arbitrary) vertex numbering.

See L<Graph::Graph6> for further notes on the formats.  See
F<examples/graph-random.pl> in the Graph-Graph6 sources for a complete
sample program.

=head1 FUNCTIONS

=over

=item C<$writer = Graph::Writer::Graph6-E<gt>new (key =E<gt> value, ...)>

Create and return a new writer object.  The only key/value option is

    header   => boolean (default false)

If C<header> is true then include a header C<E<gt>E<gt>graph6E<lt>E<lt>>.

=item C<$writer-E<gt>write_graph($graph, $filename_or_fh)>

Write C<$graph> to C<$filename_or_fh> in the selected C<format>.  A final
newline C<"\n"> is written so this is suitable for writing multiple graphs
one after the other.

C<$graph> is either a C<Graph.pm> object or something sufficiently
compatible.  There's no check on the actual class of C<$graph>.  (Don't
mistakenly pass a C<Graph::Easy> here.  It's close enough that it runs, but
doesn't give a consistent vertex order and may miss edges on undirected
graphs.)

=back

=head1 BUGS

The current implementation uses C<Graph.pm> method C<has_edge()> and makes
O(N^2) calls to it for a graph of N vertices.  The overhead of this means
writing a graph of many vertices is a touch on the slow side.  For a graph
of relatively few edges getting all C<edges()> at once would be faster, but
in that case sparse6 would be both smaller and faster, provided that format
was suitable for a given application.

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

Copyright 2015, 2016 Kevin Ryde

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
