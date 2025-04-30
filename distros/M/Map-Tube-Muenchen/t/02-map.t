#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More 0.82;
use Map::Tube::Muenchen;

eval 'use Test::Map::Tube tests => 3';
plan skip_all => 'Test::Map::Tube required for this test' if $@;

my $map = new_ok( 'Map::Tube::Muenchen' );

ok_map_functions($map);

my @routes = <DATA>;
ok_map_routes( $map, \@routes );

__DATA__
Route 1|Olympiazentrum|Maxmonument|Olympiazentrum, Petuelring, Scheidplatz, Bonner Platz, Münchner Freiheit, Giselastr., Universität, Odeonsplatz, Lehel, Maxmonument
Route 2|PASING|sandstr.|Pasing, Heimeranplatz, Schwanthalerhöhe, Theresienwiese, Hauptbahnhof, Stiglmaierplatz, Sandstr.
