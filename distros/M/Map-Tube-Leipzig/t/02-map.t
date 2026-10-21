#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More 0.82;
use Map::Tube::Leipzig;

my $min_ver = 0.44;
eval "use Test::Map::Tube $min_ver tests => 3";
plan skip_all => "Test::Map::Tube $min_ver required." if $@;

my $map = new_ok( 'Map::Tube::Leipzig' );

ok_map_functions($map);

my @routes = <DATA>;
ok_map_routes( $map, \@routes );

__DATA__
Route 1|Trotha|Halle Messe|Trotha,Wohnstadt Nord,Zoo,Dessauer Brücke,Steintorbrücke,Halle Hbf,Halle Messe
Route 2|trotha|HALLE MESSE|Trotha,Wohnstadt Nord,Zoo,Dessauer Brücke,Steintorbrücke,Halle Hbf,Halle Messe
