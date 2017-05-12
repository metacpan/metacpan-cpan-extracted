# -*- perl -*-

use Test::More tests => 17;

BEGIN { use_ok( 'Geo::WebService::OpenCellID' ); }
BEGIN { use_ok( 'Geo::WebService::OpenCellID::Response::cell::getMeasures' ); }
my $content=q{<?xml version="1.0" encoding="UTF-8" ?>
<rsp stat="ok">
 <cell nbSamples="2" lat="38.865953" lon="-77.108595" mnc="784" mcc="608" lac="46156" cellId="40072">
<measure lat="38.865953" lon="-77.108595" takenOn="Sat Feb 28 06:07:12 +0100 2009" takenBy="582" />
<measure lat="38.865953" lon="-77.108595" takenOn="Sat Feb 28 06:07:12 +0100 2009" takenBy="582" />
</cell>
</rsp>};
my $hash=Geo::WebService::OpenCellID->new->data_xml($content);
my $object=Geo::WebService::OpenCellID::Response::cell::getMeasures->new(
             content=>$content,
             url=>"URL",
             data=>$hash);

#use Data::Dumper;
#print Dumper([$object]);
is($object->stat, "ok", "stat");
is($object->content, $content, "content");
is($object->url, "URL", "url");
is($object->lat, "38.865953", "lat");
is($object->lon, "-77.108595", "lon");
#is($object->range, "6000", "range"); #TODO API Update to provide range
is($object->nbSamples, "2", "nbSamples");

my $measure=$object->measures;
is(scalar(@$measure), "2", "measure scalar context");
isa_ok($measure, "ARRAY", "measure scalar context");
isa_ok($measure->[0], "HASH", "measure->[0]");
is($measure->[0]->{"lat"}, "38.865953", "measure->[0]->{lat}");
is($measure->[0]->{"lon"}, "-77.108595", "measure->[0]->{lon}");

my @measure=$object->measures;
is(scalar(@measure), "2", "measure list context");
isa_ok($measure[0], "HASH", "measure[0]");
is($measure[0]->{"lat"}, "38.865953", "measure[0]->{lat}");
is($measure[0]->{"lon"}, "-77.108595", "measure[0]->{lon}");
