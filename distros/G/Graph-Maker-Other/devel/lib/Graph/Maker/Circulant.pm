# Copyright 2017 Kevin Ryde
#
# This file is part of Graph-Maker-Other.
#
# This file is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# This file is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Graph-Maker-Other.  See the file COPYING.  If not, see
# <http://www.gnu.org/licenses/>.

package Graph::Maker::Circulant;
use 5.004;
use strict;
use Graph::Maker;

use vars '$VERSION','@ISA';
$VERSION = 7;
@ISA = ('Graph::Maker');


sub _default_graph_maker {
  require Graph;
  return Graph->new(@_);
}
sub _make_graph {
  my ($params) = @_;
  my $graph_maker = delete($params->{'graph_maker'}) || \&_default_graph_maker;
  return $graph_maker->(%$params);
}

sub init {
  my ($self, %params) = @_;

  my $N = delete($params{'N'}) || 3;
  my $offset      = delete($params{'offset'});
  my $offset_list = delete($params{'offset_list'});
  my @offset_list = ((defined $offset      ? $offset       : ()),
                     (defined $offset_list ? @$offset_list : ()));

  my $graph = _make_graph(\%params);
  $graph->set_graph_attribute (name => "Circulant $N Offset ".join(',',@offset_list));

  my $directed = $graph->is_directed;
  $graph->add_vertices(1 .. $N);
  foreach my $from (1 .. $N) {
    foreach my $o (@offset_list) {
      my $to = ($from + $o - 1) % $N + 1;
      $graph->add_edge($from,$to);
      if ($directed && ) { $graph->add_edge($to,$from); }
    }
  }
  return $graph;
}

Graph::Maker->add_factory_type('circulant' => __PACKAGE__);
1;

__END__

=for stopwords Ryde

=head1 NAME

Graph::Maker::Circulant - create circulant graph

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::Circulant;
 $graph = Graph::Maker->new ('circulant');

=head1 DESCRIPTION

C<Graph::Maker::Circulant> creates C<Graph.pm> circulant graphs

                      1
                     / \     
               2----/---\----10
                -_ /     \ _-  
                  -_     - \/
                 / _-_ \  
                /_-  __ -__\
               3-       9

The graph has vertices 1 to C<N>.  Each vertex v an edge to v+offset, for
each offset in the given C<offset_list>.

And C<offset_list> of 2 or more values is usual, since just 1 value simply
gives some cycles.

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('circulant', key =E<gt> value, ...)>

The key/value parameters are

    N           => integer, number of vertices
    offset_list => arrayref of integers
    graph_maker => subr(key=>value) constructor, default Graph->new

Other parameters are passed to the constructor, either C<graph_maker> or
C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are added both ways
between relevant vertices.  Option C<undirected =E<gt> 1> creates an
undirected graph and for it there is a single edge between vertices.

=back

=head1 SEE ALSO

L<Graph::Maker>

=head1 LICENSE

Copyright 2015, 2016, 2017 Kevin Ryde

This file is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

This file is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
This file.  If not, see L<http://www.gnu.org/licenses/>.

=cut
