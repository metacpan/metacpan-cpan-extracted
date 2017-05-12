use strict;
use warnings;
use Modern::Perl;

use Test::More tests => 6;
use XML::LibXML;
use XML::SemanticDiff;
BEGIN { use_ok('Geo::OGC::Service::WFS') };

my $xml = <<end;
<Filter xmlns="http://www.opengis.net/fes/2.0" xmlns:gml="http://www.opengis.net/gml/3.2">
  <BBOX>
    <ValueReference>
      geometryProperty
    </ValueReference>
    <gml:Envelope>
      <gml:lowerCorner>
        231640 6794667
      </gml:lowerCorner>
      <gml:upperCorner>
        237728 6798990
      </gml:upperCorner>
    </gml:Envelope>
  </BBOX>
</Filter>
end

my $parser = XML::LibXML->new(no_blanks => 1);
my $dom = $parser->load_xml(string => $xml);
my $sql = Geo::OGC::Service::Filter::filter2sql($dom->documentElement(), { GeometryColumn => 'geom', SRID => 3067 });
is $sql, '("geom" && ST_Transform(ST_MakeEnvelope(231640,6794667,237728,6798990),3067))';

$xml = <<end;
<fes:Filter xmlns:fes="http://www.opengis.net/fes/2.0">
<fes:ResourceId rid="InWaterA_1M.1234"/>
<fes:ResourceId rid="InWaterA_1M.1235"/>
</fes:Filter>
end

$parser = XML::LibXML->new(no_blanks => 1);
$dom = $parser->load_xml(string => $xml);
$sql = Geo::OGC::Service::Filter::filter2sql($dom->documentElement(), { GeometryColumn => 'geom', "gml:id" => 'fid' });
is $sql, "fid = 'InWaterA_1M.1234' OR fid = 'InWaterA_1M.1235'";

$xml = <<end; # from page 132 of 09-025r1, but bug fixed
<fes:Filter xmlns:fes="http://www.opengis.net/fes/2.0" xmlns:gml="http://www.opengis.net/gml/3.2">
<fes:Not>
<fes:Disjoint>
<fes:ValueReference>myns:geoTemp</fes:ValueReference>
<gml:Envelope srsName="urn:ogc;def:crs:EPSG:4326">
<gml:lowerCorner>46.2023 -57.9118 </gml:lowerCorner>
<gml:upperCorner>51.8145 -46.6873</gml:upperCorner>
</gml:Envelope>
</fes:Disjoint>
</fes:Not>
</fes:Filter>
end

$parser = XML::LibXML->new(no_blanks => 1);
$dom = $parser->load_xml(string => $xml);
$sql = Geo::OGC::Service::Filter::filter2sql($dom->documentElement(), { GeometryColumn => 'geom', "gml:id" => 'fid' });
is $sql, "(NOT ST_Disjoint(\"geoTemp\", ST_MakeEnvelope(46.2023,-57.9118,51.8145,-46.6873,4326)))";

$xml = <<end;
<fes:Filter xmlns:fes="http://www.opengis.net/fes/2.0" xmlns:gml="http://www.opengis.net/gml/3.2">
<fes:Within>
<fes:ValueReference>wkbGeom</fes:ValueReference>
<gml:Polygon srsName="urn:ogc:def:crs:EPSG::4326" gml:id="pp9">
<gml:exterior>
<gml:LinearRing>
<gml:posList>-30.15 115.03 -30.17
115.02 -30.16 115.02 -30.15 115.02 -30.15 115.02 -30.15 115.02 -30.14
115.03 -30.15 115.03 </gml:posList>
</gml:LinearRing>
</gml:exterior>
</gml:Polygon>
</fes:Within>
</fes:Filter>
end

$parser = XML::LibXML->new(no_blanks => 1);
$dom = $parser->load_xml(string => $xml);
$sql = Geo::OGC::Service::Filter::filter2sql($dom->documentElement(), { GeometryColumn => 'geom', "gml:id" => 'fid' });
is $sql, "ST_Within(\"wkbGeom\", ST_GeometryFromText('POLYGON ((-30.15 115.03, -30.17 115.02, -30.16 115.02, -30.15 115.02, -30.15 115.02, -30.15 115.02, -30.14 115.03, -30.15 115.03))',4326))";

$xml = <<end;
<ogc:Filter xmlns:ogc="http://www.opengis.net/ogc">
  <ogc:BBOX>
    <gml:Envelope xmlns:gml="http://www.opengis.net/gml" srsName="EPSG:3857">
      <gml:lowerCorner>
        2343329.7146568 8601226.8962494
      </gml:lowerCorner>
      <gml:upperCorner>
        2534422.2853432 8729641.1037506
      </gml:upperCorner>
    </gml:Envelope>
  </ogc:BBOX>
</ogc:Filter>
end

$parser = XML::LibXML->new(no_blanks => 1);
$dom = $parser->load_xml(string => $xml);
$sql = Geo::OGC::Service::Filter::filter2sql($dom->documentElement(), { GeometryColumn => 'geom', "gml:id" => 'fid', SRID => 3210 });
is $sql, "(GeometryColumn && ST_Transform(ST_MakeEnvelope(2343329.7146568,8601226.8962494,2534422.2853432,8729641.1037506,3857),3210))";
