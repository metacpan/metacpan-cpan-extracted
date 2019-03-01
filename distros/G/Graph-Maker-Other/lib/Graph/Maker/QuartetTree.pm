# Copyright 2017, 2018, 2019 Kevin Ryde
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


package Graph::Maker::QuartetTree;
use 5.004;
use strict;
use Graph::Maker;

use vars '$VERSION','@ISA';
$VERSION = 13;
@ISA = ('Graph::Maker');

# uncomment this to run the ### lines
# use Smart::Comments;

sub _default_graph_maker {
  require Graph;
  Graph->new(@_);
}

# return $x,$y multiplied by 2+i
# GP-Test  (2+I)*(x+I*y) == (2*x-y) + (x+2*y)*I
sub _mul {
  my ($x,$y) = @_;
  return (2*$x -   $y,
          $x   + 2*$y);
}

sub _xy_rotate_plus90 {
  my ($x,$y, $multiple) = @_;
  $multiple %= 4;
  foreach (1 .. $multiple) {
    ($x,$y) = (-$y,$x);  # rotate +90
  }
  return ($x,$y);
}
#                      @     E
#                          < |
#                            v
#                S---->*---->*    @          expand on right
#                  v     v   ^
#                            | ^
#                @     *---->*    @
#                        v
#                         
#    *---->*           S     @
#      v

sub init {
  my ($self, %params) = @_;

  my $level = delete($params{'level'}) || 0;
  my $vertex_names = delete($params{'vertex_names'}) || 'xy';
  my $graph_maker = delete($params{graph_maker}) || \&_default_graph_maker;

  my $graph = $graph_maker->(%params);
  $graph->set_graph_attribute (name => "Quartet Tree $level");
  $graph->set_graph_attribute (vertex_name_type_xy => 1);

  my @ex = (1);
  my @ey = (0);
  foreach (1 .. $level) {
    my ($ex,$ey) = _mul($ex[-1],$ey[-1]);
    push @ex, $ex;
    push @ey, $ey;
  }

  my $straight = ($vertex_names =~ /straight/);
  my $directed = $graph->is_directed;
  my $recurse;
  $recurse = sub {
    my ($x,$y, $dir, $k) = @_;
    ### recurse: "$x,$y  dir=$dir  k=$k"
    ### assert: $k >= 0
    if ($k == 0) {
      my $from = "$x,$y";
      my ($dx,$dy) = _xy_rotate_plus90(1,0, $dir);
      $x += $dx;
      $y += $dy;
      my $to = "$x,$y";
      $graph->add_edge($from,$to);
      if ($directed) { $graph->add_edge($to,$from); }
    } else {
      $k--;
      my $dx = $ex[$k];
      my $dy = $ey[$k];
      ($dx,$dy) = _xy_rotate_plus90($dx,$dy, $dir);
      my ($lx,$ly) = _xy_rotate_plus90($dx,$dy, 1);
      $recurse->($x,           $y,           $dir,   $k);
      $recurse->($x+$dx,       $y+$dy,       $dir,   $k);
      $recurse->($x+2*$dx-$lx, $y+2*$dy-$ly, $dir+1, $k);
      if ($straight) {
        $recurse->($x+2*$dx+2*$lx, $y+2*$dy+2*$ly, $dir+1, $k);
      } else {
        $recurse->($x+$dx-$lx, $y+$dy-$ly,  $dir,   $k);
      }
      $recurse->($x+2*$dx+$lx, $y+2*$dy+$ly,  $dir-1,   $k);
    }
  };
  $recurse->(0,0, 0, $level);

  return $graph;
}

Graph::Maker->add_factory_type('quartet_tree' => __PACKAGE__);
1;

__END__

=for stopwords Ryde undirected

=head1 NAME

Graph::Maker::QuartetTree - create quartet trees

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::QuartetTree;
 $graph = Graph::Maker->new ('quartet_tree', level => 2);

=head1 DESCRIPTION

C<Graph::Maker::QuartetTree> creates C<Graph.pm> graphs of Mandelbrot's
quartet tree.

                level => 3          *---*
                                    |
        *---*                       *---*---*   *---*
        |                           |           |
        *---*---*   *---*           *   *---*   *---*---*
        |           |               |   |       |
        *   *---*   *---*---*   *   *   *---*---*
        |   |       |           |   |   |
    *   *   *---*---*   *---*   *---*---*---*---*
    |   |   |           |                   |   |
    *---*---*---*---*   *---*---*   *---*   *   *
                |   |   |           |       |
                *   *   *   *---*   *---*---*
                |       |   |       |        
                *   *   *   *---*---*   *---*
                |   |   |   |           |
            *   *   *---*---*---*---*   *---*---*---*---*
            |   |               |   |   |           |   |
            *---*---*   *---*   *   *   *---*---*   *   *
                    |   |       |       |   |   |   |
            *   *   *   *---*---*---*---*   *   *   *
            |   |   |   |               |   |
        *   *   *---*---*           *---*   *---*---*
        |   |           |                       |   |
        *---*---*---*---*                       *   *
                        |                       |
                    *---*                       *


Vertex names are currently integer coordinates "X,Y" which are locations
taking tree start as 0,0 and first edge East.  But don't rely on that.  Of
course as a graph any locations can be used for vertex display etc.

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('dragon', key =E<gt> value, ...)>

The key/value parameters are

    level       => tree expansion level, integer >= 0
    graph_maker => subr(key=>value) constructor, default Graph->new

Other parameters are passed to the constructor, either C<graph_maker> or
C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are added both ways
between vertices.  Option C<undirected =E<gt> 1> creates an undirected graph
and for it there is a single edge between vertices.

=back

=head1 HOUSE OF GRAPHS

House of Graphs entries for graphs here include

=over

=item level=0, L<https://hog.grinvin.org/ViewGraphInfo.action?id=19655>, path-2

=item level=1, L<https://hog.grinvin.org/ViewGraphInfo.action?id=496>, E tree

=item level=2, L<https://hog.grinvin.org/ViewGraphInfo.action?id=30345>

=item level=3, L<https://hog.grinvin.org/ViewGraphInfo.action?id=30347>

=back

=head1 SEE ALSO

L<Graph::Maker>

=head1 LICENSE

Copyright 2017, 2018, 2019 Kevin Ryde

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
