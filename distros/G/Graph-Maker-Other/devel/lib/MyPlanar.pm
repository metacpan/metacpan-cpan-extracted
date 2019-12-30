# Copyright 2014, 2015, 2016, 2017, 2019 Kevin Ryde
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
# with this file.  See the file COPYING.  If not, see
# <http://www.gnu.org/licenses/>.


# Extras for Math::Geometry::Planar

package MyPlanar;
use 5.010;  # for // operator
use strict;
use warnings;
use Carp 'croak';
use List::Util 'min','max';
use Math::Geometry::Planar;

# uncomment this to run the ### lines
# use Smart::Comments;


#------------------------------------------------------------------------------


# $planar->MyPlanar::rotate_plus90 modifies $planar rotating all points
# +90deg.  This is like Math::Geometry::Planar $planar->rotate, but
# preserves exact integer coordinates.
sub rotate_plus90 {
  my ($planar, $reps) = @_;
  return $planar->points(points_rotate_plus90($planar->points,$reps));
}

# $planar1->MyPlanar::has_overlap($planar2)
# $planar1 and $planar2 are Math::Geometry::Planar objects.
# Return true if they have some non-empty amount of overlapping area.
# If they touch only at some point or sides they they are not overlapping.
sub has_overlap {
  my ($planar1, $planar2) = @_;
  return gpc_has_overlap($planar1->convert2gpc, $planar2->convert2gpc);
}

# $gpc1 and $gpc2 are Math::Geometry::Planar::GPC objects.
# Return true if they have some non-empty amount of overlapping area.
# If they touch only at some point or sides they they are not overlapping.
sub gpc_has_overlap {
  my ($gpc1, $gpc2) = @_;
  ### gpc_has_overlap() ...
  my $intersect = Math::Geometry::Planar::GpcClip('INTERSECTION',$gpc1,$gpc2);
  return Math::Geometry::Planar::GPC::gpc_polygon_num_contours_get($intersect);
}

# $planar1->MyPlanar::has_boundary_touch($planar2)
# $planar1 and $planar2 are Math::Geometry::Planar objects.
# Return true if they have some boundary point or points in common.
sub has_boundary_touch {
  my ($planar1, $planar2) = @_;
  return points_has_boundary_touch($planar1->points,
                                   $planar2->points);
}
sub points_has_boundary_touch {
  my ($points1, $points2) = @_;
  ### points_has_boundary_touch() ...
  foreach my $i (0 .. $#$points1) {
    foreach my $j (0 .. $#$points2) {
      if (segment_intersection_segment([$points1->[$i-1], $points1->[$i],
                                        $points2->[$j-1], $points2->[$j]])) {
        return 1;
      }
    }
  }
  return 0;
}

# $points is an arrayref [ [x,y],[x,y],... ] of a polygon
# Return true if $point is on any of the polygon line segments.
sub poly_has_boundary_point {
  my ($points, $point) = @_;
  foreach my $i (0 .. $#$points) {
    if (segment_contains_point([$points->[$i-1], $points->[$i], $point])) {
      return 1;
    }
  }
  return 0;
}

#------------------------------------------------------------------------------

# $points is an arrayref of points arrayref pairs [ [x,y], [x,y], ... ].
# Return a new such arrayref where each point is offset by $dx,$dy, so
# x+$dx and y+$dy.
# This is like Math::Geometry::Planar $planar->move, but just on points array.
sub points_move {
  my ($points, $dx,$dy) = @_;
  return [ map {[ $_->[0]+$dx, $_->[1]+$dy ]} @$points ];
}

# $points is an arrayref of points arrayref pairs [ [x,y], [x,y], ... ].
# Return a new such arrayref where each point has x and y multiplied by $factor.
sub points_scale {
  my ($points, $factor) = @_;
  return [ map {[ map {$_*$factor} @$_ ]} @$points ];
}

# $points is an arrayref of points arrayref pairs [ [x,y], [x,y], ... ].
# Return a new such arrayref where each point has x and y multiplied by $factor.
sub points_xyscale {
  my ($points, $xfactor, $yfactor) = @_;
  return [ map {[ $_->[0]*$xfactor, $_->[1]*$yfactor ]} @$points ];
}

sub xy_rotate_plus90 {
  my ($x,$y, $reps) = @_;
  if (! defined $reps) { $reps = 1; }
  foreach (1 .. $reps&3) {
    ($x,$y) = (-$y,$x);  # rotate +90
  }
  return ($x,$y);
}

# $points is an arrayref of points arrayref pairs [ [x,y], [x,y], ... ].
# Return a new such arrayref where each point is rotated $reps many times
# +90deg.
sub points_rotate_plus90 {
  my ($points, $reps) = @_;
  return [ map {[xy_rotate_plus90(@$_,$reps)]} @$points ];
}

# $points is [ [$x,$y], ... ]
# return a Math::Geometry::Planar::GPC
sub points_to_gpc {
  my ($points) = @_;
  $points // croak "points_to_gpc() no points given";
  require Math::Geometry::Planar;
  my $planar = Math::Geometry::Planar->new;
  if (@$points) {
    $planar->points($points);
  }
  return $planar->convert2gpc;
}

sub gpc_to_points_list {
  my ($gpc) = @_;
  ### gpc_to_points_list() ...
  my @p = Math::Geometry::Planar::Gpc2Polygons($gpc);
  ### @p
  return map {@{$_->polygons}} @p;
}

sub gpc_is_empty {
  my ($gpc) = @_;
  my @p = Math::Geometry::Planar::Gpc2Polygons($gpc);
  return @p==0;
}


#------------------------------------------------------------------------------

# Return the bounding box of $planar as list ($x1,$y1, $x2,$y2).
#
#       *------ x2,y2
#       |         |
#     x1,y1 ------*
#
sub bbox_xyxy {
  my ($planar) = @_;
  my $points = $planar->points;
  my @x = map {$_->[0]} @$points;
  my @y = map {$_->[0]} @$points;
  return (min(@x),min(@y), max(@x),max(@y));
}


#------------------------------------------------------------------------------

sub points_to_area {
  my ($points) = @_;
  if (@$points < 3) { return 0; }
  require Math::Geometry::Planar;
  my $planar = Math::Geometry::Planar->new;
  $planar->points($points);
  return $planar->area;
}

sub points_to_minrectarea {
  my ($points) = @_;
  if (@$points < 3) { return 0; }
  require Math::Geometry::Planar;
  my $planar = Math::Geometry::Planar->new;
  $planar->points($points);
  $planar = $planar->minrectangle;
  return $planar->area;
}

#------------------------------------------------------------------------------

my $precision = 7;
my $delta = 10 ** (-$precision);  # like Math::Geometry::Planar

# segment_contains_point([$p1,$p2, $p3])
# Return true if segment $p1,$p2 contains point $p3.
sub segment_contains_point {
  my ($points) = @_;
  my ($p1,$p2, $p3) = @$points;
  return abs(Math::Geometry::Planar::DistanceToSegment([$p1,$p2,$p3])) < $delta;
}
sub segments_are_colinear {
  my ($points) = @_;
  my ($p1,$p2, $p3,$p4) = @$points;
  return Math::Geometry::Planar::Colinear([$p1,$p2,$p3])
    && Math::Geometry::Planar::Colinear([$p1,$p2,$p4]);
}

# segment_intersection_segment([$p1,$p2, $p3,$p4])
# Return a segment [$ps,$pe] which is the intersection of segments $p1,$p2
# and $p3,$p4.  If they do not intersect then return 0;
# If they are colinear and overlapping then return the portion where they
# overlap.
# If they touch or cross at a single point then return [$p,$p] which is that
# point (like SegmentIntersection() does).
#
sub segment_intersection_segment {
  my ($points) = @_;
  my ($p1,$p2, $p3,$p4) = @$points;
  ### segment_intersection_segment(): $points

  #   p1------p2            p1---p2              p1------p2
  #       p3------p4    p3-----------p4      p3------p4
  #
  #   p1------p2            p3---p4              p1------p2
  #       p4------p3    p1-----------p2      p4------p3
  #

  my $c1 = segment_contains_point([$p3,$p4, $p1]);
  my $c2 = segment_contains_point([$p3,$p4, $p2]);
  ### $c1
  ### $c2
  if ($c1 && $c2) {
    ### p1,p2 entirely within p3,p4 ...
    return [$p1,$p2];
  }

  my $c3 = segment_contains_point([$p1,$p2, $p3]);
  my $c4 = segment_contains_point([$p1,$p2, $p4]);
  ### $c3
  ### $c4
  if ($c3 && $c4) {
    ### p3,p4 entirely within p1,p2 ...
    return [$p3,$p4];
  }

  if (($c1||$c2) && ($c3||$c4)) {
    ### partial overlap ...
    return [$c1 ? $p1 : $p2,
            $c3 ? $p3 : $p4];
  }

  foreach my $a ($p1,$p2) {
    foreach my $b ($p3,$p4) {
      if ($a->[0]==$b->[0] && $a->[1]==$b->[1]) {
        ### endpoint in common ...
        return [$a,$a];
      }
    }
  }

  ### try point intersection ...
  if (my $p = Math::Geometry::Planar::SegmentIntersection($points)) {
    return [$p,$p];
  }
  return 0;
}

sub distance_segment_to_segment {
  my ($points) = @_;
  my ($p1,$p2, $p3,$p4) = @$points;

  # DistanceToSegment() is +ve on the left and -ve on the right.
  # Here want absolute value.
  # 
  # Shortest distance is always attained going to the endpoint of one
  # segment, since straight lines.

  my $ret;
  foreach (0,1) {
    foreach my $i (2,3) {
      my $d = abs(DistanceToSegment([$points->[0],$points->[1],$points->[$i]]));
      $ret = min($ret // $d, $d)
        or return $ret;  # if 0
    }
    $points = [reverse @$points];
  }
  return $ret;
}

# $points1 and $points2 are arrayrefs of points [ [x,y], [x,y], ...]
# which are simple polygons.
# Return the shortest distance between a point on the boundary of $points1
# and a point on the boundary of $points2.
# If their boundaries touch or cross then the return is 0.
# One polygon can be within the other.  The distance is still between their
# boundaries.
sub poly_distance_boundary_to_boundary {
  my ($points1, $points2) = @_;
  my $ret;
 OUTER: foreach my $i (0 .. $#$points1) {
    foreach my $j (0 .. $#$points2) {
      my $d = distance_segment_to_segment([$points1->[$i-1],$points1->[$i],
                                           $points2->[$j-1],$points2->[$j]]);
      if (defined $ret) {
        $ret = min($ret, $d);
      } else {
        $ret = $d;
      }
      $ret or last OUTER;
    }
  }
  return $ret;
}

sub poly_union {
  my ($points1, $points2) = @_;
  my $gpc = Math::Geometry::Planar::GpcClip('UNION',
                                            points_to_gpc($points1),
                                            points_to_gpc($points2));
  if (defined $gpc) {
    return gpc_to_points_list($gpc);
  }
  return;
}

sub poly_intersection {
  my ($points1, $points2) = @_;
  my $gpc = Math::Geometry::Planar::GpcClip('INTERSECTION',
                                            points_to_gpc($points1),
                                            points_to_gpc($points2));
  if (defined $gpc) {
    return gpc_to_points_list($gpc);
  }
  return undef;

  # foreach my $i (0 .. $#$points1) {
  #   foreach my $j (0 .. $#$points2) {
  #     if (my $p = Math::Geometry::Planar::SegmentIntersection
  #         ($points1->[$i-1],$points1->[$i],
  #          $points2->[$j-1],$points2->[$j])) {
  #       return [$p];
  #     }
  #   }
  # }
}

# $points is an arrayref [ $point1, $point2, ... $pointN ]
# Return a list of segments in the form of arrayrefs of 2 points each
#   [$point1,$point2],
#   [$point2,$point3],
#   ...
#   [$pointNsub1,$pointN],
#   [$pointN,$point1]
#
sub poly_to_segments {
  my ($points) = @_;
  return map {
    [ $points->[$_-1], $points->[$_] ]
  } 1 .. $#$points, 0;
}

# $points is an arrayref [ [$x,$y], ... ]
# Return true if it is merely a single point, so all elements the same
# [$x,$y].
sub poly_is_point {
  my ($points) = @_;
  foreach my $i (1 .. $#$points) {
    unless (point_eq($points->[$i], $points->[$i-1])) {
      return 0;
    }
  }
  return 1;
}

# ENHANCE-ME: maybe allow $delta
sub point_eq {
  my ($point1, $point2) = @_;
  return ($point1->[0] == $point2->[0]
          && $point1->[1] == $point2->[1]);
}

#------------------------------------------------------------------------------
1;
__END__
