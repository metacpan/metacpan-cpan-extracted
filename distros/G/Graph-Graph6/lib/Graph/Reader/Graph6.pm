# Copyright 2015, 2016, 2017 Kevin Ryde
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

package Graph::Reader::Graph6;
use 5.004;
use strict;
use Carp 'croak';
use Graph::Reader;

use vars '@ISA','$VERSION';
@ISA = ('Graph::Reader');
$VERSION = 7;

use Graph::Graph6;


# Not using the base class read_graph() since want Graph->new to follow the
# directed-ness of the format read.
#
# This misses the Graph::Reader::read_graph() warn() on unable to open file,
# but think something in the return would be better than a warn message
# anyway.
# 
sub read_graph {
  my ($self, $filename_or_fh) = @_;
  require Graph;

  my $width = 1;
  # this vertex_name_func not a documented feature yet ...
  my $vertex_name_func = $self->{'vertex_name_func'}
    || sub {
      my ($n) = @_;
      return sprintf '%0*d', $width, $n;
    };

  my $graph;
  my $check_countedged;
  if (Graph::Graph6::read_graph
      ((ref $filename_or_fh ? 'fh' : 'filename') => $filename_or_fh,
       format_func => sub {
         my ($format) = @_;
         $graph = Graph->new(undirected => ($format ne 'digraph6'));
         $check_countedged = ($format eq 'sparse6');
       },
       num_vertices_func => sub {
         my ($n) = @_;
         $width = length($n-1);
         foreach my $i (0 .. $n-1) {
           my $name = $vertex_name_func->($i);
           $graph->add_vertex($name);
         }
       },
       edge_func => sub {
         my ($from, $to) = @_;
         $from = $vertex_name_func->($from);
         $to   = $vertex_name_func->($to);
         if ($check_countedged && $graph->has_edge($from,$to)) {
           $graph = _countedged_copy($graph);
           undef $check_countedged;
         }
         $graph->add_edge($from,$to);
       })) {
    return $graph;
  } else {
    return 0;
  }
}

# $graph is a Graph.pm.
# Return a copy which is countedged.
sub _countedged_copy {
  my ($graph) = @_;
  my $new_graph = Graph->new (undirected => $graph->is_undirected,
                              countedged => 1);
  $new_graph->add_vertices($graph->vertices);
  $new_graph->add_edges($graph->edges);
  return $new_graph;
}

1;
__END__

=for stopwords Ryde filehandle EOF multi-edges

=head1 NAME

Graph::Reader::Graph6 - read Graph.pm from graph6, sparse6 or digraph6 file

=for test_synopsis my ($graph, $filehandle)

=head1 SYNOPSIS

 use Graph::Reader::Graph6;
 my $reader = Graph::Reader::Graph6->new;
 $graph = $reader->read_graph('filename.txt');
 $graph = $reader->read_graph($filehandle);

 # or use once,
 $graph = Graph::Reader::Graph6->new->read_graph('filename.txt');

=head1 CLASS HIERARCHY

C<Graph::Reader::Graph6> is a subclass of C<Graph::Reader>.

    Graph::Reader
      Graph::Reader::Graph6

=head1 DESCRIPTION

C<Graph::Reader::Graph6> reads a graph6, sparse6 or digraph6 format file and
returns a new C<Graph.pm> object.  These file formats are per

=over 4

L<http://cs.anu.edu.au/~bdm/data/formats.txt>

=back

The formats only contain vertex numbers 0 to n-1.  They are made into vertex
names as strings like "000" to "999" with however many decimal digits are
needed for the number of vertices.  This is designed to be round-trip clean
to an alphabetical re-write by C<Graph::Writer::Graph6> or
C<Graph::Writer::Sparse6>.

graph6 and sparse6 are undirected and digraph6 is directed.  The graph is
created undirected or directed accordingly.  sparse6 and digraph6 can have
self loops and they are added to the graph in its usual way.  sparse6 can
have multi-edges.  If any are found then the graph is created C<countedged>.

See L<Graph::Graph6> for further notes on the formats.

=head1 FUNCTIONS

=over

=item C<$reader = Graph::Reader::Graph6-E<gt>new()>

Create and return a new reader object.

=item C<$graph = $reader-E<gt>read_graph($filename_or_fh)>

Read a graph from C<$filename_or_fh>.  The return is a new C<Graph.pm>
object if successful, or false for empty file or at end of file.

A file can contain multiple graphs, one per line and each any of graph6,
sparse6 or digraph6.  A filehandle is left positioned at the start of the
next line, ready to read the next graph (or EOF).

Any invalid data or file read error is a C<croak()>.  Not sure if that the
intention for C<Graph::Reader> classes.  Perhaps this will change.

=back

=head1 BUGS

For sparse6 multi-edges, an application might sometimes prefer C<multiedged>
rater than C<countedged> for later manipulations.  Perhaps some C<Graph.pm>
constructor options could be taken to select that or other possibilities
(such as maybe multi-edge on graph6 or digraph6 too ready for later
manipulations).

=head1 SEE ALSO

L<Graph>, L<Graph::Reader>, L<Graph::Graph6>

L<Graph::Writer::Graph6>,
L<Graph::Writer::Sparse6>,
L<nauty-showg(1)>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/graph-graph6/index.html>

=head1 LICENSE

Copyright 2015, 2016, 2017 Kevin Ryde

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
