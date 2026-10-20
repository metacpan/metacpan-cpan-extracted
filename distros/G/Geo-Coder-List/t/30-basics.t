#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird;
use Test::Without::Module('LWP::UserAgent');	# This test does not reach out to the Internet

BEGIN { use_ok('Geo::Coder::List') }

# Stub geocoders whose geocode() each subtest replaces with mock_scoped, so
# the mock is removed when the subtest ends.  Two classes are needed where a
# subtest chains a failing geocoder in front of a working one.
{
	package Basics::Geocoder;
	sub new { bless {}, shift }
	sub geocode { return }
}

{
	package Basics::Fallback;
	sub new { bless {}, shift }
	sub geocode { return }
}

my $call_count = 0;

# A geocode() replacement with a controlled response, counting its calls
sub mock_response {
	my ($response, $throws) = @_;

	return sub {
		$call_count++;
		die $throws if $throws;
		return $response eq 'ARRAY' ? [ { lat => 1.23, lon => 4.56 } ]
			: $response eq 'EMPTY' ? undef
			: { %$response };
	};
}

subtest 'Response Normalization' => sub {
	# Mock OSM-style response (top-level lat/lon)
	my $guard = mock_scoped 'Basics::Geocoder::geocode' => mock_response({ lat => 1.23, lon => 4.56 });

	my $list = Geo::Coder::List->new();
	$list->push(Basics::Geocoder->new());

	my $result = $list->geocode(location => 'Paris');

	is_deeply $result->{geometry}{location},
		{ lat => 1.23, lng => 4.56 },
		'Normalized OSM-style response';

	ok exists $result->{lat}, 'Original lat also there';
	ok exists $result->{lon}, 'Original lon also there';
};

subtest 'Error Handling' => sub {
	# Create failing geocoder and successful fallback
	my $bad = mock_scoped 'Basics::Geocoder::geocode' => mock_response(undef, 'API Limit Exceeded');
	my $good = mock_scoped 'Basics::Fallback::geocode' => mock_response({
		geometry => { location => { lat => 5.67, lng => 8.90 } }
	});

	# carp_on_warn sends the failure through Carp, where warnings_like sees it
	my $list = Geo::Coder::List->new(carp_on_warn => 1);
	$list->push(Basics::Geocoder->new())->push(Basics::Fallback->new());

	my $result;
	warnings_like { $result = $list->geocode(location => 'London') }
		[ qr/API Limit Exceeded/ ],
		'Failure of the first geocoder is reported';

	is $result->{geometry}{location}{lat}, 5.67,
		'Fell back to working geocoder';

	is scalar @{$list->log}, 2,
		'Logged both attempts';
	like $list->log->[0]{error}, qr/API Limit Exceeded/,
		'Logged error from failed geocoder';
};

subtest 'Caching Behavior' => sub {
	$call_count = 0;
	my $guard = mock_scoped 'Basics::Geocoder::geocode' => mock_response({ lat => 1.23, lon => 4.56 });

	my $list = Geo::Coder::List->new(cache => {});
	$list->push(Basics::Geocoder->new());

	$list->geocode(location => 'Berlin');
	$list->geocode(location => 'Berlin');

	cmp_ok($call_count, '==', 1, 'Cached second request');
};

subtest 'Array Response Handling' => sub {
	my $guard = mock_scoped 'Basics::Geocoder::geocode' => mock_response('ARRAY');

	my $list = Geo::Coder::List->new();
	$list->push(Basics::Geocoder->new());

	my @results = $list->geocode(location => 'Rome');

	is scalar @results, 1,
		'Handled array response';
	is $results[0]{geometry}{location}{lat}, 1.23,
		'Normalized first array element';
};

subtest 'Empty Response Handling' => sub {
	my $guard = mock_scoped 'Basics::Geocoder::geocode' => mock_response('EMPTY');

	my $list = Geo::Coder::List->new();
	$list->push(Basics::Geocoder->new());

	ok !$list->geocode(location => 'Nowhere'), 'Handled empty response';
};

done_testing;
