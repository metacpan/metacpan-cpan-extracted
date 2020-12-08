#!perl -T

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

my $min_ver = 0.35;
eval "use Test::Map::Tube $min_ver tests => 3";
plan skip_all => "Test::Map::Tube $min_ver required." if $@;

use utf8;
use Map::Tube::Berlin;
my $map = Map::Tube::Berlin->new;
ok_map($map);
ok_map_functions($map);

my @routes = <DATA>;
ok_map_routes($map, \@routes);

__DATA__
Route 1|Adenauerplatz|Savignyplatz|Adenauerplatz,Wilmersdorfer Str.,Charlottenburg,Savignyplatz
Route 2|platz der luftbrücke|möckernbrücke|Platz der Luftbrücke,Mehringdamm,Möckernbrücke
Route 3|Friedrichstr.|Alexanderplatz|Friedrichstr.,Hackescher Markt,Alexanderplatz
Route 4|Treptower Park|Warschauer Str.|Treptower Park,Warschauer Str.
Route 5|Stadtmitte|Rotes Rathaus|Stadtmitte,Unter den Linden,Rotes Rathaus
