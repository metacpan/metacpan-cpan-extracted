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


package Graph::Maker::BiStar;
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
  my $N = delete($params{'N'}) || 0;
  my $M = delete($params{'M'}) || 0;

  my $graph = _make_graph(\%params);
  $graph->set_graph_attribute (name => "Bi-Star $N,$M");
  my $directed = $graph->is_directed;
  my $from = 1;
  foreach my $size ($N, $M) {
    next unless $size;
    $graph->add_vertex($from);
    foreach my $add (1 .. $size-1) {
      $graph->add_edges($from, $from+$add,
                        ($directed ? ($from+$add, $from) : ()));
    }
    $from += $size;
  }
  if ($N && $M) {
    $graph->add_edge (1, 1+$N);
  }
  return $graph;
}

Graph::Maker->add_factory_type('bi_star' => __PACKAGE__);
1;

__END__

=for stopwords Ryde

=head1 NAME

Graph::Maker::BiStar - create bi-star graphs

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::BiStar;
 $graph = Graph::Maker->new ('bi_star', N=>5, M=>4);

=head1 DESCRIPTION

C<Graph::Maker::BiStar> creates C<Graph.pm> bi-star graphs.  A bi-star graph
is two stars with an edge connecting their centres.  Parameters N and M are
how many vertices in each star, for total N+M vertices.


     3   2       9
      \ /         \          N=>5  M=>4
       1-----------6---8
      / \         /          total vertices N+M = 9
     4   5       7

Vertices of the first star are numbered per C<Graph::Maker::Star>, then the
second star.

    vertices
      1                      first star centre
      2 to N inclusive       first star surrounding
      N+1                    second star centre
      N+2 to N+M inclusive   second star surrounding

If N=0 then that star is no vertices and there is no middle edge, leaving
just star M.  Likewise conversely if M=0.  If both N=0 and M=0 then the
graph is empty.

If N=1 or M=1 then that star is a single vertex only and so is like an extra
arm on the other, giving a single star N+M.

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('bi_star', key =E<gt> value, ...)>

The key/value parameters are

    N  => integer, number of vertices in first star
    M  => integer, number of vertices in second star
    graph_maker => subr(key=>value) constructor, default Graph->new

Other parameters are passed to the constructor, either C<graph_maker> or
C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are added in both
directions (like C<Graph::Maker::Star> does).  Option C<undirected =E<gt> 1>
creates an undirected graph and for it there is a single edge between
vertices.

=back

=head1 FORMULAS

The graph diameter is 3 when both N,M>=2.  The smaller cases can be written

    diameter(N,M) = (N>=2) + (M>=2) + (N>=3 || M>=3 || (N>=1&&M>=1))

The Wiener index (total distance between vertex pairs) follows from counts
and measures between the leaf and centre vertices.  Cases M=0 or N=0 reduce
to a single star which are exceptions.

    Wiener(N,M) = N^2 + 3*N*M + M^2 - 3*N - 3*M + 2
                  if M=0 then + N-1
                  if N=0 then + M-1

                = (N+M)*(N+M-3) + N*M + 2
                  if M=0 then + N-1
                  if N=0 then + M-1

With N+M vertices, the number of pairs of distinct vertices is

    Pairs(N,M) = (N+M)*(N+M-1)/2

Mean distance between vertices is then Wiener/Pairs.  A bi-star with some
particular desired mean distance can be found by solving for N,M in

    Wiener(N,M) = Pairs(N,M) * mean

which becomes a binary quadratic form.

=head1 HOUSE OF GRAPHS

House of Graphs entries for the graphs here include

=over

=item 2,2, L<https://hog.grinvin.org/ViewGraphInfo.action?id=594>  (path-4)

=item 3,2, L<https://hog.grinvin.org/ViewGraphInfo.action?id=30>  (fork)

=item 3,3, L<https://hog.grinvin.org/ViewGraphInfo.action?id=334>  (H graph)

=item 4,2, L<https://hog.grinvin.org/ViewGraphInfo.action?id=208>  (cross)

=item 4,3, L<https://hog.grinvin.org/ViewGraphInfo.action?id=452>

=item 4,4, L<https://hog.grinvin.org/ViewGraphInfo.action?id=586>  (Ethane)

=item 5,2, L<https://hog.grinvin.org/ViewGraphInfo.action?id=266>

=item 5,4, L<https://hog.grinvin.org/ViewGraphInfo.action?id=634>

=item 5,5, L<https://hog.grinvin.org/ViewGraphInfo.action?id=112>

=item 6,2, L<https://hog.grinvin.org/ViewGraphInfo.action?id=332>

=item 6,5, L<https://hog.grinvin.org/ViewGraphInfo.action?id=650>

=item 6,6, L<https://hog.grinvin.org/ViewGraphInfo.action?id=36>

=item 7,2, L<https://hog.grinvin.org/ViewGraphInfo.action?id=366>

=item 7,6, L<https://hog.grinvin.org/ViewGraphInfo.action?id=38>

=item 7,7, L<https://hog.grinvin.org/ViewGraphInfo.action?id=166>

=item 8,2, L<https://hog.grinvin.org/ViewGraphInfo.action?id=436>

=item 8,7, L<https://hog.grinvin.org/ViewGraphInfo.action?id=168>

=item 9,2, L<https://hog.grinvin.org/ViewGraphInfo.action?id=316>

=item 10,2, L<https://hog.grinvin.org/ViewGraphInfo.action?id=320>

=item 10,6, L<https://hog.grinvin.org/ViewGraphInfo.action?id=27414>

=back

=head1 SEE ALSO

L<Graph::Maker>,
L<Graph::Maker::Star>

=head1 LICENSE

Copyright 2017 Kevin Ryde

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
