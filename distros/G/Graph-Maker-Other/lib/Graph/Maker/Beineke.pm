# Copyright 2015, 2016, 2017, 2018, 2019, 2020, 2021 Kevin Ryde
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

package Graph::Maker::Beineke;
use 5.004;
use strict;
use Carp 'croak';
use Graph::Maker;
use Graph::Maker::Star;
use Graph::Maker::Wheel;

use vars '$VERSION','@ISA';
$VERSION = 19;
@ISA = ('Graph::Maker');


# uncomment this to run the ### lines
# use Smart::Comments;

my @G_data
  = (undef, # 0
     undef, # 1
     [
      # G2    2-----+
      #      / \    |
      #     3---1   5
      #      \ /    |
      #       4-----+
      # https://hog.grinvin.org/ViewGraphInfo.action?id=438
      [1,2],[1,3],[1,4],
      [2,3],[2,5],
      [3,4],
      [4,5],
     ],
     [
      # G3 = K5-e complete 5 less one edge
      #      1
      #     /|\        +----2-----+
      #    / 2 \       |   / \    |
      #   / /|\ \      |  3---1---5
      #  / / 3 \ \     |   \ /    |
      #  |/ / \ \ |    +----4-----+
      #  4--------5
      # https://hog.grinvin.org/ViewGraphInfo.action?id=450
      #
      [1,2],[1,3],[1,4],[1,5],
      [2,3],[2,4],[2,5],
      [3,4], # missing 3,5
      [4,5],
     ],
     [
      # G4      2----6
      #        / \
      #       3---1
      #        \ /
      #         4----5
      # https://hog.grinvin.org/ViewGraphInfo.action?id=922
      #
      [1,2],[1,3],[1,4],
      [2,3],[2,6],
      [3,4],
      [4,5],
     ],
     [
      # G5  +----2----+           2
      #     |   / \   |          /|\
      #     |  3---1  5--6      / 1 \
      #     |   \ /   |        / / \ \
      #     +----4----+        4-----3
      #                        \     /
      #                         \   /
      #                           5----6
      #
      # https://hog.grinvin.org/ViewGraphInfo.action?id=21099
      #
      [1,2],[1,3],[1,4],
      [2,3],[2,4],[2,5],
      [3,4],
      [4,5],
      [5,6],
     ],
     [
      # G6  +----2--\--\              1
      #     |   / \  \  \            /|\
      #     |  3---1  5--6          / 3 \
      #     |   \ /  /  /          / / \ \
      #     +----4--/--/           4-----2
      #                            \ \ / /
      #                             \ 5 /
      #                              \|/
      #                               6
      # https://hog.grinvin.org/ViewGraphInfo.action?id=744
      #
      [1,2],[1,3],[1,4],
      [2,3],[2,5],[2,4],[2,6],
      [3,4],
      [4,5],[4,6],
      [5,6],
     ],
     [
      # G7      2-----6
      #        / \    |
      #       3---1   |
      #        \ /    |
      #         4-----5
      # https://hog.grinvin.org/ViewGraphInfo.action?id=21093
      #
      [1,2],[1,3],[1,4],
      [2,3],[2,6],
      [3,4],
      [4,5],
      [5,6],
     ],
     [
      # G8     2              3---2
      #       / \             | / |
      #      3--1---5         1---4
      #       \ | / |         | / |
      #         4---6         5---6
      # https://hog.grinvin.org/ViewGraphInfo.action?id=21096
      #
      [1,2],[1,3],[1,4],[1,5],
      [2,3],
      [3,4],
      [4,5],[4,6],
      [5,6],
     ],

     # G9 wheel     2----6
     #             / \ / |
     #            3---1  |
     #             \ / \ |
     #              4----5
     # https://hog.grinvin.org/ViewGraphInfo.action?id=204
    );

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

  my $G = delete($params{'G'}) || 0;
  ### $G

  my $graph;
  if ($G == 1) {
    # G1 = claw = star-4
    # https://hog.grinvin.org/ViewGraphInfo.action?id=204
    #
    $graph = Graph::Maker->new('star', N=>4, %params);

  } elsif ($G == 9) {
    # G9 = wheel 6
    #        2        6 vertices
    #      / | \     10 edges
    #    4---1---3
    #     \ / \  /
    #      5---6
    # https://hog.grinvin.org/ViewGraphInfo.action?id=204
    #
    $graph = Graph::Maker->new('wheel', N=>6, %params);

  } else {
    my $edge_aref = $G_data[$G]
      || croak "Unrecognised G: ", $G;

    $graph = _make_graph(\%params);
    $graph->add_edges(@$edge_aref);
    if ($graph->is_directed) {
      $graph->add_edges(map {[reverse @$_]} @$edge_aref->edges);
    }
  }

  # override possible name from star or wheel
  $graph->set_graph_attribute (name => "Beineke G$G");

  return $graph;
}

Graph::Maker->add_factory_type('Beineke' => __PACKAGE__);
1;

__END__

=for stopwords Ryde Beineke Combinatorial undirected Characterizations characterized Subgraph

=head1 NAME

Graph::Maker::Beineke - create Beineke non-line graphs

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::Beineke;
 $graph = Graph::Maker->new ('Beineke', G => 9);

=head1 DESCRIPTION

C<Graph::Maker::Beineke> creates C<Graph.pm> graphs of the 9 graphs given by
Beineke

=over

Lowell W. Beineke, "Characterizations of Derived Graphs", Journal of
Combinatorial Theory, volume 9, 1970, pages 129-135.
L<http://www.sciencedirect.com/science/article/pii/S0021980070800199>

=cut

# Elsevier journal page directs to sciencedirect to view article.

=pod

=back

Beineke shows that line graphs can be characterized as all graphs which do
not contain as induced sub-graphs any of these 9 graphs.


    G1   2            G2       2----+       G3  +----2-----+
          \                   / \   |           |   / \    |
        3--1                 3---1  5           |  3---1---5
          /                   \ /   |           |   \ /    |
         4                     4----+           +----4-----+
                                    
       G1 = claw                            G3 = K5-e
          = star-4                      complete 5 less one edge 


    G4   2----6       G5  +----2----+       G6  +----2----+--+
        / \               |   / \   |           |   / \   |  |
       3---1              |  3---1  5--6        |  3---1  5--6
        \ /               |   \ /   |           |   \ /   |  |
         4----5           +----4----+           +----4----+--+

    G7   2----6       G8     2              G9       2----6
        / \   |             / \                     / \ / |
       3---1  |            3---1--5--6             3---1  |
        \ /   |             \ /   |  |              \ / \ |
         4----5              4----+--+               4----5

                                            G9 =  wheel-6

G1 is the claw (star-4) and is created using L<Graph::Maker::Star>.  G9 is
the wheel-6 and is created using L<Graph::Maker::Wheel>.  The drawing for G8
means edges 4-to-5 and 4-to-6.  Similarly in G6 2-to-5 and 2-to-6.  Beineke
draws G8 as squares

    G8  2---3
        | / |
        1---4
        | / |
        5---6

The vertex numbering is slightly arbitrary but attempts some similarity
between the graphs, including having the outer vertices numbered around in
the style of the wheel-6 which is G9

These graphs are just a fixed set of 9 but are a convenient way to have some
or all.

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('Beineke', key =E<gt> value, ...)>

The key/value parameters are

    G           => integer 1 to 9
    graph_maker => subr(key=>value) constructor, default Graph->new

Other parameters are passed to the constructor, either C<graph_maker> or
C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are added both forward and
backward between vertices.  Option C<undirected =E<gt> 1> creates an
undirected graph and for it there is a single edge between vertices.

=back

=head1 HOUSE OF GRAPHS

House of Graphs entries for the graphs here are

=over

=item G1, L<https://hog.grinvin.org/ViewGraphInfo.action?id=500>

=item G2, L<https://hog.grinvin.org/ViewGraphInfo.action?id=438>

=item G3, L<https://hog.grinvin.org/ViewGraphInfo.action?id=450>

=item G4, L<https://hog.grinvin.org/ViewGraphInfo.action?id=922>

=item G5, L<https://hog.grinvin.org/ViewGraphInfo.action?id=21099>

=item G6, L<https://hog.grinvin.org/ViewGraphInfo.action?id=744>

=item G7, L<https://hog.grinvin.org/ViewGraphInfo.action?id=21093>

=item G8, L<https://hog.grinvin.org/ViewGraphInfo.action?id=21096>

=item G9, L<https://hog.grinvin.org/ViewGraphInfo.action?id=204>

=back

And also

=over

=item 12-vertex union L<https://hog.grinvin.org/ViewGraphInfo.action?id=748>

=item Subgraph relations L<https://hog.grinvin.org/ViewGraphInfo.action?id=25225>

=back

=head1 SEE ALSO

L<Graph::Maker>,
L<Graph::Maker::Star>,
L<Graph::Maker::Wheel>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/graph-maker-other/index.html>

=head1 LICENSE

Copyright 2015, 2016, 2017, 2018, 2019, 2020, 2021 Kevin Ryde

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
