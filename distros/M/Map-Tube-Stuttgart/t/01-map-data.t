#!perl
use 5.12.0;
use strict;
use warnings FATAL => 'all';
use Test::More 0.82;
use Map::Tube::Stuttgart;

eval 'use Test::Map::Tube';
plan skip_all => 'Test::Map::Tube required for this test' if $@;
plan skip_all => 'these tests are for authors only!' unless ( $ENV{AUTHOR_TESTING} ||  $ENV{RELEASE_TESTING} );

plan tests => 1;

ok_map( Map::Tube::Stuttgart->new( ), {
            ok_links_bidirectional     => 1, # { exclude => [ 'BX_8', 'BX_25' ] },
            ok_station_names_different => { max_allowed => 2 },
            ok_station_names_complete  => { max_allowed => 12 },
        } );

