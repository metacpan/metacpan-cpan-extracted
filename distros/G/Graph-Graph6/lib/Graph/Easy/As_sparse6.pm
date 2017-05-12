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

package Graph::Easy::As_sparse6;
use 5.006;  # Graph::Easy is 5.008 anyway
use strict;
use warnings;
use Graph::Graph6;

our $VERSION = 6;

# uncomment this to run the ### lines
# use Smart::Comments;


package Graph::Easy;
sub as_sparse6 {
  my ($graph, %options) = @_;

  my $num_vertices = scalar($graph->nodes);
  ### $num_vertices

  my @edges = $graph->edges; # Graph::Easy::Edge objects
  {
    my @vertices = $graph->sorted_nodes('name');
    my %name_to_num = map { $vertices[$_]->name => $_ } 0 .. $#vertices;
    @edges = map { [map{$name_to_num{$_->name}} $_->nodes] } @edges;
  }
  ### @edges

  Graph::Graph6::write_graph(format       => 'sparse6',
                             header       => $options{'header'},
                             str_ref      => \my $str,
                             num_vertices => $num_vertices,
                             edge_aref    => \@edges);
  ### $str
  return $str;
}

1;
__END__

=for stopwords Ryde ascii undirected multi-edges stringize

=head1 NAME

Graph::Easy::As_sparse6 - stringize Graph::Easy to sparse6 format

=head1 SYNOPSIS

 use Graph::Easy;
 my $graph = Graph::Easy->new;
 $graph->add_edge('foo','bar');

 use Graph::Easy::As_sparse6;
 print $graph->as_sparse6;

=head1 DESCRIPTION

C<Graph::Easy::As_sparse6> adds an C<as_sparse6()> method to C<Graph::Easy>
to give a graph as a string of sparse6.  This format is per

=over 4

L<http://cs.anu.edu.au/~bdm/data/formats.txt>

=back

The format represents an undirected graph possibly with multi-edges and self
loops.  If C<$graph> is directed then an edge in either direction is
written.  If there's edges both ways then a multi-edge is written.

The format has no vertex names and no attributes.  In the current
implementation nodes are sorted alphabetically
(C<$graph-E<gt>sorted_nodes('name')>) to give a consistent (though slightly
arbitrary) vertex numbering.

See L<Graph::Graph6> for some notes on the format.

=head1 FUNCTIONS

The following new method is added to C<Graph::Easy>.

=over

=item C<$str = $graph-E<gt>as_sparse6 ()>

Return a string which is the sparse6 representation of C<$graph>.

The string returned is printable ASCII.  It includes a final newline C<"\n">
so is suitable for writing directly to a file or similar.  The only
key/value option is

    header   => boolean (default false)

If C<header> is true then include a header C<E<gt>E<gt>sparse6E<lt>E<lt>>.

=back

=head1 SEE ALSO

L<Graph::Easy>,
L<Graph::Easy::As_graph6>,
L<Graph::Easy::Parser::Graph6>

L<nauty-showg(1)>, L<Graph::Graph6>

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
