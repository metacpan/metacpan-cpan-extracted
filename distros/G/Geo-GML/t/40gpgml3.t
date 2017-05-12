#!/usr/bin/perl
# Check conversions from Geo::Point objects to GML3.
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
use Geo::GML::Util    ':gml321';

use Data::Dumper;
$Data::Dumper::Indent = 1;

my $gml = Geo::GML->new('WRITER', version => '3.2.1');

# Don't expand these in template display: appears too often
my @collapse_types = qw/
   gml:MetaDataPropertyType
   gml:StringOrRefType
   gml:ReferenceType
 /;

my $text = $gml->template
 ( PERL => 'gml:Polygon'
 , hooks => [ { type => \@collapse_types, replace => 'COLLAPSE' } ]
 ); 

ok(defined $text, 'template generated');
#warn $text;

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

my $poly  = Geo::Surface->new($line);
#warn Dumper $poly;

#$gml->printIndex(\*STDERR);

my $data  = $gml->GPtoGML($poly, srs => 'EPGS:4326');
my $expected =
{
  'gml_MultiSurface' => {
    'srsName' => 'EPGS:4326',
    'gml_surfaceMembers' => {

#     'gml__Surface' => [              # in GML3.1.1 syntax
      'seq_gml_AbstractSurface' => [   # in GML3.2.1 syntax
        { 'gml_Polygon' => {
            'gml_interior' => [],
            'gml_exterior' => {
              'gml_LinearRing' => {
                'gml_posList' => {
                  'count' => 7,
                  '_' => [
                    '53.477199', '6.139263',
                    '53.588759', '5.359165',
                    '53.695178', '4.5753',
                    '52.762039', '4.224426',
                    '52.656849', '4.990792',
                    '52.54677',  '5.753162',
                    '53.477199', '6.139263'
                  ]
                }
              }
            }
          }
        }
      ]
    }
  }
};

is_deeply($data, $expected, 'nested GML surface');

### now create XML

my $w = $gml->writer('gml:multiExtentOf');
isa_ok($w, 'CODE', 'extendOf');

my $doc = XML::LibXML::Document->new('1.0', 'UTF-8');
my $xml = $w->($doc, $expected);   # $expected===$data

compare_xml($xml, <<'_XML');
<gml:multiExtentOf xmlns:gml="http://www.opengis.net/gml/3.2">
  <gml:MultiSurface srsName="EPGS:4326">
    <gml:surfaceMembers>
      <gml:Polygon>
        <gml:exterior>
          <gml:LinearRing>
            <gml:posList count="7">
              53.477199 6.139263 53.588759 5.359165 53.695178 4.5753
              52.762039 4.224426 52.656849 4.990792 52.54677 5.753162
              53.477199 6.139263
            </gml:posList>
          </gml:LinearRing>
        </gml:exterior>
      </gml:Polygon>
    </gml:surfaceMembers>
  </gml:MultiSurface>
</gml:multiExtentOf>
_XML

#
### Point
#

my $point = Geo::Point->latlong(6.139263, 53.477199, 'wgs84');
isa_ok($point, 'Geo::Point');
my $data2 = $gml->GPtoGML($point, srs => 'EPGS:4326');
my $expected2 = {
  gml_Point =>
  { srsName => 'EPGS:4326'
  , gml_pos => { _ => [ '6.139263', '53.477199' ] }
  }
};

#warn Dumper $data2;
is_deeply($data2, $expected2, 'GML point');

my $w2 = $gml->writer('gml:centerOf');
isa_ok($w2, 'CODE', 'centerOf');

my $xml2 = $w2->($doc, $data2);

compare_xml($xml2, <<'_XML');
<gml:centerOf xmlns:gml="http://www.opengis.net/gml/3.2">
  <gml:Point srsName="EPGS:4326">
    <gml:pos>6.139263 53.477199</gml:pos>
  </gml:Point>
</gml:centerOf>
_XML

#
### Line
#

my $data3 = $gml->GPtoGML($line, srs => 'EPGS:4326');
my $expected3 = {
  'gml_LinearRing' => {
    'srsName' => 'EPGS:4326',
    'gml_posList' => {
      'count' => 7,
      '_' => [
        '53.477199', '6.139263',
        '53.588759', '5.359165',
        '53.695178', '4.5753',
        '52.762039', '4.224426',
        '52.656849', '4.990792',
        '52.54677', '5.753162',
        '53.477199', '6.139263'
      ]
    }
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
