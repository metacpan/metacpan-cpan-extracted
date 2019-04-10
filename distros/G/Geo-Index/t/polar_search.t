#!perl

use constant test_count => 21;

use strict;
use warnings;
use Test::More tests => test_count;

use_ok( 'Geo::Index' );

my $index = Geo::Index->new( );
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

my @results;
my @expected;

# Closest default limit
@results = $index->Closest( [ -90, 0 ] );
is_deeply( $results[0], $south_pole, "Closest default limit (closest)" );
is( scalar @results, 1, "Closest default limit (count)" );

# Farthest default limit
@results = $index->Farthest( [ -90, 0 ] );
is_deeply( $results[0], $north_pole, "Farthest default limit (closest)" );
is( scalar @results, 1, "Farthest default limit (count)" );

# South pole closest
@results = $index->Closest( [ -90, 0 ], 0 );
@expected = ( $south_pole, $ushuaia, $buenos_aires, $canberra, $nairobi, $kuala_lumpur, $new_delhi, $ottawa, $stockholm, $svalbard, $north_pole );
is_deeply( \@results, \@expected, "South pole closest" );

# Closest near south pole
@results = $index->Closest( [ -80, 20 ], 0 );
@expected = ( $south_pole, $ushuaia, $buenos_aires, $canberra, $nairobi, $kuala_lumpur, $new_delhi, $ottawa, $stockholm, $svalbard, $north_pole );
is_deeply( \@results, \@expected, "Closest near south pole" );

# South pole farthest
@results = $index->Farthest( [ -90, 0 ], 0 );
@expected = ( $north_pole, $svalbard, $stockholm, $ottawa, $new_delhi, $kuala_lumpur, $nairobi, $canberra, $buenos_aires, $ushuaia, $south_pole );
is_deeply( \@results, \@expected, "South pole farthest" );

# North pole closest
@results = $index->Closest( [ 90, 0 ], 0 );
@expected = ( $north_pole, $svalbard, $stockholm, $ottawa, $new_delhi, $kuala_lumpur, $nairobi, $canberra, $buenos_aires, $ushuaia, $south_pole );
is_deeply( \@results, \@expected, "North pole closest" );

# Closest near north pole
@results = $index->Closest( [ 80, 20 ], 0 );
@expected = ( $svalbard, $north_pole, $stockholm, $ottawa, $new_delhi, $nairobi, $kuala_lumpur, $buenos_aires, $canberra, $ushuaia, $south_pole );
is_deeply( \@results, \@expected, "Closest near north pole" );

# North pole farthest
@results = $index->Farthest( [ 90, 0 ], 0 );
@expected = ( $south_pole, $ushuaia, $buenos_aires, $canberra, $nairobi, $kuala_lumpur, $new_delhi, $ottawa, $stockholm, $svalbard, $north_pole );
is_deeply( \@results, \@expected, "North pole farthest" );

# Southern hemisphere
@results = $index->SearchByBounds( [ -180, -90, 180, 0 ], { sort_results=>1 } );
@expected = ( $ushuaia, $south_pole, $buenos_aires, $nairobi, $canberra );
is_deeply( \@results, \@expected, "Southern hemisphere" );

# Northern hemisphere
@results = $index->SearchByBounds( [ -180, 0, 180, 90 ], { sort_results=>1 } );
@expected = ( $new_delhi, $kuala_lumpur, $svalbard, $stockholm, $north_pole, $ottawa );
is_deeply( \@results, \@expected, "Northern hemisphere" );

# Eastern hemisphere
@results = $index->SearchByBounds( [ 0, -90, 180, 90 ], { sort_results=>1 } );
@expected = ( $south_pole, $nairobi, $canberra, $new_delhi, $kuala_lumpur, $svalbard, $stockholm, $north_pole );
is_deeply( \@results, \@expected, "Eastern hemisphere" );

# Western hemisphere
@results = $index->SearchByBounds( [ -180, -90, 0, 90 ], { sort_results=>1 } );
@expected = ( $ushuaia, $south_pole, $buenos_aires, $north_pole, $ottawa );
is_deeply( \@results, \@expected, "Western hemisphere" );

# Prime hemisphere
@results = $index->SearchByBounds( [ -90, -90, 90, 90 ], { sort_results=>1 } );
@expected = sort ( $ushuaia, $south_pole, $buenos_aires, $north_pole, $ottawa, $nairobi, $new_delhi, $svalbard, $stockholm );
is_deeply( [ sort @results ], [ sort @expected ], "Prime hemisphere" );

# Antiprime hemisphere
@results = $index->SearchByBounds( [ 90, -90, -90, 90 ], { sort_results=>1 } );
@expected = ( $south_pole, $north_pole, $canberra, $kuala_lumpur );
is_deeply( [ sort @results ], [ sort @expected ], "Antiprime hemisphere" );

# Want 5
@results = $index->Closest( [ 80, 20 ], 5 );
is( scalar @results, 5, "Want 5" );

# Pre-condition
@results = sort $index->Closest( [ -80, 20 ], 0, { pre_condition=>sub { return ($_[0]->{name} =~ /$_[2]/); }, user_data=>'^S' } );
@expected = sort ( $svalbard, $stockholm, $south_pole );
is_deeply( \@results, \@expected, "Pre-condition" );

# Post-condition
@results = sort $index->Closest( [ -80, 20 ], 0, { pre_condition=>sub { return ($_[0]->{name} =~ /$_[2]/); }, user_data=>'^\S*[nN]\S*[ ,]' } );
@expected = sort ( $north_pole, $new_delhi, $nairobi, $canberra, $buenos_aires );
is_deeply( \@results, \@expected, "Post-condition" );


done_testing;
