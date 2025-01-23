#!perl -wT

use strict;

use lib 'lib';
use Carp;
use Test::Most tests => 19;

# Load the package/module where 'new' is implemented
BEGIN { use_ok('Geo::Coder::Free'); use_ok('Geo::Coder::Free::Local') }

isa_ok(Geo::Coder::Free->new(), 'Geo::Coder::Free', 'Creating Geo::Coder::Free object');
isa_ok(Geo::Coder::Free::new(), 'Geo::Coder::Free', 'Creating Geo::Coder::Free object');
isa_ok(Geo::Coder::Free->new()->new(), 'Geo::Coder::Free', 'Cloning Geo::Coder::Free object');

isa_ok(Geo::Coder::Free::Local->new(), 'Geo::Coder::Free::Local', 'Creating Geo::Coder::Free::Local object');
isa_ok(Geo::Coder::Free::Local::new(), 'Geo::Coder::Free::Local', 'Creating Geo::Coder::Free::Local object');
isa_ok(Geo::Coder::Free::Local->new()->new(), 'Geo::Coder::Free::Local', 'Cloning Geo::Coder::Free::Local object');

# Test case 1: Creating a new object with default values and alternatives
{
	my $obj = Geo::Coder::Free->new();
	isa_ok($obj, 'Geo::Coder::Free', 'Object created with default values');
	isa_ok($obj->{maxmind}, 'Geo::Coder::Free::MaxMind', 'maxmind object created');
}

# Test case 2: Cloning an existing object with new arguments
{
	my $original_obj = Geo::Coder::Free->new({ cache => 'CacheData' });
	my $cloned_obj = $original_obj->new({ additional_key => 'extra_value' });
	isa_ok($cloned_obj, 'Geo::Coder::Free', 'Cloned object created');
	is($cloned_obj->{cache}, 'CacheData', 'Cache data cloned');
	is($cloned_obj->{additional_key}, 'extra_value', 'Additional argument added to cloned object');
}

# Test case 3: Setting up with openaddr from environment variable
{
	local $ENV{'OPENADDR_HOME'} = '/';
	my $obj = Geo::Coder::Free->new();
	isa_ok($obj->{openaddr}, 'Geo::Coder::Free::OpenAddresses', 'openaddr object created using ENV variable');
}

# Test case 4: Passing openaddr directly in arguments
{
	my $obj = Geo::Coder::Free->new({ openaddr => '/' });
	isa_ok($obj->{openaddr}, 'Geo::Coder::Free::OpenAddresses', 'openaddr object created using argument');
}

# Test case 5: Cache assignment in object
{
	my $obj = Geo::Coder::Free->new({ cache => 'SomeCacheValue' });
	is($obj->{cache}, 'SomeCacheValue', 'Cache value assigned correctly');
}

# Test case 6: Cloning an existing object with new arguments
{
	my $original_obj = Geo::Coder::Free::Local->new();
	my $cloned_obj = $original_obj->new({ additional_key => 'extra_value' });
	isa_ok($cloned_obj, 'Geo::Coder::Free::Local', 'Cloned object created');
	is($cloned_obj->{additional_key}, 'extra_value', 'Additional argument added to cloned object');
	is_deeply($cloned_obj->{data}, $original_obj->{data}, 'Cloned object has the same data as original');
}
