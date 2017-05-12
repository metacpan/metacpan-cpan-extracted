#!perl -T

use strict;
use Test::More  tests => 1;

use Geo::Parse::OSM;


my $osmdata = <<'OSM';
<?xml version="1.0" encoding="UTF-8"?>
<osm version="0.6" generator="OpenStreetMap server">
  <node id="317236007" lat="55.8379347" lon="37.6608305" version="2" changeset="3790696" user="Calibrator" uid="154487" visible="true" timestamp="2010-02-04T14:39:08Z"/>
  <node id="317236016" lat="55.8378621" lon="37.6610035" version="2" changeset="3790696" user="Calibrator" uid="154487" visible="true" timestamp="2010-02-04T14:39:08Z"/>
  <node id="317236021" lat="55.8383759" lon="37.6616864" version="2" changeset="3790696" user="Calibrator" uid="154487" visible="true" timestamp="2010-02-04T14:39:08Z"/>
  <node id="317236012" lat="55.8384484" lon="37.6615134" version="2" changeset="3790696" user="Calibrator" uid="154487" visible="true" timestamp="2010-02-04T14:39:09Z"/>
  <way id="28855119" visible="true" timestamp="2010-11-22T02:03:40Z" version="3" changeset="6428552" user="AMDmi3" uid="133332">
    <nd ref="317236007"/>
    <nd ref="317236016"/>
    <nd ref="317236021"/>
    <nd ref="317236012"/>
    <nd ref="317236007"/>
    <tag k="addr:housenumber" v="200К1"/>
    <tag k="building" v="yes"/>
    <tag k="cladr:code" v="77000000000185600"/>
  </way>
</osm>
OSM


our $objcount;

Geo::Parse::OSM->parse_file( \$osmdata, sub{ $objcount ++ } );

is( $objcount, 5, 'count objects' );


