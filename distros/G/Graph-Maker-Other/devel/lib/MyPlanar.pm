# Copyright 2014, 2015, 2016, 2017 Kevin Ryde
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

# uncomment this to run the ### lines
# use Smart::Comments;


#------------------------------------------------------------------------------


# $planar->MyPlanar::rotate_plus90 modifies $planar rotating all points +90deg
# like $planar->rotate, but staying exact
sub rotate_plus90 {
  my ($planar) = @_;
  return $planar->points(points_rotate_plus90($planar->points));
}

#------------------------------------------------------------------------------

# shift each point by $dx,$dy
# (like $planar->move but just on points array)
sub points_move {
  my ($points, $dx,$dy) = @_;
  return [ map {[ $_->[0]+$dx, $_->[1]+$dy ]} @$points ];
}

sub points_scale {
  my ($points, $factor) = @_;
  return [ map {[ $_->[0]*$factor, $_->[1]*$factor ]} @$points ];
}

sub points_rotate_plus90 {
  my ($points) = @_;
  return [ map {[xy_rotate_plus90(@$_)]} @$points ];
}

# $points is [ [$x,$y], ... ]
# return a Math::Geometry::Planar::GPC
sub points_to_gpc {
  my ($points) = @_;
  $points // croak "points_to_gpc() no points given";
  my $planar = Math::Geometry::Planar->new;
  $planar->points($points);
  return $planar->convert2gpc;
}

sub gpc_to_points_list {
  my ($gpc) = @_;
  ### gpc_to_points_list() ...
  my @p = Math::Geometry::Planar::Gpc2Polygons($gpc);
  ### @p
  return map {@{$_->polygons}} @p;
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

sub segment_contains_point {
  my ($points) = @_;
  my ($p1,$p2, $p3) = @$points;
  return Math::Geometry::Planar::DistanceToSegment([$p1,$p2,$p3])==0;
}
sub segments_are_colinear {
  my ($points) = @_;
  my ($p1,$p2, $p3,$p4) = @$points;
  return Math::Geometry::Planar::Colinear([$p1,$p2,$p3])
    && Math::Geometry::Planar::Colinear([$p1,$p2,$p4]);
}

#   p1------p2            p1---p2              p1------p2          
#       p3------p4    p3-----------p4      p3------p4      
sub segment_intersection_segment {
  my ($points) = @_;
  ### segment_intersection_segment(): $points
  my ($p1,$p2, $p3,$p4) = @$points;
  if (segments_are_colinear([$p1,$p2,$p3,$p4])) {
    my $c3 = segment_contains_point([$p1,$p2, $p3]);
    my $c4 = segment_contains_point([$p1,$p2, $p4]);
    ### $c3
    ### $c4
    if ($c3 && $c4) {
      ### p3,p4 smaller ...
      return [$p3,$p4];
    }

    my $c1 = segment_contains_point([$p3,$p4, $p1]);
    my $c2 = segment_contains_point([$p3,$p4, $p2]);
    if ($c1 && $c2) {
      ### p1,p2 smaller ...
      return [$p1,$p2];
    }

    if ($c1 && $c4) {
      ### p1,p4 inside ...
      return [$p1,$p4];
    }
    if ($c2 && $c3) {
      ### p2,p3 inside ...
      return [$p2,$p3];
    }

  } else {
    my $p = Math::Geometry::Planar::SegmentIntersection($points) || return;
    return [$p,$p];
  }
}
sub poly_boundary_intersection {

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

  foreach my $i (0 .. $#$points1) {
    foreach my $j (0 .. $#$points2) {
      if (my $p = Math::Geometry::Planar::SegmentIntersection
          ($points1->[$i-1],$points1->[$i],
           $points2->[$j-1],$points2->[$j])) {
        return [$p];
      }
    }
  }
}

#------------------------------------------------------------------------------
1;
__END__
