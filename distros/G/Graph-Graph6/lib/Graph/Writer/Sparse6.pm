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

package Graph::Writer::Sparse6;
use 5.006;
use strict;
use warnings;
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

sub _write_graph {
  my ($self, $graph, $fh) = @_;

  my $num_vertices;
  my @edges = $graph->edges;  # [ $from_name, $to_name ]
  ### @edges
  {
    # as [$from,$to] numbers
    my @vertices = sort $graph->vertices;
    $num_vertices = scalar(@vertices);
    my %vertex_to_num = map { $vertices[$_] => $_ } 0 .. $#vertices;
    @edges = map { my $from = $vertex_to_num{$_->[0]};
                   my $to   = $vertex_to_num{$_->[1]};
                   [$from, $to]
                 } @edges;
  }

  Graph::Graph6::write_graph(format => 'sparse6',
                             header => $self->{'header'},
                             fh     => $fh,
                             num_vertices   => $num_vertices,
                             edge_aref      => \@edges);
  return 1;
}

1;
__END__

=for stopwords Ryde ascii undirected multi-edge multi-edges multiedged countedged ok

=head1 NAME

Graph::Writer::Sparse6 - write Graph.pm in sparse6 format

=for test_synopsis my ($graph, $filehandle)

=head1 SYNOPSIS

 use Graph::Writer::Sparse6;
 my $writer = Graph::Writer::Sparse6->new;
 $writer->write_graph($graph, 'filename.txt');
 $writer->write_graph($graph, $filehandle);

=head1 CLASS HIERARCHY

C<Graph::Writer::Sparse6> is a subclass of C<Graph::Writer>.

    Graph::Writer
      Graph::Writer::Sparse6

=head1 DESCRIPTION

C<Graph::Writer::Sparse6> writes a C<Graph.pm> graph to a file in sparse6
format.  This file format is per

=over 4

L<http://cs.anu.edu.au/~bdm/data/formats.txt>

=back

The format represents an undirected graph possibly with multi-edges and
self-loops.  If a given C<$graph> is directed then an edge in either
direction is written.  If there's edges both ways then a multi-edge is
written.

There are no vertex names and no attributes in the output.  In the current
implementation C<$graph-E<gt>vertices()> is sorted alphabetically (C<sort>)
to give a consistent (though slightly arbitrary) vertex numbering.

See L<Graph::Graph6> for further notes on the formats.

=head1 FUNCTIONS

=over

=item C<$writer = Graph::Writer::Sparse6-E<gt>new (key =E<gt> value, ...)>

Create and return a new writer object.  The only key/value option is

    header   => boolean (default false)

If C<header> is true then include a header C<E<gt>E<gt>sparse6E<lt>E<lt>>.

=item C<$writer-E<gt>write_graph($graph, $filename_or_fh)>

Write C<$graph> to C<$filename_or_fh> in sparse6 format.  A final newline
C<"\n"> is written so this is suitable for writing multiple graphs one after
the other to a file handle.

C<$graph> should be a C<Graph.pm> object or something compatible.  There's
no check on the actual class of C<$graph>.

=back

=head1 BUGS

C<Graph.pm> 0.96 had a bug on undirected multiedged graphs where its
C<edges()> method sometimes did not return all the edges of the graph,
causing C<Graph::Writer::Sparse6> to write only those edges.  This likely
affects other things too so use version 0.97 for such a graph, or undirected
countedged was ok.

=head1 SEE ALSO

L<Graph>,
L<Graph::Writer>,
L<Graph::Writer::Graph6>

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
