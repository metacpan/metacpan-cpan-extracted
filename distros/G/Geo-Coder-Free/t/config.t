#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most tests => 5;
use Test::NoWarnings;
use File::Temp;
use File::Spec;

BEGIN {
	use_ok('Geo::Coder::Free::Config');
	local $ENV{'HOME'} = File::Temp::tempdir(CLEANUP => 1);
}

# Ensure CGI::Info doesn't attempt to read from stdin
local $ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';
local $ENV{'REQUEST_METHOD'} = 'GET';
local $ENV{'QUERY_STRING'} = 'lang=en';

# Test for creating a new object
subtest 'Object creation' => sub {
	my $config_obj;

	# Check it does not die
	lives_ok(
		sub {
			$config_obj = Geo::Coder::Free::Config->new();
		},
		'Geo::Coder::Free::Config object created without errors'
	);

	isa_ok($config_obj, 'Geo::Coder::Free::Config', 'Correct object type');
};

# Test AUTOLOAD functionality
subtest 'AUTOLOAD method' => sub {
	my $config_obj = Geo::Coder::Free::Config->new(config => { test_key => 'test_value' });

	is($config_obj->test_key(), 'test_value', 'AUTOLOAD correctly retrieves a key-value pair');

	is($config_obj->nonexistent_key(), undef, 'AUTOLOAD returns undef for non-existent keys');
};

# Test config file and environment variable overrides
subtest 'Configuration overrides' => sub {
	my $custom_config = {
		test_key => 'default_value',
		override_key => 'default_override',
	};

	local $ENV{'override_key'} = 'env_override_value';

	my $config_obj = Geo::Coder::Free::Config->new(config => $custom_config);

	is($config_obj->{test_key}, 'default_value', 'Default configuration loaded correctly');

	is($config_obj->{override_key}, 'env_override_value', 'Environment variable overrides configuration value');
};
