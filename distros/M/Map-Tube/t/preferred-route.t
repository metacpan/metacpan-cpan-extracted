#!perl

use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;

my $min_ver = 1.41;
eval "use Map::Tube::London $min_ver";
plan skip_all => "Map::Tube::London $min_ver required for this test" if $@;

my $map = new_ok( 'Map::Tube::London' );

my $ret = $map->get_shortest_route('Barking', 'Morden');
isa_ok( $ret, 'Map::Tube::Route' );
is( $ret,
    join( ', ',
          'Barking (District, Hammersmith and City, Suffragette)',
          'East Ham (District, Hammersmith and City)',
          'Upton Park (District, Hammersmith and City)',
          'Plaistow (District, Hammersmith and City)',
          'West Ham (DLR, District, Hammersmith and City, Jubilee)',
          'Stratford (Central, DLR, Elizabeth, Jubilee, Mildmay)',
          'Whitechapel (District, Elizabeth, Hammersmith and City, Windrush)',
          'Shadwell (DLR, Windrush)',
          'Bank (Central, DLR, Northern, Tunnel, Waterloo and City)',
          'Waterloo (Bakerloo, Jubilee, Northern, Waterloo and City)',
          'Kennington (Northern)',
          'Oval (Northern)',
          'Stockwell (Northern, Victoria)',
          'Clapham North (Northern)',
          'Clapham Common (Northern)',
          'Clapham South (Northern)',
          'Balham (Northern)',
          'Tooting Bec (Northern)',
          'Tooting Broadway (Northern)',
          'Colliers Wood (Northern)',
          'South Wimbledon (Northern)',
          'Morden (Northern)',
         ),
    'Barking - Morden: full version'
  );

$ret = $ret->preferred( );
isa_ok( $ret, 'Map::Tube::Route' );
is( $ret,
    join( ', ',
          'Barking (District, Hammersmith and City)',
          'East Ham (District, Hammersmith and City)',
          'Upton Park (District, Hammersmith and City)',
          'Plaistow (District, Hammersmith and City)',
          'West Ham (DLR, District, Hammersmith and City, Jubilee)',
          'Stratford (DLR, Elizabeth, Jubilee)',
          'Whitechapel (Elizabeth, Windrush)',
          'Shadwell (DLR, Windrush)',
          'Bank (DLR, Northern, Waterloo and City)',
          'Waterloo (Northern, Waterloo and City)',
          'Kennington (Northern)',
          'Oval (Northern)',
          'Stockwell (Northern)',
          'Clapham North (Northern)',
          'Clapham Common (Northern)',
          'Clapham South (Northern)',
          'Balham (Northern)',
          'Tooting Bec (Northern)',
          'Tooting Broadway (Northern)',
          'Colliers Wood (Northern)',
          'South Wimbledon (Northern)',
          'Morden (Northern)',
         ),
    'Barking - Morden: preferred version'
  );

done_testing;
