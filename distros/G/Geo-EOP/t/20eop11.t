#!/usr/bin/env perl
# Try to read the two provided examples
use warnings;
use strict;

use lib 'lib';
use Test::More tests => 7;
#use Log::Report mode => 3;

use Geo::EOP;

use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Quotekeys = 0;

my $eop = Geo::EOP->new
  ( eop_version => '1.1'
  , units => {angle => 'deg', distance => 'm', percentage => 'float'}
  );

isa_ok($eop, 'Geo::EOP');

my $dir = (-d 't' ? '.' : '..') . '/examples/eop1.1';

###### try example 1

my $r1  = $eop->reader('eop:EarthObservation');
isa_ok($r1, 'CODE', 'first example');

my $d1 = $r1->("$dir/eop_example.xml");
isa_ok($d1, 'HASH', 'read data');

#warn Dumper $d1;

# just one complex location to check the whole parsing
is($d1->{gml_target}{eop_Footprint}{gml_multiExtentOf}{gml_MultiSurface}{srsName}, 'EPSG:4326');


###### try example 2

my $r2  = $eop->reader('opt:EarthObservation');
isa_ok($r2, 'CODE', 'second example');

my $d2 = $r2->("$dir/opt_example.xml");
isa_ok($d2, 'HASH', 'read data');

# interesting:
#warn Dumper $d2;

# just one complex location to check the whole parsing
is($d2->{gml_target}{eop_Footprint}{gml_multiExtentOf}{gml_MultiSurface}{srsName}, 'EPSG:4326');
