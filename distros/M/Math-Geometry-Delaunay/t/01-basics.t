#!perl -T

use Test::More tests => 14;

use Math::Geometry::Delaunay qw(TRI_CONSTRAINED TRI_CCDT TRI_CONFORMING TRI_VORONOI);

my $tri = Math::Geometry::Delaunay->new();

# Enable Triangle's basic STDOUT output.
# Won't show in "./Build test" output though.
# Run this script directly to see it.
# Something like:
# perl -Iblib/arch  -Iblib/lib -T t/03-delaunays_pslg.t
$tri->quiet(0); 

# this is an interface to the C struct
ok(ref($tri->in) eq ref($tri).'::Triangulateio');

# this gets read from C struct
ok( "0" eq $tri->in->numberofpoints()     , "input point count not properly initialized: ". $tri->in->numberofpoints());

# double check - this should have all been initialized to 3
ok( "3" eq $tri->in->numberofcorners()     , "input corner count not properly initialized: ".$tri->in->numberofcorners());

# set up for triangulation
$tri->addPoints([[-1,-1],[1,-1],[1,1],[-1,1]]);
$tri->area_constraint(0.1);

# do a triangulation
$tri->triangulate(TRI_CCDT);

# read coordinate lists out of C arrays
my @plai = $tri->in->pointlist();
my @plao = $tri->out->pointlist();

# see if counts add up
ok( $tri->in->numberofpoints() == 4 , "in points lost somehow after triangulation");
ok( $tri->out->numberofpoints() > 4 , "didn't triangulate? same number points out as in");
ok( $tri->in->numberofpoints() == scalar(@plai)/2 , "input coord list length doesn't correspond to point list length: ".$tri->in->numberofpoints()." != ".(scalar(@plai)/2));
ok( $tri->out->numberofpoints() == scalar(@plao)/2 , "output coord list length doesn't correspond to point list length");

# try a "numberof" getter/setter
ok( $tri->in->numberofcorners eq "3" , "input number of corners incorrect after triangulation");
ok( $tri->out->numberofcorners eq "3" , "output number of corners incorrect");

$tri->out->numberofcorners(777); # set to ridiculous number
ok( $tri->out->numberofcorners eq "777" , "set number of corners failed");

# reset C coordinate array in output struct
my @pla = $tri->out->pointlist(1,2,3,4,5,6,7,8,9,10);
ok(scalar(@pla) == 1 , "set pointlist array operation returned too much - more than just count");
ok($pla[0] == 10 , "set pointlist reports adding wrong number of coordinates");
# now get it back
@pla = $tri->out->pointlist();
ok(scalar(@pla) == 10, "didn't get as many coords back out as put in");
is_deeply(\@pla,[1,2,3,4,5,6,7,8,9,10], "didn't get same coords out as put in");