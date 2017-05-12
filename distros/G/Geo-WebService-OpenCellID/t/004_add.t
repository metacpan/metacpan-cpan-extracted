# -*- perl -*-

use Test::More tests => 8;

BEGIN { use_ok( 'Geo::WebService::OpenCellID' ); }
BEGIN { use_ok( 'Geo::WebService::OpenCellID::Response::measure::add' ); }
my $content=q{<?xml version="1.0" encoding="UTF-8" ?> 
  <rsp cellid="126694" id="6121024" stat="ok">
    <res>Measure added, id:6121024</res> 
  </rsp>
};
my $hash=Geo::WebService::OpenCellID->new->data_xml($content);
my $object=Geo::WebService::OpenCellID::Response::measure::add->new(
             content=>$content,
             url=>"URL",
             data=>$hash);

#use Data::Dumper;
#print Dumper([$object]);
is($object->stat, "ok", "stat");
is($object->content, $content, "content");
is($object->url, "URL", "url");
is($object->cellid, "126694", "cellid");
is($object->id, "6121024", "id");
is($object->res, "Measure added, id:6121024", "res");
