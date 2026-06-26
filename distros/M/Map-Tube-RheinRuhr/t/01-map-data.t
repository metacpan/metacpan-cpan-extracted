#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More 0.82;
use Map::Tube::RheinRuhr;

eval 'use Test::Map::Tube';
plan skip_all => 'Test::Map::Tube required for this test' if $@;
plan skip_all => 'these tests are for authors only!' unless ( $ENV{AUTHOR_TESTING} ||  $ENV{RELEASE_TESTING} );
if ( Test::Map::Tube->can('ok_links_bidirectional') ) {
  # We have a more powerful version of Test::Map::Tube at disposal!
  plan tests => 1;

  ok_map( Map::Tube::RheinRuhr->new( ), {
              ok_links_bidirectional     => { exclude => [ qw( VRR_101_10 VRR_705 VRR_706 VRR_707 VRR_U73 VRR_U78 ) ] },
              ok_station_names_different => { dist_limit => 1, max_allowed => 4 },
              ok_map_connected           => { max_allowed => 4 },
          } );
} else {
  ok_map( Map::Tube::RheinRuhr->new( ) );
}

