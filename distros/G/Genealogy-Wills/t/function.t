use strict;
use warnings;

use File::Temp qw(tempdir);
use Genealogy::Wills;
use Readonly;
use Test::Memory::Cycle;
use Test::Needs 'Test::Mockingbird';
use Test::Mockingbird;
use Test::Most;
use Test::Returns;

# -----------------------------------------------------------------------
# Shared constants
# -----------------------------------------------------------------------
Readonly my $MAX_YEAR  => (localtime)[5] + 1900;
Readonly my $ABOVE_MAX => $MAX_YEAR + 1;

# These rows are the "database" returned by our mock selectall_hashref.
# Each call to _inject_mock_db returns FRESH copies (via map+hash-slice)
# so that _decorate_will's in-place url mutation does not carry over
# between test sections.
Readonly my @MOCK_ROWS => (
	{ first => 'John', last => 'Smith', url => 'example.com/john' },
	{ first => 'Jane', last => 'Smith', url => 'example.com/jane' },
);
Readonly my %MOCK_ROW => (first => 'John', last => 'Smith', url => 'example.com/john');

# -----------------------------------------------------------------------
# Helper: white-box injection of a mock wills database object into $obj.
# Bypasses Genealogy::Wills::wills->new() so no SQLite file is needed.
# The ||= guard in search() will not replace this once it is set.
# -----------------------------------------------------------------------
sub _inject_mock_db {
	my ($obj) = @_;
	my $mock_db = bless {}, 'Genealogy::Wills::wills';
	mock 'Genealogy::Wills::wills::selectall_hashref' => sub {
		return [ map { +{%$_} } @MOCK_ROWS ];
	};
	mock 'Genealogy::Wills::wills::fetchrow_hashref' => sub {
		return { %MOCK_ROW };
	};
	$obj->{'wills'} = $mock_db;
	return $mock_db;
}

my $temp_dir = tempdir(CLEANUP => 1);

# -----------------------------------------------------------------------
# MODULE: Genealogy::Wills
# Function: new()
# -----------------------------------------------------------------------

subtest 'new() -- basic construction' => sub {
	my $obj = Genealogy::Wills->new(directory => $temp_dir);

	ok($obj, 'new() returns a defined value for a valid directory');
	isa_ok($obj, 'Genealogy::Wills', 'returned object');
	is($obj->{'directory'}, $temp_dir, 'directory attribute stored correctly');
	is($obj->{'cache_duration'}, '1 day', 'cache_duration defaults to "1 day"');
	memory_cycle_ok($obj, 'freshly constructed object has no circular references');
};

subtest 'new() -- argument forms all produce equivalent objects' => sub {
	# All three forms should reach the same internal state.
	my $obj_str  = Genealogy::Wills->new($temp_dir);          # single-string shortcut
	my $obj_href = Genealogy::Wills->new({ directory => $temp_dir });   # hashref
	my $obj_flat = Genealogy::Wills->new(directory => $temp_dir);       # flat list

	ok($obj_str,  'single-string shortcut form creates an object');
	is($obj_str->{'directory'}, $temp_dir, 'single-string form sets directory');
	ok($obj_href, 'hashref argument form creates an object');
	ok($obj_flat, 'flat key-value form creates an object');

	diag "obj_str directory: $obj_str->{'directory'}" if $ENV{TEST_VERBOSE};
};

subtest 'new() -- failure paths' => sub {
	# Non-existent config_file must croak BEFORE checking the directory.
	throws_ok(
		sub { Genealogy::Wills->new(config_file => '/does/not/exist.yml') },
		qr/Can't load configuration from/,
		'non-existent config_file croaks with descriptive message'
	);

	# An invalid directory returns undef (carp, not croak) so the caller can
	# check the return value rather than catching an exception.
	my $invalid_obj;
	{
		# Suppress the carp warning that new() emits for an invalid directory.
		local $SIG{__WARN__} = sub { };
		$invalid_obj = Genealogy::Wills->new(directory => '/no/such/path');
	}
	ok(!defined($invalid_obj), 'invalid directory returns undef rather than dying');

	# A logger that lacks the required info()/error() interface must croak.
	{
		package LoggerNoMethods;
		sub new { bless {}, shift }
		# Deliberately does NOT implement info() or error().
	}
	throws_ok(
		sub { Genealogy::Wills->new(directory => $temp_dir, logger => LoggerNoMethods->new()) },
		qr/Logger must be an object with info\(\) and error\(\)/,
		'logger missing both info() and error() causes croak'
	);

	# A logger with info() but no error() must also be rejected.
	{
		package LoggerInfoOnly;
		sub new  { bless {}, shift }
		sub info { }
		# Deliberately missing error().
	}
	throws_ok(
		sub { Genealogy::Wills->new(directory => $temp_dir, logger => LoggerInfoOnly->new()) },
		qr/Logger must be an object with info\(\) and error\(\)/,
		'logger missing error() causes croak even when info() exists'
	);
};

subtest 'new() -- valid logger is accepted' => sub {
	{
		package ValidLogger;
		sub new   { bless {}, shift }
		sub info  { }
		sub error { }
	}
	my $obj = Genealogy::Wills->new(directory => $temp_dir, logger => ValidLogger->new());
	ok($obj, 'object is created when logger has both info() and error()');
};

subtest 'new() -- cloning via instance->new()' => sub {
	my $original = Genealogy::Wills->new(directory => $temp_dir);
	my $clone    = $original->new(cache_duration => '2 days');

	ok($clone, 'instance->new() returns a cloned object');
	isnt($clone, $original, 'clone is a different reference from the original');
	is($clone->{'directory'}, $original->{'directory'},
		'clone inherits directory from original');
	is($clone->{'cache_duration'}, '2 days',
		'clone respects caller-supplied override');
	memory_cycle_ok($clone, 'cloned object has no circular references');
};

# -----------------------------------------------------------------------
# MODULE: Genealogy::Wills
# Function: search()
# -----------------------------------------------------------------------

subtest 'search() -- fatal preconditions (no DB needed)' => sub {
	# Called as a class method (not on a blessed object) must croak immediately.
	throws_ok(
		sub { Genealogy::Wills->search(last => 'Smith') },
		qr/search\(\) must be called on an object/,
		'class-method call croaks with the correct message'
	);

	my $obj = Genealogy::Wills->new(directory => $temp_dir);

	# Called with no arguments at all must croak (Usage: message).
	throws_ok(
		sub { $obj->search() },
		qr/Usage: search/,
		'search() with no arguments croaks with a Usage message'
	);
};

subtest 'search() -- carp (non-fatal) for undef last' => sub {
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	_inject_mock_db($obj);

	# undef last must produce a warning (carp), not a fatal exception.
	# The code path:  PVS allows undef through, then
	# `unless(length($params->{'last'} // ''))` fires the carp and returns.
	my @results;
	warning_like(
		sub { @results = $obj->search(last => undef) },
		qr/Value for 'last' is mandatory/,
		'carp "Value for last is mandatory" emitted for undef last'
	);
	is(scalar(@results), 0, 'search(last => undef) returns empty list, not an exception');

	restore_all();
};

subtest 'search() -- PVS validates all five input fields' => sub {
	my $obj = Genealogy::Wills->new(directory => $temp_dir);

	# 'last': ASCII word chars + hyphen only.  The /a modifier means \w is
	# [0-9A-Za-z_] -- Cyrillic and other Unicode word chars are rejected.
	# Apostrophe is NOT in the allowed set for 'last' (though it IS for 'first').
	dies_ok(
		sub { $obj->search(last => "O'Brien") },
		"apostrophe in 'last' is rejected by PVS"
	);
	dies_ok(
		sub { $obj->search(last => 'Smith;DROP TABLE wills') },
		"semicolon injection in 'last' is rejected by PVS"
	);

	# Inject mock DB so that the remaining (passing) tests reach the DB layer.
	_inject_mock_db($obj);

	# 'first': allows apostrophe, period, hyphen, space (O'Brien, St. John).
	lives_ok(
		sub { my @r = $obj->search(last => 'Smith', first => "O'Brien") },
		"apostrophe in 'first' is accepted"
	);
	lives_ok(
		sub { my @r = $obj->search(last => 'Smith', first => 'Mary-Anne') },
		"hyphen in 'first' is accepted"
	);
	dies_ok(
		sub { $obj->search(last => 'Smith', first => 'John;DROP') },
		"semicolon in 'first' is rejected"
	);

	# 'town': same as first/middle, plus comma for "Town, County, Country".
	lives_ok(
		sub { my @r = $obj->search(last => 'Smith', town => 'Canterbury, Kent, England') },
		"comma-separated town is accepted"
	);
	dies_ok(
		sub { $obj->search(last => 'Smith', town => 'Canterbury<script>') },
		"angle-bracket injection in 'town' is rejected"
	);

	# 'year': integer, min=1, max=current year (computed once at module load).
	dies_ok(
		sub { $obj->search(last => 'Smith', year => 0) },
		'year=0 is below minimum and is rejected'
	);
	lives_ok(
		sub { my @r = $obj->search(last => 'Smith', year => 1) },
		'year=1 (minimum boundary) is accepted'
	);
	lives_ok(
		sub { my @r = $obj->search(last => 'Smith', year => $MAX_YEAR) },
		'year=MAX_WILL_YEAR (maximum boundary) is accepted'
	);
	dies_ok(
		sub { $obj->search(last => 'Smith', year => $ABOVE_MAX) },
		'year=MAX_WILL_YEAR+1 (above maximum) is rejected'
	);

	diag "MAX_YEAR=$MAX_YEAR  ABOVE_MAX=$ABOVE_MAX" if $ENV{TEST_VERBOSE};

	restore_all();
};

subtest 'search() -- list context returns all matching rows' => sub {
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	_inject_mock_db($obj);

	my @results = $obj->search(last => 'Smith');

	returns_is(\@results, { type => 'arrayref', min => 2, max => 2 },
		'list context: correct number of rows returned');
	is($results[0]->{'first'}, 'John',
		'first result: first name matches mock data');
	like($results[0]->{'url'}, qr{^https://},
		'first result: url has https:// prefix injected by search()');
	like($results[1]->{'url'}, qr{^https://},
		'second result: url also has https:// prefix');

	diag "results[0] url: $results[0]{'url'}" if $ENV{TEST_VERBOSE};

	restore_all();
};

subtest 'search() -- scalar context returns first matching row only' => sub {
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	_inject_mock_db($obj);

	my $will = $obj->search(last => 'Smith');

	ok(defined($will), 'scalar context: defined value returned when rows exist');
	is(ref($will), 'HASH', 'scalar context: value is a hashref');
	like($will->{'url'}, qr{^https://},
		'scalar context: url has https:// prefix');

	restore_all();
};

subtest 'search() -- empty result set' => sub {
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	my $mock_db = bless {}, 'Genealogy::Wills::wills';
	mock 'Genealogy::Wills::wills::selectall_hashref' => sub { [] };
	mock 'Genealogy::Wills::wills::fetchrow_hashref'  => sub { undef };
	$obj->{'wills'} = $mock_db;

	my @list = $obj->search(last => 'Nonexistent');
	is(scalar(@list), 0, 'list context returns empty list when nothing matches');

	my $scalar = $obj->search(last => 'Nonexistent');
	ok(!defined($scalar), 'scalar context returns undef when nothing matches');

	restore_all();
};

subtest 'search() -- single-string shortcut form' => sub {
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	_inject_mock_db($obj);

	# search('Smith') is documented as equivalent to search(last => 'Smith').
	my @results;
	lives_ok(sub { @results = $obj->search('Smith') },
		'search("Smith") single-string form is accepted');
	ok(scalar(@results) > 0, 'single-string form returns results');

	restore_all();
};

subtest 'search() -- wills DB object is lazily initialised once' => sub {
	# The ||= operator in search() must not call Genealogy::Wills::wills->new()
	# more than once regardless of how many times search() is invoked.
	my $obj = Genealogy::Wills->new(directory => $temp_dir);

	my $new_call_count = 0;
	mock 'Genealogy::Wills::wills::new' => sub {
		$new_call_count++;
		return bless {}, 'Genealogy::Wills::wills';
	};
	mock 'Genealogy::Wills::wills::selectall_hashref' => sub { [] };
	mock 'Genealogy::Wills::wills::fetchrow_hashref'  => sub { undef };

	$obj->search(last => 'Smith');
	$obj->search(last => 'Jones');

	is($new_call_count, 1,
		'Genealogy::Wills::wills->new() is called exactly once across multiple searches');

	diag "new_call_count=$new_call_count" if $ENV{TEST_VERBOSE};

	restore_all();
};

# -----------------------------------------------------------------------
# MODULE: Genealogy::Wills
# Function: _decorate_will()  (internal helper -- white-box tests)
# -----------------------------------------------------------------------

subtest '_decorate_will() -- mutates url in place and returns same ref' => sub {
	my $will = { first => 'John', last => 'Smith', url => 'example.com/john', year => 1750 };

	my $returned = Genealogy::Wills::_decorate_will($will);

	is($will->{'url'}, 'https://example.com/john',
		'_decorate_will prepends https:// to url');
	is($returned, $will,
		'_decorate_will returns the same hashref (enables chaining in scalar branch)');
};

subtest '_decorate_will() -- invokes Data::Reuse::fixate' => sub {
	# Use a spy so the real fixate still runs (we observe, not replace).
	my $spy = spy 'Data::Reuse::fixate';

	my $will = { first => 'Jane', last => 'Smith', url => 'freepages.example.com/jane' };
	Genealogy::Wills::_decorate_will($will);

	my @calls = $spy->();
	ok(scalar(@calls) > 0,
		'Data::Reuse::fixate is called by _decorate_will to intern strings');

	diag 'fixate calls: ' . scalar(@calls) if $ENV{TEST_VERBOSE};

	restore_all();
};

# -----------------------------------------------------------------------
# MODULE: Genealogy::Wills::wills
# Thin inheritance shim -- no own methods, so test the ISA relationship.
# -----------------------------------------------------------------------

subtest 'Genealogy::Wills::wills inherits from Database::Abstraction' => sub {
	ok(Genealogy::Wills::wills->isa('Database::Abstraction'),
		'Genealogy::Wills::wills ISA Database::Abstraction');
	ok(Genealogy::Wills::wills->can('selectall_hashref'),
		'selectall_hashref is available via Database::Abstraction inheritance');
	ok(Genealogy::Wills::wills->can('fetchrow_hashref'),
		'fetchrow_hashref is available via Database::Abstraction inheritance');
};

done_testing();
