#!perl

use strict;
use warnings;

use constant test_count => 9;

use Test::More tests => test_count;

SKIP: {
	my $gpx_data =<<EOF;
<?xml version="1.0" encoding="UTF-8" standalone="no" ?>
<gpx xmlns="http://www.topografix.com/GPX/1/1" creator="MapSource 6.16.3" version="1.1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">

	<wpt lat="-54.801944" lon="-68.303056">
		<name>Ushuaia, Argentina</name>
	</wpt>
	
	<wpt lat="60.15" lon="25.03">
		<name>Helsinki, Finland</name>
	</wpt>
	
	<wpt lat="-77.846323" lon="166.668235">
		<name>McMurdo Station, Antarctica</name>
	</wpt>
	
	<wpt lat="-41.19" lon="174.46">
		<name>Wellington, New Zealand</name>
	</wpt>
	
	<wpt lat="12.06" lon="-86.20">
		<name>Managua, Nicaragua</name>
	</wpt>
	
	<wpt lat="90" lon="180">
		<name>North pole, Arctic</name>
	</wpt>
	
	<wpt lat="14.40" lon="-90.22">
		<name>Guatemala, Guatemala</name>
	</wpt>
	
	<wpt lat="78.666667" lon="16.333333">
		<name>Svalbard, Norway</name>
	</wpt>
	
	<wpt lat="52.30" lon="13.25">
		<name>Berlin, Germany</name>
	</wpt>
	
	<wpt lat="03.09" lon="101.41">
		<name>Kuala Lumpur, Malaysia</name>
	</wpt>
	
	<wpt lat="40.29" lon="49.56">
		<name>Baku, Azerbaijan</name>
	</wpt>
	
	<wpt lat="09.55" lon="-84.02">
		<name>San Jose, Costa Rica</name>
	</wpt>
	
	<wpt lat="-90" lon="0">
		<name>South pole, Antarctica</name>
	</wpt>
	
	<wpt lat="17.58" lon="102.36">
		<name>Vientiane, Lao People's Democratic Republic</name>
	</wpt>
	
	<wpt lat="09.00" lon="-79.25">
		<name>Panama, Panama</name>
	</wpt>
	
</gpx>
EOF

	eval "use Geo::Gpx";
	skip "Geo::Gpx required for testing direct indexing of GPX files", test_count if $@;
	
	my $gpx;
	eval { $gpx = Geo::Gpx->new( xml => $gpx_data ); };
	
	if ($@) {
		warn "Geo::Gpx failed to load GPX data";
		skip "Geo::Gpx failed to load GPX data", test_count;
	}
	
	if ( ( ! defined $gpx->{waypoints} ) || ( ref $gpx->{waypoints} ne 'ARRAY' ) ) {
		warn "Couldn't get waypoints from Geo::Gpx object";
		skip "Couldn't get waypoints from Geo::Gpx object", test_count;
	}
	
	my $gpx_waypoint_count = scalar @{$gpx->{waypoints}};
	
	my %points_by_name = ( );
	
	map { $points_by_name{$_->{name}} = $_; } @{$gpx->{waypoints}};
	
	use_ok( 'Geo::Index' );
	
	my $index = Geo::Index->new( { levels=>20 } );
	isa_ok $index, 'Geo::Index', 'Geo::Index object';
	
	$index->IndexPoints( $gpx->{waypoints} );
	my %config = $index->GetConfiguration();
	
	cmp_ok( $config{size}, '==', $gpx_waypoint_count, "Index" );
	
	my ( $p0, $p1, $p2 );
	
	( $p0 ) = $index->Closest( [ 0, 135 ] );
	like( $p0->{name}, '/Kuala Lumpur/', "Closest" );
	
	( $p0 ) = $index->Closest( [ 90, 0 ] );
	cmp_ok( $p0->{name}, 'eq', 'North pole, Arctic', "Closest (north polar)" );
	
	( $p0 ) = $index->Closest( [ -90, 0 ] );
	cmp_ok( $p0->{name}, 'eq', 'South pole, Antarctica', "Closest (south polar)" );
	
	( $p1 ) = $index->Closest( $p0, { sort_results=>1 } );
	like( $p1->{name}, '/McMurdo/', "Search" );
	
	( undef, $p2 ) = $index->Closest( $p1, 5, {
	                                            radius=>5_000_000, 
	                                            sort_results=>1, 
	                                            post_condition=>sub { 
	                                                                  return ( 
	                                                                           ($_[0] != $_[1] ) &&  # Not seach point
	                                                                           ($_[0] != $_[2] )     # And not user data point
	                                                                         ); 
	                                                                }, 
	                                            user_data=>$p0 
	                                          } );
	like( $p2->{name}, '/Ushuaia/', "Search multiple with radius and condition" );
	
	my %central_america = ( north=>19, west=>-94, south=>6, east=>-77  );
	
	my $_results = $index->SearchByBounds( \%central_america );
	
	eq_set( $_results, [
	                     $points_by_name{'San Jose, Costa Rica'}, 
	                     $points_by_name{'Managua, Nicaragua'}, 
	                     $points_by_name{'Guatemala, Guatemala'}, 
	                     $points_by_name{'Panama, Panama'}, 
	                   ], "SearchByBounds" );
	
	my $distance = $index->Distance( $points_by_name{'Berlin, Germany'}, $points_by_name{'Svalbard, Norway'} );
	cmp_ok( $distance, 'eq', 2934440.22994538, "Distance" );
	
}

done_testing;
