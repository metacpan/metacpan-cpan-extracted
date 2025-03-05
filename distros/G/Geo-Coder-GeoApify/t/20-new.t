#!perl -w

use strict;
use warnings;

use Carp;
use LWP::UserAgent;
use Test::More tests => 16;

# Load the package/module where 'new' is implemented
BEGIN { use_ok('Geo::Coder::GeoApify') }

# Test case 1: Creating a new object with a valid apiKey and default user agent and host
{
	my $obj = Geo::Coder::GeoApify->new({ apiKey => 'test_key' });
	isa_ok($obj, 'Geo::Coder::GeoApify', 'Object created with valid apiKey');
	is($obj->{apiKey}, 'test_key', 'apiKey set correctly');
	isa_ok($obj->{ua}, 'LWP::UserAgent', 'User agent created as LWP::UserAgent');
	is($obj->{host}, 'api.geoapify.com/v1/geocode', 'Default host set correctly');
}

# Test case 2: Passing a user agent and host in arguments
{
	my $ua = new_ok('LWP::UserAgent');
	my $obj = Geo::Coder::GeoApify->new({ apiKey => 'test_key', ua => $ua, host => 'example.com' });
	is($obj->{ua}, $ua, 'Custom user agent set correctly');
	is($obj->{host}, 'example.com', 'Custom host set correctly');
}

# Test case 3: Cloning an existing object with additional arguments
{
	my $obj = Geo::Coder::GeoApify->new({ apiKey => 'original_key' });
	my $cloned_obj = $obj->new(apiKey => 'new_key');
	isa_ok($cloned_obj, 'Geo::Coder::GeoApify', 'Cloned object created');
	is($cloned_obj->{apiKey}, 'new_key', 'Cloned object with new apiKey');
}

# Test case 4: Missing apiKey - should warn and return undef
{
	local $SIG{__WARN__} = sub { $_[0] =~ /apiKey not given/ and pass('Warning for missing apiKey') };
	ok(!defined(Geo::Coder::GeoApify->new({})), 'Object creation failed without apiKey');
}

# Test case 5: apiKey is not a scalar - should warn and return undef
{
	local $SIG{__WARN__} = sub { $_[0] =~ /apiKey must be a scalar/ and pass('Warning for non-scalar apiKey') };
	ok(!defined(Geo::Coder::GeoApify->new({ apiKey => [ 'not', 'scalar' ] })), 'Object creation failed with non-scalar apiKey');
}

# Test case 6: Ensure SSL verification is disabled if host is undefined
{
	my $obj = Geo::Coder::GeoApify->new({ apiKey => 'test_key', ua => LWP::UserAgent->new });
	ok(!$obj->{ua}->ssl_opts('verify_hostname'), 'SSL verification disabled without host');
}

# Test case 7: Ensure calling mechanism works
{
	ok(!defined(Geo::Coder::GeoApify::new()));
}
