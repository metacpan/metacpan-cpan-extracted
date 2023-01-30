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


package Graph::Maker::Twindragon;
use 5.004;
use strict;
use Graph::Maker;
use Math::PlanePath::DragonCurve 117; # v.117 for level_to_n_range()

use vars '$VERSION','@ISA';
$VERSION = 19;
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

my @_BlobN = (3, 6, 12, 9);
sub _BlobN {
  my ($k) = @_;
  return (2**($k+1) + $_BlobN[$k%4])/5;
}
sub init {
  my ($self, %params) = @_;

  my $level = delete($params{'level'}) || 0;
  my $arms = delete($params{'arms'}) || 1;
  my $graph = _make_graph(\%params);
  $graph->set_graph_attribute(name =>
                              "Twindragon Level $level"
                              . ($arms != 1 ? ", arms=$arms" : ''));
  $graph->set_graph_attribute (vertex_name_type_xy => 1);

  my $path = Math::PlanePath::DragonCurve->new;
  my ($n_lo, $n_hi) = $path->level_to_n_range($level+1);
  my ($x_hi,$y_hi) = $path->n_to_xy($n_hi);

  my ($prev_x,$prev_y) = $path->n_to_xy($n_lo);
  foreach my $n ($n_lo+1 .. $n_hi) {
    my ($x,$y) = $path->n_to_xy($n);
    $graph->add_edge("$prev_x,$prev_y", "$x,$y");
    $graph->add_edge(($x_hi-$prev_x).','.($y_hi-$prev_y),
                     ($x_hi-$x)     .','.($y_hi-$y));
    if ($arms > 1) {
      my ($x,$y) = (-$x,-$y);
      my ($prev_x,$prev_y) = (-$prev_x,-$prev_y);
      $graph->add_edge("$prev_x,$prev_y", "$x,$y");
      $graph->add_edge((-$x_hi-$prev_x).','.(-$y_hi-$prev_y),
                       (-$x_hi-$x)     .','.(-$y_hi-$y));
    }
    ($prev_x,$prev_y) = ($x,$y);
  }
  return $graph;
}

Graph::Maker->add_factory_type('twindragon' => __PACKAGE__);
1;

__END__


  # my $path = Math::PlanePath::DragonCurve->new;
  # my $num_vertices = 0;
  # my @point;
  # my ($n_lo, $n_hi) = $path->level_to_n_range($level+1);
  # my ($x_hi,$y_hi) = $path->n_to_xy($n_hi);
  # foreach my $n ($n_lo .. $n_hi) {
  #   my ($x,$y) = $path->n_to_xy($n);
  #   foreach (0,1) {
  #     {
  #       my ($x,$y) = ($x,$y);
  #       foreach my $arm (1 .. $arms) {
  #         unless ($seen{"$x,$y"}++) {
  #           $point[$num_vertices++] = [$x,$y];
  #         }
  #         ($x,$y) = (-$x,-$y);
  #       }
  #     }
  #     ($x,$y) = ($x_hi-$x, $y_hi-$y);
  #   }
  # }

  # foreach my $k (10,
  #                # 0 .. 6,
  #               ) {
  #   my %seen;
  #   my ($n_lo, $n_hi) = $path->level_to_n_range($k+1);
  #   my ($x_hi,$y_hi) = $path->n_to_xy($n_hi);
  #   foreach my $n ($n_lo .. $n_hi) {
  #     my ($x,$y) = $path->n_to_xy($n);
  #     foreach (0,1) {
  #       unless ($seen{"$x,$y"}++) {
  #         $point[$num_vertices++] = [$x,$y];
  #       }
  #       ($x,$y) = ($x_hi-$x, $y_hi-$y);
  #     }
  #     Graph::Graph6::write_graph
  #         (format => 'sparse6',
  #          fh = \*STDOUT,
  #          edge_predicate => sub {
  #            my ($from,$to) = @_;
  #            return $path->xyxy_to_n_either(@$point[$from],
  #                                           @$point[$to]);
  #          });
  #   }
  # }


=for stopwords Ryde

=head1 NAME

Graph::Maker::Twindragon - create Twindragon graph

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::Twindragon;
 $graph = Graph::Maker->new ('twindragon', level => 4);

=head1 DESCRIPTION

C<Graph::Maker::Twindragon> creates C<Graph.pm> graphs of the twindragon,
being two Heighway/Harter dragon curves back-to-back
(C<Graph::Maker::Dragon>).

                      *---*            *---*   *---*
                      |   |            |   |   |   |
       *---*          *---*---*        *---*---*---*---*
       |   |              |   |            |   |   |   |
       O---*              O---*            *---*   O---*

    level => 0        level => 1             level=2


            *---*   *---*                    *---*   *---*
            |   |   |   |                    |   |   |   |
            *---*---*---*---*                *---*---*---*---*
                |   |   |   |                    |   |   |   |
    *---*   *---*---*   O---*        *---*   *---*---*   O---*
    |   |   |   |                    |   |   |   |
    *---*---*---*---*                *---*---*---*---*
        |   |   |   |                    |   |   |   |
        *---*   *---*                    *---*---*---*---*
                                             |   |   |   |
       level => 3             level => 4     *---*---*---*---*
                                                 |   |   |   |
                                     *---*   *---*---*   *---*
                                     |   |   |   |
                                     *---*---*---*---*
                                         |   |   |   |
                                         *---*   *---*

Vertex names are integer coordinates "X,Y" which are locations in the usual
layout, starting at the origin "0,0" and spiralling anti-clockwise.  Of
course as a graph there's no need to actually use these coordinates for any
display etc.

=head2 Arms

Optional parameter C<arms =E<gt> 2> selects two curve arms.  The second
starts at the origin too and is rotated 180 degrees.  Two arms like this
eventually fill the plane, having edges horizontally or vertically between
all integer points.

    *---*   *---*                   
    |   |   |   |                   
    *---*---*---*---*                level => 3
        |   |   |   |                arms => 2
        *---*---O---*---*           
            |   |   |   |           
            *---*---*---*---*       
                |   |   |   |       
                *---*   *---*       

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('twindragon', key =E<gt> value, ...)>

The key/value parameters are

    level =>  curve expansion level >= 0
    arms  =>  1 or 2 (default 1)
    graph_maker => subr(key=>value) constructor, default Graph->new

Other parameters are passed to the constructor, either C<graph_maker> or
C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are added both ways
between vertices.  Option C<undirected =E<gt> 1> creates an undirected graph
and for it there is a single edge between vertices.

=back

=head1 SEE ALSO

L<Graph::Maker>,
L<Graph::Maker::Dragon>,
L<Graph::Maker::TwindragonAreaTree>

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
