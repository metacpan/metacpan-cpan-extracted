#!perl

use constant test_count => 7;

use strict;
use warnings;
use Test::More tests => test_count;

use_ok( 'Geo::Index' );

my $index = Geo::Index->new( { quiet=>1 } );
isa_ok $index, 'Geo::Index', 'Geo::Index object';

my $buenos_aires = { lat=>-36.30,     lon=>-60.00,     name=>'Buenos Aires, Argentina' };
my $ushuaia      = { lat=>-54.801944, lon=>-68.303056, name=>'Ushuaia, Argentina' };
my $svalbard     = { lat=>78.666667,  lon=>16.333333,  name=>'Svalbard, Norway' };
my $stockholm    = { lat=>59.20,      lon=>18.03,      name=>'Stockholm, Sweden' };
my $south_pole   = { lat=>-90.0,      lon=>0.0,        name=>'South pole, Antarctica' };
my $north_pole   = { lat=>90.0,       lon=>0.0,        name=>'North pole, Arctic' };
my $kuala_lumpur = { lat=>3.09,       lon=>101.41,     name=>'Kuala Lumpur, Malaysia' };
my $new_delhi    = { lat=>28.37,      lon=>77.13,      name=>'New Delhi, India' };
my $ottawa       = { lat=>45.27,      lon=>-75.42,     name=>'Ottawa, Canada' };
my $nairobi      = { lat=>-1.17,      lon=>36.48,      name=>'Nairobi, Kenya' };
my $canberra     = { lat=>-35.15,     lon=>149.08,     name=>'Canberra, Australia' };

my @points = ( $buenos_aires, $ushuaia, $svalbard, $stockholm, $south_pole, $north_pole, $kuala_lumpur, $new_delhi, $ottawa, $nairobi, $canberra );

$index->IndexPoints( \@points );

my $points;

# Trampoline from DeletePointIndex to Unindex

my $point_count = $index->PointCount();

# Test new method name
$index->Unindex( $new_delhi );
$point_count--;
is( $index->PointCount(), $point_count, "DeletePointIndex -> Unindex: New method name" );

# Test old method name
$index->DeletePointIndex( $svalbard );
$point_count--;
is( $index->PointCount(), $point_count, "DeletePointIndex -> Unindex: Old method name" );

# Test new method name
$index->Unindex( $nairobi );
$point_count--;
is( $index->PointCount(), $point_count, "DeletePointIndex -> Unindex: New method name" );

# Test old method name
$index->DeletePointIndex( $north_pole );
$point_count--;
is( $index->PointCount(), $point_count, "DeletePointIndex -> Unindex: Old method name" );

# Test new method name
$index->Unindex( $ottawa );
$point_count--;
is( $index->PointCount(), $point_count, "DeletePointIndex -> Unindex: New method name" );


done_testing;

