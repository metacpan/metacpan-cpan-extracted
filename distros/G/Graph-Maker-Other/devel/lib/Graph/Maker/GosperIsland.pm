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

package Graph::Maker::GosperIsland;
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

sub _mul {
  my ($x,$y) = @_;
  return ((5*$x - 3*$y)/2, ($x+5*$y)/2);
}
sub _add {
  my ($v, $ax,$ay) = @_;
  my ($x,$y) = split /,/, $v;
  $x += $ax;
  $y += $ay;
  return "$x,$y";
}
sub _rotate_plus60 {
  my ($x, $y) = @_;
  return (($x-3*$y)/2,  # rotate +60
          ($x+$y)/2);
}

my @level_0 = ('2,0', '1,1', '-1,1', '-2,0', '-1,-1', '1,-1');

sub init {
  my ($self, %params) = @_;

  my $level = delete($params{'level'}) || 0;

  my $graph = _make_graph(\%params);
  $graph->set_graph_attribute (name => "Gosper Island $level");
  $graph->set_graph_attribute (vertex_name_type_xy => 1);
  $graph->set_graph_attribute (vertex_name_type_xy_triangular => 1);
  my $multiedged = $graph->is_countedged || $graph->is_multiedged;

  $graph->add_cycle(@level_0);
  if ($graph->is_directed) { $graph->add_cycle(reverse @level_0); }

  my $cx = 3;
  my $cy = 1;
  foreach my $i (1 .. $level) {
    foreach my $edge ($graph->edges) {
      foreach (1 .. 6) {
        my ($u,$v) = @$edge;
        $u = _add($u, $cx,$cy);
        $v = _add($v, $cx,$cy);
        if (! $multiedged || ! $graph->has_edge($u,$v)) { # no duplicates
          $graph->add_edge($u,$v);
        }
        ($cx,$cy) = _rotate_plus60($cx,$cy);
      }
    }
    ($cx,$cy) = _mul($cx,$cy);
  }
  return $graph;
}

Graph::Maker->add_factory_type('Gosper_island' => __PACKAGE__);
1;

__END__

=for stopwords Ryde

=head1 NAME

Graph::Maker::GosperIsland - create GosperIsland and generalized GosperIsland graphs

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::GosperIsland;
 $graph = Graph::Maker->new ('Gosper_island');

=head1 DESCRIPTION

C<Graph::Maker::GosperIsland> creates a C<Graph.pm> graph of the Gosper
island hexagonal grid,

                                    *---*
        *---*                      /     \
       /     \                *---*       *---*      level => 1
      *       *              /     \     /     \
       \     /              *       *---*       *
        *---*                \     /     \     /
                              *---*       *---*
      level => 0             /     \     /     \
                            *       *---*       *
                             \     /     \     /
                              *---*       *---*
                                   \     /
                                    *---*

Parameter C<level =E<gt> $k> is the grid expansion level.  Each level is a 7
copies of the previous, arranged in the surround pattern of level 1.  The
effect is slowly spiralling curling boundaries (the shape of the terdragon
curve unfolded to 120 degrees).

                    * *
           * *   * *   * *
        * *   * *   * *   *          level => 2
       *   * *   * *   * *
        * *   * *   * *   * *
       *   * *   * *   * *   * *
        * *   * *   * *   * *   *
     * *   * *   * *   * *   * *
    *   * *   * *   * *   * *   *
     * *   * *   * *   * *   * *
    *   * *   * *   * *   * *
     * *   * *   * *   * *   *
        * *   * *   * *   * *
           * *   * *   * *   *
          *   * *   * *   * *
           * *   * *   * *
              * *

The graph size grows rapidly with the level,

    num hexagons = 7^k
    num vertices = 2*7^k + 3^(k+1) + 1
                 = 6, 24, 126, 768, 5046
    num edges    = 3*7^k + 3^(k+1)
                 = 6, 30, 174, 1110, 7446

Vertex names are currently x,y coordinates used in the construction, but
don't rely on that.

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('Gosper_island', key =E<gt> value, ...)>

The key/value parameters are

    level       => integer>=0, island expansion
    graph_maker => subr(key=>value) constructor, default Graph->new

Other parameters are passed to the constructor, either C<graph_maker> or
C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are added both ways
between vertices (like L<Graph::Maker::Grid> does).  Option C<undirected
=E<gt> 1> creates an undirected graph and for it there is a single edge
between vertices.

=back

=head1 HOUSE OF GRAPHS

House of Graphs entries for graphs here include

=over

=item level=0  (6-cycle)

=back

=head1 SEE ALSO

L<Graph::Maker>,
L<Graph::Maker::Cycle>,
L<Graph::Maker::Grid>

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
