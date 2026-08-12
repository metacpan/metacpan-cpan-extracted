use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Readonly;
use Scalar::Util qw(blessed);
use Test::Needs 'Test::Mockingbird';
use Test::Mockingbird;
use Test::Most;
use Test::Returns;
use YAML::Any qw(DumpFile);

use_ok('Genealogy::Wills');
use_ok('Genealogy::Wills::wills');

# -----------------------------------------------------------------------
# Shared constants -- no magic values in assertions.
# -----------------------------------------------------------------------
Readonly my $MAX_YEAR => (localtime)[5] + 1900;

# RAW_URL is what the DB stores (no scheme).  _decorate_will() prepends https://.
Readonly my $RAW_URL  => 'freepages.rootsweb.com/~mrawson/genealogy/t.html';
Readonly my $FULL_URL => "https://$RAW_URL";

# Three mock rows covering multiple first names so list-context tests can
# verify all rows are returned (not just the first one).
Readonly my @MOCK_ROWS => (
	{ first => 'John',  last => 'Smith', year => 1750, town => 'Canterbury, Kent, England', url => $RAW_URL },
	{ first => 'Jane',  last => 'Smith', year => 1780, town => 'Dover, Kent, England',      url => $RAW_URL },
	{ first => 'James', last => 'Smith', year => 1800, town => 'Ashford, Kent, England',    url => $RAW_URL },
);
Readonly my %MOCK_ROW => (
	first => 'John', last => 'Smith', year => 1750,
	town  => 'Canterbury, Kent, England', url => $RAW_URL,
);

# A single temp directory shared across subtests that don't need isolation.
my $temp_dir = tempdir(CLEANUP => 1);

# -----------------------------------------------------------------------
# Mock helpers
# Strategy: intercept Genealogy::Wills::wills->new() so the real SQLite
# open never fires, then mock the query methods.  Always call restore_all()
# at the end of each subtest that calls a mock helper.
# -----------------------------------------------------------------------

# _mock_wills_with_rows: intercepts new() and returns 3-row list / 1-row scalar.
sub _mock_wills_with_rows {
	my $mock = bless {}, 'Genealogy::Wills::wills';
	mock 'Genealogy::Wills::wills::selectall_hashref' => sub {
		return [ map { +{%$_} } @MOCK_ROWS ];    # fresh copies per call
	};
	mock 'Genealogy::Wills::wills::fetchrow_hashref' => sub {
		return { %MOCK_ROW };
	};
	intercept_new 'Genealogy::Wills::wills' => $mock;
	return $mock;
}

# _mock_wills_empty: intercepts new() and returns empty results.
sub _mock_wills_empty {
	my $mock = bless {}, 'Genealogy::Wills::wills';
	mock 'Genealogy::Wills::wills::selectall_hashref' => sub { [] };
	mock 'Genealogy::Wills::wills::fetchrow_hashref'  => sub { undef };
	intercept_new 'Genealogy::Wills::wills' => $mock;
	return $mock;
}

# =======================================================================
# SECTION 1: Module loading and cross-module ISA chain
# Verifies that both modules load and that Genealogy::Wills::wills correctly
# inherits from Database::Abstraction (the DB delegation layer).
# =======================================================================

subtest 'both modules load and expose their complete public interfaces' => sub {
	# Confirms the full load chain: Genealogy::Wills -> Genealogy::Wills::wills
	# -> Database::Abstraction.  If any link is broken the test plan fails here.
	isa_ok('Genealogy::Wills::wills', 'Database::Abstraction');
	ok(Genealogy::Wills->can('new'),    'Genealogy::Wills::new() is callable');
	ok(Genealogy::Wills->can('search'), 'Genealogy::Wills::search() is callable');
	ok(Genealogy::Wills::wills->can('selectall_hashref'),
		'selectall_hashref inherited from Database::Abstraction');
	ok(Genealogy::Wills::wills->can('fetchrow_hashref'),
		'fetchrow_hashref inherited from Database::Abstraction');
};

# =======================================================================
# SECTION 2: new() -> search() end-to-end workflows
# Each subtest covers one complete path from object construction through
# query execution to result decoration.
# =======================================================================

subtest 'workflow: new() -> search() list context returns all rows with https:// urls' => sub {
	# End-to-end path: new() constructs the object, search() lazily opens the
	# DB, selectall_hashref returns all rows, _decorate_will prepends https://.
	_mock_wills_with_rows();
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	ok($obj,                         'new() returned a valid object');
	isa_ok($obj, 'Genealogy::Wills', 'returned object is correct type');

	my @results = $obj->search(last => 'Smith');

	returns_is(\@results, { type => 'arrayref', min => 3, max => 3 },
		'list context: all three mock rows returned');

	# Every row must have https:// injected by _decorate_will regardless of
	# field order or row count.
	for my $r (@results) {
		like($r->{'url'}, qr{\Ahttps://},
			"$r->{'first'} Smith: url starts with https://");
	}

	diag 'row count: ' . scalar(@results)   if $ENV{TEST_VERBOSE};
	diag 'first url: ' . $results[0]{'url'} if $ENV{TEST_VERBOSE};

	restore_all();
};

subtest 'workflow: new() -> search() scalar context returns one hashref with https:// url' => sub {
	# Scalar context delegates to fetchrow_hashref instead of selectall_hashref.
	# The result must be a single HASH reference, not an array of one element.
	_mock_wills_with_rows();
	my $obj    = Genealogy::Wills->new(directory => $temp_dir);
	my $result = $obj->search(last => 'Smith');

	ok(defined($result),     'scalar context: defined value returned');
	is(ref($result), 'HASH', 'scalar context: value is a HASH ref, not an ARRAY ref');
	is($result->{'first'}, 'John', 'first name matches the mock row');
	like($result->{'url'}, qr{\Ahttps://}, 'url has https:// scheme');

	diag 'scalar url: ' . $result->{'url'} if $ENV{TEST_VERBOSE};

	restore_all();
};

subtest 'workflow: bare-string search() produces same results as named-argument form' => sub {
	# POD: $obj->search('Smith') is equivalent to $obj->search(last => 'Smith').
	# Test both forms on the same object and verify identical result shape.
	_mock_wills_with_rows();
	my $obj = Genealogy::Wills->new(directory => $temp_dir);

	my @named = $obj->search(last => 'Smith');
	my @bare  = $obj->search('Smith');

	is(scalar(@named), scalar(@bare),
		'bare-string and named-argument forms return same row count');
	is($named[0]{'first'}, $bare[0]{'first'},
		'first element first-name matches between both argument forms');
	like($bare[0]{'url'}, qr{\Ahttps://},
		'bare-string result url also has https:// scheme');

	diag "named: @{[scalar @named]} rows, bare: @{[scalar @bare]} rows"
		if $ENV{TEST_VERBOSE};

	restore_all();
};

subtest 'workflow: hashref argument form new({ key => value }) is accepted' => sub {
	# The POD documents three equivalent forms for new().  Test the hashref form.
	_mock_wills_with_rows();
	my $obj = Genealogy::Wills->new({ directory => $temp_dir });
	ok($obj, 'hashref argument form creates a valid object');
	is($obj->{'directory'}, $temp_dir, 'hashref form stores directory correctly');

	my @r = $obj->search(last => 'Smith');
	ok(scalar(@r) > 0, 'search() works on an object created with hashref form');

	restore_all();
};

# =======================================================================
# SECTION 3: Config-file and ENV-override workflows
# Tests the two-stage construction path: config file -> merge -> directory.
# =======================================================================

subtest 'workflow: new(config_file) reads directory from YAML and enables search()' => sub {
	# Strategy: write a minimal YAML config, construct via config_file, then
	# verify the directory was read and search() works end-to-end.
	my $cfg_dir  = tempdir(CLEANUP => 1);
	my $cfg_file = File::Spec->catfile($cfg_dir, 'wills.yml');
	DumpFile($cfg_file, { Genealogy__Wills => { directory => $temp_dir } });

	_mock_wills_with_rows();
	my $obj = Genealogy::Wills->new(config_file => $cfg_file);
	ok($obj, 'new(config_file) returns a valid object');
	is($obj->{'directory'}, $temp_dir, 'directory read from config file');

	my @results = $obj->search(last => 'Smith');
	ok(scalar(@results) > 0, 'search() works after config-file-driven construction');

	diag "config directory: $obj->{'directory'}" if $ENV{TEST_VERBOSE};

	restore_all();
};

subtest 'workflow: ENV override Genealogy__Wills__directory wins over config-file directory' => sub {
	# Object::Configure merges env vars (Genealogy__Wills__<key>) before new()
	# applies defaults.  If both a config file and an env var supply a directory,
	# the env var must win.
	my $cfg_dir  = tempdir(CLEANUP => 1);
	my $cfg_file = File::Spec->catfile($cfg_dir, 'wills.yml');
	DumpFile($cfg_file, { Genealogy__Wills => { directory => '/this/should/be/overridden' } });

	# The env var points at a valid dir; the config dir doesn't exist, so if
	# the config wins the object would be undef.  Only the env override path
	# produces a valid object, making the test self-checking.
	local $ENV{'Genealogy__Wills__directory'} = $temp_dir;

	_mock_wills_with_rows();
	my $obj = Genealogy::Wills->new(config_file => $cfg_file);
	ok($obj, 'new() succeeds when ENV supplies a valid directory override');
	is($obj->{'directory'}, $temp_dir, 'ENV override wins over config-file directory');

	restore_all();
};

# =======================================================================
# SECTION 4: Object lifecycle workflows
# Tests the clone operation and object independence.
# =======================================================================

subtest 'workflow: instance->new() clone inherits directory and applies override' => sub {
	# Cloning creates a new blessed object from { %original, %overrides }.
	# The clone must: (a) be a distinct reference, (b) share the original's
	# directory, and (c) respect any override supplied to the clone call.
	_mock_wills_with_rows();
	my $original = Genealogy::Wills->new(directory => $temp_dir);
	ok($original, 'original object created');

	# Clone before any search so the wills slot is unset on the original.
	my $clone = $original->new(cache_duration => '12 hours');
	ok($clone, 'clone created via instance->new()');
	isnt($clone, $original,              'clone is a distinct blessed reference');
	isa_ok($clone, 'Genealogy::Wills');
	is($clone->{'directory'},      $temp_dir,  'clone inherits directory from original');
	is($clone->{'cache_duration'}, '12 hours', 'clone applies caller-supplied override');
	isnt($clone->{'cache_duration'}, $original->{'cache_duration'},
		'clone cache_duration differs from original (1 day vs 12 hours)');

	# The clone must be independently searchable.
	my @r = $clone->search(last => 'Smith');
	ok(scalar(@r) > 0, 'clone is independently searchable');

	diag "original cache_duration: $original->{'cache_duration'}" if $ENV{TEST_VERBOSE};
	diag "clone cache_duration: $clone->{'cache_duration'}"        if $ENV{TEST_VERBOSE};

	restore_all();
};

subtest 'workflow: two independent objects hold separate wills DB slots' => sub {
	# Strategy: count how many times Genealogy::Wills::wills->new() is called.
	# Each object must get its own DB instance; the ||= guard must prevent
	# obj1's search from populating obj2's wills slot.
	my $new_call_count = 0;
	mock 'Genealogy::Wills::wills::new' => sub {
		$new_call_count++;
		# Return a distinct mock per call so isnt() can distinguish them.
		return bless { _instance_id => $new_call_count }, 'Genealogy::Wills::wills';
	};
	mock 'Genealogy::Wills::wills::selectall_hashref' => sub { [] };
	mock 'Genealogy::Wills::wills::fetchrow_hashref'  => sub { undef };

	my $obj1 = Genealogy::Wills->new(directory => $temp_dir);
	my $obj2 = Genealogy::Wills->new(directory => $temp_dir);
	isnt($obj1, $obj2, 'obj1 and obj2 are distinct Genealogy::Wills references');

	# Both wills slots must be uninitialised before the first search.
	ok(!defined($obj1->{'wills'}), 'obj1 wills slot empty before first search');
	ok(!defined($obj2->{'wills'}), 'obj2 wills slot empty before first search');

	# Searching obj1 must only populate obj1's wills slot.
	$obj1->search(last => 'Smith');
	ok( defined($obj1->{'wills'}),  'obj1 wills slot populated after its first search');
	ok(!defined($obj2->{'wills'}),  'obj2 wills slot still empty after obj1 search');

	# Searching obj2 must populate only obj2's wills slot.
	$obj2->search(last => 'Jones');
	ok( defined($obj2->{'wills'}),  'obj2 wills slot populated after its first search');

	isnt($obj1->{'wills'}, $obj2->{'wills'},
		'obj1 and obj2 hold distinct Genealogy::Wills::wills instances');
	is($new_call_count, 2,
		'Genealogy::Wills::wills->new() called exactly twice (once per object)');

	diag "wills->new() call count: $new_call_count" if $ENV{TEST_VERBOSE};

	restore_all();
};

# =======================================================================
# SECTION 5: Cross-module interaction workflows
# Uses spy and counting mocks to verify the calls Genealogy::Wills makes
# into Genealogy::Wills::wills and Data::Reuse.
# =======================================================================

subtest 'cross-module: Genealogy::Wills::wills->new() called exactly once per object' => sub {
	# The ||= guard in search() means the DB object is created lazily on the
	# first call and reused on every subsequent call for that object instance.
	my $new_call_count = 0;
	mock 'Genealogy::Wills::wills::new' => sub {
		$new_call_count++;
		return bless {}, 'Genealogy::Wills::wills';
	};
	mock 'Genealogy::Wills::wills::selectall_hashref' => sub { [] };
	mock 'Genealogy::Wills::wills::fetchrow_hashref'  => sub { undef };

	my $obj = Genealogy::Wills->new(directory => $temp_dir);

	# Three different searches on the same object: new() must fire only once.
	$obj->search(last => 'Smith');
	$obj->search(last => 'Jones');
	$obj->search(last => 'Cowell');

	is($new_call_count, 1,
		'Genealogy::Wills::wills->new() called exactly once across three searches');

	diag "new() call count: $new_call_count" if $ENV{TEST_VERBOSE};

	restore_all();
};

subtest 'cross-module: Data::Reuse::fixate called at least once per result row' => sub {
	# _decorate_will() calls Data::Reuse::fixate(%{$will}) on each row to
	# intern repeated strings (surname, town, url prefix) and reduce heap
	# fragmentation.  A spy confirms the call count matches the row count.
	my $fixate_spy = spy 'Data::Reuse::fixate';

	_mock_wills_with_rows();
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	my @results = $obj->search(last => 'Smith');

	my @calls = $fixate_spy->();
	ok(scalar(@calls) >= scalar(@MOCK_ROWS),
		'fixate called at least once per row (' . scalar(@MOCK_ROWS) . ' rows, '
		. scalar(@calls) . ' fixate calls)');

	diag 'fixate calls: ' . scalar(@calls) . ', rows: ' . scalar(@MOCK_ROWS)
		if $ENV{TEST_VERBOSE};

	restore_all();
};

subtest 'cross-module: all five search fields are forwarded verbatim to the DB layer' => sub {
	# When the caller provides all five search fields (last, first, middle,
	# town, year), each must reach selectall_hashref unchanged.  A capturing
	# mock records the params hashref so we can inspect them.
	# Use mock 'new' directly (not intercept_new) because Genealogy::Wills::wills
	# inherits new() from Database::Abstraction; intercept_new may not shadow
	# an inherited method reliably under all Perl caching conditions.
	my @captured;
	my $mock = bless {}, 'Genealogy::Wills::wills';
	mock 'Genealogy::Wills::wills::new' => sub { $mock };
	mock 'Genealogy::Wills::wills::selectall_hashref' => sub {
		push @captured, $_[1];    # $_[0]=invocant, $_[1]=$params
		return [];
	};
	mock 'Genealogy::Wills::wills::fetchrow_hashref' => sub { undef };

	my $obj = Genealogy::Wills->new(directory => $temp_dir);

	# Call in explicit list context so search() takes the selectall_hashref
	# branch (wantarray is true).  A lives_ok wrapper would impose void context.
	my @results = $obj->search(
		last   => 'Smith',
		first  => 'John',
		middle => 'William',
		town   => 'Canterbury, Kent, England',
		year   => 1750,
	);

	ok(scalar(@captured) > 0, 'selectall_hashref was called');
	my $p = $captured[0];
	is($p->{'last'},   'Smith',                     'last forwarded verbatim');
	is($p->{'first'},  'John',                      'first forwarded verbatim');
	is($p->{'middle'}, 'William',                   'middle forwarded verbatim');
	is($p->{'town'},   'Canterbury, Kent, England', 'town forwarded verbatim');
	is($p->{'year'},   1750,                        'year forwarded verbatim');

	diag 'params: ' . join(', ', map { "$_=$p->{$_}" } sort keys %{$p})
		if $ENV{TEST_VERBOSE} && $p;

	restore_all();
};

# =======================================================================
# SECTION 6: URL decoration invariant
# Verifies that every result from every search path has the https:// scheme
# prepended exactly once by _decorate_will().
# =======================================================================

subtest 'url decoration: every list-context result has https:// scheme exactly once' => sub {
	_mock_wills_with_rows();
	my $obj     = Genealogy::Wills->new(directory => $temp_dir);
	my @results = $obj->search(last => 'Smith');

	my @missing_https  = grep { $_->{'url'} !~ m{\Ahttps://} } @results;
	my @doubled_scheme = grep { $_->{'url'} =~ m{https://https://} } @results;

	is(scalar(@missing_https),  0, 'no result is missing the https:// prefix');
	is(scalar(@doubled_scheme), 0, 'no result has a doubled https:// scheme');

	restore_all();
};

subtest 'url decoration: scalar-context result has https:// scheme exactly once' => sub {
	_mock_wills_with_rows();
	my $obj  = Genealogy::Wills->new(directory => $temp_dir);
	my $will = $obj->search(last => 'Smith');

	ok(defined $will,                              'scalar result is defined');
	like($will->{'url'},   qr{\Ahttps://},         'url starts with https://');
	unlike($will->{'url'}, qr{https://https://},   'url does not have doubled scheme');
	is($will->{'url'}, $FULL_URL,                  'url matches expected full URL');

	diag "scalar url: $will->{'url'}" if $ENV{TEST_VERBOSE};

	restore_all();
};

# =======================================================================
# SECTION 7: Error-path workflows
# Tests every fatal and non-fatal error path documented in the POD.
# =======================================================================

subtest 'error-path: bad directory -> new() returns undef (non-fatal)' => sub {
	# The POD documents new() as returning undef for a bad directory rather
	# than dying.  The caller is responsible for checking the return value
	# before calling search().  This subtest validates that contract.
	my $obj;
	{
		local $SIG{__WARN__} = sub { };    # suppress the carp to STDERR
		$obj = Genealogy::Wills->new(directory => '/no/such/directory');
	}
	ok(!defined($obj), 'new() returns undef for a non-existent directory');

	# Simulate the documented caller guard from the SYNOPSIS.
	my $search_attempted = 0;
	if(defined $obj) {
		$search_attempted = 1;
	}
	is($search_attempted, 0, 'caller guard prevents search() call on undef object');
};

subtest 'error-path: bad config_file -> new() croaks with path in message' => sub {
	# The POD says new() croaks (fatal) when config_file is given but missing.
	# The exception message must contain the offending path.
	throws_ok(
		sub { Genealogy::Wills->new(config_file => '/no/such/config.yml') },
		qr/Can't load configuration from.*config\.yml/,
		'new() croaks and includes the config_file path in the message'
	);
};

subtest 'error-path: bad logger object -> new() croaks immediately' => sub {
	# Logger validation runs BEFORE Object::Configure::configure(), so a bad
	# logger causes an early croak, not silent replacement.
	{
		package _IntT_BadLogger;
		sub new { bless {}, shift }
		# Deliberately missing both info() and error().
	}
	throws_ok(
		sub {
			Genealogy::Wills->new(
				directory => $temp_dir,
				logger    => _IntT_BadLogger->new()
			);
		},
		qr/Logger must be an object with info\(\) and error\(\)/,
		'new() croaks when logger is missing required methods'
	);
};

subtest 'error-path: Genealogy::Wills::wills->new() returns undef -> search() croaks' => sub {
	# When the DB object cannot be initialised (e.g., missing wills.sql),
	# search() must croak with the documented message.
	mock 'Genealogy::Wills::wills::new' => sub { undef };

	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	throws_ok(
		sub { $obj->search(last => 'Smith') },
		qr/Can't open the wills database/,
		'search() croaks with documented message when DB init fails'
	);

	restore_all();
};

subtest 'error-path: search() called as a class method -> immediate croak' => sub {
	# search() requires a blessed invocant. A class-method call must croak
	# before any argument parsing or DB access.
	throws_ok(
		sub { Genealogy::Wills->search(last => 'Smith') },
		qr/search\(\) must be called on an object/,
		'class-method search() croaks with documented message'
	);
};

subtest 'error-path: search() called with no arguments -> immediate croak' => sub {
	_mock_wills_with_rows();
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	throws_ok(
		sub { $obj->search() },
		qr/Usage: search/,
		'search() with no arguments croaks with a Usage message'
	);
	restore_all();
};

# =======================================================================
# SECTION 8: Optional dependencies
# Genealogy::Wills has no optional runtime dependencies.  All `use`
# statements in the module are hard requirements that cause a compile-time
# error if the module is absent.  There are therefore no graceful-degradation
# or fallback paths to exercise with Test::Without::Module.
# =======================================================================

subtest 'all required dependencies present (no optional-dep fallback paths exist)' => sub {
	# Confirm each hard dependency's key interface is reachable from the
	# already-loaded module.  If any dependency were missing the entire test
	# file would have failed to compile at line 1.
	ok(Genealogy::Wills->can('new'),    'Genealogy::Wills compiled with new()');
	ok(Genealogy::Wills->can('search'), 'Genealogy::Wills compiled with search()');
	ok(Data::Reuse->can('fixate'),      'Data::Reuse::fixate available');
	ok(Scalar::Util->can('blessed'),    'Scalar::Util::blessed available');
	note 'No optional runtime dependencies exist: Test::Without::Module N/A for this module';
};

done_testing();
