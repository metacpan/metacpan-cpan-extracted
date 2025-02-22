#!perl
use 5.12.0;
use strict;
use warnings FATAL => 'all';
use Test::More 0.82;
use Map::Tube::Oslo;

eval 'use Test::Map::Tube';
plan skip_all => 'Test::Map::Tube required for this test' if $@;
plan skip_all => 'these tests are for authors only!' unless ( $ENV{AUTHOR_TESTING} ||  $ENV{RELEASE_TESTING} );

if ( Test::Map::Tube->can('ok_links_bidirectional') ) {
  # We have a more powerful version of Test::Map::Tube at disposal!
  plan tests => 1;

  ok_map( Map::Tube::Oslo->new( ), {
              ok_links_bidirectional     => { exclude => [ qw( OSL_1 OSL_13 OSL_17 OSL_18 OSL_19 ) ] },
              ok_station_names_different => { max_allowed => 20 },
              ok_station_names_complete  => { max_allowed => 10 },
          } );
} else {
  ok_map( Map::Tube::Oslo->new( ) );
}

