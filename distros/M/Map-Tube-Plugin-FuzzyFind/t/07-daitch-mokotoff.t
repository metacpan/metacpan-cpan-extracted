#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More 0.82;

eval 'use Map::Tube::London 1.39';
plan skip_all => 'Map::Tube::London (>= 1.39) required for this test' if $@;
eval 'use Text::Phonetic::DaitchMokotoff';
plan skip_all => 'Text::Phonetic::DaitchMokotoff required for this test'      if $@;

plan tests => 15;

sub a2n { return [ map { $_->name( ) } @{ $_[0] } ]; }

diag( "*** Expect many messages saying 'Negative repeat count does nothing at ...' -- ignore these, please! *** \n",
      "*** (They are coming from Text::Phonetic::DaitchMokotoff. They are ugly but functionally harmless.)  ***" );

my $tube = new_ok( 'Map::Tube::London' );
my $ret;

$ret = $tube->fuzzy_find( 'Bakerloo', objects => 'lines', method => 'daitchmokotoff' );
is( $ret, 'Bakerloo', 'Finding line Bakerloo based on Daitch-Mokotoff' );

$ret = $tube->fuzzy_find( 'Bkrl', objects => 'lines', method => 'daitchmokotoff' );
is( $ret, 'Bakerloo', 'Finding line Bkrl based on Daitch-Mokotoff' );

$ret = $tube->fuzzy_find( 'Bxqxq', objects => 'lines', method => 'daitchmokotoff' );
is( $ret, undef, 'Finding line Bxqxq based on Daitch-Mokotoff should fail' );

$ret = [ $tube->fuzzy_find( 'Bakerloo', objects => 'lines', method => 'daitchmokotoff' ) ];
is_deeply( $ret, [ 'Bakerloo' ], 'Finding many lines Bakerloo based on Daitch-Mokotoff' );

$ret = [ $tube->fuzzy_find( 'Bkrl', objects => 'lines', method => 'daitchmokotoff' ) ];
is_deeply( $ret, [ 'Bakerloo' ], 'Finding many lines Bkrl based on Daitch-Mokotoff' );

$ret = [ $tube->fuzzy_find( 'Bxqxq', objects => 'lines', method => 'daitchmokotoff' ) ];
is_deeply( $ret, [ ], 'Finding many lines Bxqxq based on Daitch-Mokotoff should fail' );

$ret = $tube->fuzzy_find( 'Baker Street', objects => 'stations', method => 'daitchmokotoff' );
ok( $ret, 'Finding station Baker Street based on Daitch-Mokotoff' );
is( $ret->name(), 'Baker Street', 'Finding station Baker Street based on Daitch-Mokotoff' );

$ret = $tube->fuzzy_find( 'Bkstrt', objects => 'stations', method => 'daitchmokotoff' );
ok( $ret, 'Finding station Bkstrt based on Daitch-Mokotoff' );
is( $ret->name(), 'Baker Street', 'Finding station Bkstrt based on Daitch-Mokotoff' );

$ret = $tube->fuzzy_find( 'Pxqxq', objects => 'stations', method => 'daitchmokotoff' );
is( $ret, undef, 'Finding station Pxqxq based on Daitch-Mokotoff should fail' );

$ret = [ $tube->fuzzy_find( 'Baker Street', objects => 'stations', method => 'daitchmokotoff' ) ];
is_deeply( a2n($ret), [ 'Baker Street' ], 'Finding many stations Baker Street based on Daitch-Mokotoff' );

$ret = [ $tube->fuzzy_find( 'Bkstrt', objects => 'stations', method => 'daitchmokotoff' ) ];
is_deeply( a2n($ret), [ 'Baker Street' ], 'Finding many stations Bkstrt based on Daitch-Mokotoff' );

$ret = [ $tube->fuzzy_find( 'Pxqxq', objects => 'stations', method => 'daitchmokotoff' ) ];
is_deeply( $ret, [ ], 'Finding many stations Pxqxq based on Daitch-Mokotoff should fail' );

