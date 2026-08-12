use strict;
use warnings;

use File::Temp qw(tempdir);
use Genealogy::Wills;
use Test::Most tests => 19;	# Define the number of tests
use Test::Returns;

# Mock database
BEGIN {
	package Genealogy::Wills::wills;
	use strict;
	use warnings;
	sub new {
		my $class = shift;
		return bless {}, $class;
	}
	sub selectall_hashref {
		# Return mock data
		return [
			{ first => 'John', last => 'Smith', url => 'example.com/john_smith' },
			{ first => 'Jane', last => 'Smith', url => 'example.com/jane_smith' },
		];
	}
	sub fetchrow_hashref {
		# Return a single record
		return { first => 'John', last => 'Smith', url => 'example.com/john_smith' };
	}
}

# Test directory setup
my $temp_dir = tempdir(CLEANUP => 1);

# Test object creation
my $obj = Genealogy::Wills->new(directory => $temp_dir);
ok($obj, 'Object created successfully');

# Test invalid directory
my $invalid_dir_obj = Genealogy::Wills->new(directory => '/invalid/directory');
ok(!defined($invalid_dir_obj), 'Object creation fails with invalid directory');

# Test object properties
is($obj->{'directory'}, $temp_dir, 'Directory property set correctly');

# Test search with valid parameters
my @results = $obj->search(last => 'Smith');
returns_is(\@results, { 'type' => 'arrayref', 'min' => 2, 'max' => 2 }, 'Search returned correct number of results');
is($results[0]->{'first'}, 'John', 'First result matches expected value');
like($results[0]->{'url'}, qr/^https:\/\//, 'URL in results is correctly formatted');

# Test search with missing parameters
dies_ok(sub { $obj->search() }, 'Search with missing parameters dies');

# Test cloning existing object
my $cloned_obj = $obj->new(logger => sub { print @_ });
ok($cloned_obj, 'Successfully cloned an existing object');
is($cloned_obj->{'directory'}, $obj->{'directory'}, 'Cloned object retains original directory');

# Test overwriting default properties
my $custom_obj = Genealogy::Wills->new(directory => $temp_dir, cache_duration => '2 days');
is($custom_obj->{'cache_duration'}, '2 days', 'Custom cache_duration property is set correctly');

# Test search returning no results
{
	no warnings 'redefine';	# Mock `selectall_hashref` to return an empty list

	*Genealogy::Wills::wills::selectall_hashref = sub { [] };
	my @no_results = $obj->search(last => 'Nonexistent');
	returns_is(\@no_results, { 'type' => 'arrayref', 'min' => 0, 'max' => 0 }, 'Search with non-existent name returns no results');
}

# Test URL formatting
{
	no warnings 'redefine';	# Mock `selectall_hashref` to return URLs without protocol
	*Genealogy::Wills::wills::selectall_hashref = sub {
		return [{ first => 'John', last => 'Smith', url => 'example.com/john_smith' }];
	};
	my @results = $obj->search(last => 'Smith');
	returns_is(\@results, { 'type' => 'arrayref', 'min' => 1, 'max' => 1 }, 'Search returns correct number of results');
	like($results[0]->{'url'}, qr/^https:\/\//, 'URL formatting correctly prepends https://');
}

# ------------------------------------------------------------------
# Equivalence-partition boundary tests for 'year'
# Major Premise:  PVS enforces year in range [1 .. MAX_WILL_YEAR].
# Partition A: below min (year=0)   => validation FAILS  (invalid partition)
# Partition B: min boundary (year=1) => validation PASSES (valid partition)
# Partition C: max boundary (year=MAX_WILL_YEAR) => validation PASSES
# Partition D: above max (year=MAX_WILL_YEAR+1) => validation FAILS
# ------------------------------------------------------------------

my $max_year = (localtime)[5] + 1900;

# Partition A: below minimum -- PVS must reject
dies_ok(
	sub { $obj->search(last => 'Smith', year => 0) },
	'year=0 (below min boundary) is rejected by PVS'
);

# Partition B: minimum boundary -- PVS must accept
lives_ok(
	sub { my @r = $obj->search(last => 'Smith', year => 1) },
	'year=1 (min boundary) is accepted by PVS'
);

# Partition C: maximum boundary -- PVS must accept
lives_ok(
	sub { my @r = $obj->search(last => 'Smith', year => $max_year) },
	'year=MAX_WILL_YEAR (max boundary) is accepted by PVS'
);

# Partition D: above maximum -- PVS must reject
dies_ok(
	sub { $obj->search(last => 'Smith', year => $max_year + 1) },
	'year=MAX_WILL_YEAR+1 (above max boundary) is rejected by PVS'
);

# Scalar context: search() must return a single hashref (or undef), not a list
{
	no warnings 'redefine';
	*Genealogy::Wills::wills::fetchrow_hashref = sub {
		return { first => 'John', last => 'Smith', url => 'example.com/js' };
	};
	my $one = $obj->search(last => 'Smith');
	ok(ref($one) eq 'HASH', 'scalar context returns a single hashref');
	like($one->{'url'}, qr/^https:\/\//, 'scalar-context url has https:// prefix');
}
