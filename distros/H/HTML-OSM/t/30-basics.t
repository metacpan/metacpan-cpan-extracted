#!/usr/bin/env perl

use strict;
use warnings;

use File::Temp qw/tempfile/;
use Test::HTTPStatus;
use Test::Most;
use Test::RequiresInternet ('nominatim.openstreetmap.org' => 'https');

BEGIN { use_ok('HTML::OSM') }

# Test for broken smokers that don't set AUTOMATED_TESTING
if(my $reporter = $ENV{'PERL_CPAN_REPORTER_CONFIG'}) {
	if($reporter =~ /smoker/i) {
		diag('AUTOMATED_TESTING added for you') if(!defined($ENV{'AUTOMATED_TESTING'}));
		$ENV{'AUTOMATED_TESTING'} = 1;
	}
}

if(defined($ENV{'GITHUB_ACTION'}) || defined($ENV{'CIRCLECI'}) || defined($ENV{'TRAVIS_PERL_VERSION'}) || defined($ENV{'APPVEYOR'})) {
	# Prevent downloading and installing stuff
	diag('AUTOMATED_TESTING added for you') if(!defined($ENV{'AUTOMATED_TESTING'}));
	$ENV{'AUTOMATED_TESTING'} = 1;
	$ENV{'NO_NETWORK_TESTING'} = 1;
}

# Helper to silence warnings in error-checking tests
local $SIG{__WARN__} = sub { };

# 1. Object Creation Tests
my $osm = new_ok('HTML::OSM');

subtest 'should load config file if provided' => sub {
	my ($fh, $config_file) = tempfile(TEMPLATE => 'test_configXXXX', SUFFIX => '.yml');
	print $fh "---\ncss_url: https://example.com\n";
	close $fh;

	my $osm = HTML::OSM->new(config_file => $config_file);
	is $osm->{'css_url'}, 'https://example.com', 'Config file loaded correctly';
	unlink $config_file;
};

# Check default values
cmp_ok($osm->{zoom}, '==', 12, 'Default zoom is 12');
is($osm->{height}, '400px', 'Default height is 400px');
is($osm->{width}, '600px', 'Default width is 600px');
is_deeply($osm->{coordinates}, [], 'Coordinates default to an empty array');

# Invalid constructor arguments
dies_ok { HTML::OSM->new({ coordinates => 'not an array' }) } 'Dies with invalid coordinate structure';

# 2. Marker Handling Tests
# Valid marker addition
ok($osm->add_marker([37.7749, -122.4194], html => 'San Francisco'), 'Valid marker added successfully');
is(scalar @{$osm->{coordinates}}, 1, 'One marker is present');

# Invalid marker inputs
ok(!$osm->add_marker([undef, undef], html => 'Invalid'), 'Rejects marker with undefined coordinates');
ok(!$osm->add_marker([200, 300], html => 'Out of range'), 'Rejects out-of-range coordinates');
ok(!$osm->add_marker('not an array'), 'Dies with invalid marker type');

# 3. Centering Tests
# Valid center
ok($osm->center([40.7128, -74.0060]), 'Centering on New York');
is_deeply($osm->{center}, [40.7128, -74.0060], 'Center is correctly updated');

# Invalid center inputs
ok(!$osm->center([999, 999]), 'Invalid coordinates do not update the center');
ok(!$osm->center('place not found'), 'Fails on unknown center location');

# 4. Zoom Level Tests
# Valid zoom changes
$osm->zoom(8);
is($osm->zoom(), 8, 'Zoom updated successfully to 8');

# Invalid zoom changes
dies_ok { $osm->zoom('invalid') } 'Dies on invalid zoom type';
dies_ok { $osm->zoom(-5) } 'Dies on negative zoom level';

# 5. Geocoding Tests
# Simulate address lookup (Requires proper mocking for real tests)
ok(!$osm->add_marker(['xyzzy']), 'Rejects when geocoding fails');

# 6. Map Rendering Tests
my ($head, $body) = $osm->onload_render();
like($head, qr/leaflet/, 'Leaflet script is included in the head');
like($body, qr/map\.setView/, 'Body includes map initialization');

# No coordinates error
my $osm_empty = HTML::OSM->new();
dies_ok { $osm_empty->onload_render() } 'Dies if no coordinates are provided';

# Clone Tests
my $osm_clone = $osm->new(zoom => 17);
isa_ok($osm_clone, 'HTML::OSM', 'Cloned object is still HTML::OSM');
is($osm_clone->{zoom}, 17, 'Cloned object has updated zoom');

unless($ENV{'NO_NETWORK_TESTING'}) {
	# HTTP Tests
	http_ok($osm->{'css_url'}, HTTP_OK);
	http_ok($osm->{'js_url'}, HTTP_OK);
}

done_testing();
