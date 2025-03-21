use strict;
use warnings;
use Test::Most;
use Geo::Coder::Free;

# Mocking databases for tests
my $mock_db_path = 'mock/geo_coder_free.sql';
my $geo_coder = Geo::Coder::Free->new(
	dbname => $mock_db_path,
	verbose => 1,
);

# Test cases
subtest 'Initialization' => sub {
	ok($geo_coder, 'Geo::Coder::Free object created successfully');

	throws_ok {
		Geo::Coder::Free->new(openaddr => '/nonexistent')
	} qr/Can't find the directory/, 'Fails when directory does not exist';
};

subtest 'Geocode edge cases' => sub {
	my $result;

	# Empty address
	lives_ok {
		$result = $geo_coder->geocode('')
	} 'No crash with empty string';
	is_deeply($result, undef, 'Returns undef for empty string input');

	# Nonexistent location
	lives_ok {
		$result = $geo_coder->geocode('Middle of Nowhere')
	} 'No crash with nonexistent location';
	is($result, undef, 'Returns undef for nonexistent location');
};

subtest 'Invalid inputs' => sub {
	throws_ok {
		$geo_coder->geocode(undef)
	} qr/Usage/, 'Fails when input is undefined';

	throws_ok {
		$geo_coder->geocode(12345)
	} qr/invalid location/, 'Fails when input is numeric';
};

subtest 'Reverse geocode' => sub {
	my $lat = 40.7128;
	my $lon = -74.0060;

	throws_ok {
		$geo_coder->reverse_geocode($lat, $lon)
	} qr/not yet supported/, 'Throws not supported error for reverse_geocode';
};

subtest 'Scantext edge cases' => sub {
	my $result;

	# Empty text
	lives_ok {
		$result = $geo_coder->geocode(scantext => '');
	} 'No crash with empty text';
	is_deeply($result, undef, 'Returns undef for empty text input');

	# Text without locations
	lives_ok {
		$result = $geo_coder->geocode(scantext => 'No locations here');
	} 'No crash with text without locations';
	is($result, undef, 'Returns undefined for text without locations');
};

subtest 'Environment variable configuration' => sub {
	local $ENV{OPENADDR_HOME} = '/mock/path';
	throws_ok {
		my $geo_coder_env = Geo::Coder::Free->new();
	} qr/Can't find the directory \/mock\/path/, 'Reads configuration from environment variable';
};

# Clean up mock databases and finalize tests
note "Mock database path: $mock_db_path";
done_testing();
