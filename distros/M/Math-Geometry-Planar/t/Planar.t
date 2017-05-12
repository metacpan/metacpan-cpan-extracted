
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test;
use strict;

BEGIN {plan tests => 77};

eval {require Math::Geometry::Planar};
ok ($@,'');
croak() if $@;
use Math::Geometry::Planar;

################################################################################
# create contour object
my $contour = Math::Geometry::Planar->new;
ok ($contour);
################################################################################
# add a polygon to the contour object
my $count = $contour->add_polygons([[1,1],[2,3],[3,4],[6,2]]);
ok ($contour->num_polygons == 1 && $count == 1);
ok ($contour->area == 7);
$count = $contour->add_polygons([[2,2],[3,4],[4,5],[7,3]],[[3,3],[4,5],[5,6],[8,4]]);
ok ($contour->num_polygons == 3 && $count == 3);
my @polygons = $contour->get_polygons(0,2);
ok (@polygons == 2);
################################################################################
# length of a vector
my $pointsref = [[1,1],[4,5]];
ok (SegmentLength($pointsref) == 5);
################################################################################
# determinant x1,y1,x2,y2
ok (Determinant(2,5,3,7) == -1);
################################################################################
# dot product of 2 vectors
$pointsref = [[1,1],[6,1],[1,1],[3,3]];
ok (DotProduct($pointsref) == 10);
# should be 0 for perpendicular vectors
$pointsref = [[1,3],[2,1],[2,2],[4,3]];
ok (DotProduct($pointsref) == 0);
################################################################################
# Cross product of 2 vectors
$pointsref = [[1,1],[5,5],[1,4]];
ok (CrossProduct($pointsref) == 12);
################################################################################
# Triangle area
$pointsref = [[1,1],[1,8],[3,6]];
ok (TriangleArea($pointsref) == -7);
################################################################################
# Colinear points
$pointsref = [[1,1],[7,3],[4,2]];
ok (Colinear($pointsref));
$pointsref = [[1,1],[7.000001,3],[4,2]];
ok (! Colinear($pointsref));
################################################################################
# Segment intersection
$pointsref = [[1,1],[2,2],[3,0],[4,2]];
ok (! SegmentIntersection($pointsref));
$pointsref = [[1,1],[4,2],[0,3],[3,0]];
my @result = @{SegmentIntersection($pointsref)};
ok ($result[0] == 1.75 && $result[1] == 1.25);
$pointsref = [[1,1],[4,2],[1,1],[3,0]];
ok (! SegmentIntersection($pointsref));
################################################################################
# Line intersection
$pointsref = [[1,1],[2,2],[3,0],[4,2]];
@result = @{LineIntersection($pointsref)};
ok ($result[0] == 6 && $result[1] == 6);
$pointsref = [[1,1],[5,2],[2,4],[6,5]];
ok (! LineIntersection($pointsref));
################################################################################
# Ray intersection
$pointsref = [[1,1],[5,3],[4,0],[2,4]];
@result = @{RayIntersection($pointsref)};
ok ($result[0] == 3 && $result[1] == 2);
$pointsref = [[1,1],[5,3],[4,0],[8,1]];
ok (! RayIntersection($pointsref));
################################################################################
# Ray-Line intersection
$pointsref = [[-1,0],[1,1],[2,4],[0,8]];
@result = @{RayLineIntersection($pointsref)};
ok ($result[0] == 3 && $result[1] == 2);
$pointsref = [[5,3],[9,5],[2,4],[0,8]];
ok (! RayLineIntersection($pointsref));
################################################################################
# Segment-Line intersection
$pointsref = [[5,3],[1,1],[2,4],[0,8]];
@result = @{SegmentLineIntersection($pointsref)};
ok ($result[0] == 3 && $result[1] == 2);
$pointsref = [[-1,0],[1,1],[2,4],[0,8]];
ok (! SegmentLineIntersection($pointsref));
################################################################################
# Segment-Ray intersection
$pointsref = [[-2,2],[0,-2],[5,3],[1,1]];
@result = @{SegmentRayIntersection($pointsref)};
ok ($result[0] == -1 && $result[1] == 0);
$pointsref = [[6,6],[8,2],[5,3],[1,1]];
ok (! SegmentRayIntersection($pointsref));
################################################################################
# Perpendicular Lines
$pointsref = [[2,1],[7,2],[3,3.000001],[2,8]];
ok (! Perpendicular($pointsref));
$pointsref = [[2,1],[7,2],[3,3],[2,8]];
ok (Perpendicular($pointsref));
################################################################################
# Perpendicular Foot
$pointsref = [[1,1],[2,2],[3,0]];
@result = @{PerpendicularFoot($pointsref)};
ok ($result[0] == 1.5 && $result[1] == 1.5);
################################################################################
# Distance to line
$pointsref = [[2,1],[6,4],[3,8]];
ok (DistanceToLine($pointsref) == 5);
################################################################################
# Distance to segment
$pointsref = [[1,1],[3,1],[-2,5]];
ok (DistanceToSegment($pointsref) == 5);
$pointsref = [[1,1],[3,1],[2,5]];
ok (DistanceToSegment($pointsref) == 4);
$pointsref = [[1,1],[3,1],[6,5]];
ok (DistanceToSegment($pointsref) == 5);
################################################################################
# create polygon object
my $poly = Math::Geometry::Planar->new;
ok ($poly);
################################################################################
# polygon cleanup
$poly->points([[1,1],[5,1],[5,5],[5,3],[1,3]]);
$pointsref = $poly->cleanup;
my @points = @{$pointsref};
ok (@points == 4);
$contour->polygons([[[1,1],[5,1],[5,5],[5,3],[1,3]]]);
my $polygonsref = $contour->cleanup;
my @polygonrefs = @{$polygonsref};
$pointsref = $polygonrefs[0];
@points = @{$pointsref};
ok (@points == 4);
################################################################################
# convex polygon test
$poly->points([[1,1],[5,1],[5,5],[5,3],[1,3]]);
ok ($poly->isconvex);
$poly->points([[1,1],[5,1],[3,2],[5,3],[1,3]]);
ok (! $poly->isconvex);
################################################################################
# simple polygon test
$poly->points([[1,1],[3,4],[6,3],[5,-1]]);
ok ($poly->issimple);
$poly->points([[1,1],[3,4],[5,-1],[6,3]]);
ok (! $poly->issimple);
$contour->polygons([[[1,1],[3,4],[6,3],[5,-1]]]);
ok ($contour->issimple);
$contour->add_polygons([[1,1],[3,4],[5,-1],[6,3]]);
ok (! $contour->issimple);
################################################################################
# polygon perimeter
$poly->points([[1,1],[4,5],[8,2],[5,-2]]);
ok ($poly->perimeter == 20);
my $cont1 = Math::Geometry::Planar->new;
$cont1 ->add_polygons([[1,1],[4,5],[8,2],[5,-2]]);
ok ($cont1->perimeter == 20);
ok ($cont1->isconvex);
################################################################################
# polygon area
$poly->points([[1,1],[2,3],[3,4],[6,2]]);
ok ($poly->area == 7);
################################################################################
# polygon centroid
$poly->points([[3,1],[2,4],[1,5],[2,6],[3,9],[4,6],[5,5],[4,4]]);
@result = @{$poly->centroid};
ok ($result[0] == 3 && $result[1] == 5);
################################################################################
# point in polygon
$poly->points([[1,1],[3,4],[2,3],[6,2]]);
ok ($poly->isinside([2,2]));
ok (! $poly->isinside([1,2]));
my $poly1 = [[1,0],[5,0],[5,5],[1,5]];
my $poly2 = [[3,1],[2,2],[3,3],[4,2]];
$contour->polygons([$poly1,$poly2]);
ok ($contour->isinside([2,3]));
ok (! $contour->isinside([6,5]));
ok (! $contour->isinside([3,2]));
################################################################################
# rotate polygon
$poly->points([[1,1],[3,4],[2,3],[6,2]]);
@points = @{$poly->rotate(atan2(1,1)*2,[2,2])->points};
ok (abs (${$points[3]}[0] - 3) < 1e-10 &&
    abs (${$points[3]}[1] - 1) < 1e-10 &&
    abs (${$points[2]}[0] - 0) < 1e-10 &&
    abs (${$points[2]}[1] - 3) < 1e-10 &&
    abs (${$points[1]}[0] - 1) < 1e-10 &&
    abs (${$points[1]}[1] - 2) < 1e-10 &&
    abs (${$points[0]}[0] - 2) < 1e-10 &&
    abs (${$points[0]}[1] - 6) < 1e-10 );
################################################################################
# move polygon
$poly->points([[1,1],[3,4],[2,3],[6,2]]);
@points = @{$poly->move(1,2)->points};
ok (${$points[3]}[0] == 2 &&
    ${$points[3]}[1] == 3 &&
    ${$points[2]}[0] == 4 &&
    ${$points[2]}[1] == 6 &&
    ${$points[1]}[0] == 3 &&
    ${$points[1]}[1] == 5 &&
    ${$points[0]}[0] == 7 &&
    ${$points[0]}[1] == 4 );
################################################################################
# mirrorx polygon
$poly->points([[1,1],[3,4],[2,3],[6,2]]);
@points = @{$poly->mirrorx([3,2])->points};
ok (${$points[0]}[0] == 5 &&
    ${$points[0]}[1] == 1 &&
    ${$points[1]}[0] == 3 &&
    ${$points[1]}[1] == 4 &&
    ${$points[2]}[0] == 4 &&
    ${$points[2]}[1] == 3 &&
    ${$points[3]}[0] == 0 &&
    ${$points[3]}[1] == 2 );
################################################################################
# mirrory polygon
$poly->points([[1,1],[3,4],[2,3],[6,2]]);
@points = @{$poly->mirrory([3,2])->points};
ok (${$points[0]}[0] == 1 &&
    ${$points[0]}[1] == 3 &&
    ${$points[1]}[0] == 3 &&
    ${$points[1]}[1] == 0 &&
    ${$points[2]}[0] == 2 &&
    ${$points[2]}[1] == 1 &&
    ${$points[3]}[0] == 6 &&
    ${$points[3]}[1] == 2 );
################################################################################
# mirror polygon
$poly->points([[1,1],[3,4],[2,3],[6,2]]);
@points = @{$poly->mirror([[2,2],[3,3]])->points};
ok (${$points[0]}[0] == 1 &&
    ${$points[0]}[1] == 1 &&
    ${$points[1]}[0] == 4 &&
    ${$points[1]}[1] == 3 &&
    ${$points[2]}[0] == 3 &&
    ${$points[2]}[1] == 2 &&
    ${$points[3]}[0] == 2 &&
    ${$points[3]}[1] == 6 );
################################################################################
# scale polygon
$poly->points([[1,1],[3,4],[2,3],[6,2]]);
@points = @{$poly->scale(2,[2,2])->points};
ok (${$points[3]}[0] == 0 &&
    ${$points[3]}[1] == 0 &&
    ${$points[2]}[0] == 4 &&
    ${$points[2]}[1] == 6 &&
    ${$points[1]}[0] == 2 &&
    ${$points[1]}[1] == 4 &&
    ${$points[0]}[0] == 10 &&
    ${$points[0]}[1] == 2 );
################################################################################
# bounding boxes - orthogonal and minimum area
$contour->polygons([[[1,1],[5,1],[5,3],[3,4],[1,3]]]);
@points = @{$contour->bbox->points};
ok (${$points[3]}[0] == 1 &&
    ${$points[3]}[1] == 1 &&
    ${$points[2]}[0] == 1 &&
    ${$points[2]}[1] == 4 &&
    ${$points[1]}[0] == 5 &&
    ${$points[1]}[1] == 4 &&
    ${$points[0]}[0] == 5 &&
    ${$points[0]}[1] == 1 );
@points = @{$contour->minrectangle->points};
ok (${$points[3]}[0] == 1 &&
    ${$points[3]}[1] == 1 &&
    ${$points[2]}[0] == 1 &&
    ${$points[2]}[1] == 4 &&
    ${$points[1]}[0] == 5 &&
    ${$points[1]}[1] == 4 &&
    ${$points[0]}[0] == 5 &&
    ${$points[0]}[1] == 1 );
$contour->polygons([[[2,4],[3,3],[5,3],[9,7],[9,11],[7,11],[2,6]]]);
@points = @{$contour->minrectangle->points};
ok (${$points[3]}[0] == 4 &&
    ${$points[3]}[1] == 2 &&
    ${$points[2]}[0] == 1 &&
    ${$points[2]}[1] == 5 &&
    ${$points[1]}[0] == 8 &&
    ${$points[1]}[1] == 12 &&
    ${$points[0]}[0] == 11 &&
    ${$points[0]}[1] == 9 );
################################################################################
# polygon convex hull
$poly->points([[1,1],[2,-1],[0,-4],[4,-2],[6,-3],
               [8,3],[4,1]]);
@points = @{$poly->convexhull->points};
ok (${$points[0]}[0] == 8 &&
    ${$points[0]}[1] == 3 &&
    ${$points[1]}[0] == 1 &&
    ${$points[1]}[1] == 1 &&
    ${$points[2]}[0] == 0 &&
    ${$points[2]}[1] == -4 &&
    ${$points[3]}[0] == 6 &&
    ${$points[3]}[1] == -3 );
################################################################################
# polygon convex hull
$poly->points([[1,1],[2,-1],[0,-4],[4,-2],[6,-3],
               [8,3],[4,1],[5,-1],[0,-3],[1,-4]]);
@points = @{$poly->convexhull2->points};
ok (${$points[0]}[0] == 0 &&
    ${$points[0]}[1] == -4 &&
    ${$points[1]}[0] == 1 &&
    ${$points[1]}[1] == -4 &&
    ${$points[2]}[0] == 6 &&
    ${$points[2]}[1] == -3 &&
    ${$points[3]}[0] == 8 &&
    ${$points[3]}[1] == 3 &&
    ${$points[4]}[0] == 1 &&
    ${$points[4]}[1] == 1 &&
    ${$points[5]}[0] == 0 &&
    ${$points[5]}[1] == -3 );
################################################################################
# gpc polygon clip operations
$poly1 = Math::Geometry::Planar->new;
$poly2 = Math::Geometry::Planar->new;
$poly1->points([[1,1],[1,3],[3,3],[3,1]]);
$poly2->points([[2,2],[2,4],[4,4],[4,2]]);
my $gpc_poly1 = $poly1->convert2gpc([$poly1]);
my $gpc_poly2 = $poly2->convert2gpc([$poly2]);
my $result = GpcClip("DIFFERENCE",$gpc_poly1,$gpc_poly2);
my @contours = Gpc2Polygons($result);
my $polygon_refs = $contours[0]->polygons;
my $polygon_ref  = ${$polygon_refs}[0];
@points = @{$polygon_ref};
ok (${$points[5]}[0] == 2 &&
    ${$points[5]}[1] == 2 &&
    ${$points[4]}[0] == 3 &&
    ${$points[4]}[1] == 2 &&
    ${$points[3]}[0] == 3 &&
    ${$points[3]}[1] == 1 &&
    ${$points[2]}[0] == 1 &&
    ${$points[2]}[1] == 1 &&
    ${$points[1]}[0] == 1 &&
    ${$points[1]}[1] == 3 &&
    ${$points[0]}[0] == 2 &&
    ${$points[0]}[1] == 3 );
$result = GpcClip("INTERSECTION",$gpc_poly1,$gpc_poly2);
@contours = Gpc2Polygons($result);
$polygon_refs = $contours[0]->polygons;
$polygon_ref  = ${$polygon_refs}[0];
@points = @{$polygon_ref};
ok (${$points[3]}[0] == 3 &&
    ${$points[3]}[1] == 2 &&
    ${$points[2]}[0] == 2 &&
    ${$points[2]}[1] == 2 &&
    ${$points[1]}[0] == 2 &&
    ${$points[1]}[1] == 3 &&
    ${$points[0]}[0] == 3 &&
    ${$points[0]}[1] == 3 );
$result = GpcClip("XOR",$gpc_poly1,$gpc_poly2);
@contours = Gpc2Polygons($result);
my $polygon_refs0 = $contours[0]->polygons;
my $polygon_refs1 = $contours[1]->polygons;
my $polygon_ref0  = ${$polygon_refs0}[0];
my $polygon_ref1  = ${$polygon_refs1}[0];
my @points0 = @{$polygon_ref0};
my @points1 = @{$polygon_ref1};
ok (${$points0[5]}[0] == 4 &&
    ${$points0[5]}[1] == 2 &&
    ${$points0[4]}[0] == 3 &&
    ${$points0[4]}[1] == 2 &&
    ${$points0[3]}[0] == 3 &&
    ${$points0[3]}[1] == 3 &&
    ${$points0[2]}[0] == 2 &&
    ${$points0[2]}[1] == 3 &&
    ${$points0[1]}[0] == 2 &&
    ${$points0[1]}[1] == 4 &&
    ${$points0[0]}[0] == 4 &&
    ${$points0[0]}[1] == 4 &&
    ${$points1[5]}[0] == 2 &&
    ${$points1[5]}[1] == 2 &&
    ${$points1[4]}[0] == 3 &&
    ${$points1[4]}[1] == 2 &&
    ${$points1[3]}[0] == 3 &&
    ${$points1[3]}[1] == 1 &&
    ${$points1[2]}[0] == 1 &&
    ${$points1[2]}[1] == 1 &&
    ${$points1[1]}[0] == 1 &&
    ${$points1[1]}[1] == 3 &&
    ${$points1[0]}[0] == 2 &&
    ${$points1[0]}[1] == 3 );
$result = GpcClip("UNION",$gpc_poly1,$gpc_poly2);
@contours = Gpc2Polygons($result);
$polygon_refs = $contours[0]->polygons;
$polygon_ref  = ${$polygon_refs}[0];
@points = @{$polygon_ref};
ok (${$points[7]}[0] == 4 &&
    ${$points[7]}[1] == 2 &&
    ${$points[6]}[0] == 3 &&
    ${$points[6]}[1] == 2 &&
    ${$points[5]}[0] == 3 &&
    ${$points[5]}[1] == 1 &&
    ${$points[4]}[0] == 1 &&
    ${$points[4]}[1] == 1 &&
    ${$points[3]}[0] == 1 &&
    ${$points[3]}[1] == 3 &&
    ${$points[2]}[0] == 2 &&
    ${$points[2]}[1] == 3 &&
    ${$points[1]}[0] == 2 &&
    ${$points[1]}[1] == 4 &&
    ${$points[0]}[0] == 4 &&
    ${$points[0]}[1] == 4 );

################################################################################
# A test: what happens if we and a non-simple polygon with itself ?
$poly->points([[1,1],[1,3],[3,1],[3,3]]);
my $gpc_poly = $poly->convert2gpc;
$result = GpcClip("UNION",$gpc_poly,$gpc_poly);
@contours = Gpc2Polygons($result);
$polygon_refs = $contours[0]->polygons;
$polygon_ref  = ${$polygon_refs}[0];
@points = @{$polygon_ref};
ok (${$points[5]}[0] == 3 &&
    ${$points[5]}[1] == 1 &&
    ${$points[4]}[0] == 2 &&
    ${$points[4]}[1] == 2 &&
    ${$points[3]}[0] == 1 &&
    ${$points[3]}[1] == 1 &&
    ${$points[2]}[0] == 1 &&
    ${$points[2]}[1] == 3 &&
    ${$points[1]}[0] == 2 &&
    ${$points[1]}[1] == 2 &&
    ${$points[0]}[0] == 3 &&
    ${$points[0]}[1] == 3 );

################################################################################
# Triangulation test
# outer contour -> counter clock wise
$poly1 = [[1,0],[5,0],[5,5],[1,5]];
$poly2 = [[3,1],[2,2],[3,3],[4,2]];
$contour->polygons([$poly1,$poly2]);
@polygons = $contour->triangulate;
ok (@polygons == 8);

################################################################################
# GPC clip creating a contour with multiple outer shapes
# each having holes (comversion test)
# create contour object
my $contour1 = Math::Geometry::Planar->new;
my $contour2 = Math::Geometry::Planar->new;
# outer contour -> counter clock wise
$poly1 = [[1,1],[6,1],[6,8],[1,8]]; # outer
$poly2 = [[2,2],[2,7],[3,7],[3,2]]; # hole 1
my $poly3 = [[4,6],[4,7],[5,7],[5,6]]; # hole 2
my $poly4 = [[4,2],[4,3],[5,3],[5,2]]; # hole 3
$contour1->polygons([$poly1,$poly2,$poly3,$poly4]);
$gpc_poly1 = $contour1->convert2gpc;
my $poly5 = [[0,4],[0,5],[7,5],[7,4]]; # outer
$contour2->polygons([$poly5]);
$gpc_poly2 = $contour2->convert2gpc;
$result = GpcClip("DIFFERENCE",$gpc_poly1,$gpc_poly2);
@contours = Gpc2Polygons($result);
$polygon_refs0 = $contours[0]->polygons;
$polygon_refs1 = $contours[1]->polygons;
my $polygon_ref00 = ${$polygon_refs0}[0];
my $polygon_ref01 = ${$polygon_refs0}[1];
my $polygon_ref10 = ${$polygon_refs1}[0];
my $polygon_ref11 = ${$polygon_refs1}[1];
my @points00 = @{$polygon_ref00};
my @points01 = @{$polygon_ref01};
my @points10 = @{$polygon_ref10};
my @points11 = @{$polygon_ref11};
ok (${$points00[7]}[0] == 6 &&
    ${$points00[7]}[1] == 5 &&
    ${$points00[6]}[0] == 3 &&
    ${$points00[6]}[1] == 5 &&
    ${$points00[5]}[0] == 3 &&
    ${$points00[5]}[1] == 7 &&
    ${$points00[4]}[0] == 2 &&
    ${$points00[4]}[1] == 7 &&
    ${$points00[3]}[0] == 2 &&
    ${$points00[3]}[1] == 5 &&
    ${$points00[2]}[0] == 1 &&
    ${$points00[2]}[1] == 5 &&
    ${$points00[1]}[0] == 1 &&
    ${$points00[1]}[1] == 8 &&
    ${$points00[0]}[0] == 6 &&
    ${$points00[0]}[1] == 8 &&
    ${$points01[3]}[0] == 5 &&
    ${$points01[3]}[1] == 7 &&
    ${$points01[2]}[0] == 4 &&
    ${$points01[2]}[1] == 7 &&
    ${$points01[1]}[0] == 4 &&
    ${$points01[1]}[1] == 6 &&
    ${$points01[0]}[0] == 5 &&
    ${$points01[0]}[1] == 6 &&
    ${$points10[7]}[0] == 6 &&
    ${$points10[7]}[1] == 1 &&
    ${$points10[6]}[0] == 1 &&
    ${$points10[6]}[1] == 1 &&
    ${$points10[5]}[0] == 1 &&
    ${$points10[5]}[1] == 4 &&
    ${$points10[4]}[0] == 2 &&
    ${$points10[4]}[1] == 4 &&
    ${$points10[3]}[0] == 2 &&
    ${$points10[3]}[1] == 2 &&
    ${$points10[2]}[0] == 3 &&
    ${$points10[2]}[1] == 2 &&
    ${$points10[1]}[0] == 3 &&
    ${$points10[1]}[1] == 4 &&
    ${$points10[0]}[0] == 6 &&
    ${$points10[0]}[1] == 4 &&
    ${$points11[3]}[0] == 5 &&
    ${$points11[3]}[1] == 3 &&
    ${$points11[2]}[0] == 4 &&
    ${$points11[2]}[1] == 3 &&
    ${$points11[1]}[0] == 4 &&
    ${$points11[1]}[1] == 2 &&
    ${$points11[0]}[0] == 5 &&
    ${$points11[0]}[1] == 2 );

################################################################################
# convert circle defined by 3 points
@points = @{CircleToPoly(8,[2,2],[3,3],[4,2])->points};
ok (
abs (${$points[0]}[0] - 4) < 1e-07 &&
abs (${$points[0]}[1] - 2) < 1e-07 &&
abs (${$points[1]}[0] - 3.70710678118655) < 1e-07 &&
abs (${$points[1]}[1] - 2.70710678118655) < 1e-07 &&
abs (${$points[2]}[0] - 3) < 1e-7 &&
abs (${$points[2]}[1] - 3) < 1e-7 &&
abs (${$points[3]}[0] - 2.29289321881345) < 1e-07 &&
abs (${$points[3]}[1] - 2.70710678118655) < 1e-07 &&
abs (${$points[4]}[0] - 2) < 1e-7 &&
abs (${$points[4]}[1] - 2) < 1e-7 &&
abs (${$points[5]}[0] - 2.29289321881345) < 1e-07 &&
abs (${$points[5]}[1] - 1.29289321881345) < 1e-07 &&
abs (${$points[6]}[0] - 3) < 1e-7 &&
abs (${$points[6]}[1] - 1) < 1e-7 &&
abs (${$points[7]}[0] - 3.70710678118655) < 1e-07 &&
abs (${$points[7]}[1] - 1.29289321881345) < 1e-07
);

################################################################################
# convert circle defined by point and center
@points = @{CircleToPoly(8,[3,2],[2,2])->points};
ok (
abs (${$points[0]}[0] - 4) < 1e-07 &&
abs (${$points[0]}[1] - 2) < 1e-07 &&
abs (${$points[1]}[0] - 3.70710678118655) < 1e-07 &&
abs (${$points[1]}[1] - 2.70710678118655) < 1e-07 &&
abs (${$points[2]}[0] - 3) < 1e-7 &&
abs (${$points[2]}[1] - 3) < 1e-7 &&
abs (${$points[3]}[0] - 2.29289321881345) < 1e-07 &&
abs (${$points[3]}[1] - 2.70710678118655) < 1e-07 &&
abs (${$points[4]}[0] - 2) < 1e-7 &&
abs (${$points[4]}[1] - 2) < 1e-7 &&
abs (${$points[5]}[0] - 2.29289321881345) < 1e-07 &&
abs (${$points[5]}[1] - 1.29289321881345) < 1e-07 &&
abs (${$points[6]}[0] - 3) < 1e-7 &&
abs (${$points[6]}[1] - 1) < 1e-7 &&
abs (${$points[7]}[0] - 3.70710678118655) < 1e-07 &&
abs (${$points[7]}[1] - 1.29289321881345) < 1e-07
);

################################################################################
# convert circle defined by radius and center
@points = @{CircleToPoly(8,[3,2],1)->points};
ok (
abs (${$points[0]}[0] - 4) < 1e-07 &&
abs (${$points[0]}[1] - 2) < 1e-07 &&
abs (${$points[1]}[0] - 3.70710678118655) < 1e-07 &&
abs (${$points[1]}[1] - 2.70710678118655) < 1e-07 &&
abs (${$points[2]}[0] - 3) < 1e-7 &&
abs (${$points[2]}[1] - 3) < 1e-7 &&
abs (${$points[3]}[0] - 2.29289321881345) < 1e-07 &&
abs (${$points[3]}[1] - 2.70710678118655) < 1e-07 &&
abs (${$points[4]}[0] - 2) < 1e-7 &&
abs (${$points[4]}[1] - 2) < 1e-7 &&
abs (${$points[5]}[0] - 2.29289321881345) < 1e-07 &&
abs (${$points[5]}[1] - 1.29289321881345) < 1e-07 &&
abs (${$points[6]}[0] - 3) < 1e-7 &&
abs (${$points[6]}[1] - 1) < 1e-7 &&
abs (${$points[7]}[0] - 3.70710678118655) < 1e-07 &&
abs (${$points[7]}[1] - 1.29289321881345) < 1e-07
);

################################################################################
# convert arc defined by 3 points
$poly = ArcToPoly(6,[2,2],[3,3],[3,1]);
@points = @{$poly};
ok (
abs (${$points[0]}[0] - 2) < 1e-07 &&
abs (${$points[0]}[1] - 2) < 1e-07 &&
abs (${$points[1]}[0] - 2.29289321881345) < 1e-07 &&
abs (${$points[1]}[1] - 2.70710678118655) < 1e-07 &&
abs (${$points[2]}[0] - 3) < 1e-07 &&
abs (${$points[2]}[1] - 3) < 1e-07 &&
abs (${$points[3]}[0] - 3.70710678118655) < 1e-07 &&
abs (${$points[3]}[1] - 2.70710678118655) < 1e-07 &&
abs (${$points[4]}[0] - 4) < 1e-07 &&
abs (${$points[4]}[1] - 2) < 1e-07 &&
abs (${$points[5]}[0] - 3.70710678118655) < 1e-07 &&
abs (${$points[5]}[1] - 1.29289321881345) < 1e-07 &&
abs (${$points[6]}[0] - 3) < 1e-07 &&
abs (${$points[6]}[1] - 1) < 1e-07
);

################################################################################
# convert arc with center - counter clock wise
$poly = ArcToPoly(6,[3,2],[2,2],[3,3],0); # counter clock wise
@points = @{$poly};
ok (
abs (${$points[0]}[0] - 2) < 1e-07 &&
abs (${$points[0]}[1] - 2) < 1e-07 &&
abs (${$points[1]}[0] - 2.29289321881345) < 1e-07 &&
abs (${$points[1]}[1] - 1.29289321881345) < 1e-07 &&
abs (${$points[2]}[0] - 3) < 1e-07 &&
abs (${$points[2]}[1] - 1) < 1e-07 &&
abs (${$points[3]}[0] - 3.70710678118655) < 1e-07 &&
abs (${$points[3]}[1] - 1.29289321881345) < 1e-07 &&
abs (${$points[4]}[0] - 4) < 1e-07 &&
abs (${$points[4]}[1] - 2) < 1e-07 &&
abs (${$points[5]}[0] - 3.70710678118655) < 1e-07 &&
abs (${$points[5]}[1] - 2.70710678118655) < 1e-07 &&
abs (${$points[6]}[0] - 3) < 1e-07 &&
abs (${$points[6]}[1] - 3) < 1e-07
);

################################################################################
# convert arc with center - clock wise
$poly = ArcToPoly(2,[3,2],[2,2],[3,3],1); # clock wise
@points = @{$poly};
ok (
abs (${$points[0]}[0] - 2) < 1e-07 &&
abs (${$points[0]}[1] - 2) < 1e-07 &&
abs (${$points[1]}[0] - 2.29289321881345) < 1e-07 &&
abs (${$points[1]}[1] - 2.70710678118655) < 1e-07 &&
abs (${$points[2]}[0] - 3) < 1e-07 &&
abs (${$points[2]}[1] - 3) < 1e-07
);
