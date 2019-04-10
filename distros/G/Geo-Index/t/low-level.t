#!perl

# Test swappable low-level functions
# (Perl, C float, and C double)

use strict;
use warnings;
use Test::More;
use Config;

use_ok( 'Geo::Index' );

my $index;

# Create and populate index
$index = Geo::Index->new( { levels=>20 } );
isa_ok $index, 'Geo::Index', 'Geo::Index object';

# Determine what type of key we expect to have
my $expecting_numeric_keys = ( $Config{use64bitint} ) ? 1 : 0;

# Determine what type of keys we actually have
my %config = $index->GetConfiguration();
my $have_numeric_keys = ( ( $config{key_type} eq 'numeric' ) || ( $config{key_type} eq 'packed' ) ) ? 1 : 0;

# See whether our expectations are met
cmp_ok( $have_numeric_keys, '==', $expecting_numeric_keys, "Key type is sensible" );

# Create new index
$index = Geo::Index->new();

# Find out what code types it supports
my $_types = $index->GetSupportedLowLevelCodeTypes();

# Skip tests if we don't have C code

if ( scalar(@$_types) == 0 ) {
	fail "No low-level code available, WTF?";
	warn "Couldn't determine available low-level code types";
	
} elsif ( scalar(@$_types) == 1 ) {
	warn "Accelerated C code not available";
}

# Set up points for test
my $svalbard      = { lat=>78.666667,  lon=>16.333333,  name=>'Svalbard, Norway' };
my $berlin        = { lat=>52.30,      lon=>13.25,      name=>'Berlin, Germany' };
my $north_pole    = { lat=>90.0,       lon=>12.3,       name=>'North pole' };
my $south_pole    = { lat=>-90.0,      lon=>45.6,       name=>'South pole' };
my $scott_station = { lat=>-89.997553, lon=>139.272892, name=>'Amundsen-Scott Station' };

my $wellington    = { lat=>-41.19,     lon=>174.46,     name=>"Wellington, New Zealand" }, 
my $tuvalu_am_w   = { lat=>-8.31,      lon=>179.13,     name=>"Funafuti, Tuvalu" }, 
my $tonga_am_e    = { lat=>-21.10,     lon=>-174.00,    name=>"Nuku'alofa, Tonga" }, 
my $buenos_aires  = { lat=>-36.30,     lon=>-60.00,     name=>"Buenos Aires, Argentina" }, 
my $mcmurdo       = { lat=>-77.846323, lon=>166.668235, name=>"McMurdo Station, Antarctica" }, 

my @points;

my $_results;

# Loop through all available code types...
foreach my $type ( 'default', @$_types ) {
	
	# Create and populate index using specific low-level code type
	my $index;
	if ($type eq 'default') {
		$index = Geo::Index->new( );
	} else {
		$index = Geo::Index->new( { function_type => $type } );
		
		# See if we got the code type we asked for
		my $type_in_use = $index->GetLowLevelCodeType();
		cmp_ok( $type_in_use, 'eq', $type, "Type in use is type requested ($type)" );
	}
	
	$index->IndexPoints( [ $svalbard, $berlin, $north_pole, $scott_station, $south_pole ] );
	
	
	# Check distance code
	my $distance = int $index->Distance( $svalbard, $berlin );
	cmp_ok( $distance, 'eq', 2934440, "Distance, $type" );
	
	my $_options;
	
	
	
	$_options = { sort_results=>1 };
	
	$_results = $index->Search( $berlin, $_options );
	is_deeply( $_results, [ $berlin, $svalbard, $north_pole, $south_pole, $scott_station ], "Search, $type (Berlin)" );
	
	$_results = $index->Search( $svalbard, $_options );
	is_deeply( $_results, [ $svalbard, $north_pole, $berlin, $south_pole, $scott_station ], "Search, $type (Svalbard)" );
	
	$_results = $index->Search( $north_pole, $_options );
	is_deeply( $_results, [ $north_pole, $svalbard, $berlin, $scott_station, $south_pole ], "Search, $type (north pole)" );
	
	$_results = $index->Search( $scott_station, $_options );
	is_deeply( $_results, [ $scott_station, $south_pole, $berlin, $svalbard, $north_pole ], "Search, $type (Amundsen-Scott Station)" );
	
	$_results = $index->Search( $south_pole, $_options );
	is_deeply( $_results, [ $south_pole, $scott_station, $berlin, $svalbard, $north_pole ], "Search, $type (south pole)" );
	
	
	
	$_options = { sort_results=>1, radius=>0 };
	
	$_results = $index->Search( $berlin, $_options );
	is_deeply( $_results, [ $berlin ], "Search, $type (Berlin), 0 m radius" );
	
	$_results = $index->Search( $svalbard, $_options );
	is_deeply( $_results, [ $svalbard ], "Search, $type (Svalbard), 0 m radius" );
	
	$_results = $index->Search( $north_pole, $_options );
	is_deeply( $_results, [ $north_pole ], "Search, $type (north pole), 0 m radius" );
	
	$_results = $index->Search( $scott_station, $_options );
	is_deeply( $_results, [ $scott_station ], "Search, $type (Amundsen-Scott Station), 0 m radius" );
	
	$_results = $index->Search( $south_pole, $_options );
	is_deeply( $_results, [ $south_pole ], "Search, $type (south pole), 0 m radius" );
	
	
	
	$_options = { sort_results=>1, radius=>1 };
	
	$_results = $index->Search( $berlin, $_options );
	is_deeply( $_results, [ $berlin ], "Search, $type (Berlin), 1 m radius" );
	
	$_results = $index->Search( $svalbard, $_options );
	is_deeply( $_results, [ $svalbard ], "Search, $type (Svalbard), 1 m radius" );
	
	$_results = $index->Search( $north_pole, $_options );
	is_deeply( $_results, [ $north_pole ], "Search, $type (north pole), 1 m radius" );
	
	$_results = $index->Search( $scott_station, $_options );
	is_deeply( $_results, [ $scott_station ], "Search, $type (Amundsen-Scott Station), 1 m radius" );
	
	$_results = $index->Search( $south_pole, $_options );
	is_deeply( $_results, [ $south_pole ], "Search, $type (south pole), 1 m radius" );
	
	
	
	$_options = { sort_results=>1, radius=>1_000 };
	
	$_results = $index->Search( $berlin, $_options );
	is_deeply( $_results, [ $berlin ], "Search, $type (Berlin), 1 km radius" );
	
	$_results = $index->Search( $svalbard, $_options );
	is_deeply( $_results, [ $svalbard ], "Search, $type (Svalbard), 1 km radius" );
	
	$_results = $index->Search( $north_pole, $_options );
	is_deeply( $_results, [ $north_pole ], "Search, $type (north pole), 1 km radius" );
	
	$_results = $index->Search( $scott_station, $_options );
	is_deeply( $_results, [ $scott_station, $south_pole ], "Search, $type (Amundsen-Scott Station), 1 km radius" );
	
	$_results = $index->Search( $south_pole, $_options );
	is_deeply( $_results, [ $south_pole, $scott_station ], "Search, $type (south pole), 1 km radius" );
	
	
	
	$_options = { sort_results=>1, radius=>3_000_000 };
	
	$_results = $index->Search( $berlin, $_options );
	is_deeply( $_results, [ $berlin, $svalbard ], "Search, $type (Berlin), 3,000 km radius" );
	
	$_results = $index->Search( $svalbard, $_options );
	is_deeply( $_results, [ $svalbard, $north_pole, $berlin ], "Search, $type (Svalbard), 3,000 km radius" );
	
	$_results = $index->Search( $north_pole, $_options );
	is_deeply( $_results, [ $north_pole, $svalbard ], "Search, $type (north pole), 3,000 km radius" );
	
	$_results = $index->Search( $scott_station, $_options );
	is_deeply( $_results, [ $scott_station, $south_pole ], "Search, $type (Amundsen-Scott Station), 3,000 km radius" );
	
	$_results = $index->Search( $south_pole, $_options );
	is_deeply( $_results, [ $south_pole, $scott_station ], "Search, $type (south pole), 3,000 km radius" );
	
	
	$_options = { sort_results=>1, radius=>19_000_000 };
	
	$_results = $index->Search( $berlin, $_options );
	is_deeply( $_results, [ $berlin, $svalbard, $north_pole, $south_pole, $scott_station ], "Search, $type (Berlin), 19,000 km radius" );
	
	$_results = $index->Search( $svalbard, $_options );
	is_deeply( $_results, [ $svalbard, $north_pole, $berlin, $south_pole, $scott_station ], "Search, $type (Svalbard), 19,000 km radius" );
	
	$_results = $index->Search( $north_pole, $_options );
	is_deeply( $_results, [ $north_pole, $svalbard, $berlin ], "Search, $type (north pole), 19,000 km radius" );
	
	$_results = $index->Search( $scott_station, $_options );
	is_deeply( $_results, [ $scott_station, $south_pole, $berlin, $svalbard ], "Search, $type (Amundsen-Scott Station), 19,000 km radius" );
	
	$_results = $index->Search( $south_pole, $_options );
	is_deeply( $_results, [ $south_pole, $scott_station, $berlin, $svalbard ], "Search, $type (south pole), 19,000 km radius" );
	
	
	
	$_options = { sort_results=>1, radius=>21_000_000 };
	
	$_results = $index->Search( $berlin, $_options );
	is_deeply( $_results, [ $berlin, $svalbard, $north_pole, $south_pole, $scott_station ], "Search, $type (Berlin), 21,000 km radius" );
	
	$_results = $index->Search( $svalbard, $_options );
	is_deeply( $_results, [ $svalbard, $north_pole, $berlin, $south_pole, $scott_station ], "Search, $type (Svalbard), 21,000 km radius" );
	
	$_results = $index->Search( $north_pole, $_options );
	is_deeply( $_results, [ $north_pole, $svalbard, $berlin, $scott_station, $south_pole ], "Search, $type (north pole), 21,000 km radius" );
	
	$_results = $index->Search( $scott_station, $_options );
	is_deeply( $_results, [ $scott_station, $south_pole, $berlin, $svalbard, $north_pole ], "Search, $type (Amundsen-Scott Station), 21,000 km radius" );
	
	$_results = $index->Search( $south_pole, $_options );
	is_deeply( $_results, [ $south_pole, $scott_station, $berlin, $svalbard, $north_pole ], "Search, $type (south pole), 21,000 km radius" );
	
	
	
	$_options = { sort_results=>1, radius=>42_000_000 };
	
	$_results = $index->Search( $berlin, $_options );
	is_deeply( $_results, [ $berlin, $svalbard, $north_pole, $south_pole, $scott_station ], "Search, $type (Berlin), 42,000 km radius" );
	
	$_results = $index->Search( $svalbard, $_options );
	is_deeply( $_results, [ $svalbard, $north_pole, $berlin, $south_pole, $scott_station ], "Search, $type (Svalbard), 42,000 km radius" );
	
	$_results = $index->Search( $north_pole, $_options );
	is_deeply( $_results, [ $north_pole, $svalbard, $berlin, $scott_station, $south_pole ], "Search, $type (north pole), 42,000 km radius" );
	
	$_results = $index->Search( $scott_station, $_options );
	is_deeply( $_results, [ $scott_station, $south_pole, $berlin, $svalbard, $north_pole ], "Search, $type (Amundsen-Scott Station), 42,000 km radius" );
	
	$_results = $index->Search( $south_pole, $_options );
	is_deeply( $_results, [ $south_pole, $scott_station, $berlin, $svalbard, $north_pole ], "Search, $type (south pole), 42,000 km radius" );
	
	
	
	
	
	
	
	
	if ($type eq 'default') {
		$index = Geo::Index->new( );
	} else {
		$index = Geo::Index->new( { function_type => $type } );
	}
	$index->IndexPoints( [ $wellington, $tuvalu_am_w, $tonga_am_e, $buenos_aires, $mcmurdo ] );
	
	
	
	$_options = { sort_results=>1 };
	my @expected;
	
	$_results = $index->Search( $wellington, $_options );
	@expected = ( $wellington, $tonga_am_e, $tuvalu_am_w, $mcmurdo, $buenos_aires );
	is_deeply( $_results, \@expected, "Search, $type (Wellington)" );
	
	
	$_options = { sort_results=>1, radius=>0 };
	
	$_results = $index->Search( $wellington, $_options );
	@expected = ( $wellington );
	is_deeply( $_results, \@expected, "Search, $type (Wellington), 0 m radius" );
	
	
	$_options = { sort_results=>1, radius=>1 };
	
	$_results = $index->Search( $wellington, $_options );
	is_deeply( $_results, \@expected, "Search, $type (Wellington), 1 m radius" );
	
	
	$_options = { sort_results=>1, radius=>1_000 };
	
	$_results = $index->Search( $wellington, $_options );
	is_deeply( $_results, \@expected, "Search, $type (Wellington), 1 km radius" );
	
	
	$_options = { sort_results=>1, radius=>3_000_000 };
	
	$_results = $index->Search( $wellington, $_options );
	@expected = ( $wellington, $tonga_am_e );
	is_deeply( $_results, \@expected, "Search, $type (Wellington), 3,000 km radius" );
	
	
	$_options = { sort_results=>1, radius=>8_000_000 };
	
	$_results = $index->Search( $wellington, $_options );
	@expected = ( $wellington, $tonga_am_e,$tuvalu_am_w, $mcmurdo );
	is_deeply( $_results, \@expected, "Search, $type (Wellington), 8,000 km radius" );
	
	
	$_options = { sort_results=>1, radius=>3_000_000 };
	
	$_results = $index->Search( $tonga_am_e, $_options );
	@expected = ( $tonga_am_e, $tuvalu_am_w, $wellington );
	is_deeply( $_results, \@expected, "Search, $type (Tonga: antimeridian east), 3,000 km radius" );
	
	
	$_results = $index->Search( $tuvalu_am_w, $_options );
	@expected = ( $tuvalu_am_w, $tonga_am_e );
	is_deeply( $_results, \@expected, "Search, $type (Tuvalu: antimeridian west), 3,000 km radius" );
	
	
	$_results = $index->Search( $tonga_am_e, $_options );
	@expected = ( $tonga_am_e, $tuvalu_am_w, $wellington );
	is_deeply( $_results, \@expected, "Search, $type (Tonga: antimeridian east), 8,000 km radius" );
	
	
	$_results = $index->Search( $tuvalu_am_w, $_options );
	@expected = ( $tuvalu_am_w, $tonga_am_e );
	is_deeply( $_results, \@expected, "Search, $type (Tuvalu: antimeridian west), 8,000 km radius" );
	
}

done_testing;
