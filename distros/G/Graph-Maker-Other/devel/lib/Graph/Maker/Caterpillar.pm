# Copyright 2015, 2016, 2017, 2018, 2019 Kevin Ryde
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


# A005418 caterpillars
# A052471 non-caterpillars  first n=7 is unique


package Graph::Maker::Caterpillar;
use 5.004;
use strict;
use Graph::Maker;

use vars '$VERSION','@ISA';
$VERSION = 13;
@ISA = ('Graph::Maker');


sub _default_graph_maker {
  require Graph;
  Graph->new(@_);
}

sub init {
  my ($self, %params) = @_;

  my @N_list = grep {$_ != 0} @{delete($params{'N_list'})};
  if (@N_list <= 1) {
    require Graph::Maker::Star;
    my $N = $N_list[0] || 0;
    my $graph = Graph::Maker->new('star', N => $N, %params);

    # workaround for Graph::Maker::Star 0.01 giving empty graph for N=1
    if ($N == 1 && $graph->vertices == 0) { $graph->add_vertex(1); }

    return $graph;
  }
  my $graph_maker = delete($params{'graph_maker'}) || \&_default_graph_maker;

  my $graph = $graph_maker->(%params);
  $graph->set_graph_attribute (name => "Star Chain ".join(',',@N_list));

  my $directed = $graph->is_directed;
  $graph->add_path(1 .. scalar(@N_list));
  if ($directed) { $graph->add_path(reverse 1 .. scalar(@N_list)); }

  my $v = scalar(@N_list) + 1;
  foreach my $i (0 .. $#N_list) {
    my $from = $i + 1;
    foreach (2 .. $N_list[$i]) {
      my $to = $v++;
      $graph->add_edge($from, $to);
      if ($directed) { $graph->add_edge($to, $from); }
    }
  }
  return $graph;
}

Graph::Maker->add_factory_type('caterpillar' => __PACKAGE__);
1;

__END__

=for stopwords Ryde

=head1 NAME

Graph::Maker::Caterpillar - create caterpillar graphs

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::Caterpillar;
 $graph = Graph::Maker->new ('caterpillar', N_list => [3,1,4]);

=head1 DESCRIPTION

C<Graph::Maker::Caterpillar> creates C<Graph.pm> caterpillar graphs.
A caterpillar graph has a linear spine of vertices and from them leaf nodes
can be attached.  A caterpillar is specified here as a list of how many
vertices at each position.  For example

     *   *         *
      \ /          |         N_list => [5,1,1,3]
       @---@---@---@    
      / \          |         total vertices sum(N_list) = 10
     *   *         *

The vertices marked "@" are the spine and those marked "*" are the leaves
attached to them.  This is equivalent to a chain of star graphs connected at
their centres.  The C<N_list> count of vertices includes the centre, the
same as the N in C<Graph::Maker::Star> includes the centre.

At either end of the chain there's a choice whether to have a 1-vertex on
the spine or to take that as a leaf on the second last of the spine.  For
example the following is equivalent to the 5,1,1,3 above

       *           *
       |           |         N_list => [1,4,1,1,3]
   @---@---@---@---@
      / \          |         same as above
     *   *         *

This changes the numbering of the vertices, but the structure is the same
(isomorphic).

If C<N_list> is a single element then the graph is a single star the same as
L<Graph::Maker::Star>.  An empty C<N_list=E<gt>[]> gives an empty graph.
Likewise a single C<N_list=E<gt>[0]>, and in general any zeros in C<N_list>
are treated as nothing at all for the spine.

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('caterpillar', key =E<gt> value, ...)>

The key/value parameters are

    N_list => arrayref of integers
    graph_maker => subr(key=>value) constructor, default Graph->new

Other parameters are passed to the constructor, either C<graph_maker> or
C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are added in both
directions.  Option C<undirected =E<gt> 1> creates an undirected graph and
for it there is a single edge between vertices.

=back

=head1 SEE ALSO

L<Graph::Maker>,
L<Graph::Maker::Star>

=head1 LICENSE

Copyright 2015, 2016, 2017, 2018, 2019 Kevin Ryde

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
