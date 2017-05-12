#!perl -T

use Test::More tests => 22;

use Math::Geometry::Delaunay qw(TRI_CONSTRAINED TRI_CCDT TRI_CONFORMING TRI_VORONOI);

my $tri = Math::Geometry::Delaunay->new();

# Enable Triangle's basic STDOUT output.
# Won't show in "./Build test" output though.
# Run this script directly to see it.
# Something like:
# perl -Iblib/arch  -Iblib/lib -T t/03-delaunays_pslg.t
$tri->quiet(0); 

$tri->addPolygon([[-1,-1],[1,-1],[1,1],[-1,1]]);
$tri->area_constraint(0.3);

my $topo = $tri->triangulate('Y');
#diag("last optstr: ".$tri->{optstr});

ok($topo,"nothing instead of topo hash");

ok($tri->out->numberofpoints == 5,"topo point count wrong");
ok($tri->out->numberofedges == 8,"topo edge count wrong");
ok($tri->out->numberofsegments == 4,"topo seg count wrong");
ok($tri->out->numberoftriangles == 4,"topo tri count wrong");
ok(@{$topo->{nodes}} == $tri->out->numberofpoints,"topo and raw point counts don't match: ".@{$topo->{nodes}} . " != " . $tri->out->numberofpoints);
ok(@{$topo->{elements}} == $tri->out->numberoftriangles,"topo and raw tri counts don't match: ".@{$topo->{elements}} . " != " . $tri->out->numberoftriangles);
ok(@{$topo->{edges}} == 0,"edge list should be empty : ".@{$topo->{edges}}); # edges counted but not output by default

# all triangles reference 3 nodes
ok((grep {@{$_->{nodes}}==3} @{$topo->{elements}}) == @{$topo->{elements}},"some tri doesn't have three nodes");
# all nodes reference at least 2 triangles, (in this case)
ok((grep {@{$_->{elements}}>1} @{$topo->{nodes}}) == @{$topo->{nodes}},"some node doesn't reference enough tris");
# the center node references all the triangles (in this case)
ok((grep {@{$_->{elements}} == @{$topo->{elements}}} @{$topo->{nodes}}) == 1,"center node should reference 5 triangles");

# all triangles reference 3 edges
#ok(grep {@{$_->{edges}}==3} @{$topo->{elements}} == $tri->out->numberoftriangles);

# go through some connections and see if data looks right
# then use this to do stl,gts,maybe afm exports all in a few lines

# same again, but with edges enabled

$topo = $tri->triangulate(TRI_CONSTRAINED,'e');
ok($tri->{optstr}=~'e', "edge option missing from flags");
ok($topo,"nothing instead of topo hash, second run");
ok(@{$topo->{edges}} == $tri->out->numberofedges,"topo tri count doesn't match raw count");
# all triangles reference 3 edges
ok((grep {@{$_->{edges}}==3} @{$topo->{elements}}) == @{$topo->{elements}},"some tri doesn't reference three nodes");
# all nodes reference at least 2 edges
ok((grep {@{$_->{edges}}>1} @{$topo->{nodes}}) == @{$topo->{nodes}},"some node doesn't ref at least 2 edges");
# the center node references as many edges as triangles (in this case)
ok((grep {@{$_->{edges}} == @{$topo->{elements}}} @{$topo->{nodes}}) == 1,"center node doesn't ref right number of edges and tris");

# same again, but with neighbors enabled
$topo = $tri->triangulate(TRI_CONSTRAINED,'n');
ok($tri->{optstr}=~'n', "neighbor option missing from flags");
ok($topo,"nothing instead of topo hash, third run");
# make sure we have as many neighbor lists as triangles - must force array context here with @{[]}
ok(@{[$tri->out->neighborlist]} == $tri->out->numberoftriangles*3,"neighbor list length doesn't match triangel list length");
# all triangles reference 2 neighbors (in this case)
ok((grep {@{$_->{neighbors}} == 2} @{$topo->{elements}}) == @{$topo->{elements}},"all tris should ref at least two neighbors here");
ok(1,"done");
