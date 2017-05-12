#!perl -I../lib
use Math::Intersection::Circle::Line q(:all);
use Test::More tests=>407;
use warnings FATAL => q(all);
use strict;
use utf8;

#-------------------------------------------------------------------------------
# Useful values
#-------------------------------------------------------------------------------

my $f = sqrt(5);
my $h = sqrt(1/2);
my $t = sqrt(3);

#-------------------------------------------------------------------------------
# Tests
#-------------------------------------------------------------------------------

# Useful functions
ok $Math::Intersection::Circle::Line::near;
 {local $Math::Intersection::Circle::Line::near = 10;
	ok near(1);
 }
ok near(0);
ok near(1,1);
ok near2(0,0);
ok near3(0,0,0);
ok near4(0,0,0,0);
ok near2(0,1,0,1);
ok near3(0,1,2,0,1,2);
ok near4(0,1,2,3,0,1,2,3);
ok 5 == vectorLength(3, 4);

ok &near4(lengthsOfTheSidesOfAPolygon(0,0, 1,0, 1,1, 0,1), 1, 1, 1, 1);

ok  threeCollinearPoints(0,1, 0,2, 0,3);
ok  threeCollinearPoints(1,1, 2,2, 3,3);
ok  threeCollinearPoints(1,1, 2,1, 3,1);
ok !threeCollinearPoints(1,1, 2,2, 2,3);
ok  threeCollinearPoints(1,1, 2,2, 2,2);
ok !threeCollinearPoints(2,2+0.01, 2,2-0.01, 2+0.01,2-0.01);
ok  threeCollinearPoints(-9,-9,  1,1,  0,0);

ok "@{[midPoint(-2, -1, 4, 3)]}" eq "1 1";
ok "@{[rotate90CW(-1,  1)]}" eq "1 1";
ok "@{[rotate90CCW(1, -1)]}" eq "1 1";
ok "@{[&rotate90CCW(rotate90CW(11,12))]}" eq "11 12";
ok "@{[rotate90AroundMidPoint(-1, -1, 1, 1)]}" eq "-1 1 1 -1";
ok "@{[rotate90AroundMidPoint( 0, -1, 0, 1)]}" eq "-1 0 1 0";

# Circle/Circle
# Two identical
intersectionCircles{ok($_[0] =~ /Duplicate circles/)} 1, 1, 1,   1, 1, 1;

# No intersection
intersectionCircles{ok($_[0] =~ /No intersection/)} 1, 2, 1,   1,  2, 2;        # Concentric - no parameters passed in
intersectionCircles{ok($_[0] =~ /No intersection/)} 1, 1, 1,  -1, -1, 1;
intersectionCircles{ok($_[0] =~ /No intersection/)} 0, 0, 1,   0,  0, 2;
# Centre of one outside other
intersectionCircles{ok &near2(@_, 0, 0)} -1, 0, 1,  1,  0, 1;
intersectionCircles{ok &near2(@_, 0, 0)}  0, 1, 1,  0, -1, 1;
intersectionCircles{ok &near4(@_, 0, +$t, 0, -$t)} -1, 0, 2,  1,  0, 2;
intersectionCircles{ok &near4(@_, 0, -$t, 0, +$t)} +1, 0, 2, -1,  0, 2;
intersectionCircles{ok &near4(@_, 0, 2, 2, 0)}      0, 0, 2,  2,  2, 2;
intersectionCircles{ok &near4(@_, 2, 0, 0, 2)}      2, 2, 2,  0,  0, 2;
# Centre of one inside other
intersectionCircles{ok &near2(@_, 0, 0)} 0, 2, 2, 0, 1, 1;                      # Low y
intersectionCircles{ok &near2(@_, 0, 4)} 0, 2, 2, 0, 3, 1;                      # High y
intersectionCircles{ok &near2(@_, 0, 0)} 2, 0, 2, 1, 0, 1;                      # Low x
intersectionCircles{ok &near2(@_, 4, 0)} 2, 0, 2, 3, 0, 1;                      # High x

intersectionCircles{ok &near4(@_, 1, 0, 0, 1)} 2, 2, $f,  0,  0, 1;             # Outside
intersectionCircles{ok &near4(@_, 1, 0, 0, 1)} 2, 2, $f,  1,  1, 1;             # Inside
intersectionCircles{ok &near4(@_, 0, 3, 1, 4)} 2, 2, $f,  1,  3, 1;             # Inside
intersectionCircles{ok &near4(@_, 3, 4, 4, 3)} 2, 2, $f,  3,  3, 1;             # Inside
intersectionCircles{ok &near4(@_, 4, 1, 3, 0)} 2, 2, $f,  3,  1, 1;             # Inside

# Line, Point

intersectionLinePoint{ok &near2(@_, 0, 0)} -9,  -9,  1,  1,  0,  0;             # On top

intersectionLinePoint{ok &near2(@_, 2, 1)} -9,  1,  9,  1,  2,  2;              # Inside
intersectionLinePoint{ok &near2(@_, 0, 0)} -9, -9,  1,  1,  1, -1;
intersectionLinePoint{ok &near2(@_, 0, 0)} -1,  1,  9, -9,  1,  1;

intersectionLinePoint{ok &near2(@_, 2, 1)} -9,  1, -8,  1,  2,  2;              # Outside
intersectionLinePoint{ok &near2(@_, 0, 0)} -9, -9, -8, -8,  1, -1;
intersectionLinePoint{ok &near2(@_, 0, 0)} -1,  1, -9,  9,  1,  1;

intersectionLinePoint{ok &near2(@_, -9, 0)} -1, 0, 1, 0, -9, 0;
                                                                                # Collinear possibilities
intersectionLinePoint{ok &near2(@_, 0,   0)} -1,0, 1,0,  0,  0;                 # Centre
intersectionLinePoint{ok &near2(@_, 0.5, 0)} -1,0, 1,0,  0.5,0;                 # Centre right
intersectionLinePoint{ok &near2(@_,-0.5, 0)} -1,0, 1,0, -0.5,0;                 # Centre left

intersectionLinePoint{ok &near2(@_,-1,   0)} -1,0, 1,0,  -1,0;                  # Left end
intersectionLinePoint{ok &near2(@_,-2,   0)} -1,0, 1,0,  -2,0;                  # Left

intersectionLinePoint{ok &near2(@_, 1,   0)} -1,0, 1,0,  +1,0;                  # Right end
intersectionLinePoint{ok &near2(@_, 2,   0)} -1,0, 1,0,  +2,0;                  # Right

# Lines
intersectionLines{ok($_[0] =~ /Parallel lines/)} -1, 0,  0, 0,  -9, 0, -8, 0;
intersectionLines{ok($_[0] =~ /Parallel lines/)} -1, 1,  1, 1,   0, 0,  1, 0;
intersectionLines{ok($_[0] =~ /Parallel lines/)}  0, 0,  2, 1,   0, 1,  2, 2;

intersectionLines{ok &near2(@_, 1, 0)} 0, 1, 1, 0,  1, 0, 0, -1;                # Line segment points coincide

intersectionLines{ok &near2(@_, 0, 0)} -1,  1,  1, -1,   -1, -1,  1,  1;
intersectionLines{ok &near2(@_, 0, 0)} -1, -1,  1,  1,   -1,  1,  1, -1;

intersectionLines{ok &near2(@_, 1, 1)}  0,  0,  2,  2,   0,  2,  2, 0;
intersectionLines{ok &near2(@_, 2, 2)}  1,  1,  3,  3,   1,  3,  3, 1;

intersectionLines{ok &near2(@_, 1, 1/2)}  0,  0,  2,  1,   0,  1,  2, 0;
intersectionLines{ok &near2(@_, 1, 1)  }  0,  0,  2,  2,   0,  2,  2, 0;
intersectionLines{ok &near2(@_, 1.5, 3/4)}  0,  0,  2,  1,   1,  1,  3, 0;
intersectionLines{ok &near2(@_, 1.5, 3/4)}  2,  1,  0,  0,   3,  0,  1, 1;
intersectionLines{ok &near2(@_, 1.5, 3/4)}  0,  0,  2,  1,   1,  1,  3, 0;
intersectionLines{ok &near2(@_, 2/3, 1/3)}  0,  0,  2,  1,   0,  1,  1, 0;

# Circle/Line
intersectionCircleLine {ok &near2(@_)} 0, 0, 0,  0, 1,  0, 0;
ok ((eval {intersectionCircleLine {1} 0, 0, 1,  0, 0,  0, 0} || $@) =~ /Points on line are too close!/);

# On top
intersectionCircleLine {ok &near4(@_,  0,   1,  0,  -1)}          0,   0,   1,    0,  0,   0,  1;
intersectionCircleLine {ok &near4(@_,  1,   0, -1,   0)}          0,   0,   1,    0,  0,   1,  0;

intersectionCircleLine {ok &near2(@_,  0,   1)}                   0,   0,   1,   -1,  1,   1,  1;
intersectionCircleLine {ok &near4(@_, $h, -$h,   -$h,  $h  )}     0,   0,   1,   -1,  1,   1, -1;
intersectionCircleLine {ok &near4(@_,  2,   1,     0,   1  )}     1,   1,   1,   -1,  1,   1,  1;
intersectionCircleLine {ok &near4(@_,  1,   2,     1,   0  )}     1,   1,   1,    1,  0,   1,  1;
intersectionCircleLine {ok &near4(@_, -0.5, 0,     0.5, 0)}       0, -$t/2, 1,   -1,  0,   1,  0;
intersectionCircleLine {ok &near4(@_,  0,   0.5,   0,  -0.5)} -$t/2,   0,   1,    0, -1,   0,  1;
intersectionCircleLine {ok &near4(@_, 18,   0,     0,   0  )}     9,   0,   9,    0,  0,   1,  0;
intersectionCircleLine {ok &near4(@_,  0,  18,     0,   0  )}     0,   9,   9,    0,  0,   0,  1;
intersectionCircleLine {ok($_[0]=~/No intersection!/)}            0,   0,   1,   -2,  2,   2,  2;

# Area of intersection of two circles
intersectionCirclesArea {ok 0 == $_[0]} 0,0,1, 2,0,1;
intersectionCirclesArea {ok 1 == $_[0]} 0,0,1, 0,0,2;
intersectionCirclesArea {ok 1 == $_[0]} 0,0,1, 0,0,1;
intersectionCirclesArea {ok 1 == $_[0]} 0,0,2, 0,0,1;

intersectionCirclesArea {ok near 0.391002218955771, $_[0]} 0,0,1, 0,1,1;        # Half way
intersectionCirclesArea {ok near 0.464533102441601, $_[0]} 0,0,1, 3,0,3;
intersectionCirclesArea {ok near 0.5,               $_[0]} 0,0,1, 1e6,0,1e6;

intersectionCirclesArea {ok near 0.144293612814387, $_[0]} 0,0,1, 1+1/2,0,1;    # Quarter way
intersectionCirclesArea {ok near 0.166291228579923, $_[0]} 0,0,1, 2+1/2,0,2;
intersectionCirclesArea {ok near 0.175016357257398, $_[0]} 0,0,1, 3+1/2,0,3;

# Area of a lune

intersectionCircleLineArea {ok near $_[0], 0.5} 0, 0, 1,  -1,  0,   1,  0;
intersectionCircleLineArea {ok near $_[0], 0.5} 0, 0, 2,  -1,  1,   1, -1;
intersectionCircleLineArea {ok near $_[0], 0}   0, 0, 2,  -1,  2,   1,  2;
intersectionCircleLineArea {ok near $_[0], 0}   0, 0, 2,  -1, -2,   1, -2;
intersectionCircleLineArea {ok near $_[0], 0}   0, 0, 2,  -1, -9,   1, -9;

intersectionCircleLineArea {ok near $_[0], 0.252315787734345} 0, 0, 10,  -1,  4,  1,  4;
intersectionCircleLineArea {ok near $_[0], 0.252315787734345} 0, 0, 10,  -1, -4,  1, -4;

 {my @a = qw(0.5 0.436758652254219 0.37595360216027 0.319618195367086 0.269119028690608 0.225092427876051 0.187548298237462 0.156058330518233 0.129950172265672 0.108462074342535 0.0908450569081047 0.0764190428332745 0.0645962159595361 0.0548843436401053 0.0468795700937104 0.0402547866492494 0.0347470614854018 0.0301458791266196 0.0262829117617124 0.0230234889082072 0.020259663176917);
  intersectionCircleLineArea {ok near $_[0], $a[$_]} 0, 0, 10,  0,  $_,  10, 0 for 0..$#a;
  intersectionCircleLineArea {ok near $_[0], $a[$_]} 0, 0, 10,  0, -$_,  10, 0 for 0..$#a;
 }

# Circle through three points

circumCircle {ok &near3(@_, 1, 0, 1)}  0, 0, 1, 1,  1, -1;

# Circle inscribed in a triangle

circleInscribedInTriangle {ok &near3(@_, 0.585786437626905, 0, 0.414213562373095)}  0, 0, 1, 1,  1, -1;

# Circle through the midpoints of each side of a triangle

ninePointCircle{ok &near3(@_, 0.5, 0, 0.5)}                    0, 0, 1, 1,  1, -1;
ninePointCircle{ok &near3(@_, 0.75, 0.25, 0.353553390593274)}  0, 0, 1, 1,  1, 0;

# Area of triangle

areaOfTriangle {ok &near(@_, 0.5)}  1,2,  2,3,  2,2;
areaOfTriangle {ok &near(@_, 1)}    1,2,  2,3,  2,1;
areaOfTriangle {ok &near(@_, 1)}    1,2,  2,3,  3,2;
areaOfTriangle {ok &near(@_)}       0,0, 0,0, 0,0;                              # Zero because collinear
areaOfTriangle {ok &near(@_)}       0,1, 0,2, 0,3;
areaOfTriangle {ok &near(@_)}       0,0, 0,10, 0,100;
areaOfTriangle {ok &near(@_)}       0,0,  0,0,  0,0;
areaOfTriangle {ok &near(@_)}       0,0,  1,1,  0.01,0.01;
areaOfTriangle {ok &near(@_)}       0,0,  1,1,  1.01,1.01;

# Area of polygon

&areaOfPolygon (sub{ok &near(@_, 0.5)}  , 1,2,  2,3,  2,2);
&areaOfPolygon (sub{ok &near(@_, 1)}    , 0,0,  1,0,  1,1,  0,1);
&areaOfPolygon (sub{ok &near(@_, 4)}    , 1,0,  1,1,  0,1, -1,1, -1,0, -1,-1, 0,-1, 1,-1);

# Angle between two lines

ok near(90, smallestPositiveAngleBetweenTwoLines(0, 0, 0, 1,  0, 0,  1, 0));
ok near(90, smallestPositiveAngleBetweenTwoLines(0, 0, 1, 1,  0, 0, -1, 1));
ok near(45, smallestPositiveAngleBetweenTwoLines(0, 0, 1, 1,  1, 1,  0, 1));
ok near(60, smallestPositiveAngleBetweenTwoLines(0, 0, 1, 0,  1, 0,  0, sqrt(3)));
ok near(30, smallestPositiveAngleBetweenTwoLines(0, 0, 0, sqrt(3),  0, sqrt(3), 1, 0));

# Triangle types

ok isEquilateralTriangle(-1,0, 1,0, 0,sqrt(3));
ok isIsoscelesTriangle(1,1, 3,1, 2,1+sqrt(3));
ok isIsoscelesTriangle(1,1, 3,1, 2,12);
ok isRightAngledTriangle(0,0, 0,3, 4,0);

# Documentation tests

# Euler Line, see: https://en.wikipedia.org/wiki/Euler_line

if (1)
 {my @t = (0, 0, 4, 0, 0, 3);                                                   # Corners of the triangle
  &areaOfPolygon(sub {ok !$_[0]},                                               # Polygon formed by these points has zero area and so is a line or a point
    &circumCircle   (sub {@_[0,1]}, @t),                                        # green
    &ninePointCircle(sub {@_[0,1]}, @t),                                        # red
    &orthoCentre    (sub {@_[0,1]}, @t),                                        # blue
    &centroid       (sub {@_[0,1]}, @t));                                       # orange
 }

if (1)
 {my $𝗻 = 20; my $𝗿 = 10;                                                       # Number of trials, radius
  for(1..$𝗻-1)
   {my $a = $_ * 𝝿()/$𝗻;
    my $y = $𝗿 * sin($_ * 𝝿()/$𝗻);
    my @t = (-1, 0, 1, 0, $𝗿*cos($a), $𝗿*sin($a));                              # Corners of the triangle

    my $p;                                                                      # Save the points - see https://en.wikipedia.org/wiki/Euler_line#/media/File:Triangle.EulerLine.svg
    @{$p->[0]} = &circumCircle   (sub {@_[0,1]}, @t);                           # green
    @{$p->[1]} = &ninePointCircle(sub {@_[0,1]}, @t);                           # red
    @{$p->[2]} = &orthoCentre    (sub {@_[0,1]}, @t);                           # blue
    @{$p->[3]} = &centroid       (sub {@_[0,1]}, @t);                           # orange

    &areaOfPolygon(sub {ok !$_[0]}, map {@$_} @$p);                             # Polygon formed by these points has zero area and so is a line or a point

    for   my $i(   0..$#$p)
     {for my $j($i+1..$#$p)
       {ok !&near2(@{$p->[$i]}, @{$p->[$j]});                                   # However in the triangles tested (non equilateral) the points are pairwise distinct
       }
     }
   }
 }

# The Euler line for an equilateral triangle is a single point

if (1)
 {my @t = (-1, 0, 1, 0, 0, sqrt(3));                                            # Corners of the equilateral triangle
  my $p;                                                                        # Save the points
  @{$p->[0]} = &circumCircle   (sub {@_[0,1]}, @t);                             # green
  @{$p->[1]} = &ninePointCircle(sub {@_[0,1]}, @t);                             # red
  @{$p->[2]} = &orthoCentre    (sub {@_[0,1]}, @t);                             # blue
  @{$p->[3]} = &centroid       (sub {@_[0,1]}, @t);                             # orange

  for   my $i(0..$#$p)
   {for my $j(0..$#$p)
     {ok &near2(@{$p->[$i]}, @{$p->[$j]});                                      # All the points are identical for an equilateral triangle
     }
   }
 }

# An isosceles tringle with an apex height of 3/4 of the radius of its
# circumcircle divides Euler's line into 6 equal pieces

if (1)
 {my $r = 400;                                                                  # Arbitrary but convenient radius
  intersectionCircleLine                                                        # Find coordinates of equiangles of isosceles triangle
   {my ($x, $y, $𝕩, $𝕪) = @_;                                                   # Coordinates of equiangles
    my ($𝘅, $𝘆) = (0, $r);                                                      # Coordinates of apex
    my ($nx, $ny, $nr) = ninePointCircle {@_} $x, $y, $𝘅, $𝘆, $𝕩, $𝕪;           # Coordinates of centre and radius of nine point circle
    my ($cx, $cy)      = centroid        {@_} $x, $y, $𝘅, $𝘆, $𝕩, $𝕪;           # Coordinates of centroid
    my ($ox, $oy)      = orthoCentre     {@_} $x, $y, $𝘅, $𝘆, $𝕩, $𝕪;           # Coordinates of orthocentre
                                                                                # Six equally spaced points along Euler's line
    ok near(100, $y);                                                           # Circumcentre to base of triangle
    ok near(200, $cy);                                                          # Circumcentre to lower circumference of nine point circle
    ok near(300, $y+$nr);                                                       # Circumcentre to centre of nine point circle
    ok near(400, $𝘆);                                                           # Circumcentre to apex of isosceles triangle
    ok near(500, $y+2*$nr);                                                     # Circumcentre to upper circumference of nine point circle
    ok near(600, $oy);                                                          # Circumcentre to orthocentre

    ok near(37.761243907035, smallestPositiveAngleBetweenTwoLines               # Equiangle of isosceles triangle
     ($x, $y, 0, $r,  0, $r, $𝕩, $𝕪)/2);

    if (1)                                                                      # Check that the CircumCircle, ninepointCircle and Altitude all intersect at the same point
     {my ($x11, $y11, $x12, $y12) = intersectionCircles   (sub{@_}, 0, 0, $r, $nx, $ny, $nr);
      my ($x21, $y21, $x22, $y22) = intersectionCircleLine(sub{@_}, 0, 0, $r, $x, $y, $ox, $oy);
      my ($x31, $y31, $x32, $y32) = intersectionCircleLine(sub{@_}, $nx, $ny, $nr, $x, $y, $ox, $oy);

      if    (near2($x11, $y11, $x21, $y21) or near2($x11, $y11, $x22, $y22))
       {ok  (near2($x11, $y11, $x31, $y31) or near2($x11, $y11, $x32, $y32))
       }
      elsif (near2($x12, $y12, $x21, $y21) or near2($x12, $y12, $x22, $y22))
       {ok  (near2($x12, $y12, $x31, $y31) or near2($x12, $y12, $x32, $y32))
       }
      else {ok 0}
     }

   } 0, 0, $r,  0, $r/4, 1, $r/4;                                               # Chord at 1/4 radius to start layout of reference triangle
 }

# The triplex

if (1)
 {my @l = (0, +1); my @𝗹 = (1, +1);                                             # Line 1
  my @L = (0, -1); my @𝗟 = (2, -1);                                             # Line 2
  my $n = 10;                                                                   # Number of tests
  for(1..$n)
   {my ($x, $y, $dx, $dy) = (@l, @l );                                          # Positions on line 1
    my ($𝘅, $𝘆) = ($x+$dx, $y+$dy);
    my ($𝕩, $𝕪) = ($𝘅+$_*$dx, $𝘆+$_*$dy);

    my ($X, $Y, $dX, $dY) = (@L, @𝗟);                                           # Positions on line 2
    my ($𝗫, $𝗬) = ($X+   $dX, $Y+   $dY);
    my ($𝕏, $𝕐) = ($𝗫+$_*$dX, $𝗬+$_*$dY);

    &areaOfPolygon(sub {ok !$_[0]},                                             # Intersections are collinear
      &intersectionLines(sub{@_}, $x, $y, $𝗫, $𝗬, $X, $Y, $𝘅, $𝘆),
      &intersectionLines(sub{@_}, $x, $y, $𝕏, $𝕐, $X, $Y, $𝕩, $𝕪),
      &intersectionLines(sub{@_}, $𝘅, $𝘆, $𝕏, $𝕐, $𝗫, $𝗬, $𝕩, $𝕪));
   }
 }

# A line between the centres of the ex-circles intersects a corner of the reference triangle

if (1)
 {my $𝗻 = 20; my $𝗿 = 10;                                                       # Number of trials, radius
  for(1..$𝗻-1)
   {my $a = $_ * 𝝿()/$𝗻;
    my $y = $𝗿 * sin($_ * 𝝿()/$𝗻);
    my @t = ([-1, 0], [1, 0], [$𝗿*cos($a), $𝗿*sin($a)]);                        # Corners of the triangle
    my @e = &exCircles(sub{@_}, map {@$_} @t);
    &areaOfTriangle(sub{ok &near(@_)}, @{$t[1]}, $e[0][0], $e[0][1], $e[2][0], $e[2][1]);
    &areaOfTriangle(sub{ok &near(@_)}, @{$t[2]}, $e[1][0], $e[1][1], $e[0][0], $e[0][1]);
    &areaOfTriangle(sub{ok &near(@_)}, @{$t[0]}, $e[2][0], $e[2][1], $e[1][0], $e[1][1]);
   }
 }

# A line across a circle is never longer than a diameter

if (1)                                                                          # Random circle and random line
 {my ($x, $y, $r, $𝘅, $𝘆, $𝕩, $𝕪) = map {rand()} 1..7;
  intersectionCircleLine                                                        # Find intersection of a circle and a line
   {return ok 1 unless @_ == 4;                                                 # Ignore line unless it crosses circle
    ok &vectorLength(@_) <= 2*$r;                                               # Length if line segment is less than or equal to that of a diameter
	 } $x, $y, $r, $𝘅, $𝘆, $𝕩, $𝕪;                                                # Circle and line to be intersected
 }

# The length of a side of a hexagon is the radius of a circle inscribed through
# its vertices

if (1)
 {my ($x, $y, $r) = map {rand()} 1..3;                                          # Random circle
  my @p = intersectionCircles {@_} $x, $y, $r, $x+$r, $y, $r;                   # First step of one radius
	my @𝗽 = intersectionCircles {@_} $x, $y, $r, $p[0], $p[1], $r;                # Second step of one radius
	my @q = !&near($x+$r, $y, @𝗽[0,1]) ? @𝗽[0,1] : @𝗽[2,3];                       # Away from start point
	my @𝗾 = intersectionCircles {@_} $x, $y, $r, $q[0], $q[1], $r;                # Third step of one radius
  ok &near2(@𝗾[0,1], $x-$r, $y) or                                              # Brings us to a point
     &near2(@𝗾[2,3], $x-$r, $y);                                                # opposite to the start point
 }

# Circle through three points chosen at random has the same centre regardless of
# the pairing of the points

sub circleThrough3
 {my ($x, $y, $𝘅, $𝘆, $𝕩, $𝕪) = @_;                                             # Three points
	&intersectionLines
	 (sub                                                                         # Intersection of bisectors is the centre of the circle
	   {my @r =(&vectorLength(@_, $x, $y),                                        # Radii from centre of circle to each point
	            &vectorLength(@_, $𝘅, $𝘆),
	            &vectorLength(@_, $𝕩, $𝕪));
	    ok &near(@r[0,1]);                                                        # Check radii are equal
	    ok &near(@r[1,2]);
      @_                                                                        # Return centre
		 }, rotate90AroundMidPoint($x, $y, $𝘅, $𝘆),                                 # Bisectors between pairs of points
		    rotate90AroundMidPoint($𝕩, $𝕪, $𝘅, $𝘆));
 }

if (1)
 {my (@points) = map {1000 * rand()} 1..6;                                      # Three points chosen at random
  if (&threeCollinearPoints(@points)) {ok 1; ok 1;}                             # Avoid three collinear points
  else
   {ok &near2(circleThrough3(@points), circleThrough3(@points[2..5, 0..1]));    # Circle has same centre regardless
    ok &near2(circleThrough3(@points), circleThrough3(@points[4..5, 0..3]));    # of the pairing of the points
   }
 }
