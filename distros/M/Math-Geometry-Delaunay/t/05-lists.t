#!perl -T

use Test::More tests => 13;

use Math::Geometry::Delaunay qw(TRI_CONSTRAINED TRI_CCDT TRI_CONFORMING TRI_VORONOI);

my $tri = Math::Geometry::Delaunay->new();

# Enable Triangle's basic STDOUT output.
# Won't show in "./Build test" output though.
# Run this script directly to see it.
# Something like:
# perl -Iblib/arch  -Iblib/lib -T t/03-delaunays_pslg.t
$tri->quiet(0); 

# run the various packaged delaunay triangulations on a list of points

my $el = [
	[1,1],
	[7,1],
	[7,3],
	[3,3],
	[3,5],
	[1,5],
	];

$tri->addPolygon($el);

$tri->triangulate(TRI_CONSTRAINED,TRI_VORONOI,'e');

my $vedges = $tri->vedges(); # this should have triggered generation of node list
my $vnodes = $tri->vnodes(); # so this should be coming from node list cache
my $voutcnt=$tri->vorout->numberofpoints;
my $veoutcnt=$tri->vorout->numberofedges;
ok($voutcnt == 4, "wrong number of voronoi nodes $voutcnt");
ok(scalar(@{$vnodes}) == $voutcnt,"node list count doesn't correspond to raw point list length: ".scalar(@{$vnodes})." vs $voutcnt");
ok($veoutcnt == 9, "wrong number of voronoi edges: $veoutcnt");
ok(scalar(@{$vedges}) == $veoutcnt,"edge list count doesn't correspond to raw edge list length");

my $eles = $tri->elements(); # this should have triggered generation of node list
my $nodes = $tri->nodes(); # so this should be coming from node list cache
my $edges = $tri->edges();
my $segments = $tri->segments();
my $outcnt=$tri->out->numberofpoints;
my $eoutcnt=$tri->out->numberofedges;
my $segoutcnt=$tri->out->numberofsegments;
my $eleoutcnt=$tri->out->numberoftriangles;
ok($outcnt == 6, "wrong number of delaunay nodes $outcnt");
ok(scalar(@{$nodes}) == $outcnt,"node list count doesn't correspond to point list length: ".scalar(@{$nodes})." vs $outcnt");
ok($eoutcnt == 9, "wrong number of delaunay edges: $eoutcnt");
ok(scalar(@{$edges}) == $eoutcnt,"edge list count doesn't correspond to edge list length: ".scalar(@{$edges})." vs $eoutcnt");
ok($segoutcnt == 6, "wrong number of segments: $segoutcnt");
ok(scalar(@{$segments}) == $segoutcnt,"segment list count doesn't correspond to segment list length");
ok($eleoutcnt == 4, "wrong number of triangles: $eleoutcnt");
ok(scalar(@{$eles}) == $eleoutcnt,"triangle list count doesn't correspond to triangle list length");

ok(1);
