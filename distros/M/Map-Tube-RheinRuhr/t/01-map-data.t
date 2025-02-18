#!perl
use 5.12.0;
use strict;
use warnings FATAL => 'all';
use Test::More 0.82;
use Map::Tube::RheinRuhr;

eval 'use Test::Map::Tube';
plan skip_all => 'Test::Map::Tube required for this test' if $@;
plan skip_all => 'these tests are for authors only!' unless ( $ENV{AUTHOR_TESTING} ||  $ENV{RELEASE_TESTING} );
if ( Test::Map::Tube->can('ok_links_bidirectional') ) {
  # We have a more powerful version of Test::Map::Tube at disposal!
  plan tests => 1;

  ok_map( Map::Tube::RheinRuhr->new( ), {
              ok_links_bidirectional     => { exclude => [ qw( vrr_101_106 vrr_705 vrr_706 vrr_709 vrr_H_BAHN vrr_U73 vrr_U78 vrr_U83 ) ] },
              ok_station_names_different => { dist_limit => 1, max_allowed => 4 },
              ok_map_connected           => { max_allowed => 4 },
          } );
} else {
  ok_map( Map::Tube::RheinRuhr->new( ) );
}

