#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use Test::MockObject;
use Test::Without::Module('LWP::UserAgent');	# This test does not reach out to the Internet

BEGIN { use_ok('Geo::Coder::List') }

my $call_count = 0;

# Mock geocoders with controlled responses
sub mock_geocoder {
	my ($response, $throws) = @_;
	my $mock = Test::MockObject->new();
	$mock->mock('geocode', sub { 
		$call_count++;
		die $throws if $throws; 
		return $response eq 'ARRAY' ? [ { lat => 1.23, lon => 4.56 } ] 
			   : $response eq 'EMPTY' ? undef 
			   : { %$response };
	});
	return $mock;
}

subtest 'Response Normalization' => sub {
	# Mock OSM-style response (top-level lat/lon)
	my $osm = mock_geocoder({ lat => 1.23, lon => 4.56 });
	
	my $list = Geo::Coder::List->new();
	$list->push($osm);
	
	my $result = $list->geocode(location => 'Paris');
	
	is_deeply $result->{geometry}{location},
		{ lat => 1.23, lng => 4.56 },
		'Normalized OSM-style response';
	
	ok exists $result->{lat}, 'Original lat also there';
	ok exists $result->{lon}, 'Original lon also there';
};

subtest 'Error Handling' => sub {
	# Create failing geocoder and successful fallback
	my $bad_geocoder = mock_geocoder(undef, 'API Limit Exceeded');
	my $good_geocoder = mock_geocoder({ 
		geometry => { location => { lat => 5.67, lng => 8.90 } 
	}});
	
	my $list = Geo::Coder::List->new();
	$list->push($bad_geocoder)->push($good_geocoder);
	
	my $result = $list->geocode(location => 'London');
	
	is $result->{geometry}{location}{lat}, 5.67,
		'Fell back to working geocoder';
	
	is scalar @{$list->log}, 2,
		'Logged both attempts';
	like $list->log->[0]{error}, qr/API Limit Exceeded/,
		'Logged error from failed geocoder';
};

subtest 'Caching Behavior' => sub {
	$call_count = 0;
	my $mock = mock_geocoder({ lat => 1.23, lon => 4.56 });
	
	my $list = Geo::Coder::List->new(cache => {});
	$list->push($mock);
	
	$list->geocode(location => 'Berlin');
	$list->geocode(location => 'Berlin');
	
	cmp_ok($call_count, '==', 1, 'Cached second request');
};

subtest 'Array Response Handling' => sub {
	my $multi = mock_geocoder('ARRAY');
	
	my $list = Geo::Coder::List->new();
	$list->push($multi);
	
	my @results = $list->geocode(location => 'Rome');
	
	is scalar @results, 1, 
		'Handled array response';
	is $results[0]{geometry}{location}{lat}, 1.23,
		'Normalized first array element';
};

subtest 'Empty Response Handling' => sub {
	my $empty = mock_geocoder('EMPTY');
	my $list = Geo::Coder::List->new();
	$list->push($empty);
	
	ok !$list->geocode(location => 'Nowhere'), 'Handled empty response';
};

done_testing;
