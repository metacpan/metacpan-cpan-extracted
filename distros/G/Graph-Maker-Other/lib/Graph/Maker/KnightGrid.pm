# Copyright 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde
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


package Graph::Maker::KnightGrid;
use 5.004;
use strict;
use Graph::Maker;

use vars '$VERSION','@ISA';
$VERSION = 15;
@ISA = ('Graph::Maker');

# uncomment this to run the ### lines
# use Smart::Comments;


sub _default_graph_maker {
  require Graph;
  Graph->new(@_);
}

# last $dim runs fastest, per Graph::Maker::Grid
sub _coordinates_to_vertex {
  my ($c, $dims) = @_;
  my $v = $c->[0];
  die if $c->[0] >= $dims->[0];
  foreach my $i (1 .. $#$dims) {
    $v *= $dims->[$i];
    $v += $c->[$i];
    die if $c->[$i] >= $dims->[$i];
  }
  return $v+1;
}

sub init {
  my ($self, %params) = @_;

  my $dims   = delete($params{'dims'}) || [];
  my $cyclic = delete($params{'cyclic'});
  my $graph_maker = delete($params{'graph_maker'}) || \&_default_graph_maker;

  ### KnightGrid ...
  ### $dims

  my $graph = $graph_maker->(%params);

  $graph->set_graph_attribute(name =>
                              "Knight Grid "
                              . (@$dims ? join('x',@$dims) : 'empty')
                              . ($cyclic ? " cyclic" : ""));
  unless (_aref_any_nonzero($dims)) {
    ### all dims zero ...
    return $graph;
  }

  my @c = (0) x scalar(@$dims);
  for (;;) {
    my $v = _coordinates_to_vertex(\@c, $dims);
    $graph->add_vertex($v);
    ### at: join(',',@c)."=[$v]"

    foreach my $i (0 .. $#c) {
      foreach my $j (0 .. $#c) {
        next if $i == $j;
        foreach my $isign (1,-1) {
          foreach my $jsign (1,-1) {
            foreach my $offset (0, 1) {
              my @c2 = @c;
              $c2[$i] += (1+$offset)*$isign;
              $c2[$j] += (2-$offset)*$jsign;
              if ($cyclic) {
                $c2[$i] %= $dims->[$i];
                $c2[$j] %= $dims->[$j];
              } else {
                next unless ($c2[$i] >= 0 && $c2[$i] < $dims->[$i]
                             && $c2[$j] >= 0 && $c2[$j] < $dims->[$j]);
              }
              my $v2 = _coordinates_to_vertex(\@c2, $dims);
              ### edge: join(',',@c)."=[$v] to ".join(',',@c2)."=[$v2]"
              unless ($graph->has_edge($v,$v2)) {
                $graph->add_edge($v,$v2);
              }
            }
          }
        }
      }
    }

    # increment @c coordinates
    for (my $i = 0; ; $i++) {
      if ($i > $#$dims) {
        return $graph;
      }
      if (++$c[$i] < $dims->[$i]) {
        last;
      }
      $c[$i] = 0;
    }
  }
}

sub _aref_any_nonzero {
  my ($aref) = @_;
  foreach my $elem (@$aref) {
    if ($elem) {
      return 1;
    }
  }
  return 0;
}

Graph::Maker->add_factory_type('knight_grid' => __PACKAGE__);
1;

__END__

=for stopwords Ryde OEIS undirected tesseract

=head1 NAME

Graph::Maker::KnightGrid - create Knight grid graph

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::KnightGrid;
 $graph = Graph::Maker->new ('knight_grid', dims => [8,8]);

=head1 DESCRIPTION

C<Graph::Maker::KnightGrid> creates a C<Graph.pm> graph for a grid of
squares with edges connecting squares as a chess knight moves.

The C<dims> and C<cyclic> parameters are the same as C<Graph::Maker::Grid>
but the edges here are steps 2,1.

    +------+------+------+------+    dims => [3,4]
    |      |      |      |      |
    |  1   |   2  |   3  |   4  |    edges 1 to 7
    |      |      |      |      |          1 to 10
    +------+------+------+------+          2 to 9
    |      |      |      |      |          2 to 11
    |  5   |   6  |   7  |   8  |          2 to 8
    |      |      |      |      |          ...
    +------+------+------+------+          6 to 4
    |      |      |      |      |          6 to 12
    |  9   |  10  |  11  |  12  |          ...
    |      |      |      |      |          etc
    +------+------+------+------+

For 3 or more dimensions the moves are step by 2 in some coordinate and 1 in
another different coordinate.

=head2 Cyclic

C<cyclic =E<gt> 1> makes the grid wrap-around at its sides.  For 2
dimensions this is knight moves on a torus.

For 1 dimension like C<dims =E<gt> [6]> there are no edges.  A knight move
2,1 means move 2 in one dimension and 1 in another.  When there is only 1
dimension there is no second dimension for the second step.  2 dimensions
like C<dims =E<gt> [6,1]> can be given and in that case the effect with
C<cyclic> is steps +/-1 and +/-2 along the row of vertices cycling at the
ends.

For a 1x1 cyclic grid C<dims =E<gt> [1,1]>, or any higher 1x1x1 etc, there
is a self-loop edge since the knight move wraps around from the single
vertex to itself.  This is the same as the 1-vertex cyclic case in
C<Graph::Maker::Grid>.  (That class also has a self-loop for 1-dimension
C<dims =E<gt> [1]> whereas here that is no edges as described above.)

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('knight_grid', key =E<gt> value, ...)>

The key/value parameters are

    dims     => arrayref of dimensions
    cyclic   => boolean
    graph_maker => subr(key=>value) constructor, default Graph->new

C<dims> and C<cyclic> are in the style of C<Graph::Maker::Grid>.  Other
parameters are passed to the constructor, either C<graph_maker> or
C<Graph-E<gt>new()>.

Like C<Graph::Maker::Grid>, if the graph is directed (the default) then
edges are added both forward and backward between vertices.  Option
C<undirected =E<gt> 1> creates an undirected graph and for it there is a
single edge between vertices.

=back

=head1 FORMULAS

=head2 Vertex Degree

For a 2-dimensional grid each vertex is degree up to 8 if the grid is big
enough (each dimension E<gt>= 5).  In a cyclic grid all vertices are this
degree.  For higher dimensions the degree increases.  In general for D
dimensions

    max_degree = 4*D*(D-1)  = 0, 8, 24, 48, 80, ...       (A033996)

=cut

# GP-DEFINE  max_degree(D) = 4*D*(D-1);
# GP-Test  max_degree(2) == 8
# GP-Test  vector(6,D, max_degree(D)) == 8*[0,1,3,6,10,15]

=pod

=head1 HOUSE OF GRAPHS

House of Graphs entries for graphs here include

=over

L<https://hog.grinvin.org/ViewGraphInfo.action?id=52> (etc)

=back

    52      2x2               4 disconnected
    674     2x2 cyclic        4-cycle
    896     3x2
    226     3x2 cyclic
    126     3x3
    6607    3x3 cyclic        Paley 9
    684     4x2
    1022    4x2 cyclic
    21067   4x3
    32802   4x3 cyclic        circulant N=12 1,2,5
    1340    4x4 cyclic or 2x2x2x2 cyclic,   tesseract
    21063   5x2 cyclic
    32806   6x2 cyclic        circulant N=12 1,5
    68      2x2x2             8 singletons
    1022    2x2x2 cyclic      cube
    32810   3x2x2 cyclic 
    1082    4x2x2             four 4-cycles

=head1 OEIS

A few of the entries in Sloane's Online Encyclopedia of Integer Sequences
related to these graphs include

=over

L<http://oeis.org/A035008> (etc)

=back

    A033996    max vertex degree in a D dimensional grid
    A035008    number of edges in NxN grid
    A180413    number of edges in NxNxN grid
    A006075    domination number of NxN
    A006076,A103315  count of ways domination number attained

=head1 SEE ALSO

L<Graph::Maker>, L<Graph::Maker::Grid>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/graph-maker/index.html>

=head1 LICENSE

Copyright 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde

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
