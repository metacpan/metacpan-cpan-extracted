#!perl
use 5.14.0;
use strict;
use utf8;
use warnings FATAL => 'all';
use Test::More 0.82;
use Map::Tube::Glasgow;

eval 'use Test::Map::Tube tests => 3';
plan skip_all => 'Test::Map::Tube required for this test' if $@;

my $map = new_ok( 'Map::Tube::Glasgow' );

ok_map_functions($map);

my @routes = <DATA>;
ok_map_routes( $map, \@routes );

__DATA__
Route 1|Cowcaddens|Ibrox|Cowcaddens, St George's Cross, Kelvinbridge, Hillhead, Kelvinhall, Partick, Govan, Ibrox
Route 2|hillhead|IBROX|Hillhead, Kelvinhall, Partick, Govan, Ibrox
