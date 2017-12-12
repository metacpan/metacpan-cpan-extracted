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


package Graph::Maker::Crown;
use 5.004;
use strict;
use Graph::Maker;

use vars '$VERSION','@ISA';
$VERSION = 10;
@ISA = ('Graph::Maker');


sub _default_graph_maker {
  require Graph;
  Graph->new(@_);
}

sub init {
  my ($self, %params) = @_;

  my $N = delete $params{'N'};
  my $graph_maker = delete($params{'graph_maker'}) || \&_default_graph_maker;

  my $graph = $graph_maker->(%params);
  $graph->set_graph_attribute (name => "Crown $N");

  my $directed = $graph->is_directed;
  foreach my $u (1 .. $N) {
    $graph->add_vertex ($u);
    $graph->add_vertex ($u+$N);
    foreach my $v (1 .. $N) {
      if ($u != $v) {
        $graph->add_edge($u, $v+$N);
        if ($directed) {
          $graph->add_edge($v+$N, $u);
        }
      }
    }
  }
  return $graph;
}

Graph::Maker->add_factory_type('crown' => __PACKAGE__);
1;

__END__

=for stopwords Ryde

=head1 NAME

Graph::Maker::Crown - create crown graphs

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::Crown;
 $graph = Graph::Maker->new ('crown', N => 5);

=head1 DESCRIPTION

C<Graph::Maker::Crown> creates C<Graph.pm> crown graphs.  A crown graph is a
complete bipartite but without edges "horizontally" across.

Vertices are numbered 1 to 2*N inclusive.  Edges are i to N+j for pairs
1<=i,j<=N and i!=j.

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('crown', key =E<gt> value, ...)>

The key/value parameters are

    N => integer
    graph_maker => subr(key=>value) constructor, default Graph->new

Other parameters are passed to the constructor, either C<graph_maker> or
C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are added in both
directions.  Option C<undirected =E<gt> 1> creates an undirected graph and
for it there is a single edge between vertices.

=back

=head1 HOUSE OF GRAPHS

House of Graphs entries for the graphs here include

=over

=item N=0, L<https://hog.grinvin.org/ViewGraphInfo.action?id=6901>  (empty)

=item N=1, L<https://hog.grinvin.org/ViewGraphInfo.action?id=19653>  (2 isolated)

=item N=2, L<https://hog.grinvin.org/ViewGraphInfo.action?id=538>  (two path-2)

=item N=3, L<https://hog.grinvin.org/ViewGraphInfo.action?id=670>  (6-cycle)

=item N=4, L<https://hog.grinvin.org/ViewGraphInfo.action?id=1022>  (cube)

=back

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to
this tree include

=over

L<http://oeis.org/A287063> (etc)

=back

    A287063    number of dominating sets
    A289121    number of minimal dominating sets

=head1 SEE ALSO

L<Graph::Maker>,
L<Graph::Maker::Graph::Maker::CompleteBipartite>

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
