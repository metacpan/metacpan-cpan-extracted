#!perl
use v5.14.0;
use strict;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More 0.82;
use Map::Tube::Madrid;

eval 'use Test::Map::Tube';
plan skip_all => 'Test::Map::Tube required for this test' if $@;
plan skip_all => 'these tests are for authors only!' unless ( $ENV{AUTHOR_TESTING} ||  $ENV{RELEASE_TESTING} );
plan tests => 1;
if ( Test::Map::Tube->can('ok_links_bidirectional') ) {
  # We have a more powerful version of Test::Map::Tube at disposal!
  ok_map( Map::Tube::Madrid->new( ) );
} else {
  ok_map( Map::Tube::Madrid->new( ) );
}

