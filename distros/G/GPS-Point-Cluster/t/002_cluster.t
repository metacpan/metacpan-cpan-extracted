# -*- perl -*-
use Test::More tests => 565;

BEGIN { use_ok( 'GPS::Point::Cluster' ); }
BEGIN { use_ok( 'GPS::Point' ); }

my $cluster=GPS::Point::Cluster->new();
isa_ok($cluster, 'GPS::Point::Cluster');

foreach my $time (0 .. 50) {
  my $lat=25.938743;
  my $lon=-80.138647;
  my $pt=GPS::Point->new(lat=>$lat, lon=>$lon, 'time'=>$time);
  isa_ok($pt, "GPS::Point", "GPS::Point");
  is($pt->lat,  $lat,  'lat');
  is($pt->lon,  $lon,  'lon');
  is($pt->time, $time, 'time');
  #printf "Time: %s, Lat: %s, Lon: %s\n", $pt->time, $pt->latlon;
  my $obj=$cluster->merge_attempt($pt);
  if (0 == $time) {
    #new cluster
    isa_ok($obj, "GPS::Point::Cluster");
    $cluster=$obj;
    isa_ok($cluster, "GPS::Point::Cluster");
    is($cluster->index, 1, "new cluster index, time: $time");
    is($cluster->start, 0, "new cluster start");
    is($cluster->end, 0, "new cluster end");
    is($cluster->lat, $lat, "new cluster lat");
    is($cluster->lon, $lon, "new cluster lon");
    is($cluster->weight, 1, "new cluster weight");
  } else {
    #old cluster
    is($obj,             undef,     "old cluster");
    is($cluster->index,  1,         "old cluster index, time: $time");
    is($cluster->start,  0,         "old cluster start");
    is($cluster->end,    $time,     "old cluster end");
    #is($cluster->lat, $lat,    "lat");
    #is($cluster->lon, $lon,    "lon");
    ok(near($cluster->lat, $lat,    12), "lat");
    ok(near($cluster->lon, $lon,    12), "lon");
    is($cluster->weight, $time + 1, "old cluster weight");
  }
}

sub near {
  my $x=shift();
  my $y=shift();
  my $p=shift()||12;
  if (abs(($x-$y)/$y) < 10**-$p) {
    return 1;
  } else {
    return 0;
  }
}

