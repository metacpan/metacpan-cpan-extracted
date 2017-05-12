# -*- perl -*-

use Test::More tests => 9;

BEGIN { use_ok( 'Geo::WebService::OpenCellID' ); }
BEGIN { use_ok( 'Geo::WebService::OpenCellID::Response::cell::get' ); }
my $content=q{<?xml version="1.0" encoding="UTF-8"?><rsp stat="ok"><cell mnc="99" lat="57.8240013122559" lac="0" lon="28.00119972229" nbSamples="38" cellId="29513" range="6000" mcc="250"/></rsp>};
my $hash=Geo::WebService::OpenCellID->new->data_xml($content);
my $object=Geo::WebService::OpenCellID::Response::cell::get->new(
             content=>$content,
             url=>"URL",
             data=>$hash);

#use Data::Dumper;
#print Dumper([$object]);
is($object->stat, "ok", "stat");
is($object->content, $content, "content");
is($object->url, "URL", "url");
is($object->lat, "57.8240013122559", "lat");
is($object->lon, "28.00119972229", "lon");
is($object->range, "6000", "range");
is($object->nbSamples, "38", "nbSamples");
