use strict;
use warnings;

use File::Temp qw(tempdir);
use Readonly;
use Scalar::Util qw(blessed);
use Test::Needs 'Test::Mockingbird';
use Test::Mockingbird;
use Test::Most;
use Test::Returns;

use_ok('Genealogy::Wills');

# -----------------------------------------------------------------------
# Constants extracted from the POD API SPECIFICATION to avoid magic values.
# -----------------------------------------------------------------------
Readonly my $MAX_YEAR  => (localtime)[5] + 1900;
Readonly my $ABOVE_MAX => $MAX_YEAR + 1;

# Mock rows returned by the DB layer. Each helper call produces fresh
# copies (via map+hash-slice) so _decorate_will's in-place url mutation
# does not carry over between subtests that reuse the same mock.
Readonly my $MOCK_URL  => 'freepages.rootsweb.com/~mrawson/genealogy/t.html';
Readonly my @MOCK_ROWS => (
	{ first => 'John', last => 'Smith', url => $MOCK_URL },
	{ first => 'Jane', last => 'Smith', url => $MOCK_URL },
);
Readonly my %MOCK_ROW => (first => 'John', last => 'Smith', url => $MOCK_URL);

# -----------------------------------------------------------------------
# API LEDGER
#
# Every documented message and return state from the POD MESSAGES and
# RETURNS sections.  Each key is deleted the moment the corresponding
# condition is triggered in a subtest.  The final assertion in this file
# fails explicitly if any entry survives -- indicating a gap in coverage.
# -----------------------------------------------------------------------
my %ledger = (
	# new() -- from =head3 MESSAGES (lines ~326-346)
	'new:croak:config_file'   => q(Can't load configuration from <path>),
	'new:croak:bad_logger'    => q(Logger must be an object with info() and error() methods),
	'new:carp:bad_directory'  => q(Genealogy::Wills: <dir> is not a directory),

	# new() -- from =head3 RETURNS
	'new:return:object'       => q(returns blessed Genealogy::Wills object on success),
	'new:return:undef'        => q(returns undef when directory is invalid),

	# search() -- from =head3 MESSAGES (lines ~567-593)
	'search:croak:not_object' => q(search() must be called on an object),
	'search:croak:no_args'    => q(Usage: search({ last => $last_name })),
	'search:carp:undef_last'  => q(Value for 'last' is mandatory),
	'search:croak:db_fail'    => q(Can't open the wills database),

	# search() -- from =head3 RETURNS / =head4 output (url always https://)
	'search:return:list_rows'      => q(list context: array of hashrefs, every url starts with https://),
	'search:return:list_empty'     => q(list context: empty list when no rows match),
	'search:return:scalar_hashref' => q(scalar context: hashref, url starts with https://),
	'search:return:scalar_undef'   => q(scalar context: undef when no rows match),

	# search() -- from API SPECIFICATION 'last' matches constraint
	'search:reject:last_invalid'   => q(PVS rejects non-word / non-hyphen chars in last),

	# search() -- from API SPECIFICATION 'year' min/max bounds
	'search:reject:year_below_min' => q(PVS rejects year < 1),
	'search:reject:year_above_max' => q(PVS rejects year > MAX_WILL_YEAR),
);

# -----------------------------------------------------------------------
# Mock helpers (black-box: no direct injection into $obj internals).
# intercept_new replaces Genealogy::Wills::wills->new so the real SQLite
# file is never accessed.  Always call restore_all() after each subtest.
# -----------------------------------------------------------------------

sub _mock_db_with_rows {
	my $mock = bless {}, 'Genealogy::Wills::wills';
	mock 'Genealogy::Wills::wills::selectall_hashref' => sub {
		return [ map { +{%$_} } @MOCK_ROWS ];
	};
	mock 'Genealogy::Wills::wills::fetchrow_hashref' => sub {
		return { %MOCK_ROW };
	};
	intercept_new 'Genealogy::Wills::wills' => $mock;
	return $mock;
}

sub _mock_db_empty {
	my $mock = bless {}, 'Genealogy::Wills::wills';
	mock 'Genealogy::Wills::wills::selectall_hashref' => sub { [] };
	mock 'Genealogy::Wills::wills::fetchrow_hashref'  => sub { undef };
	intercept_new 'Genealogy::Wills::wills' => $mock;
	return $mock;
}

my $temp_dir = tempdir(CLEANUP => 1);

# =======================================================================
# MODULE: Genealogy::Wills
# PUBLIC FUNCTION: new()
# =======================================================================

subtest 'new() -- returns a blessed object on success' => sub {
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	ok($obj,                          'new() returns a truthy value');
	isa_ok($obj, 'Genealogy::Wills',  'return value is a Genealogy::Wills object');
	delete $ledger{'new:return:object'};
};

subtest 'new() -- all three argument forms produce valid objects' => sub {
	# POD: "Genealogy::Wills->new(key => value, ...)" flat list
	my $flat = Genealogy::Wills->new(directory => $temp_dir);
	ok($flat && $flat->{'directory'} eq $temp_dir, 'flat key-value form');

	# POD: "Genealogy::Wills->new({ key => value, ... })" hashref
	my $href = Genealogy::Wills->new({ directory => $temp_dir });
	ok($href && $href->{'directory'} eq $temp_dir, 'hashref form');

	# POD: "Genealogy::Wills->new('/path/to/data')" single string = directory
	my $str = Genealogy::Wills->new($temp_dir);
	ok($str && $str->{'directory'} eq $temp_dir, 'single-string form');
};

subtest 'new() -- cache_duration defaults to "1 day" per POD' => sub {
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	# POD API SPECIFICATION: cache_duration default => '1 day'
	is($obj->{'cache_duration'}, '1 day',
		'default cache_duration matches POD-documented default');
};

subtest 'new() -- caller-supplied cache_duration is respected' => sub {
	my $obj = Genealogy::Wills->new(directory => $temp_dir, cache_duration => '12 hours');
	is($obj->{'cache_duration'}, '12 hours', 'custom cache_duration stored');
};

subtest 'new() -- invalid directory: returns undef (non-fatal)' => sub {
	# POD RETURNS: "On failure: undef, with a warning printed to STDERR"
	# Suppressing the warning here; the carp test below verifies its text.
	my $obj;
	{
		local $SIG{__WARN__} = sub { };
		$obj = Genealogy::Wills->new(directory => '/no/such/path');
	}
	ok(!defined($obj), 'new() returns undef for a non-existent directory');
	delete $ledger{'new:return:undef'};
};

subtest 'new() -- invalid directory: carps with path and "is not a directory"' => sub {
	# POD MESSAGES: "Genealogy::Wills: <dir> is not a directory" (Warning, not fatal)
	warning_like(
		sub { Genealogy::Wills->new(directory => '/no/such/path') },
		qr{no/such/path.*is not a directory}i,
		'carp includes the bad path and "is not a directory"'
	);
	delete $ledger{'new:carp:bad_directory'};
};

subtest 'new() -- non-existent config_file: croaks with path in message' => sub {
	# POD MESSAGES: "Can't load configuration from <path>" (Fatal)
	throws_ok(
		sub { Genealogy::Wills->new(config_file => '/does/not/exist.yml') },
		qr/Can't load configuration from/,
		'croak message starts with documented text'
	);
	throws_ok(
		sub { Genealogy::Wills->new(config_file => '/does/not/exist.yml') },
		qr{/does/not/exist\.yml},
		'croak message includes the offending file path'
	);
	delete $ledger{'new:croak:config_file'};
};

subtest 'new() -- bad logger: croaks with exact documented message' => sub {
	# POD MESSAGES: "Logger must be an object with info() and error() methods" (Fatal)
	# POD API SPECIFICATION: logger => { type => 'object', can => ['info', 'error'] }
	{
		package _UnitT_NoMethodLogger;
		sub new { bless {}, shift }
		# Deliberately has no info() or error() methods.
	}
	{
		package _UnitT_InfoOnlyLogger;
		sub new  { bless {}, shift }
		sub info { }
		# Deliberately missing error().
	}

	# Case A: logger is not blessed at all.
	throws_ok(
		sub { Genealogy::Wills->new(directory => $temp_dir, logger => 'plain_string') },
		qr/Logger must be an object with info\(\) and error\(\)/,
		'unblessed logger causes croak with documented message'
	);

	# Case B: logger is blessed but lacks both methods.
	throws_ok(
		sub { Genealogy::Wills->new(directory => $temp_dir, logger => _UnitT_NoMethodLogger->new()) },
		qr/Logger must be an object with info\(\) and error\(\)/,
		'logger missing both methods causes croak'
	);

	# Case C: logger has info() but not error() -- still rejected.
	throws_ok(
		sub { Genealogy::Wills->new(directory => $temp_dir, logger => _UnitT_InfoOnlyLogger->new()) },
		qr/Logger must be an object with info\(\) and error\(\)/,
		'logger missing error() causes croak'
	);

	delete $ledger{'new:croak:bad_logger'};
};

subtest 'new() -- valid logger with both methods is accepted' => sub {
	{
		package _UnitT_GoodLogger;
		sub new   { bless {}, shift }
		sub info  { }
		sub error { }
	}
	my $obj;
	lives_ok(
		sub { $obj = Genealogy::Wills->new(directory => $temp_dir, logger => _UnitT_GoodLogger->new()) },
		'logger with both info() and error() is accepted without croak'
	);
	ok($obj, 'valid logger: object still constructed successfully');
};

subtest 'new() -- cloning: instance->new() returns a distinct copy' => sub {
	my $orig  = Genealogy::Wills->new(directory => $temp_dir);
	my $clone = $orig->new(cache_duration => '2 days');

	isa_ok($clone, 'Genealogy::Wills');
	isnt($clone, $orig, 'clone is a different reference');
	is($clone->{'directory'}, $orig->{'directory'}, 'clone inherits directory from original');
	is($clone->{'cache_duration'}, '2 days', 'clone applies the supplied override');
};

# =======================================================================
# MODULE: Genealogy::Wills
# PUBLIC FUNCTION: search()
# =======================================================================

subtest 'search() -- croaks with exact message when called as class method' => sub {
	# POD MESSAGES: "search() must be called on an object"
	throws_ok(
		sub { Genealogy::Wills->search(last => 'Smith') },
		qr/search\(\) must be called on an object/,
		'class-method call: croak text matches documented message exactly'
	);
	delete $ledger{'search:croak:not_object'};
};

subtest 'search() -- croaks with Usage message when called with no arguments' => sub {
	# POD MESSAGES: "Usage: search({ last => $last_name })"
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	throws_ok(
		sub { $obj->search() },
		qr/Usage:\s+search/,
		'zero-argument call: croak text matches documented Usage pattern'
	);
	delete $ledger{'search:croak:no_args'};
};

subtest 'search() -- undef last: carps with exact message, returns empty list' => sub {
	# POD MESSAGES: "Value for 'last' is mandatory" (Warning, not Fatal)
	# The code path: PVS allows undef through; the length() guard fires the carp.
	# search() returns before reaching the DB, so no mock DB is needed.
	my $obj = Genealogy::Wills->new(directory => $temp_dir);

	my @results;
	warning_like(
		sub { @results = $obj->search(last => undef) },
		qr/Value for 'last' is mandatory/,
		'carp text matches documented message'
	);
	is(scalar @results, 0, 'list context returns empty list after the carp');
	delete $ledger{'search:carp:undef_last'};
};

subtest 'search() -- croaks when DB cannot be opened' => sub {
	# POD MESSAGES: "Can't open the wills database" (Fatal)
	# Force Genealogy::Wills::wills->new() to return undef.
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	mock 'Genealogy::Wills::wills::new' => sub { return undef };

	throws_ok(
		sub { $obj->search(last => 'Smith') },
		qr/Can't open the wills database/,
		'DB-init failure: croak text matches documented message exactly'
	);

	restore_all();
	delete $ledger{'search:croak:db_fail'};
};

subtest "search() -- 'last' validation: non-word and non-hyphen chars rejected" => sub {
	# POD ARGUMENTS: "Must be non-empty and contain only letters, digits,
	# underscores (\w set), and hyphens. Any other characters (including
	# apostrophes) cause the call to fail validation."
	my $obj = Genealogy::Wills->new(directory => $temp_dir);

	# Apostrophe: documented explicitly in the POD as rejected
	dies_ok(sub { $obj->search(last => "O'Brien") },
		q(apostrophe in 'last' causes validation failure));

	# Shell metacharacters
	dies_ok(sub { $obj->search(last => 'Smith;DROP TABLE') },
		q(semicolon in 'last' causes validation failure));

	# Angle bracket (XSS attempt)
	dies_ok(sub { $obj->search(last => '<script>') },
		q(angle-bracket in 'last' causes validation failure));

	# Hyphen IS allowed (explicitly documented as permitted)
	_mock_db_with_rows();
	lives_ok(sub { my @r = $obj->search(last => 'Hyde-White') },
		q(hyphen in 'last' is accepted per the documented constraint));
	restore_all();

	delete $ledger{'search:reject:last_invalid'};
};

subtest "search() -- 'year' validation: must be integer in [1, MAX_WILL_YEAR]" => sub {
	# POD ARGUMENTS: "Must be a positive whole number no greater than the
	# current calendar year."
	my $obj = Genealogy::Wills->new(directory => $temp_dir);

	# Below minimum (0 < 1)
	dies_ok(sub { $obj->search(last => 'Smith', year => 0) },
		'year=0 (below minimum of 1) causes validation failure');
	delete $ledger{'search:reject:year_below_min'};

	# Above maximum
	dies_ok(sub { $obj->search(last => 'Smith', year => $ABOVE_MAX) },
		'year above MAX_WILL_YEAR causes validation failure');
	delete $ledger{'search:reject:year_above_max'};

	# Boundary values must be accepted (needs mock DB)
	_mock_db_with_rows();
	lives_ok(sub { my @r = $obj->search(last => 'Smith', year => 1) },
		'year=1 (minimum boundary) is accepted');
	lives_ok(sub { my @r = $obj->search(last => 'Smith', year => $MAX_YEAR) },
		'year=MAX_WILL_YEAR (maximum boundary) is accepted');
	restore_all();

	diag "MAX_YEAR=$MAX_YEAR  ABOVE_MAX=$ABOVE_MAX" if $ENV{TEST_VERBOSE};
};

subtest 'search() -- list context: returns all matching rows with https:// urls' => sub {
	# POD RETURNS: "List context: a list of hash references (may be empty)"
	# POD OUTPUT schema: url matches => qr/^https:\/\//
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	_mock_db_with_rows();

	my @results = $obj->search(last => 'Smith');

	# Validate the shape of the return against the documented output schema.
	returns_is(\@results, { type => 'arrayref', min => 2, max => 2 },
		'list context returns the documented number of rows');

	# Every url field must begin with https:// per the API SPECIFICATION.
	for my $i (0 .. $#results) {
		like($results[$i]->{'url'}, qr{^https://},
			"result[$i] url starts with https:// as documented");
	}

	# Other documented fields are present.
	ok(exists $results[0]->{'first'}, 'first field present');
	ok(exists $results[0]->{'last'},  'last field present');

	restore_all();
	delete $ledger{'search:return:list_rows'};
};

subtest 'search() -- list context: empty list when no rows match' => sub {
	# POD RETURNS: "List context: a list of hash references (may be empty)"
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	_mock_db_empty();

	my @results = $obj->search(last => 'Nonexistent');
	returns_is(\@results, { type => 'arrayref', min => 0, max => 0 },
		'empty result set in list context');

	restore_all();
	delete $ledger{'search:return:list_empty'};
};

subtest 'search() -- scalar context: hashref with https:// url when match found' => sub {
	# POD RETURNS: "Scalar context: one hash reference, or undef if nothing matched"
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	_mock_db_with_rows();

	my $result = $obj->search(last => 'Smith');

	ok(defined $result, 'scalar context returns defined value when a row matches');
	is(ref($result), 'HASH', 'scalar context returns a hashref');
	like($result->{'url'}, qr{^https://}, 'scalar result url starts with https://');
	ok(exists $result->{'first'}, 'first field present in scalar result');

	restore_all();
	delete $ledger{'search:return:scalar_hashref'};
};

subtest 'search() -- scalar context: undef when no rows match' => sub {
	# POD RETURNS: "Scalar context: one hash reference, or undef if nothing matched"
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	_mock_db_empty();

	my $result = $obj->search(last => 'Nonexistent');
	ok(!defined $result, 'scalar context returns undef when nothing matches');

	restore_all();
	delete $ledger{'search:return:scalar_undef'};
};

subtest 'search() -- bare-string form: accepted per documented short form' => sub {
	# POD: "search('Smith') -- bare string = last name only"
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	_mock_db_with_rows();

	my @results;
	lives_ok(sub { @results = $obj->search('Smith') },
		'bare string form is accepted without dying');
	ok(scalar @results >= 1, 'bare string form returns results');

	restore_all();
};

subtest 'search() -- all five fields accepted simultaneously' => sub {
	# POD EXAMPLE: search(first=>, last=>, town=>) all accepted together.
	# Also tests first/middle with documented allowed chars (apostrophe, period, hyphen).
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	_mock_db_with_rows();

	lives_ok(
		sub {
			my @r = $obj->search(
				last   => 'Smith',
				first  => "O'Brien",          # apostrophe allowed in first
				middle => 'St. John',          # period allowed in middle
				town   => 'Ash, Kent, England', # comma allowed in town
				year   => 1750,
			);
		},
		'all five fields accepted simultaneously with allowed special chars'
	);

	restore_all();
};

# -----------------------------------------------------------------------
# Global state integrity tests
# The for-loop in search() uses $_ as the iteration variable.
# Perl's foreach/for always localizes $_, so the caller's $_ is preserved.
# -----------------------------------------------------------------------

subtest 'search() -- does not clobber $_ (default variable)' => sub {
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	_mock_db_with_rows();

	# Set $_ to a sentinel and verify it is unchanged after the search.
	local $_ = 'sentinel_underscore';
	my @r = $obj->search(last => 'Smith');
	is($_, 'sentinel_underscore',
		'$_ is unchanged after search() (for loop correctly localizes $_)');

	restore_all();
};

subtest 'search() -- does not clobber $@ (eval error variable)' => sub {
	# PVS may use eval internally; the module is responsible for localising
	# $@ around PVS calls if needed.  If this test fails, add local $@ to search().
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	_mock_db_with_rows();

	$@ = 'pre_existing_eval_error';
	my @r = $obj->search(last => 'Smith');
	is($@, 'pre_existing_eval_error',
		'$@ is not clobbered by a successful search() call');

	restore_all();
};

# =======================================================================
# MODULE: Genealogy::Wills::wills
# This module is a thin Database::Abstraction subclass with no own public
# API.  Tests validate the POD claims (NAME, VERSION, ISA).
# =======================================================================

subtest 'Genealogy::Wills::wills -- VERSION matches POD' => sub {
	is($Genealogy::Wills::wills::VERSION, $Genealogy::Wills::VERSION,
		'VERSION matches the parent module version');
};

subtest 'Genealogy::Wills::wills -- ISA Database::Abstraction' => sub {
	ok(Genealogy::Wills::wills->isa('Database::Abstraction'),
		'Genealogy::Wills::wills inherits from Database::Abstraction per POD');
};

# =======================================================================
# LEDGER ASSERTION
#
# Any surviving entries in %ledger mean a documented condition was never
# triggered during this test run -- a coverage gap.  Fail explicitly so
# the gap is visible in the test output rather than silently ignored.
# =======================================================================

if(%ledger) {
	my @untested = map { "  - $_: $ledger{$_}" } sort keys %ledger;
	fail(
		"UNTESTED DOCUMENTED CONDITIONS -- the following POD states were never triggered:\n"
		. join("\n", @untested)
	);
} else {
	pass('ledger empty: all documented messages and return states were exercised');
}

done_testing();
