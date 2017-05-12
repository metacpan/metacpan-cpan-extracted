=pod

=encoding utf8

=head1 Name

 Math::Intersection::Circle::Line - Find the points at which circles and lines
 intersect to test geometric intuition.

=head1 Synopsis

 use Math::Intersection::Circle::Line q(:all);
 use Test::More q(no_plan);
 use utf8;

 # Euler Line, see: L<https://en.wikipedia.org/wiki/Euler_line>

 if (1)
  {my @t = (0, 0, 4, 0, 0, 3);                                                  # Corners of the triangle
   &areaOfPolygon(sub {ok !$_[0]},                                              # Polygon formed by these points has zero area and so is a line or a point
     &circumCircle   (sub {@_[0,1]}, @t),                                       # green
     &ninePointCircle(sub {@_[0,1]}, @t),                                       # red
     &orthoCentre    (sub {@_[0,1]}, @t),                                       # blue
     &centroid       (sub {@_[0,1]}, @t));                                      # orange
  }

 # An isosceles tringle with an apex height of 3/4 of the radius of its
 # circumcircle divides Euler's line into 6 equal pieces

 if (1)
  {my $r = 400;                                                                 # Arbitrary but convenient radius
   intersectionCircleLine                                                       # Find coordinates of equiangles of isoceles triangle
    {my ($x, $y, $𝕩, $𝕪) = @_;                                                  # Coordinates of equiangles
     my ($𝘅, $𝘆) = (0, $r);                                                     # Coordinates of apex
     my ($nx, $ny, $nr) = ninePointCircle {@_} $x, $y, $𝘅, $𝘆, $𝕩, $𝕪;          # Coordinates of centre and radius of nine point circle
     my ($cx, $cy)      = centroid        {@_} $x, $y, $𝘅, $𝘆, $𝕩, $𝕪;          # Coordinates of centroid
     my ($ox, $oy)      = orthoCentre     {@_} $x, $y, $𝘅, $𝘆, $𝕩, $𝕪;          # Coordinates of orthocentre
     ok near(100, $y);                                                          # Circumcentre to base of triangle
     ok near(200, $cy);                                                         # Circumcentre to lower circumference of nine point circle
     ok near(300, $y+$nr);                                                      # Circumcentre to centre of nine point circle
     ok near(400, $𝘆);                                                          # Circumcentre to apex of isosceles triangle
     ok near(500, $y+2*$nr);                                                    # Circumcentre to upper circumference of nine point circle
     ok near(600, $oy);                                                         # Circumcentre to orthocentre
    } 0, 0, $r,  0, $r/4, 1, $r/4;                                              # Chord at 1/4 radius
  }

 # A line segment across a circle is never longer than the diameter

 if (1)                                                                         # Random circle and random line
  {my ($x, $y, $r, $𝘅, $𝘆, $𝕩, $𝕪) = map {rand()} 1..7;
   intersectionCircleLine                                                       # Find intersection of a circle and a line
    {return ok 1 unless @_ == 4;                                                # Ignore line unless it crosses circle
     ok &vectorLength(@_) <= 2*$r;                                              # Length if line segment is less than or equal to that of a diameter
 	 } $x, $y, $r, $𝘅, $𝘆, $𝕩, $𝕪;                                                # Circle and line to be intersected
  }

 # The length of a side of a hexagon is the radius of a circle inscribed through
 # its vertices

 if (1)
  {my ($x, $y, $r) = map {rand()} 1..3;                                         # Random circle
   my @p = intersectionCircles {@_} $x, $y, $r, $x+$r, $y, $r;                  # First step of one radius
 	 my @𝗽 = intersectionCircles {@_} $x, $y, $r, $p[0], $p[1], $r;               # Second step of one radius
 	 my @q = !&near($x+$r, $y, @𝗽[0,1]) ? @𝗽[0,1] : @𝗽[2,3];                      # Away from start point
 	 my @𝗾 = intersectionCircles {@_} $x, $y, $r, $q[0], $q[1], $r;               # Third step of one radius
   ok &near2(@𝗾[0,1], $x-$r, $y) or                                             # Brings us to a point
      &near2(@𝗾[2,3], $x-$r, $y);                                               # opposite to the start point
  }

 # Circle through three points chosen at random has the same centre regardless of
 # the pairing of the points

 sub circleThrough3
  {my ($x, $y, $𝘅, $𝘆, $𝕩, $𝕪) = @_;                                            # Three points
 	&intersectionLines
 	 (sub                                                                         # Intersection of bisectors is the centre of the circle
 	   {my @r =(&vectorLength(@_, $x, $y),                                        # Radii from centre of circle to each point
 	            &vectorLength(@_, $𝘅, $𝘆),
 	            &vectorLength(@_, $𝕩, $𝕪));
 	    ok &near(@r[0,1]);                                                        # Check radii are equal
 	    ok &near(@r[1,2]);
       @_                                                                       # Return centre
 		 }, rotate90AroundMidPoint($x, $y, $𝘅, $𝘆),                                 # Bisectors between pairs of points
 		    rotate90AroundMidPoint($𝕩, $𝕪, $𝘅, $𝘆));
  }

 if (1)
  {my (@points) = map {rand()} 1..6;                                            # Three points chosen at random
   ok &near2(circleThrough3(@points), circleThrough3(@points[2..5, 0..1]));     # Circle has same centre regardless
   ok &near2(circleThrough3(@points), circleThrough3(@points[4..5, 0..3]));     # of the pairing of the points
  }

=cut
package Math::Intersection::Circle::Line;
#-------------------------------------------------------------------------------
# Locate the points at which lines and circles cross in two dimensions
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2016, http://www.appaapps.com
#-------------------------------------------------------------------------------

use v5.18;
use warnings FATAL => qw(all);
use strict;
use utf8;
use Carp;

#-------------------------------------------------------------------------------
# Our definition of nearness
#-------------------------------------------------------------------------------

our $near = 1e-6;                                                               # Define nearness

sub near($;$) {return abs(($_[1]//0) - $_[0]) < $near}                          # Values this close are considered identical

sub near2($$;$$)                                                                # Check that we are near enough
 {my ($a, $b, $A, $B) = @_;
  near($A//0, $a) &&
  near($B//0, $b)
 }

sub near3($$$;$$$)                                                              # Check that we are near enough
 {my ($a, $b, $c, $A, $B, $C) = @_;
  near($A//0, $a) &&
  near($B//0, $b) &&
  near($C//0, $c)
 }

sub near4($$$$;$$$$)                                                            # Check that we are near enough
 {my ($a, $b, $c, $d, $A, $B, $C, $D) = @_;
  near($A//0, $a) &&
  near($B//0, $b) &&
  near($C//0, $c) &&
  near($D//0, $d)
 }

#-------------------------------------------------------------------------------
# Trigonometric functions
#-------------------------------------------------------------------------------

sub 𝝿 {4*atan2(1,1)}                                                            # Pi
sub acos($) {my ($a) = @_; atan2(sqrt(1 - $a**2), $a)}                          # acos

#-------------------------------------------------------------------------------
# Length of a vector
#-------------------------------------------------------------------------------

sub vectorSquaredLength($$;$$)                                                  # Length of a vector or distance between two vectors squared - useful for finding out which is longest without having to take a square root
 {my ($x, $y, $𝘅, $𝘆) = @_;
  my $r = ($x-($𝘅//0))**2+($y-($𝘆//0))**2;
  $r
 }

sub vectorLength($$;$$) {sqrt(&vectorSquaredLength(@_))}                        # Length of a vector or distance between two vectors

#-------------------------------------------------------------------------------
# Lengths of the sides of a polygon
#-------------------------------------------------------------------------------

sub lengthsOfTheSidesOfAPolygon($$@)
 {my ($x, $y, @vertices) = @_;
  @_% 2 == 0 or confess "Odd number of coordinates!";
  @_> 4      or confess "Must have at least two vertices!";
  my @l;
  my ($𝘅, $𝘆);
  for(;scalar(@vertices);)
   {($𝘅, $𝘆, @vertices) = @vertices;
    push @l, vectorLength($x, $y, $𝘅, $𝘆);
    ($x, $y) = ($𝘅, $𝘆)
   }
  push @l, vectorLength($_[-2]-$_[0], $_[-1]-$_[1]);
  @l
 }

#-------------------------------------------------------------------------------
# Check whether three points are close to collinear by the Schwartz inequality
#-------------------------------------------------------------------------------

sub threeCollinearPoints($$$$$$)                                                # Three points to be tested
 {my ($x, $y, $𝘅, $𝘆, $𝕩, $𝕪) = @_;
  @_ == 6 or confess "Wrong number of parameters";
  return 1 if near($x, $𝘅) && near($y, $𝘆) or near($x, $𝕩) && near($y, $𝕪);     # When two points are close the points are effectively collinear - although we should really check that all three points are not close sa this would identify either a number representation problem or a bad definition of nearness for this application
  my $d = vectorLength($𝘅, $𝘆, $𝕩, $𝕪);
  my $𝗱 = vectorLength($x, $y, $𝕩, $𝕪);                                         # Lengths of sides opposite corners
  my $𝕕 = vectorLength($x, $y, $𝘅, $𝘆);
  return 1 if near($d, $𝗱) && near($𝕕);                                         # Two sides equal and the other small makes the lines effectively collinear
  return 1 if near($d, $𝕕) && near($𝗱);
  return 1 if near($𝗱, $𝕕) && near($d);
  near($d, $𝗱+$𝕕) or near($𝗱, $𝕕+$d) or near($𝕕, $d+$𝗱)                         # One side is almost as long as the other two combined
 }

#-------------------------------------------------------------------------------
# Average of two vectors = coordinates of the mid point on the line between them
#-------------------------------------------------------------------------------

sub midPoint($$$$)
 {my ($x, $y, $𝘅, $𝘆) = @_;
  @_ == 4 or confess "Wrong number of parameters";
  (($x+$𝘅) / 2, ($y+$𝘆) / 2)
 }

#-------------------------------------------------------------------------------
# Rotations
#-------------------------------------------------------------------------------

sub rotate90CW ($$) {my ($x, $y) = @_; (+$y, -$x)}                              # Clockwise
sub rotate90CCW($$) {my ($x, $y) = @_; (-$y, +$x)}                              # Counter clockwise

sub rotate90AroundMidPoint($$$$)
 {my ($x, $y, $𝘅, $𝘆) = @_;
  @_ == 4 or confess "Wrong number of parameters";
	my ($𝕩, $𝕪) = map {$_/2} rotate90CW($𝘅 - $x, $𝘆 - $y);
	my ($X, $Y) = &midPoint(@_);
	($X - $𝕩, $Y - $𝕪, $X + $𝕩, $Y + $𝕪)
 }

#-------------------------------------------------------------------------------
# 𝗜ntersection of a circle A, with a circle B.
#
# 𝗞nown: coordinates of the centre and radius of each circle  x, y, r, 𝘅, 𝘆, 𝗿
#
# 𝗙ind: the coordinates of the points at which the circles intersect.
#
# 𝗠ethod: Two different circles either do not intersect, or if they do, they
# intersect at one or two points.  If they intersect at two points, the
# intersections are mirror images of each other in the line that connects the
# centres of the two circles.
#
# Let 𝗟 be the line joining the two centres with length 𝗹 = a + 𝗮 where a is the
# distance from (x, y) along 𝗟 to the point closest to the intersections. Then:
#
#   r*r-a*a == 𝗿*𝗿-𝗮*𝗮
#   r*r-𝗿*𝗿  == a*a-𝗮*𝗮
#           == a*a-𝗮*𝗮 = (a+𝗮)(a-𝗮) == 𝗹*(a-𝗮) == 𝗹*(a - (𝗹 - a)) = 2*a*𝗹 - 𝗹*𝗹
#
#   a == (r*r-𝗿*𝗿 + 𝗹*𝗹)/ (2*𝗹)
#
# The distance 𝗮 at right angles to 𝗟 to an intersection is sqrt(r*r-a*a)
#
# The unit vector 𝕕 == (𝕩, 𝕪) along line 𝗟 from (x,y) to (𝘅, 𝘆) is the unit in
# direction: (𝘅-x, 𝘆-y)
#
# The unit vectors d, 𝗱 at right angles to 𝗟 are (-𝕪, 𝕩) and (𝕪, -𝕩)
#-------------------------------------------------------------------------------

sub intersectionCircles(&$$$$$$)
 {my ($sub,                                                                     # Sub routine to process intersection
      $x, $y, $r,                                                               # First circle centre, radius
      $𝘅, $𝘆, $𝗿) = @_;                                                         # Second circle centre, radius
  @_ == 7 or confess "Wrong number of parameters";
  return &$sub("Duplicate circles!") if                                         # Complain if the two circles are in fact the same circle within the definition of nearness
    near($x, $𝘅) and near($y, $𝘆) and near($r, $𝗿);

  my ($𝕏, $𝕐) = ($𝘅 - $x, $𝘆 - $y);                                             # Vector between centres
  my $𝗹 = vectorLength($𝕏, $𝕐);                                                 # Distance between centres
  return &$sub("No intersection!") if $𝗹 > $r + $𝗿 or $𝗹 < abs($r - $𝗿);        # The circles are too far apart or too close to intersect

  my ($𝕩, $𝕪) = ($𝕏 / $𝗹, $𝕐 / $𝗹);                                             # Unit vector between centres
  my $a = ($r*$r - $𝗿*$𝗿 + $𝗹*$𝗹)/ (2*$𝗹);                                      # Length of the common side

  return &$sub($x+$𝕩*$a, $y+$𝕪*$a) if near($𝗹,     $r + $𝗿) or                  # The circles touch at one point if within the definition of nearness
                                      near($𝗹, abs($r - $𝗿));

  my $𝗮 = sqrt($r*$r-$a*$a);
  &$sub($x+$𝕩*$a-$𝕪*$𝗮, $y+$𝕪*$a+$𝕩*$𝗮,                                         # The circles touch at two points
        $x+$𝕩*$a+$𝕪*$𝗮, $y+$𝕪*$a-$𝕩*$𝗮);
 }

#-------------------------------------------------------------------------------
# 𝗔rea of intersection of two circles.
#
# 𝗞nown: two circles specified by ($x, $y, $r) and ($𝘅, $𝘆, $𝗿)
#
# 𝗙ind: the area of intersection expressed as a fraction of the area
# of the smaller circle
#
# 𝗠ethod: the area of a triangle is (base * height) / 2, the area of a slice is
# 𝝰𝗿𝗿/2 where 𝝰 is the angle of a slice.
#-------------------------------------------------------------------------------

sub intersectionCirclesArea(&$$$$$$)
 {my ($sub,                                                                     # Sub routine to process area
      $x, $y, $r,                                                               # First circle centre, radius
      $𝘅, $𝘆, $𝗿) = @_;                                                         # Second circle centre, radius
  @_ == 7 or confess "Wrong number of parameters";
  near($r) and confess "Radius of first circle is too small!";
  near($𝗿) and confess "Radius of second circle is too small!";
  my $l = vectorLength($𝘅 - $x, $𝘆 - $y);                                       # Distance between centres
  return &$sub(0) if $l >= $r + $𝗿;                                             # The circles are too far apart to overlap
  my $𝕣 = $r < $𝗿 ? $r : $𝗿;                                                    # Radius of smaller circle
  return &$sub(1) if $l <= abs($r - $𝗿);                                        # The larger circle overlaps the smaller circle completely

  intersectionCircles
   {my ($X, $Y, $𝗫, $𝗬) = @_;
    my $h = vectorLength($X - $𝗫, $Y - $𝗬) / 2;                                 # Height of triangles
    my $R = sqrt($r**2 - $h**2);                                                # Base of triangle in first circle
    my $𝗥 = sqrt($𝗿**2 - $h**2);                                                # Base of triangle in second circle
    &$sub(($r**2*atan2($h, $R) + $𝗿**2*atan2($h, $𝗥) - $h*($R+$𝗥))/(𝝿()*$𝕣**2)) # Fraction of smaller circle overlapped
   } $x, $y, $r, $𝘅, $𝘆, $𝗿;
 }

#-------------------------------------------------------------------------------
# 𝗣osition on a line closest to a specified point
#
# 𝗞nown: two points on the line 𝗟 such that: 𝗹 = (𝘅, 𝘆), 𝕝 = (𝕩, 𝕪) and the
# specified point 𝗽 = (x, y).
#
# 𝗙ind 𝗰 the point on 𝗟 closest to 𝗽.
#
# 𝗠ethod: a circle with centre 𝗹 through 𝗽 will intersect a circle with centre 𝕝
# through 𝗽 at 𝗾. 𝗰 is then the average of 𝗽 and 𝗾.
#-------------------------------------------------------------------------------

sub intersectionLinePoint(&$$$$$$)
 {my ($sub,                                                                     # Sub routine to process intersection
      $𝘅, $𝘆, $𝕩, $𝕪,                                                           # Two points on line 𝗹
      $x, $y) = @_;                                                             # The point 𝗽
  @_ == 7 or confess "Wrong number of parameters";
  near($𝘅, $𝕩) and near($𝘆, $𝕪) and confess "Points on line are too close!";    # Line not well defined

  return &$sub($x, $y) if near($x, $𝘅) && near($y, $𝘆) or                       # Point in question is near an end of the line segment
                          near($x, $𝕩) && near($y, $𝕪);

  return &$sub($x, $y) if threeCollinearPoints($𝘅, $𝘆, $𝕩, $𝕪, $x, $y);         # Collinear
                                                                                # Points known not to be collinear
  my $𝗿 = vectorLength($𝘅 - $x, $𝘆 - $y);                                       # Radius of first circle
  my $𝕣 = vectorLength($𝕩 - $x, $𝕪 - $y);                                       # Radius of second circle
  intersectionCircles
   {return &$sub(@_) if @_ == 2;                                                # Point is on line
    my ($x, $y, $𝘅, $𝘆) = @_;
    &$sub(($x+$𝘅) / 2, ($y+$𝘆) / 2)                                             # Average intersection of intersection points
   } $𝘅, $𝘆, $𝗿, $𝕩, $𝕪, $𝕣;
 }

sub unsignedDistanceFromLineToPoint(&$$$$$$)                                    # Unsigned distance from point to line
 {my ($sub, $𝘅, $𝘆, $𝕩, $𝕪, $x, $y) = @_;                                       # Parameters are the same as for intersectionLinePoint()
  @_ == 7 or confess "Wrong number of parameters";
  intersectionLinePoint {&$sub(&vectorLength($x, $y, @_))} $𝘅,$𝘆, $𝕩,$𝕪, $x,$y; # Distance from point to nearest point on line
 }

#-------------------------------------------------------------------------------
# 𝗜ntersection of two lines
#
# 𝗞nown: two lines l specified by two points 𝗹 = (𝘅, 𝘆),  𝕝 = (𝕩, 𝕪) and
#                  L specified by two points 𝗟 = (𝗫, 𝗬), 𝕃 = (𝕏, 𝕐)
# 𝗙ind 𝗰 the point where the two lines intersect else $sub is called empty
#
# 𝗠ethod: Let the closest point to point 𝗟 on line l be 𝗮 and the closest point
# to point 𝗮 on line L be 𝗯. L𝗮𝗯 is similar to L𝗮𝗰.
#-------------------------------------------------------------------------------

sub intersectionLines(&$$$$$$$$)
 {my ($sub,                                                                     # Sub routine to process intersection
      $𝘅, $𝘆, $𝕩, $𝕪,                                                           # Two points on line l
      $𝗫, $𝗬, $𝕏, $𝕐) = @_;                                                     # Two points on line L
  @_ == 9 or confess "Wrong number of parameters";
  near($𝘅, $𝕩) and near($𝘆, $𝕪) and confess "Points on first line are too close!";
  near($𝗫, $𝕏) and near($𝗬, $𝕐) and confess "Points on second line are too close!";
  return &$sub("Parallel lines!") if                                             # Lines are parallel if they have the same gradient
    near(atan2($𝘆-$𝕪, $𝘅-$𝕩), atan2($𝗬-$𝕐, $𝗫-$𝕏));

  intersectionLinePoint                                                         # Find 𝗮
   {my ($𝗮x, $𝗮y) = @_;

    intersectionLinePoint                                                       # Find 𝗯
     {my ($𝗯x, $𝗯y) = @_;
      my $La = vectorSquaredLength($𝗫 - $𝗮x, $𝗬 - $𝗮y);                         # Squared distance from 𝗟 to 𝗮
      return &$sub($𝗫, $𝗬) if near($La);                                        # End point of second line is on first line but the lines are not parallel
      my $Lb = vectorSquaredLength($𝗫 - $𝗯x, $𝗬 - $𝗯y);                         # Squared distance from 𝗟 to 𝗯
      near($Lb) and confess "Parallel lines!";                                  # Although this should not happen as we have already checked that the lines are not parallel
      my $s  = $La / $Lb;                                                       # Scale factor for 𝗟𝗯
      &$sub($𝗫 + $s * ($𝗯x - $𝗫), $𝗬 + $s * ($𝗯y - $𝗬))                         # Point of intersection
     } $𝗫,$𝗬,  $𝕏,$𝕐,  $𝗮x,$𝗮y;                                                 # Find 𝗯 on second line
   } $𝘅,$𝘆,  $𝕩,$𝕪,  $𝗫,$𝗬;                                                     # Find 𝗮 on first line
 }

#-------------------------------------------------------------------------------
# 𝗜ntersection of a circle with a line
#
# 𝗞nown: a circle specified by its centre (x, y), and radius (r)
# and a line that passes through points: ($𝘅, $𝘆) and ($𝕩, $𝕪).
#
# 𝗙ind: the two points at which the line crosses the circle or the single point
# at which the line touches the circle or report that there are no points in
# common.
#
# 𝗠ethod: If the line crosses the circle we can draw an isosceles triangle from
# the centre of the circle to the points of intersection, with the line forming
# the base of said triangle.  The centre of the base is the closest point on the
# line to the centre of the circle. The line is at right angles to the line from
# the centre of the circle to the centre of the base.
#-------------------------------------------------------------------------------

sub intersectionCircleLine(&$$$$$$$)
 {my ($sub,                                                                     # Sub routine to process intersection
      $x, $y, $r,                                                               # Circle centre, radius
      $𝘅, $𝘆, $𝕩, $𝕪) = @_;                                                     # Line goes through these two points
  @_ == 8 or confess "Wrong number of parameters";
  near($𝘅, $𝕩) and near($𝘆, $𝕪) and confess "Points on line are too close!";
  if (near($r))                                                                 # Zero radius circle
   {return &$sub($x, $y) if threeCollinearPoints($x, $y, $𝘅, $𝘆, $𝕩, $𝕪);       # Line passes through the centre of the circle
    confess "Radius is too small!";
   }

  intersectionLinePoint
   {my ($X, $Y) = @_;                                                           # Midpoint on line
    if (near($x, $X) and near($y, $Y))                                          # Line passes through centre of circle
     {my ($𝗫, $𝗬) = ($𝕩 - $𝘅, $𝕪 - $𝘆);                                         # Vector along line
      my $D = vectorLength($𝗫, $𝗬);                                             # Length of vector along line
      my $s = $r/$D;                                                            # Length from midpoint along line to circumference relative to length from centre to midpoint
      return &$sub($x + $s * $𝗫, $y + $s * $𝗬, $x - $s * $𝗫, $y - $s * $𝗬);     # Intersection points
     }
    my ($𝗫, $𝗬) = ($X - $x, $Y - $y);                                           # Centre to midpoint
    my $𝗗 = vectorLength($𝗫, $𝗬);                                               # Distance to midpoint
    return &$sub("No intersection!") if $𝗗 > $r;                                # Midpoint outside circle
    return &$sub($X, $Y)        if near($𝗗,  $r);                               # Tangent
    my $𝔻 = sqrt($r*$r - $𝗗*$𝗗);                                                # Length from midpoint along line to circumference
    my $s = $𝔻/$𝗗;                                                              # Length from midpoint along line to circumference relative to length from centre to midpoint
    &$sub($X - $s * $𝗬, $Y + $s * $𝗫, $X + $s * $𝗬, $Y - $s * $𝗫)               # Intersection points
   } $𝘅, $𝘆,  $𝕩, $𝕪,  $x, $y;                                                  # Find point on line closest to centre of circle
 }

#-------------------------------------------------------------------------------
# 𝗔rea of intersection of a circle with a line
#
# 𝗞nown: a circle specified by its centre (x, y), and radius (r)
# and a line that passes through points: ($𝘅, $𝘆) and ($𝕩, $𝕪).
# 𝗙ind: the area of the smallest lune as a fraction of the area of the circle
# 𝗠ethod:
#-------------------------------------------------------------------------------

sub intersectionCircleLineArea(&$$$$$$$)
 {my ($sub,                                                                     # Sub routine to process area
      $x, $y, $r,                                                               # Circle centre, radius
      $𝘅, $𝘆, $𝕩, $𝕪) = @_;                                                     # Line goes through these two points
  @_ == 8 or confess "Wrong number of parameters";
  near($𝘅, $𝕩) and near($𝘆, $𝕪) and confess "Points on line are too close!";
  near($r) and confess "Radius is too small!";

  intersectionCircleLine
   {return &$sub(0) if @_ < 4;
	  my ($X, $Y, $𝗫, $𝗬) = @_;                                                   # Intersection points
    my $h = vectorLength($X - $𝗫, $Y - $𝗬) / 2;                                 # Height of triangle
    my $w = sqrt($r**2 - $h**2);                                                # Base of triangle
    &$sub(($r**2*atan2($h, $w) - $h*$w)/(𝝿()*$r**2))                            # Area of smallest lune as a fraction of circle
   } $x, $y, $r, $𝘅, $𝘆, $𝕩, $𝕪;
 }

#-------------------------------------------------------------------------------
# 𝗖ircumCentre: intersection of the sides of a triangle when rotated 𝝿/2 at
# their mid points - centre of the circumCircle
# 𝗞nown: coordinates of each corner of the triangle
#-------------------------------------------------------------------------------

sub circumCentre(&$$$$$$)
 {my ($sub, $x, $y, $𝘅, $𝘆, $𝕩, $𝕪) = @_;                                       # Subroutine to process results, coordinates of corners
  @_ == 7 or confess "Wrong number of parameters";
  (near($x, $𝘅) && near($y, $𝘆) or near($𝘅, $𝕩) && near($𝘆, $𝕪)) and confess "Corners are too close!";

  &intersectionLines(sub{&$sub(@_)},
    rotate90AroundMidPoint($x, $y, $𝘅, $𝘆),
    rotate90AroundMidPoint($𝘅, $𝘆, $𝕩, $𝕪));
 }

#-------------------------------------------------------------------------------
# 𝗖ircle through three points: https://en.wikipedia.org/wiki/Circumscribed_circle
# 𝗞nown: coordinates of each point
# 𝗙ind: coordinates of the centre and radius of the circle through these three
# points
#-------------------------------------------------------------------------------

sub circumCircle(&$$$$$$)
 {my ($sub, $x, $y, $𝘅, $𝘆, $𝕩, $𝕪) = @_;                                       # Subroutine to process results, coordinates of corners
  @_ == 7 or confess "Wrong number of parameters";
  (near($x, $𝘅) && near($y, $𝘆) or near($𝘅, $𝕩) && near($𝘆, $𝕪)) and confess "Points are too close!";

  circumCentre
   {my ($X, $Y) = @_;                                                           # Centre
    my @r = (vectorLength($x, $y, $X, $Y),                                      # Radii
             vectorLength($𝘅, $𝘆, $X, $Y),
             vectorLength($𝕩, $𝕪, $X, $Y));
    &near(@r[0,1]) && &near(@r[1,2]) or confess "Bad radius computed!";
    &$sub($X, $Y, $r[0])                                                        # Result
   } $x, $y, $𝘅, $𝘆, $𝕩, $𝕪;                                                    # Centre lies at the intersection of
 }

#-------------------------------------------------------------------------------
# 𝗖entre of a circle inscribed inside a triangle so that the inscribed circle
# touches each side just once.
#
# 𝗞nown: coordinates of each corner of the triangle
# 𝗙ind: centre coordinates and radius of inscribed circle
# 𝗠ethod: find the intersection of the lines bisecting two angles
#-------------------------------------------------------------------------------

sub circleInscribedInTriangle(&$$$$$$)
 {my ($sub, $x, $y, $𝘅, $𝘆, $𝕩, $𝕪) = @_;                                       # Subroutine to process results, coordinates of corners
  @_ == 7 or confess "Wrong number of parameters";
  (near($x, $𝘅) && near($y, $𝘆) or near($𝘅, $𝕩) && near($𝘆, $𝕪)) and confess "Corners are too close!";
  my $𝗱 = vectorLength($x, $y, $𝕩, $𝕪);                                         # Lengths of sides opposite corners
  my $𝕕 = vectorLength($x, $y, $𝘅, $𝘆);
  my $d = vectorLength($𝘅, $𝘆, $𝕩, $𝕪);

  intersectionLines
     {my ($X, $Y) = @_;                                                         # Intersection point
      my @r = ((unsignedDistanceFromLineToPoint {@_} $x, $y, $𝘅, $𝘆, $X, $Y),
               (unsignedDistanceFromLineToPoint {@_} $𝘅, $𝘆, $𝕩, $𝕪, $X, $Y),
               (unsignedDistanceFromLineToPoint {@_} $𝕩, $𝕪, $x, $y, $X, $Y));
      &near(@r[0,1]) && &near(@r[1,2]) or confess "Bad radius computed!";
      return &$sub($X, $Y, $r[0]);                                              # Coordinates of the centre of the inscribed circle, plus three estimates of its radius
     }
    $x, $y, $x + ($𝘅-$x)/$𝕕 + ($𝕩-$x)/$𝗱, $y + ($𝘆-$y)/$𝕕 + ($𝕪-$y)/$𝗱,         # Intersection of an angle bisector
    $𝘅, $𝘆, $𝘅 + ($𝕩-$𝘅)/$d + ($x-$𝘅)/$𝕕, $𝘆 + ($𝕪-$𝘆)/$d + ($y-$𝘆)/$𝕕;         # Intersection of an angle bisector
 }

#-------------------------------------------------------------------------------
# 𝗖entre of a circle inscribed through the midpoints of each side of a triangle
# == Nine point circle: https://en.wikipedia.org/wiki/Nine-point_circle
# 𝗞nown: coordinates of each corner of the triangle
# 𝗙ind: centre coordinates and radius of circle through midpoints
# 𝗠ethod: use circumCircle on the midpoints
#-------------------------------------------------------------------------------

sub ninePointCircle(&$$$$$$)
 {my ($sub, $x, $y, $𝘅, $𝘆, $𝕩, $𝕪) = @_;                                       # Subroutine to process results, coordinates of corners
  @_ == 7 or confess "Wrong number of parameters";
  (near($x, $𝘅) && near($y, $𝘆) or near($𝘅, $𝕩) && near($𝘆, $𝕪)) and confess "Corners are too close!";

  &circumCircle(sub{&$sub(@_)},                                                 # Circle through mid points
    midPoint($x, $y, $𝘅, $𝘆),
    midPoint($𝘅, $𝘆, $𝕩, $𝕪),
    midPoint($𝕩, $𝕪, $x, $y));
 }

#-------------------------------------------------------------------------------
# Bisect the first angle of a triangle
#-------------------------------------------------------------------------------

sub bisectAnAngle(&$$$$$$)
 {my ($sub, $x, $y, $𝘅, $𝘆, $𝕩, $𝕪) = @_;                                       # Subroutine to process results, coordinates of corners
  @_ == 7 or confess "Wrong number of parameters";
  (near($x, $𝘅) && near($y, $𝘆) or near($𝘅, $𝕩) && near($𝘆, $𝕪)) and confess "Corners are too close!";
  my $𝕕 = vectorLength($x, $y, $𝕩, $𝕪);                                         # Lengths to opposite corners
  my $𝗱 = vectorLength($x, $y, $𝘅, $𝘆);
  &$sub($x, $y, $x + ($𝘅-$x)/$𝕕 + ($𝕩-$x)/$𝗱, $y + ($𝘆-$y)/$𝕕 + ($𝕪-$y)/$𝗱)     # Vector from vertex pointing along bisector
 }

#-------------------------------------------------------------------------------
# 𝗙ind the centres and radii of the excircles of a triangle
# https://en.wikipedia.org/wiki/Incircle_and_excircles_of_a_triangle
# 𝗞nown: coordinates of each corner of the triangle
# 𝗠ethod: intersection of appropriate angles of the triangles
#-------------------------------------------------------------------------------

sub exCircles(&$$$$$$)
 {my ($sub, $x, $y, $𝘅, $𝘆, $𝕩, $𝕪) = @_;                                       # Subroutine to process results, coordinates of corners
  @_ == 7 or confess "Wrong number of parameters";
  (near($x, $𝘅) && near($y, $𝘆) or near($𝘅, $𝕩) && near($𝘆, $𝕪)) and confess "Corners are too close!";

  my @c = &intersectionLines(sub{@_},                                           # Centres
   (bisectAnAngle {@_} $x, $y, $𝘅, $𝘆,   $𝕩,        $𝕪),
   (bisectAnAngle {@_} $𝘅, $𝘆, $𝕩, $𝕪, 2*$𝘅 - $x, 2*$𝘆 - $y));

  my @𝗰 = &intersectionLines(sub{@_},
   (bisectAnAngle {@_} $𝘅, $𝘆, $𝕩, $𝕪, $x, $y),
   (bisectAnAngle {@_} $𝕩, $𝕪, $x, $y, 2*$𝕩 - $𝘅, 2*$𝕪 - $𝘆));

  my @𝕔 = &intersectionLines(sub{@_},
   (bisectAnAngle {@_} $𝕩, $𝕪, $x, $y, $𝘅, $𝘆),
   (bisectAnAngle {@_} $x, $y, $𝘅, $𝘆, 2*$x - $𝕩, 2*$y - $𝕪));

  my @r = (&unsignedDistanceFromLineToPoint(sub {@_}, $x, $y, $𝘅, $𝘆, @c),
           &unsignedDistanceFromLineToPoint(sub {@_}, $𝘅, $𝘆, $𝕩, $𝕪, @c),
           &unsignedDistanceFromLineToPoint(sub {@_}, $𝕩, $𝕪, $x, $y, @c));

  my @𝗿 = (&unsignedDistanceFromLineToPoint(sub {@_}, $x, $y, $𝘅, $𝘆, @𝗰),
           &unsignedDistanceFromLineToPoint(sub {@_}, $𝘅, $𝘆, $𝕩, $𝕪, @𝗰),
           &unsignedDistanceFromLineToPoint(sub {@_}, $𝕩, $𝕪, $x, $y, @𝗰));

  my @𝕣 = (&unsignedDistanceFromLineToPoint(sub {@_}, $x, $y, $𝘅, $𝘆, @𝕔),
           &unsignedDistanceFromLineToPoint(sub {@_}, $𝘅, $𝘆, $𝕩, $𝕪, @𝕔),
           &unsignedDistanceFromLineToPoint(sub {@_}, $𝕩, $𝕪, $x, $y, @𝕔));
  ([@c, @r], [@𝗰, @𝗿], [@𝕔, @𝕣])                                                # For each circle, the centre followed by the radii estimates
 }

#-------------------------------------------------------------------------------
# 𝗖entroid: intersection of lines between corners and mid points of opposite sides
# 𝗙ind: coordinates of centroid
# 𝗞nown: coordinates of each corner of the triangle
#-------------------------------------------------------------------------------

sub centroid(&$$$$$$)
 {my ($sub, $x, $y, $𝘅, $𝘆, $𝕩, $𝕪) = @_;                                       # Subroutine to process results, coordinates of corners
  @_ == 7 or confess "Wrong number of parameters";
  (near($x, $𝘅) && near($y, $𝘆) or near($𝘅, $𝕩) && near($𝘆, $𝕪)) and confess "Corners are too close!";

  &intersectionLines(sub{&$sub(@_)},
    $x, $y, midPoint($𝘅, $𝘆, $𝕩, $𝕪),
    $𝘅, $𝘆, midPoint($𝕩, $𝕪, $x, $y));
 }

#-------------------------------------------------------------------------------
# 𝗢rthocentre: intersection of altitudes
# 𝗙ind: coordinates of orthocentre
# 𝗞nown: coordinates of each corner of the triangle
#-------------------------------------------------------------------------------

sub orthoCentre(&$$$$$$)
 {my ($sub, $x, $y, $𝘅, $𝘆, $𝕩, $𝕪) = @_;                                       # Subroutine to process results, coordinates of corners
  @_ == 7 or confess "Wrong number of parameters";
  (near($x, $𝘅) && near($y, $𝘆) or near($𝘅, $𝕩) && near($𝘆, $𝕪)) and confess "Corners are too close!";

  &intersectionLines(sub{&$sub(@_)},
    $x, $y, (intersectionLinePoint {@_} $𝘅, $𝘆, $𝕩, $𝕪, $x, $y),
    $𝘅, $𝘆, (intersectionLinePoint {@_} $𝕩, $𝕪, $x, $y, $𝘅, $𝘆));
 }

#-------------------------------------------------------------------------------
# 𝗔rea of a triangle
# 𝗞nown: coordinates of each corner of the triangle
# 𝗙ind: area
# 𝗠ethod: height of one corner from line through other two corners
#-------------------------------------------------------------------------------

sub areaOfTriangle(&$$$$$$)
 {my ($sub, $x, $y, $𝘅, $𝘆, $𝕩, $𝕪) = @_;                                       # Subroutine to process results, coordinates of corners
  @_ == 7 or confess "Wrong number of parameters";
  return &$sub(0) if near($x, $𝘅) && near($y, $𝘆) or near($𝘅, $𝕩) && near($𝘆, $𝕪); # A pair of corners are close, so the area of the triangle must be zero
  my ($d) = unsignedDistanceFromLineToPoint(sub {@_}, $𝘅, $𝘆, $𝕩, $𝕪, $x, $y);  # Distance for first corner from opposite line
  &$sub($d * vectorLength($𝘅, $𝘆, $𝕩, $𝕪)/2)                                    # Area = half base * height
 }

#-------------------------------------------------------------------------------
# 𝗔rea of a polygon
# 𝗞nown: coordinates of each corner=vertex of the polygon
# 𝗙ind: area
# 𝗠ethod: divide the polygon into triangles which all share the first vertex
#-------------------------------------------------------------------------------

sub areaOfPolygon(&@)
 {my ($sub, $x, $y, $𝘅, $𝘆, $𝕩, $𝕪, @vertices) = @_;                            # Subroutine to process results, coordinates of vertices
  my ($area) = areaOfTriangle {@_} $x, $y, $𝘅, $𝘆, $𝕩, $𝕪;                      # Area of first triangle
  for(;scalar @vertices;)                                                       # Each subsequent triangle
   {($𝘅, $𝘆) = ($𝕩, $𝕪);                                                        # Move up one vertex at a time
    ($𝕩, $𝕪) = splice @vertices, 0, 2;                                          # Remove one vertex
    my ($a) = areaOfTriangle {@_} $x, $y, $𝘅, $𝘆, $𝕩, $𝕪;                       # Area of latest triangle
    $area += $a;                                                                # Sum areas
   }
  &$sub($area)                                                                  # Area of polygon
 }

#-------------------------------------------------------------------------------
# 𝗦mallest positive angle made at the intersection of two lines, expressed in degrees
# 𝗞nown: coordinates of start and end of each line segment
# 𝗙ind: smallest angle between the two lines or zero if they do not intersect
# 𝗠ethod: use dot product
#-------------------------------------------------------------------------------

sub smallestPositiveAngleBetweenTwoLines($$$$$$$$)
 {my ($x, $y, $𝘅, $𝘆, $X, $Y, $𝗫, $𝗬) = @_;                                     # Start and end coordinates of two line segments
  my ($𝕩, $𝕪) = ($𝘅 - $x, $𝘆 - $y);                                             # Vector along first line segment
  my ($𝕏, $𝕐) = ($𝗫 - $X, $𝗬 - $Y);                                             # Vector along second line segment
  my $r = acos(($𝕩*$𝕏 + $𝕪*$𝕐) / sqrt(($𝕩*$𝕩+$𝕪*$𝕪) * ($𝕏*$𝕏 + $𝕐*$𝕐)));        # Result in radians
  my $𝗿 = abs(180 * $r / 𝝿());                                                  # Result in positive degrees
  $𝗿 > 90 ? 180 - $𝗿 : $𝗿                                                       # Smallest angle between two lines
 }

#-------------------------------------------------------------------------------
# 𝗜s a triangle equilateral?
# 𝗞nown: coordinates of each corner=vertex of the triangle
# 𝗠ethod: compare lengths of sides
#-------------------------------------------------------------------------------

sub isEquilateralTriangle(@)
 {my ($x, $y, $𝘅, $𝘆, $𝕩, $𝕪) = @_;                                             # Coordinates of vertices
  @_ == 6 or confess "Wrong number of parameters";
  my ($d, $𝗱, $𝕕) = &lengthsOfTheSidesOfAPolygon(@_);                           # Lengths of sides
  near($d, $𝗱) && near($𝗱, $𝕕)                                                  # Equal sided?
 }

#-------------------------------------------------------------------------------
# 𝗜s a triangle isosceles
# 𝗞nown: coordinates of each corner=vertex of the triangle
# 𝗠ethod: compare lengths of sides
#-------------------------------------------------------------------------------

sub isIsoscelesTriangle(@)
 {my ($x, $y, $𝘅, $𝘆, $𝕩, $𝕪) = @_;                                             # Coordinates of vertices
  @_ == 6 or confess "Wrong number of parameters";
  my ($d, $𝗱, $𝕕) = &lengthsOfTheSidesOfAPolygon(@_);                           # Lengths of sides
  near($d, $𝗱) || near($𝗱, $𝕕)  || near($d, $𝕕)                                 # Two sides with equal lengths
 }

#-------------------------------------------------------------------------------
# 𝗜s a right angled triangle
# 𝗞nown: coordinates of each corner=vertex of the triangle
# 𝗠ethod: pythagoras on sides
#-------------------------------------------------------------------------------

sub isRightAngledTriangle(@)
 {my ($x, $y, $𝘅, $𝘆, $𝕩, $𝕪) = @_;                                             # Coordinates of vertices
  @_ == 6 or confess "Wrong number of parameters";
  my ($d, $𝗱, $𝕕) = &lengthsOfTheSidesOfAPolygon(@_);                           # Lengths of sides
  near($d**2,$𝗱**2+$𝕕**2)||near($𝗱**2,$d**2+$𝕕**2) || near($𝕕**2,$d**2+$𝗱**2)   # Pythagoras
 }

#-------------------------------------------------------------------------------
# 𝗘xport details
#-------------------------------------------------------------------------------

require 5;
require Exporter;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

@ISA       = qw(Exporter);

@EXPORT    = qw(exCircles intersectionCircles intersectionCirclesArea
intersectionCircleLine intersectionCircleLineArea intersectionLines
intersectionLinePoint circumCircle circumCentre circleInscribedInTriangle
ninePointCircle areaOfTriangle areaOfPolygon  orthoCentre centroid
isEquilateralTriangle isIsoscelesTriangle isRightAngledTriangle);

@EXPORT_OK = qw(midPoint near near2 near3 near4 rotate90CW rotate90CCW
rotate90AroundMidPoint vectorLength 𝝿 lengthsOfTheSidesOfAPolygon
threeCollinearPoints smallestPositiveAngleBetweenTwoLines);

$EXPORT_TAGS{all} = [@EXPORT, @EXPORT_OK];

=head1 Description

 Find the points at which circles and lines intersect to test geometric
 intuition.

 Fast, fun and easy to use these functions are written in 100% Pure Perl.

=head2 areaOfTriangle 𝘀𝘂𝗯 triangle

 Calls 𝘀𝘂𝗯($a) where $a is the area of the specified triangle:

 A triangle is specified by supplying a list of six numbers:

  (x, y, 𝘅, 𝘆, 𝕩, 𝕪)

 where (x, y), (𝘅, 𝘆) and (𝕩, 𝕪) are the coordinates of the vertices of the
 triangle.

=head2 areaOfPolygon 𝘀𝘂𝗯 points...

 Calls 𝘀𝘂𝗯($a) where $a is the area of the polygon with vertices specified by
 the points.

 A point is specified by supplying a list of two numbers:

  (𝘅, 𝘆)

=head2 centroid 𝘀𝘂𝗯 triangle

 Calls 𝘀𝘂𝗯($x,$y) where $x,$y are the coordinates of the centroid of the
 specified triangle:

 See: L<https://en.wikipedia.org/wiki/Centroid>

 A triangle is specified by supplying a list of six numbers:

  (x, y, 𝘅, 𝘆, 𝕩, 𝕪)

 where (x, y), (𝘅, 𝘆) and (𝕩, 𝕪) are the coordinates of the vertices of the
 triangle.

=head2 circumCentre 𝘀𝘂𝗯 triangle

 Calls 𝘀𝘂𝗯($x,$y,$r) where $x,$y are the coordinates of the centre of the
 circle drawn through the corners of the specified triangle and $r is its
 radius:

 See: L<https://en.wikipedia.org/wiki/Circumscribed_circle>

 A triangle is specified by supplying a list of six numbers:

  (x, y, 𝘅, 𝘆, 𝕩, 𝕪)

 where (x, y), (𝘅, 𝘆) and (𝕩, 𝕪) are the coordinates of the vertices of the
 triangle.

=head2 circumCircle 𝘀𝘂𝗯 triangle

 Calls 𝘀𝘂𝗯($x,$y,$r) where $x,$y are the coordinates of the circumcentre of
 the specified triangle and $r is its radius:

 See: L<https://en.wikipedia.org/wiki/Circumscribed_circle>

 A triangle is specified by supplying a list of six numbers:

  (x, y, 𝘅, 𝘆, 𝕩, 𝕪)

 where (x, y), (𝘅, 𝘆) and (𝕩, 𝕪) are the coordinates of the vertices of the
 triangle.

=head2 exCircles 𝘀𝘂𝗯 triangle

 Calls 𝘀𝘂𝗯([$x,$y,$r]...) where $x,$y are the coordinates of the centre of each
 ex-circle and $r its radius for the specified triangle:

 See: L<https://en.wikipedia.org/wiki/Incircle_and_excircles_of_a_triangle>

 A triangle is specified by supplying a list of six numbers:

  (x, y, 𝘅, 𝘆, 𝕩, 𝕪)

 where (x, y), (𝘅, 𝘆) and (𝕩, 𝕪) are the coordinates of the vertices of the
 triangle.

=head2 circleInscribedInTriangle 𝘀𝘂𝗯 triangle

 Calls 𝘀𝘂𝗯($x,$y,$r) where $x,$y are the coordinates of the centre of
 a circle which touches each side of the triangle just once and $r is its radius:

 See: L<https://en.wikipedia.org/wiki/Incircle_and_excircles_of_a_triangle#Incircle>

 A triangle is specified by supplying a list of six numbers:

  (x, y, 𝘅, 𝘆, 𝕩, 𝕪)

 where (x, y), (𝘅, 𝘆) and (𝕩, 𝕪) are the coordinates of the vertices of the
 triangle.

=head2 intersectionCircles 𝘀𝘂𝗯 circle1, circle2

 Find the points at which two circles intersect.  Complains if the two circles
 are identical.

  𝘀𝘂𝗯 specifies a subroutine to be called with the coordinates of the
 intersection points if there are any or an empty parameter list if there are
 no points of intersection.

 A circle is specified by supplying a list of three numbers:

  (𝘅, 𝘆, 𝗿)

 where (𝘅, 𝘆) are the coordinates of the centre of the circle and (𝗿) is its
 radius.

 Returns whatever is returned by 𝘀𝘂𝗯.

=head2 intersectionCirclesArea 𝘀𝘂𝗯 circle1, circle2

 Find the area of overlap of two circles expressed as a fraction of the area of
 the smallest circle. The fractional area is expressed as a number between 0
 and 1.

 𝘀𝘂𝗯 specifies a subroutine to be called with the fractional area.

 A circle is specified by supplying a list of three numbers:

  (𝘅, 𝘆, 𝗿)

 where (𝘅, 𝘆) are the coordinates of the centre of the circle and (𝗿) is its
 radius.

 Returns whatever is returned by 𝘀𝘂𝗯.

=head2 intersectionCircleLine 𝘀𝘂𝗯 circle, line

 Find the points at which a circle and a line intersect.

  𝘀𝘂𝗯 specifies a subroutine to be called with the coordinates of the
 intersection points if there are any or an empty parameter list if there are
 no points of intersection.

 A circle is specified by supplying a list of three numbers:

  (𝘅, 𝘆, 𝗿)

 where (𝘅, 𝘆) are the coordinates of the centre of the circle and (𝗿) is its
 radius.

 A line is specified by supplying a list of four numbers:

  (x, y, 𝘅, 𝘆)

 where (x, y) and (𝘅, 𝘆) are the coordinates of two points on the line.

 Returns whatever is returned by 𝘀𝘂𝗯.

=head2 intersectionCircleLineArea 𝘀𝘂𝗯 circle, line

 Find the fractional area of a circle occupied by a lune produced by an
 intersecting line. The fractional area is expressed as a number
 between 0 and 1.

  𝘀𝘂𝗯 specifies a subroutine to be called with the fractional area.

 A circle is specified by supplying a list of three numbers:

  (𝘅, 𝘆, 𝗿)

 where (𝘅, 𝘆) are the coordinates of the centre of the circle and (𝗿) is its
 radius.

 A line is specified by supplying a list of four numbers:

  (x, y, 𝘅, 𝘆)

 where (x, y) and (𝘅, 𝘆) are the coordinates of two points on the line.

 Returns whatever is returned by 𝘀𝘂𝗯.

=head2 intersectionLines 𝘀𝘂𝗯 line1, line2

 Finds the point at which two lines intersect.

  𝘀𝘂𝗯 specifies a subroutine to be called with the coordinates of the
 intersection point or an empty parameter list if the two lines do not
 intersect.

 Complains if the two lines are collinear.

 A line is specified by supplying a list of four numbers:

  (x, y, 𝘅, 𝘆)

 where (x, y) and (𝘅, 𝘆) are the coordinates of two points on the line.

 Returns whatever is returned by 𝘀𝘂𝗯.

=head2 intersectionLinePoint 𝘀𝘂𝗯 line, point

 Find the point on a line closest to a specified point.

  𝘀𝘂𝗯 specifies a subroutine to be called with the coordinates of the
 intersection points if there are any.

 A line is specified by supplying a list of four numbers:

  (x, y, 𝘅, 𝘆)

 where (x, y) and (𝘅, 𝘆) are the coordinates of two points on the line.

 A point is specified by supplying a list of two numbers:

  (𝘅, 𝘆)

 where (𝘅, 𝘆) are the coordinates of the point.

 Returns whatever is returned by 𝘀𝘂𝗯.

=head2 isEquilateralTriangle triangle

 Return true if the specified triangle is close to being equilateral within the
 definition of nearness.

 A triangle is specified by supplying a list of six numbers:

  (x, y, 𝘅, 𝘆, 𝕩, 𝕪)

 where (x, y), (𝘅, 𝘆) and (𝕩, 𝕪) are the coordinates of the vertices of the
 triangle.

=head2 isIsoscelesTriangle triangle

 Return true if the specified triangle is close to being isosceles within the
 definition of nearness.

 A triangle is specified by supplying a list of six numbers:

  (x, y, 𝘅, 𝘆, 𝕩, 𝕪)

 where (x, y), (𝘅, 𝘆) and (𝕩, 𝕪) are the coordinates of the vertices of the
 triangle.

=head2 isRightAngledTriangle triangle

 Return true if the specified triangle is close to being right angled within
 the definition of nearness.

 A triangle is specified by supplying a list of six numbers:

  (x, y, 𝘅, 𝘆, 𝕩, 𝕪)

 where (x, y), (𝘅, 𝘆) and (𝕩, 𝕪) are the coordinates of the vertices of the
 triangle.

=head2 ninePointCircle 𝘀𝘂𝗯 triangle

 Calls 𝘀𝘂𝗯($x,$y,$r) where $x,$y are the coordinates of the centre of the
 circle drawn through the midpoints of each side of the specified triangle and
 $r is its radius which gives the nine point circle:

 See: L<https://en.wikipedia.org/wiki/Nine-point_circle>

 A triangle is specified by supplying a list of six numbers:

  (x, y, 𝘅, 𝘆, 𝕩, 𝕪)

 where (x, y), (𝘅, 𝘆) and (𝕩, 𝕪) are the coordinates of the vertices of the
 triangle.

=head2 orthoCentre 𝘀𝘂𝗯 triangle

 Calls 𝘀𝘂𝗯($x,$y) where $x,$y are the coordinates of the orthocentre of the
 specified triangle:

 See: L<https://en.wikipedia.org/wiki/Altitude_%28triangle%29>

 A triangle is specified by supplying a list of six numbers:

  (x, y, 𝘅, 𝘆, 𝕩, 𝕪)

 where (x, y), (𝘅, 𝘆) and (𝕩, 𝕪) are the coordinates of the vertices of the
 triangle.

=head2 $Math::Intersection::Circle::Line::near

 As a finite computer cannot represent an infinite plane of points it is
 necessary to make the plane discrete by merging points closer than the
 distance contained in this variable, which is set by default to 1e-6.

=head1 Exports

 The following functions are exported by default:

=over

=item C<areaOfPolygon()>

=item C<areaOfTriangle()>

=item C<centroid()>

=item C<circumCentre()>

=item C<circumCircle()>

=item C<circleInscribedInTriangle()>

=item C<circleThroughMidPointsOfTriangle()>

=item C<exCircles()>

=item C<intersectionCircleLine()>

=item C<intersectionCircleLineArea()>

=item C<intersectionCircles()>

=item C<intersectionCircles()>

=item C<intersectionCirclesArea()>

=item C<intersectionLines()>

=item C<intersectionLinePoint()>

=item C<isEquilateralTriangle()>

=item C<isIsoscelesTriangle()>

=item C<isRightAngledTriangle()>

=item C<orthoCentre()>

=back

 Optionally some useful helper functions can also be exported either by
 specifying the tag :𝗮𝗹𝗹 or by naming the required functions individually:

=over

=item C<acos()>

=item C<lengthsOfTheSidesOfAPolygon()>

=item C<midPoint()>

=item C<midPoint()>

=item C<near()>

=item C<near2()>

=item C<near3()>

=item C<near4()>

=item C<rotate90CW()>

=item C<rotate90CCW()>

=item C<rotate90AroundMidPoint()>

=item C<smallestPositiveAngleBetweenTwoLines()>

=item C<threeCollinearPoints()>

=item C<vectorLength()>

=item C<𝝿()>

=back

=head1 Changes

 1.003 Sun 30 Aug 2015 - Started Geometry app
 1.005 Sun 20 Dec 2015 - Still going!
 1.006 Sat 02 Jan 2016 - Euler's line divided into 6 equal pieces
 1.007 Sat 02 Jan 2016 - [rt.cpan.org #110849] Test suite fails with uselongdouble
 1.008 Sun 03 Jan 2016 - [rt.cpan.org #110849] Removed dump

=cut

$VERSION   = '1.008';

=pod

=head1 Installation

 Standard Module::Build process for building and installing modules:

   perl Build.PL
   ./Build
   ./Build test
   ./Build install

 Or, if you're on a platform (like DOS or Windows) that doesn't require
 the "./" notation, you can do this:

   perl Build.PL
   Build
   Build test
   Build install

=head1 Author

 Philip R Brenan at gmail dot com

 http://www.appaapps.com

=head1 Copyright

 Copyright (c) 2016 Philip R Brenan.

 This module is free software. It may be used, redistributed and/or
 modified under the same terms as Perl itself.

=cut
