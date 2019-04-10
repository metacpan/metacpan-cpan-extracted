#!perl

use constant test_count => 3;

use strict;
use warnings;
use Test::More tests => test_count;

use_ok( 'Geo::Index' );

my $index = Geo::Index->new( { levels=>20, quiet=>1 } );
isa_ok $index, 'Geo::Index', 'Geo::Index object';

eval {
	# This is just a basic sanity check, not a thorough test.
	
	my ($results, $closest, $farthest);
	
	my @points = ( { lat=>1.0, lon=>2.0 }, { lat=>-90.0, lon=>0.0, name =>'South Pole' }, { lat=>30.0, lon=>-20.0, ele=>123.4 } );
	my $point = { lat=>10.0, lon=>20.0 };
	
	$index->index_points( \@points );
	$index->index( $point );
	$index->index( [ 30, 40 ] );
	($closest) = $index->closest( $points[1], { post_condition=>'NONE' } );
	
	
	my %search_options = ( sort_results => 1, radius=>5_000_000 );
	$results = $index->search( [ -80, 20 ], \%search_options );
	
	$results = $index->search_by_bounds( [ -180, -90, 180, 0 ] );
	
	($closest) = $index->closest( [ -80, 20 ] );
	
	($closest) = $index->closest( $points[1], { post_condition=>'NONE' } );
	
	($farthest) = $index->farthest( [ 90, 0 ] );
};

if ($@) {
	fail "Alternate names";
} else {
  ok "Alternate names";
}

done_testing;

