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


package Graph::Maker::Dragon;
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

# GP-Test  (1+I)*('x+I*'y) == ('x-'y) + I*('x+'y)

sub _n_to_xy_dxdy {
  my ($n) = @_;
  my $odd = $n & 1;
  my $x = my $y = 0;
  my $bx = 1;          # power b^j where b=I+1
  my $by = 0;
  my $s = 1;           # sign +/- power
  for ( ; $n; $n >>= 1) {
    if (($n & 3) == 1) {
      $s = -$s;
    }
    if ($n & 1) {
      $x += $s*$bx;
      $y += $s*$by;
    }
    ($bx,$by) = ($bx-$by, $bx+$by);  # multiply b
  }
  ### final: "xy=$x,$y  s=$s"

  return ($s*$x, $s*$y,
          ($odd ? (0,-$s) : ($s,0)));
}

{
  my @_BlobN = (3, 6, 12, 9);
  sub _BlobN {
    my ($k) = @_;
    return (2**($k+1) + $_BlobN[$k&3]) / 5;
  }
}

my @dir4_to_dx = (1,0,-1,0);
my @dir4_to_dy = (0,1,0,-1);

sub init {
  my ($self, %params) = @_;

  my $level = delete($params{'level'}) || 0;
  my $arms = delete($params{'arms'}) || 1;
  my $part = delete($params{'part'}) || 'dragon';
  my $n_lo = delete($params{'n_lo'});
  my $n_hi = delete($params{'n_hi'});
  my $graph_maker = delete($params{graph_maker}) || \&_default_graph_maker;

  my $graph = $graph_maker->(%params);

  if (! defined $n_lo) {
    if ($part eq 'blob') {
      $n_lo = _BlobN($level);
    } else {
      $n_lo = 0;
    }
  }
  if (! defined $n_hi) {
    if ($part eq 'blob') {
      $n_hi = _BlobN($level+1) - 3;
    } else {
      $n_hi = 1 << $level;
    }
  }
  ### $arms
  ### $n_lo
  ### $n_hi

  # empty
  if ($n_lo > $n_hi) {
    return $graph;
  }

  my ($a_x,$a_y, $a_dx,$a_dy) = _n_to_xy_dxdy($n_lo);

  foreach my $arm (1 .. $arms) {
    ### $arm
    my $x = $a_x;
    my $y = $a_y;
    my $dx = $a_dx;
    my $dy = $a_dy;

    my $from = "$x,$y";
    $graph->add_vertex($from);

    foreach my $n ($n_lo+1 .. $n_hi) {
      $x += $dx;
      $y += $dy;

      my $to = "$x,$y";
      $graph->add_edge($from, $to);
      ### edge: "$from to $to"

      $from = $to;
      if (((($n-1) ^ $n) + 1) & $n) {  # turn right = bit above lowest 1
        ($dx,$dy) = ($dy,-$dx);   # -90
      } else {
        ($dx,$dy) = (-$dy,$dx);   # +90
      }
    }

    ($a_x,$a_y) = (-$a_y,$a_x);    # rotate +90
    ($a_dx,$a_dy) = (-$a_dy,$a_dx);
  }
  return $graph;
}
# GP-Test  I*('x+I*'y) == -'y + I*'x

Graph::Maker->add_factory_type('dragon' => __PACKAGE__);
1;

__END__

=for stopwords Ryde

=head1 NAME

Graph::Maker::Dragon - create dragon graph

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::Dragon;
 $graph = Graph::Maker->new ('dragon', level => 4);

=head1 DESCRIPTION

C<Graph::Maker::Dragon> creates C<Graph.pm> graphs of the Heighway/Harter
dragon curve.

            *---*   *---*
            |   |   |   |
            *---*---*   *---*      level => 5
                |           |
    *---*   *---*       *---*
    |   |   |
    *---*---*---*
        |   |   |
        *---*---*
            |
            *---*
                |
        *   *---*
        |   |
        *---*

Vertex names are integer coordinates "X,Y" which are locations in the usual
layout, starting at the origin "0,0" and spiralling anti-clockwise.  Of
course as a graph there's no need to actually use these coordinates for any
display etc.

The first and last vertices are degree 1.  All others are degree 2 or 4,
being single-visited or double-visited points of the curve.

=head2 Arms

Optional parameter C<arms =E<gt> $integer> selects up to 4 curve arms
starting at the origin and each rotated 90 degrees around.  4 arms
eventually fill the plane, having edges horizontally or vertically between
all integer points.

                    *---*
                        |
            *---*   *---*                   level => 4
            |   |   |                       arms => 4
            *---*---*---*   *---*
                |   |   |   |   |
    *---*   *---*---*---*---*---*
    |   |   |   |   |   |   |
    *   *---*---*---O---*---*---*   *
            |   |   |   |   |   |   |
        *---*---*---*---*---*   *---*
        |   |   |   |   |
        *---*   *---*---*---*
                    |   |   |
                *---*   *---*
                |
                *---*

=head2 Blob

Optional parameter C<part =E<gt> 'blob'> selects the sub-graph which is the
middle biggest blob in curve C<$level>.

                    *---*
                    |   |       level => 6
    *---*   *---*---*---*       part => 'blob'
    |   |   |   |   |
    *---*---*---*---*
        |   |   |   |
        *---*   *---*

The C<arms> parameter can be given but is not very interesting for the blob
part.  The middle blob of the arms do not touch so the effect is just to
generate C<arms> many disconnected copies.

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('dragon', key =E<gt> value, ...)>

The key/value parameters are

    level =>  curve expansion level >= 0
    arms  =>  1 to 4 (default 1)
    graph_maker => subr(key=>value) constructor, default Graph->new

Other parameters are passed to the constructor, either C<graph_maker> or
C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are added both ways
between vertices.  Option C<undirected =E<gt> 1> creates an undirected graph
and for it there is a single edge between vertices.

=back

=head1 SEE ALSO

L<Graph::Maker>,
L<Graph::Maker::Twindragon>

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
