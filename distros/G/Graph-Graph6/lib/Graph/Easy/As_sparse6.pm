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

package Graph::Easy::As_sparse6;
use 5.006;  # Graph::Easy is 5.008 anyway
use strict;
use warnings;
use Graph::Easy::As_graph6;

our $VERSION = 7;

# uncomment this to run the ### lines
# use Smart::Comments;


package Graph::Easy;
sub as_sparse6 {
  my $graph = shift;
  return $graph->as_graph6 (format => 'sparse6', @_);
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
to give a graph as a string of sparse6.  This is the same as

    $graph->as_graph6 (format => 'sparse6');

See L<Graph::Easy::As_graph6> for details.

=head1 SEE ALSO

L<Graph::Easy>,
L<Graph::Easy::As_graph6>,
L<Graph::Easy::Parser::Graph6>

L<nauty-showg(1)>, L<Graph::Graph6>

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
