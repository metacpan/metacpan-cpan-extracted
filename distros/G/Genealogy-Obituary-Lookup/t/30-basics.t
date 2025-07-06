#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use Test::Most;

# Module loads
BEGIN { use_ok('Genealogy::Obituary::Lookup') }

# Mock database
BEGIN {
	package Genealogy::Obituary::Lookup::obituaries;
	use strict;
	use warnings;

	sub new {
		my $class = shift;
		return bless {}, $class;
	}
	sub selectall_hashref {
		# Return mock data
		return [
			{ first => 'John', last => 'Smith', source => 'M', page => 1 },
			{ first => 'Jane', last => 'Smith', source => 'F', page => 2 }
		];
	}
	sub fetchrow_hashref {
		# Return a single record
		return { first => 'John', last => 'Smith', source => 'M', page => 1 }
	}
}

# Object creation
my $directory = tempdir(CLEANUP => 1);
my $obj = Genealogy::Obituary::Lookup->new(
	directory => $directory,
);
ok($obj, 'Object created successfully');

# Method 'search' for mandatory 'last' argument
my @results = $obj->search(last => 'Smith');
is(scalar(@results), 2, 'Search returned correct number of results');
is($results[0]->{'first'}, 'John', 'First result matches expected value');
like($results[0]->{'url'}, qr/^https:\/\//, 'URL in results is correctly formatted');

# Begin edge case testing
subtest 'Testing new() constructor' => sub {
	# Test with no arguments
	my $obj = Genealogy::Obituary::Lookup->new();
	ok($obj, 'Constructor works without arguments');

	# Test with invalid directory
	my $invalid_dir_obj = Genealogy::Obituary::Lookup->new(directory => '/nonexistent/path');
	ok(!$invalid_dir_obj, 'Constructor fails gracefully with invalid directory');

	# Test with valid directory argument
	my $valid_dir_obj = Genealogy::Obituary::Lookup->new(directory => '.');
	ok($valid_dir_obj, 'Constructor works with valid directory argument');

	# Test cloning an object
	my $clone = $valid_dir_obj->new();
	ok($clone, 'Cloning works with an existing object');
	cmp_deeply($clone, $valid_dir_obj, 'Cloned object matches original');
};

subtest 'Testing search() method' => sub {
	my $obj = Genealogy::Obituary::Lookup->new(directory => $directory);

	# Test without required argument (last name)
	my @results;
	throws_ok {
		@results = $obj->search();
	} qr/Usage/, 'Fails when input is undefined';
	ok(!@results, 'Search fails gracefully when last name is not provided');

	# Test with valid last name
	@results = $obj->search('Smith');
	isa_ok(\@results, 'ARRAY', 'Search returns an array');
	cmp_ok(scalar(@results), '>', 0, 'At least one Smith is returned');
	pass('Search handles valid inputs correctly');
	foreach my $result(@results) {
		cmp_ok($result->{'last'}, 'eq', 'Smith', 'Only Smiths are returned');
	}

	# Test with additional parameters
	@results = $obj->search(last => 'Smith', first => 'John');
	isa_ok(\@results, 'ARRAY', 'Search accepts additional parameters');
};

subtest 'Testing _create_url() private method' => sub {
	# Create a mock obituary object
	my $mock_obit = {
		source => 'M',
		page   => '1',
	};

	# Test valid input
	my $url = Genealogy::Obituary::Lookup::_create_url($mock_obit);
	like($url, qr/^https:\/\/wayback.archive-it\.org/, 'Valid URL is created');

	# Test missing page
	delete $mock_obit->{page};
	throws_ok {
		Genealogy::Obituary::Lookup::_create_url($mock_obit);
	} qr/undefined \$page/, 'Throws error for missing page';

	# Test missing source
	$mock_obit = { page => '1' };
	throws_ok {
		Genealogy::Obituary::Lookup::_create_url($mock_obit);
	} qr/undefined source/, 'Throws error for missing source';

	# Test invalid source
	$mock_obit = { source => 'X', page => '1' };
	throws_ok {
		Genealogy::Obituary::Lookup::_create_url($mock_obit);
	} qr/Invalid source/, 'Throws error for invalid source';
};

subtest 'Test loading configuration from a file' => sub {
	my $config_file = File::Spec->catfile($Bin, File::Spec->updir(), 'config.yaml');

	my $obj = Genealogy::Obituary::Lookup->new(config_file => $config_file);

	cmp_ok($obj->{'directory'}, 'eq', '/', 'Can read configuration in from a file');
};

# End tests
done_testing();
