# -*- perl -*-
use Test::More tests => 35;

BEGIN { use_ok( 'GPS::Point::Cluster' ); }
BEGIN { use_ok( 'GPS::Point' ); }

{
my $cluster=GPS::Point::Cluster->new();
isa_ok($cluster, 'GPS::Point::Cluster');
is($cluster->weight, 0, "empty cluster");
my $lat1=25.938743;
my $lon1=-80.138647;
my $t1=1000000;
my $pt=GPS::Point->new(lat=>$lat1, lon=>$lon1, time=>$t1);
my $obj=$cluster->merge_attempt($pt);
isa_ok($obj, "GPS::Point::Cluster");
$cluster=$obj;
isa_ok($cluster,     "GPS::Point::Cluster");
is($cluster->index,  1,         "new cluster index");
is($cluster->start,  $t1,       "new cluster start");
is($cluster->end,    $t1,       "new cluster end");
is($cluster->lat,    $lat1,      "new cluster lat");
is($cluster->lon,    $lon1,      "new cluster lon");
is($cluster->weight, 1,         "new cluster weight");

my $lat2=25.9419278618238;
my $lon2=-80.1351244159226; #499 meters north east
my $t2=$t1 + 1;
$pt=GPS::Point->new(lat=>$lat2, lon=>$lon2, time=>$t2);
$obj=$cluster->merge_attempt($pt);
is($obj,             undef,     "old cluster");
is($cluster->index,  1,         "old cluster index");
is($cluster->start,  $t1,       "old cluster start");
is($cluster->end,    $t2,       "old cluster end");
is($cluster->lat,    ($lat1*1+$lat2)/2,  "old cluster lat");
is($cluster->lon,    ($lon1*1+$lon2)/2,  "old cluster lon");
is($cluster->weight, 2,         "old cluster weight");
}
{
my $cluster=GPS::Point::Cluster->new();
isa_ok($cluster, 'GPS::Point::Cluster');
is($cluster->weight, 0, "empty cluster");
my $lat1=25.938743;
my $lon1=-80.138647;
my $t1=1000000;
my $pt=GPS::Point->new(lat=>$lat1, lon=>$lon1, time=>$t1);
my $obj=$cluster->merge_attempt($pt);
isa_ok($obj, "GPS::Point::Cluster");
$cluster=$obj;
isa_ok($cluster,     "GPS::Point::Cluster");
is($cluster->index,  1,         "new cluster index");
is($cluster->start,  $t1,       "new cluster start");
is($cluster->end,    $t1,       "new cluster end");
is($cluster->lat,    $lat1,      "new cluster lat");
is($cluster->lon,    $lon1,      "new cluster lon");
is($cluster->weight, 1,         "new cluster weight");

my $lat2=25.9355452856276;
my $lon2=-80.1351104879399; #501 meters north west
my $t2=$t1 + 1;
$pt=GPS::Point->new(lat=>$lat2, lon=>$lon2, time=>$t2);
$obj=$cluster->merge_attempt($pt);
is($obj->index,  2,         "new cluster index");
is($obj->start,  $t2,       "new cluster start");
is($obj->end,    $t2,       "new cluster end");
is($obj->lat,    $lat2,     "new cluster lat");
is($obj->lon,    $lon2,     "new cluster lon");
is($obj->weight, 1,         "new cluster weight");
}
