#!perl
use 5.12.0;
use strict;
use warnings FATAL => 'all';
use Test::More 0.82;
use Map::Tube::SanFrancisco;

eval 'use Test::Map::Tube';
plan skip_all => 'Test::Map::Tube required for this test' if $@;
plan skip_all => 'these tests are for authors only!' unless ( $ENV{AUTHOR_TESTING} ||  $ENV{RELEASE_TESTING} );

plan tests => 1;

ok_map( Map::Tube::SanFrancisco->new( ), {
            ok_links_bidirectional     => undef,
        } );

