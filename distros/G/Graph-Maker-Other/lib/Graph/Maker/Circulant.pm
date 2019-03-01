# Copyright 2018, 2019 Kevin Ryde
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
use List::Util 'min';

use vars '$VERSION','@ISA';
$VERSION = 13;
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

  my $N = delete($params{'N'}) || 0;
  my $offset_list = delete($params{'offset_list'});
  my $graph = _make_graph(\%params);
  $graph->set_graph_attribute
    (name => "Circulant $N Offset ".join(',',@$offset_list));

  my $directed = $graph->is_directed;
  $graph->add_vertices(1 .. $N);
  my %seen;
  my $half = $N/2;
  foreach my $o (@$offset_list) {
    my $o = min($o%$N, (-$o)%$N);
    next if $seen{$o}++;
    foreach my $from (1 .. ($o==$half ? $half : $N)) {
      my $to = ($from + $o - 1) % $N + 1;  # 1 to N modulo
      $graph->add_edge($from,$to);
      if ($directed && $o) { $graph->add_edge($to,$from); }
    }
  }
  return $graph;
}

Graph::Maker->add_factory_type('circulant' => __PACKAGE__);
1;

__END__

=for stopwords Ryde circulant coprime Circulant undirected octohedral Mobius

=head1 NAME

Graph::Maker::Circulant - create circulant graph

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::Circulant;
 $graph = Graph::Maker->new ('circulant', N=>8, offset_list=>[1,4]);

=head1 DESCRIPTION

C<Graph::Maker::Circulant> creates C<Graph.pm> circulant graphs.  The graph
has vertices 1 to N.  Each vertex v has an edge to v+offset, for each offset
in the given C<offset_list>.  v+offset is taken mod N in the range 1 to N.

Offsets will usually be 1 E<lt>= offset E<lt>= N/2.  Anything bigger can be
reduced mod N, and any bigger than N/2 is equivalent to some -offset, and
that is equivalent to an edge v-offset to v.  Offset 0 means a self-loop at
each vertex.

A single C<offset_list =E<gt> [1]> gives a cycle the same as
L<Graph::Maker::Cycle>.  Bigger single offset is a cycle with vertices in a
different order, or if offset and N have a common factor then multiple
cycles.

In general, if N and all offsets have a common factor g then the effect is g
many copies of circulant N/g and offsets/g.

A full C<offset_list> 1..N/2 is the complete graph the same as
L<Graph::Maker::Complete>.

If a factor m coprime to N is put through all C<offset_list> then the
resulting graph is isomorphic.  Edges are m*v to m*v+m*offset which is the
same by identifying m*v in the multiple with v in plain.  For example
circulant N=8 offsets 1,4 is isomorphic to offsets 3,4, the latter being
multiple m=3.  If an offset list doesn't have 1 but does have some offset
coprime to N then dividing through mod N gives an isomorphic graph with 1 in
the list.

Circulant N=6 2,3 is isomorphic to the rook grid 3x2 per
L<Graph::Maker::RookGrid>.

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
between vertices.  Option C<undirected =E<gt> 1> creates an undirected graph
and for it there is a single edge between vertices.

=back

=head1 HOUSE OF GRAPHS

House of Graphs entries for graphs here, excluding cycles and completes,
include

=over

=item N=6 1,2 L<https://hog.grinvin.org/ViewGraphInfo.action?id=226>, octohedral

=item N=6 1,3 L<https://hog.grinvin.org/ViewGraphInfo.action?id=84>, complete bipartite 3,3

=item N=6 2,3 L<https://hog.grinvin.org/ViewGraphInfo.action?id=746>, circular ladder 3 rungs

=item N=7 1,2 L<https://hog.grinvin.org/ViewGraphInfo.action?id=710>

=back

Z<>

=over

=item N=8 1,2 L<https://hog.grinvin.org/ViewGraphInfo.action?id=160>

=item N=8 1,3 L<https://hog.grinvin.org/ViewGraphInfo.action?id=570>

=item N=8 1,2,3 L<https://hog.grinvin.org/ViewGraphInfo.action?id=176>, sixteen cell

=item N=8 1,4 L<https://hog.grinvin.org/ViewGraphInfo.action?id=640>, Mobius ladder 4 rungs

=item N=8 2,4 L<https://hog.grinvin.org/ViewGraphInfo.action?id=116>, two complete-4s

=back

Z<>

=over

=item N=9 1,3 L<https://hog.grinvin.org/ViewGraphInfo.action?id=328>

=item N=9 1,2,4 L<https://hog.grinvin.org/ViewGraphInfo.action?id=370>

=back

Z<>

=over

=item N=10 1,2 L<https://hog.grinvin.org/ViewGraphInfo.action?id=21063>

=item N=10 2,4 L<https://hog.grinvin.org/ViewGraphInfo.action?id=138>, two complete-5

=item N=10 1,2,4 L<https://hog.grinvin.org/ViewGraphInfo.action?id=21117>, cross-linked complete-5s

=item N=10 1,2,3,4 L<https://hog.grinvin.org/ViewGraphInfo.action?id=148>

=item N=10 1,2,5 L<https://hog.grinvin.org/ViewGraphInfo.action?id=20611>

=item N=10 1,3,5 L<https://hog.grinvin.org/ViewGraphInfo.action?id=252>

=item N=10 1,2,3,5 L<https://hog.grinvin.org/ViewGraphInfo.action?id=142>

=back

=head1 SEE ALSO

L<Graph::Maker>,
L<Graph::Maker::Cycle>,
L<Graph::Maker::Complete>,
L<Graph::Maker::RookGrid>

=head1 LICENSE

Copyright 2018, 2019 Kevin Ryde

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
