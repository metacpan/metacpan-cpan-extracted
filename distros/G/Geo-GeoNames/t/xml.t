#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Geo::GeoNames;

# http://api.geonames.org/get?geonameId=1&username=demo&type=json - as you can see this only returns XML
my $get_xml =<< 'XML'
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<geoname>
<toponymName>Kūh-e Zardar</toponymName>
<name>Kūh-e Zardar</name>
<lat>32.98333</lat>
<lng>49.13333</lng>
<geonameId>1</geonameId>
<countryCode>IR</countryCode>
<countryName>Iran</countryName>
<fcl>T</fcl>
<fcode>MT</fcode>
<fclName>mountain,hill,rock,... </fclName>
<fcodeName>mountain</fcodeName>
<population/>
<asciiName>Kuh-e Zardar</asciiName>
<alternateNames>Kuh-e Zardar,Kūh-e Zardar</alternateNames>
<elevation/>
<srtm3>1473</srtm3>
<continentCode>AS</continentCode>
<adminCode1 ISO3166-2="20">23</adminCode1>
<adminName1>Lorestān</adminName1>
<adminCode2/>
<adminName2/>
<alternateName lang="fa">Kūh-e Zardar</alternateName>
<timezone dstOffset="4.5" gmtOffset="3.5">Asia/Tehran</timezone>
<bbox>
<west>21.72792</west>
<north>42.39132</north>
<east>21.74009</east>
<south>42.38233</south>
</bbox>
</geoname>
XML
;

my $get_exp = [
  {
    'adminCode1' => {
      'content' => '23',
      'ISO3166-2' => '20'
    },
    'geonameId' => '1',
    'lng' => '49.13333',
    'continentCode' => 'AS',
    'alternateName' => {
      'content' => "K\x{16b}h-e Zardar",
      'lang' => 'fa'
    },
    'adminName2' => {},
    'timezone' => {
      'content' => 'Asia/Tehran',
      'gmtOffset' => '3.5',
      'dstOffset' => '4.5'
    },
    'fclName' => 'mountain,hill,rock,... ',
    'countryCode' => 'IR',
    'alternateNames' => "Kuh-e Zardar,K\x{16b}h-e Zardar",
    'toponymName' => "K\x{16b}h-e Zardar",
    'elevation' => {},
    'adminCode2' => {},
    'lat' => '32.98333',
    'asciiName' => 'Kuh-e Zardar',
    'fcodeName' => 'mountain',
    'srtm3' => '1473',
    'population' => {},
    'countryName' => 'Iran',
    'fcl' => 'T',
    'fcode' => 'MT',
    'name' => "K\x{16b}h-e Zardar",
    'adminName1' => "Lorest\x{101}n",
    'bbox' => {
      'west' => [
        '21.72792'
      ],
      'north' => [
        '42.39132'
      ],
      'south' => [
        '42.38233'
      ],
      'east' => [
        '21.74009'
      ]
    }
  }
];

is_deeply(Geo::GeoNames->_parse_xml_result($get_xml, 1), $get_exp, 'XML is parsed correctly');

# http://api.geonames.org/search?username=demo&maxRows=1&style=FULL&type=xml
my $search_in =<< 'XML'
<geonames style="FULL">
  <totalResultsCount>10740710</totalResultsCount>
  <geoname>
    <toponymName>Roxton</toponymName>
    <name>Roxton</name>
    <lat>33.54622</lat>
    <lng>-95.72579</lng>
    <geonameId>4724202</geonameId>
    <countryCode>US</countryCode>
    <countryName>United States</countryName>
    <fcl>P</fcl>
    <fcode>PPL</fcode>
    <fclName>city, village,...</fclName>
    <fcodeName>populated place</fcodeName>
    <population>650</population>
    <asciiName>Roxton</asciiName>
    <alternateNames/>
    <elevation>156</elevation>
    <continentCode>NA</continentCode>
    <adminCode1 ISO3166-2="TX">TX</adminCode1>
    <adminName1>Texas</adminName1>
    <adminCode2>277</adminCode2>
    <adminName2>Lamar County</adminName2>
    <alternateName lang="link">http://en.wikipedia.org/wiki/Roxton%2C_Texas</alternateName>
    <alternateName lang="post">75477</alternateName>
    <timezone dstOffset="-5.0" gmtOffset="-6.0">America/Chicago</timezone>
    <bbox><west>-95.72687</west><north>33.54712</north><east>-95.72472</east><south>33.54532</south></bbox>
    <score>1.0</score>
  </geoname>
</geonames>
XML
;
my $search_exp = [
  {
    'adminCode1' => {
      'ISO3166-2' => 'TX',
      'content' => 'TX'
    },
    'adminCode2' => '277',
    'adminName1' => 'Texas',
    'adminName2' => 'Lamar County',
    'alternateName' => [ {
        'content' => 'http://en.wikipedia.org/wiki/Roxton%2C_Texas',
        'lang' => 'link'
      },{
        'content' => '75477',
        'lang'    => 'post',
      }
    ],
    'alternateNames' => {},
    'asciiName' => 'Roxton',
    'bbox' => {
      'east' => [
        '-95.72472'
      ],
      'north' => [
        '33.54712'
      ],
      'south' => [
        '33.54532'
      ],
      'west' => [
        '-95.72687'
      ]
    },
    'continentCode' => 'NA',
    'countryCode' => 'US',
    'countryName' => 'United States',
    'elevation' => '156',
    'fcl' => 'P',
    'fclName' => 'city, village,...',
    'fcode' => 'PPL',
    'fcodeName' => 'populated place',
    'geonameId' => '4724202',
    'lat' => '33.54622',
    'lng' => '-95.72579',
    'name' => 'Roxton',
    'population' => '650',
    'score' => '1.0',
    'timezone' => {
      'content' => 'America/Chicago',
      'dstOffset' => '-5.0',
      'gmtOffset' => '-6.0'
    },
    'toponymName' => 'Roxton'
  }
];

is_deeply(Geo::GeoNames->_parse_xml_result($search_in), $search_exp, 'XML is parsed correctly');

done_testing;
