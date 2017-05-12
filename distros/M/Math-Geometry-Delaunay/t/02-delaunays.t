#!perl -T

use Test::More tests => 8;

use Math::Geometry::Delaunay qw(TRI_CONSTRAINED TRI_CCDT TRI_CONFORMING TRI_VORONOI);

my $tri = Math::Geometry::Delaunay->new();

# Enable Triangle's basic STDOUT output.
# Won't show in "./Build test" output though.
# Run this script directly to see it.
# Something like:
# perl -Iblib/arch  -Iblib/lib -T t/03-delaunays_pslg.t
$tri->quiet(0); 

# run the various packaged delaunay triangulations on a list of points

$tri->addPoints([[-1,-1],[1,-1],[1,1],[-1,1]]);

$tri->triangulate(TRI_CONSTRAINED);
$constroutcnt=$tri->out->numberofpoints;
$tri->triangulate(TRI_CONSTRAINED);
$constr2outcnt=$tri->out->numberofpoints;
#diag("constr:$constroutcnt,$constr2outcnt\n");
ok($constroutcnt == 4);
ok($constroutcnt == $constr2outcnt);

$tri->triangulate(TRI_CCDT);
my $ccdoutcnt=$tri->out->numberofpoints;
$tri->triangulate(TRI_CCDT);
my $ccd2outcnt=$tri->out->numberofpoints;
ok($ccdoutcnt == 4);
ok($ccdoutcnt == $ccd2outcnt);

$tri->triangulate(TRI_CONFORMING);
my $cdoutcnt=$tri->out->numberofpoints;
$tri->triangulate(TRI_CONFORMING);
my $cd2outcnt=$tri->out->numberofpoints;
ok($cdoutcnt == 4);
ok($cdoutcnt == $cd2outcnt);

$tri->triangulate(TRI_CONFORMING,TRI_VORONOI);
my $voutcnt=$tri->vorout->numberofpoints;
ok($voutcnt == 2);

#diag("ccd:$ccdoutcnt,$ccd2outcnt\ncd:$cdoutcnt,$cd2outcnt\nvor:$voutcnt\n");

ok(1);
