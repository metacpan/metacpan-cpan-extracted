#!perl -T

use Test::More tests => 15;

use Math::Geometry::Delaunay qw(TRI_CONSTRAINED TRI_VORONOI);

{
my $tri = Math::Geometry::Delaunay->new();

# Enable Triangle's basic STDOUT output.
# Won't show in "./Build test" output though.
# Run this script directly to see it.
# Something like:
# perl -Iblib/arch  -Iblib/lib -T t/06-addsegs.t
$tri->quiet(0); 

my $el = [
	[1,1],
	[7,1],
	[7,3],
	[3,3],
	[3,5],
	[1,5],
	];

$tri->addSegments([
        # not in contiguous order
        # but they do form a closed polygon
	[$el->[0], $el->[1]],
	[$el->[2], $el->[1]],
	[$el->[4], $el->[5]],
	[$el->[3], $el->[2]],
	[$el->[5], $el->[0]],
	[$el->[4], $el->[3]],
	]);

$tri->triangulate(TRI_CONSTRAINED,'e');

ok($tri->in->numberofsegments == 6, "wrong number of segments in input structure ".$tri->in->numberofsegments." != 6");

my $segments = $tri->segments();
my $segcnt=$tri->out->numberofsegments;
ok($segcnt == 6, "wrong number of output segments: $segcnt != 6");
ok(scalar(@{$segments}) == $segcnt,"segment list count doesn't correspond to actual segment list length: ".scalar(@{$segments})." vs $segcnt");

my $nodes = $tri->nodes();
# segments don't always have to be on the boundary, but here they are, so 
# edges with both ends on the boundary are the same as the segments. 
my @seg_edges = grep $_->[-1], @{$tri->edges()};
ok(scalar(@seg_edges) == $segcnt, "boundary edge count (by edge marker) doesn't match segment edge count: ".scalar(@seg_edges)." != $segcnt");

# The segments list has 12 point references, but each point is duplicated in a different segment.
# See if duplicates were detected and combined.
ok($tri->in->numberofpoints  == 6, "duplicate point refs in input not detected");
ok($tri->out->numberofpoints == 6, "duplicate segment end points repeated in output points");
ok(scalar(@{$tri->nodes})    == 6, "node list count not right - probably duplicates not detected");
}


# now lets test the by-coordinate (rather than by reference) point combining
{
my $tri = Math::Geometry::Delaunay->new();

$tri->quiet(0); 

my $el = [
	[1,1],
	[7,1],
	[7,3],
	[3,3],
	[3,5],
	[1,5],

	# duplicate coordinates for same point, different reference point combining
	[1,1],
	[7,1],
	[7,3],
	[3,3],
	[3,5],
	[1,5],

	];

$tri->addSegments([
        # not in contiguous order
        # but they do form a closed polygon
	[$el->[0], $el->[1]],
	[$el->[8], $el->[7]], # using duplicates
	[$el->[4], $el->[5]],
	[$el->[9], $el->[8]], # using duplicates
	[$el->[5], $el->[0]],
	[$el->[4], $el->[3]],
	]);

$tri->triangulate(TRI_CONSTRAINED,'e');

ok($tri->in->numberofsegments == 6, "wrong number of segments in input structure ".$tri->in->numberofsegments." != 6");

my $segments = $tri->segments();
my $segcnt=$tri->out->numberofsegments;
ok($segcnt == 6, "wrong number of output segments: $segcnt != 6");
ok(scalar(@{$segments}) == $segcnt,"segment list count doesn't correspond to actual segment list length: ".scalar(@{$segments})." vs $segcnt");

my $nodes = $tri->nodes();
# segments don't always have to be on the boundary, but here they are, so 
# edges with both ends on the boundary are the same as the segments. 
my @seg_edges = grep $_->[-1], @{$tri->edges()};
ok(scalar(@seg_edges) == $segcnt, "boundary edge count (by edge marker) doesn't match segment edge count: ".scalar(@seg_edges)." != $segcnt");

# The segments list has 12 point references, but each point is duplicated in a different segment.
# See if duplicates were detected and combined.
# This time we should have combined some points by looking at coordinate values.
# The final unique point counts should come out the same as when we were just looking
# for duplicate point references.
ok($tri->in->numberofpoints  == 6, "duplicate point refs in input not detected");
ok($tri->out->numberofpoints == 6, "duplicate segment end points repeated in output points");
ok(scalar(@{$tri->nodes})    == 6, "node list count not right - probably duplicates not detected");

}



ok(1);
