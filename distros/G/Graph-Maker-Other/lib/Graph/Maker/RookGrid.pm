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


package Graph::Maker::RookGrid;
use 5.004;
use strict;
use Graph::Maker;

use vars '$VERSION','@ISA';
$VERSION = 8;
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

  ### RookGrid ...
  ### $dims

  my $graph = $graph_maker->(%params);

  $graph->set_graph_attribute(name => "Rook Grid "
                              . (@$dims ? join('x',@$dims) : 'empty'));
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
      foreach my $i_to ($c[$i]+1 .. $dims->[$i]-1) {
        my @c2 = @c;
        $c2[$i] = $i_to;
        if ($cyclic) {
          $c2[$i] %= $dims->[$i];
        }
        my $v2 = _coordinates_to_vertex(\@c2, $dims);
        ### edge: join(',',@c)."=[$v] to ".join(',',@c2)."=[$v2]"
        $graph->add_edge($v,$v2);
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

Graph::Maker->add_factory_type('rook_grid' => __PACKAGE__);
1;

__END__

=for stopwords Ryde OEIS undirected

=head1 NAME

Graph::Maker::RookGrid - create Rook grid graph

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::RookGrid;
 $graph = Graph::Maker->new ('rook_grid', dims => [8,8]);

=head1 DESCRIPTION

C<Graph::Maker::RookGrid> creates a C<Graph.pm> graph for a grid of squares
with edges connecting squares as a chess rook moves.

This means at a given vertex move anywhere in the same row or column.  For
higher dimensions it means any change in a single coordinate.

The C<dims> parameter is the same as C<Graph::Maker::Grid> but the edges
here include steps bigger than 1.

    +------+------+------+------+    dims => [3,4]
    |      |      |      |      |
    |  1   |   2  |   3  |   4  |    edges 1 to 2,3,4,5,9
    |      |      |      |      |          2 to 1,6,10,3,4
    +------+------+------+------+          ...
    |      |      |      |      |          7 to 5,6,8,3,11
    |  5   |   6  |   7  |   8  |          ...
    |      |      |      |      |          etc
    +------+------+------+------+
    |      |      |      |      |
    |  9   |  10  |  11  |  12  |
    |      |      |      |      |
    +------+------+------+------+

1xN grids are complete-N graphs the same as L<Graph::Maker::Complete>.

2x2x...x2 grids are hypercubes the same as L<Graph::Maker::Hypercube>.

There is no C<cyclic> parameter since the edges are already effectively
cyclic, having for example an edge 4 to 1, and 4 to anywhere else in the
row, etc.

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('rook_grid', key =E<gt> value, ...)>

The key/value parameters are

    dims     => arrayref of dimensions
    graph_maker => subr(key=>value) constructor, default Graph->new

C<dims> is in the style of C<Graph::Maker::Grid>.  Other parameters are
passed to the constructor, either C<graph_maker> or C<Graph-E<gt>new()>.

Like C<Graph::Maker::Grid>, if the graph is directed (the default) then
edges are added both forward and backward between vertices.  Option
C<undirected =E<gt> 1> creates an undirected graph and for it there is a
single edge between vertices.

=back

=head1 HOUSE OF GRAPHS

House of Graphs entries for graphs here include

=over

=item 1x1, L<https://hog.grinvin.org/ViewGraphInfo.action?id=1310>, single vertex

=item 1x2, L<https://hog.grinvin.org/ViewGraphInfo.action?id=19655>, path-2

=item 1x3, L<https://hog.grinvin.org/ViewGraphInfo.action?id=1374>, 3-cycle

=item 1x4, L<https://hog.grinvin.org/ViewGraphInfo.action?id=74>, complete-4

=item 1x5, L<https://hog.grinvin.org/ViewGraphInfo.action?id=462>, complete-5

=item 1x6, L<https://hog.grinvin.org/ViewGraphInfo.action?id=232>, complete-6

=item 1x7, L<https://hog.grinvin.org/ViewGraphInfo.action?id=58>, complete-7

=item 1x8, L<https://hog.grinvin.org/ViewGraphInfo.action?id=180>, complete-8

=item 2x2, L<https://hog.grinvin.org/ViewGraphInfo.action?id=674>, 4-cycle

=item 2x3, L<https://hog.grinvin.org/ViewGraphInfo.action?id=746>

=item 3x3, L<https://hog.grinvin.org/ViewGraphInfo.action?id=6607>, Paley

=item 4x4, L<https://hog.grinvin.org/ViewGraphInfo.action?id=30317>, Paley

=item 2x2x2, L<https://hog.grinvin.org/ViewGraphInfo.action?id=1022>, cube

=item 2x2x2x2, L<https://hog.grinvin.org/ViewGraphInfo.action?id=1340>, tesseract

=item 2x2x2x2x2, L<https://hog.grinvin.org/ViewGraphInfo.action?id=28533>, 5-hypercube

=back

=head1 OEIS

A few of the entries in Sloane's Online Encyclopedia of Integer Sequences
related to these graphs include

=over

L<http://oeis.org/A088699> (etc)

=back

    A088699    NxN number of independent sets
    A287274    NxM number of dominating sets
    A287065    NxN number of dominating sets
    A290632    NxM number of minimal dominating sets
    A289196    NxN number of connected dominating sets
    A286189    NxN number of connected induced subgraphs

=head1 SEE ALSO

L<Graph::Maker>,
L<Graph::Maker::Grid>,
L<Graph::Maker::Complete>,
L<Graph::Maker::Hypercube>

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
