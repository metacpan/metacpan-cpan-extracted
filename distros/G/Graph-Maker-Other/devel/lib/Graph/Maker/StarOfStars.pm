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

package Graph::Maker::StarOfStars;
use 5.004;
use strict;
use Graph::Maker;

use vars '$VERSION','@ISA';
$VERSION = 14;
@ISA = ('Graph::Maker');


sub _default_graph_maker {
  require Graph;
  Graph->new(@_);
}
sub _make_graph {
  my ($params) = @_;
  my $graph_maker = delete($params->{'graph_maker'}) || \&_default_graph_maker;
  return $graph_maker->(%$params);
}

sub init {
  my ($self, %params) = @_;

  my $N     = delete($params{'N'});
  my $level = delete($params{'level'});
  my $graph = _make_graph(\%params);
  $graph->set_graph_attribute (name => "StarOfStars $N level $level");
  $graph->add_vertex(1);

  if ($level > 0) {
    my $directed = $graph->is_directed;
    my $upto = 2;
    foreach (1 .. $level) {
      my @edges = $graph->edges;
      foreach my $v ($graph->vertices) {
        my $num_neighbours = $graph->neighbours($v);
        foreach ($num_neighbours+1 .. $N-1) {
          my $new = $upto++;
          $graph->add_edge ($v, $new);
          if ($directed) { $graph->add_edge ($new, $v); }
        }
      }
      foreach my $edge (@edges) {
        my ($u,$v) = @$edge;
        my $new = $upto++;
        $graph->delete_edge($u,$v);
        $graph->add_path($u,$new,$v);
        if ($directed) {
          $graph->delete_edge($v,$u);
          $graph->add_path($v,$new,$u);
        }
      }
    }
  }
  return $graph;
}

Graph::Maker->add_factory_type('star_of_stars' => __PACKAGE__);
1;

__END__

=for stopwords Ryde

=head1 NAME

Graph::Maker::StarOfStars - create star-of-star self-similar graphs

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::StarOfStars;
 $graph = Graph::Maker->new ('star_of_stars', N=>4, level=>2);

=head1 DESCRIPTION

C<Graph::Maker::StarOfStars> creates C<Graph.pm> star-of-star self-similar
graphs.  A level 0 graph is a single vertex.  Each level replaces vertices
with a star-N.  Each existing edge becomes a vertex in common between the
new stars.

                  *
                 /              N=>4, level=>2
           *----*
                 \
                  *
                 /
           *----*        *
          /      \      /
    *----*        *----*
          \             \
           *             *

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('star_of_stars', key =E<gt> value, ...)>

The key/value parameters are

    arm_list => arrayref of integers
    graph_maker => subr(key=>value) constructor, default Graph->new

Other parameters are passed to the constructor, either C<graph_maker> or
C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are added in both
directions.  Option C<undirected =E<gt> 1> creates an undirected graph and
for it there is a single edge each.

=back

=head1 SEE ALSO

L<Graph::Maker>,
L<Graph::Maker::Star>
L<Graph::Maker::Linear>

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
