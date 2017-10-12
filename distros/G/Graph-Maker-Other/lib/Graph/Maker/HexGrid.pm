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


#
# For interest, 3x3x3 appears in Emden R. Gansner, Yifan Hu, Stephen
# G. Kobourov, "On Touching Triangle Graphs", with a drawing by triangles
# (each vertex is a triangle with sides touching its neighbours).


package Graph::Maker::HexGrid;
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
  return Graph->new(@_);
}
sub _make_graph {
  my ($params) = @_;
  my $graph_maker = delete($params->{'graph_maker'}) || \&_default_graph_maker;
  return $graph_maker->(%$params);
}

sub _rotate_plus60 {
  my ($x, $y) = @_;
  return (($x-3*$y)/2,  # rotate +60
          ($x+$y)/2);
}
sub _rotate_plus120 {
  my ($x, $y) = @_;
  return (($x+3*$y)/-2,  # rotate +120
          ($x-$y)/2);
}

my @hexagon = ([0,0], [2,0], [3,1], [2,2], [0,2], [-1,1]);

sub init {
  my ($self, %params) = @_;

  my $dims = delete($params{'dims'}) || 0;
  my @dims = ($dims->[0] || 1,
              $dims->[1] || 1,
              $dims->[2] || 1);

  my $graph = _make_graph(\%params);
  $graph->set_graph_attribute (name => "Hex Grid ".join(',',@dims));
  $graph->set_graph_attribute (vertex_name_type_xy => 1);
  $graph->set_graph_attribute (vertex_name_type_xy_triangular => 1);
  my $multiedged = $graph->is_countedged || $graph->is_multiedged;

  my $seg_dx = 2;
  my $seg_dy = 0;
  my $step_dx =  3;
  my $step_dy = -1;
  my $top_dx =  0;
  my $top_dy =  2;
  my $x = 0;
  my $y = 0;
  foreach (1 .. 3) {
    ### @dims
    my $limit = $dims[2];
    my $top_side = $dims[1];
    foreach my $i (1 .. $dims[0] + $dims[1] - 1) {
      ### $i
      ### $limit
      foreach my $j (0 .. $limit) {
        my $x = $x + $j*$top_dx;
        my $y = $y + $j*$top_dy;
        my $from = "$x,$y";
        my $to = ($x+$seg_dx).','.($y+$seg_dy);
        ### edge: "$from to $to"
        $graph->add_edge($from, $to);
      }
      if ($i == $dims[0]) {
        ($step_dx,$step_dy) = _rotate_plus60($step_dx,$step_dy);
      }
      $x += $step_dx;
      $y += $step_dy;
      $limit += ($i < $dims[1]);
      $limit -= ($i >= $dims[0]);
    }

    unshift @dims, pop @dims;
    ($step_dx,$step_dy) = _rotate_plus60($step_dx,$step_dy);
    ($top_dx,$top_dy) = _rotate_plus120($top_dx,$top_dy);
    ($seg_dx,$seg_dy) = _rotate_plus120($seg_dx,$seg_dy);
    # $top_dx = -$top_dx;
    # $top_dy = -$top_dy;
    # $x += $step_dx;
    # $y += $step_dy;
    # $x += $seg_dx;
    # $y += $seg_dy;
  }

  if ($graph->is_directed) {
    $graph->add_edges(map {[reverse @$_]} $graph->edges);
  }
  return $graph;
}

Graph::Maker->add_factory_type('hex_grid' => __PACKAGE__);
1;

__END__

=for stopwords Ryde

=head1 NAME

Graph::Maker::HexGrid - create hexagonal grid graphs

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::HexGrid;
 $graph = Graph::Maker->new ('hex_grid');

=head1 DESCRIPTION

C<Graph::Maker::HexGrid> creates a C<Graph.pm> graph of hexagons arranged in
a hexagonal shape,

                  *---*
                 /     \
            *---*       *---*
           /     \     /     \               dims => [4,3,2]
      *---*       *---*       *---*
     /     \     /     \     /     \
    *       *---*       *---*       *---*
     \     /     \     /     \     /     \
      *---*       *---*       *---*       *
     /     \     /     \     /     \     /
    *       *---*       *---*       *---*
     \     /     \     /     \     /     \
      *---*       *---*       *---*       *
           \     /     \     /     \     /
            *---*       *---*       *---*
                 \     /     \     /
                  *---*       *---*
                       \     /
                        *---*

C<dims> is the side lengths of the hexagonal shape.  The example above is 4
hexagons along the bottom left side, then 3 for the bottom right, and 2
vertically.  The opposite sides the same 4,3,2.

If a side is 1 then the result is a parallelogram of hexagons.

                  *---*                       
                 /     \                      
            *---*       *---*                 
           /     \     /     \              dims => [4,3,1]
      *---*       *---*       *---*           
     /     \     /     \     /     \          
    *       *---*       *---*       *---*     
     \     /     \     /     \     /     \    
      *---*       *---*       *---*       *   
           \     /     \     /     \     /    
            *---*       *---*       *---*     
                 \     /     \     /          
                  *---*       *---*           
                       \     /                
                        *---*                 

If two sides are 1 then the result is line of hexagons, like a ladder
(L<Graph::Maker::Ladder>) with every second rung.

      *---*                 
     /     \                            dims => [3,1,1]       
    *       *---*           
     \     /     \          
      *---*       *---*     
           \     /     \    
            *---*       *   
                 \     /    
                  *---*     

The order in which C<dims> are given doesn't matter.  Any cyclic rotation is
just the graph rotated, and reversing is a mirror image, so any order is an
isomorphic graph.

Vertex names are currently x,y coordinates used in the construction, but
don't rely on that.

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('hex_grid', key =E<gt> value, ...)>

The key/value parameters are

    dims        => arrayref of 3 integers
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

=item 1,1,1 L<https://hog.grinvin.org/ViewGraphInfo.action?id=670> 6-cycle

=item 2,2,2 L<https://hog.grinvin.org/ViewGraphInfo.action?id=28529>

=item 3,3,3 L<https://hog.grinvin.org/ViewGraphInfo.action?id=28500>

=back

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to
this tree include

=over

L<http://oeis.org/A143366> (etc)

=back

    A143366    Wiener index of NxNxN

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
