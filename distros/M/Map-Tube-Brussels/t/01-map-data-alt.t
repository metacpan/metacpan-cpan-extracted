#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More 0.82;
use Map::Tube::Brussels;

eval 'use Test::Map::Tube';
plan skip_all => 'Test::Map::Tube required for this test' if $@;
plan skip_all => 'these tests are for authors only!' unless ( $ENV{AUTHOR_TESTING} ||  $ENV{RELEASE_TESTING} );

plan tests => 1;

ok_map( Map::Tube::Brussels->new( nametype => 'alt' ), {
            ok_links_bidirectional     => { exclude => [ 'BX_8', 'BX_25' ] },
            ok_station_names_different => { max_allowed => 2, dist_limit  => 1 },
            ok_station_names_complete  => { max_allowed => 7 },
        } );

