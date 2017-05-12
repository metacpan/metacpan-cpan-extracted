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

package Graph::Reader::Graph6;
use 5.004;
use strict;
use Carp 'croak';
use Graph::Reader;

use vars '@ISA','$VERSION';
@ISA = ('Graph::Reader');
$VERSION = 6;

use Graph::Graph6;

# uncomment this to run the ### lines
# use Smart::Comments;


# override this from the superclass so can create an undirected graph
sub read_graph {
  my ($self, $filename_or_fh) = @_;
  require Graph;
  my $graph = Graph->new(undirected => 1);

  if ($self->_read_graph($graph, $filename_or_fh)) {
    return $graph;
  } else {
    return 0;
  }
}

sub _read_graph {
  my ($self, $graph, $fh) = @_;

  my $width = 1;
  my $vertex_name_func = $self->{'vertex_name_func'}
    || sub {
      my ($n) = @_;
      return sprintf '%0*d', $width, $n;
    };

  my $ret = Graph::Graph6::read_graph
    ((ref $fh ? (fh => $fh) : (filename => $fh)),
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
       $graph->add_edge($vertex_name_func->($from),
                        $vertex_name_func->($to));
     });
  return $ret;
}

1;
__END__

=for stopwords Ryde filehandle EOF multi-edges

=head1 NAME

Graph::Reader::Graph6 - read Graph.pm from graph6 or sparse6 format

=for test_synopsis my ($graph, $filehandle)

=head1 SYNOPSIS

 use Graph::Reader::Graph6;
 my $reader = Graph::Reader::Graph6->new;
 $graph = $reader->read_graph('filename.txt');
 $graph = $reader->read_graph($filehandle);

=head1 DESCRIPTION

C<Graph::Reader::Graph6> reads a graph6 or sparse6 format file and returns a
new C<Graph.pm> object.  These file formats are per

=over 4

L<http://cs.anu.edu.au/~bdm/data/formats.txt>

=back

Sparse6 can have multi-edges and self loops and they are added to the
resulting graph in its usual way.

The format only contains vertex numbers 0 to n-1.  They are made into vertex
names as strings like "000" to "999" with however many decimal digits are
needed for the number of vertices.  This is designed to be round-trip clean
to an alphabetical re-write by C<Graph::Writer::Graph6> or
C<Graph::Writer::Sparse6>.

See L<Graph::Graph6> for further notes on the formats.

=head1 FUNCTIONS

=over

=item C<$reader = Graph::Reader::Graph6-E<gt>new()>

Create and return a new reader object.

=item C<$graph = $reader-E<gt>read_graph($filename_or_fh)>

Read a graph from C<$filename_or_fh>.  The return is a new C<Graph> object
if successful, or false for empty file or at end of file.

A file can contain multiple graphs, one per line (each either graph6 or
sparse6).  A filehandle is left positioned at the start of the next line,
ready to read the next graph (or EOF).

Any invalid data or file read error is a C<croak()>.  Is that the intention
for C<Graph::Reader> classes?  Perhaps this will change.

=back

=head1 SEE ALSO

L<Graph>, L<Graph::Reader>

L<Graph::Writer::Graph6>,
L<Graph::Writer::Sparse6>,
L<nauty-showg(1)>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/graph-graph6/index.html>

=head1 LICENSE

Copyright 2015 Kevin Ryde

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
