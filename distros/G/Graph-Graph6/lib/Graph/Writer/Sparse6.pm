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

package Graph::Writer::Sparse6;
use 5.006;
use strict;
use warnings;
use Graph::Writer::Graph6;

use vars '@ISA','$VERSION';
@ISA = ('Graph::Writer::Graph6');
$VERSION = 8;

# uncomment this to run the ### lines
# use Smart::Comments;


sub _init  {
  my ($self,%param) = @_;
  ### Graph-Writer-Sparse6 _init() ...
  ### %param

  $self->SUPER::_init(format => 'sparse6', %param);

  ### self: %$self
}

1;
__END__

=for stopwords Ryde ascii Superclass

=head1 NAME

Graph::Writer::Sparse6 - write Graph.pm in sparse6 format

=for test_synopsis my ($graph, $filehandle)

=head1 SYNOPSIS

 use Graph::Writer::Sparse6;
 my $writer = Graph::Writer::Sparse6->new;
 $writer->write_graph($graph, 'filename.txt');
 $writer->write_graph($graph, $filehandle);

 Graph::Writer::Sparse6->new->write_graph($graph,'filename.txt');

=head1 CLASS HIERARCHY

C<Graph::Writer::Sparse6> is a subclass of C<Graph::Writer>.

    Graph::Writer
      Graph::Writer::Graph6
        Graph::Writer::Sparse6

Superclass C<Graph::Writer::Graph6> is reckoned an implementation detail and
should not be relied on, only C<Graph::Writer>.

=head1 DESCRIPTION

C<Graph::Writer::Sparse6> writes a C<Graph.pm> graph to a file or file
handle in sparse6 format.  It is the same as

    my $writer = Graph::Writer::Graph6->new (format => 'sparse6');

See L<Graph::Writer::Graph6> for details.

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
