#!perl
use 5.012;
use strict;
use warnings FATAL => 'all';
use Test::More 0.82 tests => 10;
use lib 't/';
use Sample;
use Try::Tiny;

my $tube = Sample->new( );

my $ret;

$ret = $tube->fuzzy_find( 'Bakerloo',             objects => 'lines' );
is( $ret, 'Bakerloo', 'Finding bare pattern' );

$ret = $tube->fuzzy_find( search => 'Bakerloo',   objects => 'lines' );
is( $ret, 'Bakerloo', 'Finding pattern in hash' );

$ret = $tube->fuzzy_find( { search => 'Bakerloo', objects => 'lines' } );
is( $ret, 'Bakerloo', 'Finding with hash ref' );

$ret = $tube->fuzzy_find( { search => 'Bakerloo', objects => 'lines', method => 'exact' } );
is( $ret, 'Bakerloo', 'Finding with explicit method "exact"' );

$ret = $tube->fuzzy_find( { search => qr/erloo/,  objects => 'lines'  } );
is( $ret, 'Bakerloo', 'Finding re without explicit method' );

$ret = $tube->fuzzy_find( { search => qr/erloo/,  objects => 'lines', method => 're' } );
is( $ret, 'Bakerloo', 'Finding re with explicit method' );

$ret = $tube->fuzzy_find( { search => 'erloo',    objects => 'lines', method => 're' } );
is( $ret, 'Bakerloo', 'Finding string as re with explicit method re' );

$ret = $tube->fuzzy_find( { search => 'erloo',    objects => 'lines', method => 'regex' } );
is( $ret, 'Bakerloo', 'Finding string as re with explicit method regex' );

try {
  $ret = $tube->fuzzy_find( { search => 'Bakerloo', objects => 'lines', method => 'dummy' } );
  fail( 'Finding with explicit nonsense method should fail' );
} catch {
  pass( 'Finding with explicit nonsense method' );
};

$ret = $tube->fuzzy_find( search => 'Bakerloo' );
is( $ret, 'Bakerloo', 'Finding without objects' );

