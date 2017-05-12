#!/usr/bin/perl
# Check conversions from Geo::Point objects to GML2.
use warnings;
use strict;

use lib 'lib', '../XMLCompile/lib';
use Test::More;
use XML::Compile::Tester;

BEGIN
{   eval { require Geo::Point};
    plan skip_all => 'Geo::Point not installed' if $@;
    plan tests => 9;
}

#use Log::Report mode => 3;
use Geo::GML;
use Geo::GML::Util    ':gml212';

use Data::Dumper;
$Data::Dumper::Indent = 1;

my $gml = Geo::GML->new('WRITER', version => '2.1.2');

my $text = $gml->template(PERL => 'gml:MultiPolygon');

ok(defined $text, 'template generated');
#warn $text;   # debug data-structure

# coords processed as string to avoid rounding differences.
my $line = Geo::Line->filled
  ( [ '6.139263', '53.477199' ]
  , [ '5.359165', '53.588759' ]
  , [ '4.5753',   '53.695178' ]
  , [ '4.224426', '52.762039' ]
  , [ '4.990792', '52.656849' ]
  , [ '5.753162', '52.54677'  ]
  , proj => 'wgs84'
  );

my $poly  = Geo::Space->new($line);
#warn Dumper $poly;

#$gml->printIndex(\*STDERR);

my $data  = $gml->GPtoGML($poly, srs => 'EPGS:4326');
my $expected =
{
  'gml_MultiPolygon' => {
    'srsName' => 'EPGS:4326',
    'seq_gml_polygonMember' => [
      {
        'gml_polygonMember' => {
          'gml_Polygon' => {
            'gml_innerBoundaryIs' => [],
            'gml_outerBoundaryIs' => {
              'gml_LinearRing' => {
                'srsName' => 'EPGS:4326',
                'gml_coordinates' => {
                  'ts' => ' ',
                  'cs' => ',',
                  '_' => '6.139263,53.477199 5.359165,53.588759 4.5753,53.695178 4.224426,52.762039 4.990792,52.656849 5.753162,52.54677 6.139263,53.477199'
                }
              }
            }
          }
        }
      }
    ]
  },
};

is_deeply($data, $expected, 'nested GML surface');

### now create XML

my $w = $gml->writer('gml:multiExtentOf');
isa_ok($w, 'CODE', 'extendOf');

my $doc = XML::LibXML::Document->new('1.0', 'UTF-8');
my $xml = $w->($doc, $expected);   # $expected===$data

compare_xml($xml, <<'_XML');
<gml:multiExtentOf xmlns:gml="http://www.opengis.net/gml"
    xmlns:xlink="http://www.w3.org/1999/xlink">
  <gml:MultiPolygon srsName="EPGS:4326">
    <gml:polygonMember>
      <gml:Polygon>
        <gml:outerBoundaryIs>
          <gml:LinearRing srsName="EPGS:4326">
            <gml:coordinates cs="," ts=" ">6.139263,53.477199
               5.359165,53.588759 4.5753,53.695178 4.224426,52.762039
               4.990792,52.656849 5.753162,52.54677 6.139263,53.477199
            </gml:coordinates>
          </gml:LinearRing>
        </gml:outerBoundaryIs>
      </gml:Polygon>
    </gml:polygonMember>
  </gml:MultiPolygon>
</gml:multiExtentOf>
_XML

#
### Point
#

my $point = Geo::Point->latlong(6.139263, 53.477199, 'wgs84');
isa_ok($point, 'Geo::Point');
my $data2 = $gml->GPtoGML($point, srs => 'EPGS:4326');
my $expected2 =
{
  'gml_Point' => {
    'srsName' => 'EPGS:4326',
    'gml_coord' => {
      'gml_Y' => '6.139263',
      'gml_X' => '53.477199'
    }
  }
};


#warn Dumper $data2;
is_deeply($data2, $expected2, 'GML point');

my $w2 = $gml->writer('gml:centerOf');
isa_ok($w2, 'CODE', 'centerOf');

my $xml2 = $w2->($doc, $data2);

compare_xml($xml2, <<'_XML');
<gml:centerOf xmlns:gml="http://www.opengis.net/gml"
    xmlns:xlink="http://www.w3.org/1999/xlink">
  <gml:Point srsName="EPGS:4326">
    <gml:coord>
      <gml:X>53.477199</gml:X>
      <gml:Y>6.139263</gml:Y>
    </gml:coord>
  </gml:Point>
</gml:centerOf>
_XML

#
### Line
#

my $data3 = $gml->GPtoGML($line, srs => 'EPGS:4326');
my $expected3 =
{
  'gml_LinearRing' => {
    'gml_coordinates' => {
      'ts' => ' ',
      'cs' => ',',
      '_' => '6.139263,53.477199 5.359165,53.588759 4.5753,53.695178 4.224426,52.762039 4.990792,52.656849 5.753162,52.54677 6.139263,53.477199'
    },
    'srsName' => 'EPGS:4326'
  }
};

#warn Dumper $data3;
is_deeply($data3, $expected3, 'GML line');

=for don't know a ring type :(

my $w3 = $gml->writer('gml:centerOf');
isa_ok($w3, 'CODE', 'centerOf');

my $xml3 = $w3->($doc, $data3);

compare_xml($xml3, <<'_XML');

_XML

=cut
