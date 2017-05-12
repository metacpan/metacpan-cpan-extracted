# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 36;
use Test::Number::Delta;

BEGIN { use_ok( 'GPS::Point' ); }

my $pt1 = GPS::Point->new(lat=>39,
                          lon=>-77,
                          mode=>2);
isa_ok ($pt1, 'GPS::Point');

is($pt1->lat,  39, "lat");
is($pt1->lon, -77, "lon");
is($pt1->mode, 2, "lon");

is($pt1->fix, "1", "fix method");
$pt1->mode(undef);
is($pt1->fix, "0", "fix method");
$pt1->mode(3);
is($pt1->fix, "1", "fix method");

is(scalar($pt1->latlon), "39 -77", "latlon method scalar context");

my @latlon=$pt1->latlon;
is($latlon[0],  39, "latlon method array context");
is($latlon[1], -77, "latlon method array context");

SKIP: {
  eval { require Geo::ECEF };
  skip "Geo::ECEF not installed", 5 if $@;

  ok(1, "We have Geo::ECEF but is it geo::ecef on Win32?");

  my $sub=Geo::ECEF->can("new");
  skip "We have geo::ecef but need Geo::ECEF on Win32", 4 unless $sub;

  ok(1, "Running tests that require Geo::ECEF");

  my @xyz=$pt1->ecef;
  delta_ok($xyz[0], 3857229.79658403, "ecef method x" );
  delta_ok($xyz[1], 3123523.10163777, "ecef method y" );
  delta_ok($xyz[2], 3992317.02275173, "ecef method z" );
}

SKIP: {
  eval { require Geo::Point };
  skip "Geo::Point not installed", 5 if $@;

  ok(1, "Running tests that require Geo::Point");

  my $pt=$pt1->GeoPoint;
  is( ref($pt),   "Geo::Point", "Geo::Point");
  is( $pt->lat,   "39",         "GeoPoint->lat");
  is( $pt->long,  "-77",        "GeoPoint->long");
  is( $pt->proj,  "wgs84",      "GeoPoint->proj");
}

SKIP: {
  eval { require Geo::Inverse };
  skip "Geo::Inverse not installed", 5 if $@;

  ok(1, "Running tests that require Geo::Inverse");

  my $pt1=GPS::Point->new(lat=>39,   lon=>-77);
  my $pt2=GPS::Point->new(lat=>39.1, lon=>-77.1);
  my @dist=$pt1->distance($pt2);
  delta_ok($dist[2], 14077.7169524386, "distance method array context");
  delta_ok($dist[0], 322.08605713267, "distance faz");
  delta_ok($dist[1], 142.02305726502, "distance baz");

  my $dist=$pt1->distance($pt2);
  delta_ok( $dist, "14077.7169524386", "distance method scalar context");
}

SKIP: {
  eval { require Geo::Forward };
  skip "Geo::Forward not installed", 5 if $@;

  ok(1, "Running tests that require Geo::Forward");

  my $pt1=GPS::Point->new(lat=>39, lon=>-77, heading=>322.08605713267, speed=>100);
  my $pt2=$pt1->forward(14077.7169524386);
  delta_ok($pt2->lat, 39.1, 'forward->lat');
  delta_ok($pt2->lon, -77.1, 'forward->lon');

  my $pt3=$pt1->track(140.777169524386);
  delta_ok($pt3->lat, 39.1, 'track->lat');
  delta_ok($pt3->lon, -77.1, 'track->lon');
}

my $pt4=GPS::Point->new(time=>"1260855713");
is($pt4->time, "1260855713", "time method" );

SKIP: {
  eval { require DateTime };
  skip "DateTime not installed", 4 if $@;

  ok(1, "Running tests that require DateTime");

  isa_ok($pt4->datetime,       "DateTime",            "datetime method" );
  is($pt4->datetime->datetime, "2009-12-15T05:41:53", "datetime method" );
  is($pt4->datetime->epoch,    "1260855713",          "datetime method" );
}
