#!perl

use constant test_count => 3;

use strict;
use warnings;
use Test::More tests => test_count;

use_ok( 'Geo::Index' );

my $index = Geo::Index->new( { levels=>20 } );
isa_ok $index, 'Geo::Index', 'Geo::Index object';

my @points = (
               { lat=>78.666667, lon=>16.333333, name=>'Svalbard, Norway' },
               { lat=>52.30,     lon=>13.25,     name=>'Berlin, Germany' }
             );

$index->IndexPoints( \@points );

my ( $result ) = $index->Closest( $points[0] );
is_deeply( $result, $points[1], "Point storage and retrieval" );

done_testing;
