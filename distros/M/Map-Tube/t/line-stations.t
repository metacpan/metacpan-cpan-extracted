#!perl

use 5.006;
use strict; use warnings;
use Test::More;

my $min_ver = '0.87';
eval "use Map::Tube::London $min_ver tests => 1";
plan skip_all => "Map::Tube::London $min_ver required." if $@;

my $map  = Map::Tube::London->new;
my $line = 'Bakerloo';

my $exp = $map->get_stations($map->get_line_by_name($line));
my $got = $map->get_line_by_name($line)->get_stations;

is_deeply($exp, $got, "Test index station for line.");

done_testing();