#!perl -T

use Test::More tests => 10;

use Math::Geometry::Delaunay qw(TRI_CONSTRAINED TRI_CCDT TRI_CONFORMING TRI_VORONOI);

my $tri = Math::Geometry::Delaunay->new();

# Enable Triangle's basic STDOUT output.
# Won't show in "./Build test" output though.
# Run this script directly to see it.
# Something like:
# perl -Iblib/arch  -Iblib/lib -T t/03-delaunays_pslg.t
$tri->quiet(0); 

# run the various packaged delaunay triangulations
# this time as PSLGs (p switch, triggered by using addRegion() instead of addPoints())

$tri->addPolygon([[-1,-1],[1,-1],[1,1],[-1,1]]);

$tri->triangulate(TRI_CONSTRAINED,'Y');
$constroutcnt=$tri->out->numberofpoints;
$tri->triangulate(TRI_CONSTRAINED,'Y');
$constr2outcnt=$tri->out->numberofpoints;
$constredgecnt=$tri->out->numberofedges;
#diag("\nconstr:$constroutcnt,$constr2outcnt, and edgcnt: $constredgecnt\n");
ok($constroutcnt == 4, "constrained on square should give 4 pts, gave $constroutcnt"); #no steiner points allowed, so we can predict point count
ok($constredgecnt == 5, "constrained on square should give 5 edges"); #no steiner points allowed, so we can predict point count
ok($constroutcnt == $constr2outcnt, "Constrained: different point counts from identical runs");
#diag("last optstring was: ".$tri->{optstr}."\n");
#diag(join(',',$tri->in->pointlist));
#diag(join(',',$tri->out->pointlist));

$tri->area_constraint(0.1);

$tri->triangulate(TRI_CCDT);
my $ccdoutcnt=$tri->out->numberofpoints;
$tri->triangulate(TRI_CCDT);
my $ccd2outcnt=$tri->out->numberofpoints;
ok($ccdoutcnt > 5,"CCDT should give 5 pts on square");
ok($ccdoutcnt == $ccd2outcnt, "CCDT: different point counts from identical runs");

$tri->triangulate(TRI_CONFORMING);
my $cdoutcnt=$tri->out->numberofpoints;
$tri->triangulate(TRI_CONFORMING);
my $cd2outcnt=$tri->out->numberofpoints;
ok($cdoutcnt > 5,"Conforming should give 5 points");
ok($cdoutcnt == $cd2outcnt,"Conforming: different point counts from identical runs");

# turn on voronoi output before next run
$tri->triangulate(TRI_CONFORMING,TRI_VORONOI);

my $cd3outcnt=$tri->out->numberofpoints;
ok($cd3outcnt > 5,"Conforming should give 5 points (voronoi run)");
my $voutcnt=$tri->vorout->numberofpoints;
ok($voutcnt > 0, "no points in voronoi output");

#diag("ccd:$ccdoutcnt,$ccd2outcnt\ncd:$cdoutcnt,$cd2outcnt,$cd3outcnt\nvor:$voutcnt\n");
#diag("last optstring was: ".$tri->{optstr}."\n");

ok(1);
