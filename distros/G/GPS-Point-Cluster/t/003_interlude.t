# -*- perl -*-
use Test::More tests => 32;

BEGIN { use_ok( 'GPS::Point::Cluster' ); }
BEGIN { use_ok( 'GPS::Point' ); }

my $cluster=GPS::Point::Cluster->new();
isa_ok($cluster, 'GPS::Point::Cluster');
is($cluster->weight, 0, "empty cluster");
my $lat=25.938743;
my $lon=-80.138647;
my $t1=1000000;
my $pt=GPS::Point->new(lat=>$lat, lon=>$lon, time=>$t1);
my $obj=$cluster->merge_attempt($pt);
isa_ok($obj, "GPS::Point::Cluster");
$cluster=$obj;
isa_ok($cluster,     "GPS::Point::Cluster");
is($cluster->index,  1,         "new cluster index");
is($cluster->start,  $t1,       "new cluster start");
is($cluster->end,    $t1,       "new cluster end");
is($cluster->lat,    $lat,      "new cluster lat");
is($cluster->lon,    $lon,      "new cluster lon");
is($cluster->weight, 1,         "new cluster weight");

my $t2=$t1 + $cluster->interlude - 1;
$pt=GPS::Point->new(lat=>$lat, lon=>$lon, time=>$t2);
$obj=$cluster->merge_attempt($pt);
is($obj,             undef,     "old cluster");
is($cluster->index,  1,         "old cluster index");
is($cluster->start,  $t1,       "old cluster start");
is($cluster->end,    $t2,       "old cluster end");
is($cluster->lat,    $lat,      "old cluster lat");
is($cluster->lon,    $lon,      "old cluster lon");
is($cluster->weight, 2,         "old cluster weight");

my $t3=$t2 + $cluster->interlude + 1;
$pt=GPS::Point->new(lat=>$lat, lon=>$lon, time=>$t3);
$obj=$cluster->merge_attempt($pt);
is($cluster->index,  1,         "old cluster index");
is($cluster->start,  $t1,       "old cluster start");
is($cluster->end,    $t2,       "old cluster end");
is($cluster->lat,    $lat,      "old cluster lat");
is($cluster->lon,    $lon,      "old cluster lon");
is($cluster->weight, 2,         "old cluster weight");
isa_ok($obj, "GPS::Point::Cluster", "new cluster");
is($obj->index,      2,         "new cluster index");
is($obj->start,      $t3,       "new cluster start");
is($obj->end,        $t3,       "new cluster end");
is($obj->lat,        $lat,      "new cluster lat");
is($obj->lon,        $lon,      "new cluster lon");
is($obj->weight,     1,         "new cluster weight");
