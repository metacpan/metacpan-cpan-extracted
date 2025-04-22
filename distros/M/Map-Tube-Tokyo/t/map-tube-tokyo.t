#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
#use Carp::Always;
#use open ':std', ':encoding(UTF-8)';

my $min_ver = 0.35;
eval "use Test::Map::Tube $min_ver tests => 4";
plan skip_all => "Test::Map::Tube $min_ver required." if $@;

use utf8;
use Map::Tube::Tokyo;

my $map = new_ok('Map::Tube::Tokyo');
ok_map($map);
ok_map_functions($map);

my @routes = <DATA>;
ok_map_routes($map, \@routes);

__DATA__
Route 1|Takaracho|Otemachi|Takaracho,Nihombashi,Otemachi
