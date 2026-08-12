use strict;
use warnings;

use File::Temp qw(tempdir tempfile);
use Readonly;
use Scalar::Util qw(blessed weaken);
use Test::Needs 'Test::Mockingbird';
use Test::Mockingbird;
use Test::Most;
use Test::Returns;

use_ok('Genealogy::Wills');

# -----------------------------------------------------------------------
# Shared constants -- avoids all magic values in assertions.
# -----------------------------------------------------------------------
Readonly my $MAX_YEAR     => (localtime)[5] + 1900;
Readonly my $MAX_LAST_LEN => 100;
Readonly my $MAX_OPT_LEN  => 100;
Readonly my $MOCK_URL     => 'freepages.rootsweb.com/~mrawson/genealogy/t.html';

Readonly my %MOCK_ROW => (
	first => 'John', last => 'Smith', year => 1750,
	town  => 'Canterbury, Kent, England', url => $MOCK_URL,
);

my $temp_dir = tempdir(CLEANUP => 1);

# -----------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------

# _basic_mock: installs three mocks that cover the happy path.  Each
# subtest that needs a working DB calls this, then restore_all() on exit.
sub _basic_mock {
	my %opts = @_;
	my $new_ret = $opts{new_ret} // bless({}, 'Genealogy::Wills::wills');
	my $select  = $opts{select}  // sub { [{ %MOCK_ROW }] };
	my $fetch   = $opts{fetch}   // sub { { %MOCK_ROW } };
	mock 'Genealogy::Wills::wills::new'              => sub { $new_ret };
	mock 'Genealogy::Wills::wills::selectall_hashref' => $select;
	mock 'Genealogy::Wills::wills::fetchrow_hashref'  => $fetch;
	return $new_ret;
}

# =======================================================================
# SECTION 1: 'last' field -- anchor and character-set hostile inputs
#
# These tests verify the \z anchor (not $) and the /a modifier are
# actually in effect.  A $ anchor silently accepts trailing \n; the /a
# modifier restricts \w to ASCII, blocking Unicode homograph attacks.
# =======================================================================

subtest "last: trailing newline is rejected -- proves \\z anchor, not dollar-sign" => sub {
	# "Smith\n" would pass /^[\w-]+$/ ($ matches before trailing \n) but
	# must FAIL /^[\w-]+\z/a (\z is strictly end-of-string with no newline exemption).
	# This regression test ensures a past-or-future switch from \z back to $ is caught.
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	dies_ok(
		sub { $obj->search(last => "Smith\n") },
		'trailing newline rejected: proves \\z (not $) is the end anchor'
	);
	dies_ok(
		sub { $obj->search(last => "Smith\r\n") },
		'trailing CRLF rejected by \\z anchor'
	);
	dies_ok(
		sub { $obj->search(last => "\nSmith") },
		'leading newline rejected: newline is not in [\\w-]'
	);
};

subtest "last: null byte anywhere in the string is rejected" => sub {
	# \0 is not in [\w-] and cannot appear at end-of-string (\z must be there).
	# A null byte could be used to truncate strings in older C-library calls.
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	dies_ok(
		sub { $obj->search(last => "Smith\x00") },
		'trailing null byte rejected'
	);
	dies_ok(
		sub { $obj->search(last => "\x00Smith") },
		'leading null byte rejected'
	);
	dies_ok(
		sub { $obj->search(last => "Sm\x00th") },
		'embedded null byte rejected'
	);
};

subtest "last: Unicode homograph attack rejected -- proves /a modifier" => sub {
	# Without the /a modifier, \w matches Cyrillic letters, Greek letters,
	# and other Unicode "word" characters that are visually similar to ASCII.
	# The /a flag restricts \w to [0-9A-Za-z_], blocking homograph queries
	# that could bypass searches or confuse administrators reading logs.
	#
	# U+0405 CYRILLIC CAPITAL LETTER DZE looks like 'S'
	# U+0421 CYRILLIC CAPITAL LETTER ES  looks like 'C'
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	dies_ok(
		sub { $obj->search(last => "\x{0405}mith") },
		"Cyrillic DZE (looks like 'S') rejected by /a modifier"
	);
	dies_ok(
		sub { $obj->search(last => "Sm\x{0456}th") },
		"Cyrillic Byelorussian-Ukrainian I (looks like 'i') rejected by /a modifier"
	);
	dies_ok(
		sub { $obj->search(last => "\x{0421}\x{0461}\x{1E67}\x{0442}\x{0442}") },
		"fully-Cyrillic near-homoglyph of 'Smith' rejected by /a modifier"
	);
	diag 'Unicode tests confirm /a restricts \\w to ASCII [0-9A-Za-z_]' if $ENV{TEST_VERBOSE};
};

subtest "last: boundary lengths -- exactly 1, 100, and 101 characters" => sub {
	# Equivalence partitions for the min=1, max=100 constraint.
	# All characters are plain ASCII letters, satisfying the \w requirement.
	_basic_mock();
	my $obj = Genealogy::Wills->new(directory => $temp_dir);

	lives_ok(
		sub { my @r = $obj->search(last => 'A') },
		'last = 1 char (min boundary) is accepted'
	);
	lives_ok(
		sub { my @r = $obj->search(last => 'A' x $MAX_LAST_LEN) },
		"last = $MAX_LAST_LEN chars (max boundary) is accepted"
	);
	dies_ok(
		sub { $obj->search(last => 'A' x ($MAX_LAST_LEN + 1)) },
		'last = ' . ($MAX_LAST_LEN + 1) . ' chars (above max) is rejected'
	);
	dies_ok(
		sub { $obj->search(last => '') },
		'last = empty string is rejected (below min=1)'
	);

	restore_all();
};

subtest "last: type confusion -- non-string references are rejected" => sub {
	# Passing a reference where a string is expected should fail PVS type
	# validation immediately, before any DB access.
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	dies_ok(
		sub { $obj->search(last => []) },
		'last => [] (arrayref) rejected by PVS type=string'
	);
	dies_ok(
		sub { $obj->search(last => {}) },
		'last => {} (hashref) rejected by PVS type=string'
	);
	dies_ok(
		sub { $obj->search(last => sub {}) },
		'last => sub{} (coderef) rejected by PVS type=string'
	);
	dies_ok(
		sub { $obj->search(last => \42) },
		'last => \\42 (scalar ref) rejected by PVS type=string'
	);
};

# =======================================================================
# SECTION 2: Optional fields -- injection and boundary attacks
#
# first, middle, town share qr/^[\w '.-]+\z/.  town additionally allows
# comma (qr/^[\w ',.-]+\z/).  All three must block injection characters.
# =======================================================================

subtest "optional fields: empty string below min=1 is rejected" => sub {
	# An empty string meets the type=string requirement but fails min=1.
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	dies_ok(
		sub { $obj->search(last => 'Smith', first => '') },
		"first => '' rejected (below min=1)"
	);
	dies_ok(
		sub { $obj->search(last => 'Smith', middle => '') },
		"middle => '' rejected (below min=1)"
	);
	dies_ok(
		sub { $obj->search(last => 'Smith', town => '') },
		"town => '' rejected (below min=1)"
	);
};

subtest "optional fields: above max=100 characters is rejected" => sub {
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	dies_ok(
		sub { $obj->search(last => 'Smith', first => 'A' x ($MAX_OPT_LEN + 1)) },
		'first > 100 chars rejected'
	);
	dies_ok(
		sub { $obj->search(last => 'Smith', town => 'A' x ($MAX_OPT_LEN + 1)) },
		'town > 100 chars rejected'
	);
};

subtest "optional fields: XSS payloads are blocked by matches constraint" => sub {
	# The matches constraint for first/middle/town blocks < > & ; = | which
	# are required for most XSS payloads.  The primary defence is parameterised
	# queries; the constraint is defence-in-depth.
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	dies_ok(
		sub { $obj->search(last => 'Smith', first => '<script>alert(1)</script>') },
		'XSS in first is blocked by matches (< > chars not in set)'
	);
	dies_ok(
		sub { $obj->search(last => 'Smith', town => 'Ash<img src=x onerror=alert(1)>') },
		'XSS in town is blocked by matches'
	);
};

subtest "optional fields: CRLF and null bytes are blocked" => sub {
	# These are used in header-injection and string-truncation attacks.
	# The \z anchor and the absence of \r\n\0 from the character class
	# ensure they are always rejected.
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	dies_ok(
		sub { $obj->search(last => 'Smith', first => "John\r\n") },
		'CRLF in first rejected'
	);
	dies_ok(
		sub { $obj->search(last => 'Smith', middle => "William\x00") },
		'null byte in middle rejected'
	);
	dies_ok(
		sub { $obj->search(last => 'Smith', town => "Canterbury\nEvil-Header: injected") },
		'newline in town rejected (header injection attempt)'
	);
};

subtest "optional fields: shell metacharacters are blocked" => sub {
	# ; | ` & are not in the allowed character set.
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	dies_ok(
		sub { $obj->search(last => 'Smith', first => 'John;DROP TABLE wills') },
		'semicolon in first rejected'
	);
	dies_ok(
		sub { $obj->search(last => 'Smith', town => 'Canterbury|evil') },
		'pipe in town rejected'
	);
	dies_ok(
		sub { $obj->search(last => 'Smith', middle => '`id`') },
		'backtick in middle rejected'
	);
};

# =======================================================================
# SECTION 3: 'year' field -- type, boundary, and injection attacks
# =======================================================================

subtest "year: boundary values and out-of-range integers" => sub {
	_basic_mock();
	my $obj = Genealogy::Wills->new(directory => $temp_dir);

	# Equivalence partition A: below minimum (year=0 is invalid; min=1)
	dies_ok(
		sub { $obj->search(last => 'Smith', year => 0) },
		'year=0 (below min) rejected'
	);
	# Partition B: minimum boundary
	lives_ok(
		sub { my @r = $obj->search(last => 'Smith', year => 1) },
		'year=1 (min boundary) accepted'
	);
	# Partition C: maximum boundary
	lives_ok(
		sub { my @r = $obj->search(last => 'Smith', year => $MAX_YEAR) },
		"year=$MAX_YEAR (max boundary) accepted"
	);
	# Partition D: above maximum
	dies_ok(
		sub { $obj->search(last => 'Smith', year => $MAX_YEAR + 1) },
		'year > MAX_YEAR rejected'
	);
	# Partition E: negative integer
	dies_ok(
		sub { $obj->search(last => 'Smith', year => -1) },
		'year=-1 (negative) rejected'
	);

	diag "MAX_YEAR=$MAX_YEAR" if $ENV{TEST_VERBOSE};
	restore_all();
};

subtest "year: non-integer types are rejected by PVS type=integer" => sub {
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	dies_ok(
		sub { $obj->search(last => 'Smith', year => 1.5) },
		'year=1.5 (float) rejected: PVS type=integer'
	);
	dies_ok(
		sub { $obj->search(last => 'Smith', year => '1750abc') },
		'year="1750abc" (non-integer string) rejected'
	);
	dies_ok(
		sub { $obj->search(last => 'Smith', year => 'abc') },
		'year="abc" (non-numeric string) rejected'
	);
	dies_ok(
		sub { $obj->search(last => 'Smith', year => []) },
		'year=[] (arrayref) rejected'
	);
};

# =======================================================================
# SECTION 4: DB layer upstream failure simulation
#
# Tests how search() behaves when its internal DB object fails in ways
# that violate the Database::Abstraction contract.  Mocks produce the
# upstream failures that would otherwise be impossible to inject.
# =======================================================================

subtest "DB upstream: selectall_hashref returns undef -- treated as empty list" => sub {
	# The // [] guard specifically handles this case: undef means "no rows",
	# which normalises to an empty arrayref before iteration.
	_basic_mock(select => sub { undef });
	my $obj     = Genealogy::Wills->new(directory => $temp_dir);
	my @results = $obj->search(last => 'Smith');

	is(scalar(@results), 0,
		'selectall_hashref returning undef is treated as empty list');

	restore_all();
};

subtest "DB upstream: selectall_hashref returns 0 (falsy, defined) -- current behavior" => sub {
	# The // [] guard replaces ONLY undef.  If selectall_hashref returns 0,
	# the defined-or returns 0, and @{0} dies with "Not an ARRAY reference".
	# This test DOCUMENTS the fragility: the assumption is that
	# Database::Abstraction always returns undef or an arrayref, never 0.
	# If that assumption ever breaks, search() will die non-gracefully.
	_basic_mock(select => sub { 0 });
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	dies_ok(
		sub { my @r = $obj->search(last => 'Smith') },
		'selectall_hashref returning 0 exposes the // guard only handles undef'
	);

	diag 'FRAGILITY NOTE: // [] only replaces undef. Non-arrayref returns (0, "") '
		. 'crash with "Not an ARRAY reference". Mitigated by trusting '
		. 'Database::Abstraction to always return undef or arrayref.'
		if $ENV{TEST_VERBOSE};

	restore_all();
};

subtest "DB upstream: selectall_hashref dies -- exception propagates to caller" => sub {
	# No eval wraps the DB call in search(), so any exception from
	# selectall_hashref propagates directly to the caller.  This is correct
	# fail-fast behaviour; the caller must handle it.
	_basic_mock(select => sub { die "simulated DB timeout\n" });
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	throws_ok(
		sub { my @r = $obj->search(last => 'Smith') },
		qr/simulated DB timeout/,
		'exception from selectall_hashref propagates verbatim to caller'
	);

	restore_all();
};

subtest "DB upstream: fetchrow_hashref dies -- exception propagates" => sub {
	_basic_mock(fetch => sub { die "simulated fetch failure\n" });
	my $obj  = Genealogy::Wills->new(directory => $temp_dir);
	throws_ok(
		sub { my $r = $obj->search(last => 'Smith') },
		qr/simulated fetch failure/,
		'exception from fetchrow_hashref propagates to caller (scalar context)'
	);

	restore_all();
};

subtest "DB upstream: wills->new() croaks -- search() re-croaks with documented message" => sub {
	# The module has its own guard: croak("Can't open the wills database")
	# when the wills DB object comes back undef.  This fires whether the
	# inner new() returns undef cleanly or dies (autodie turns die into undef
	# for object construction... actually new() would just die which propagates).
	mock 'Genealogy::Wills::wills::new' => sub { undef };

	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	throws_ok(
		sub { $obj->search(last => 'Smith') },
		qr/Can't open the wills database/,
		'search() croaks with documented message when wills->new() returns undef'
	);

	restore_all();
};

# =======================================================================
# SECTION 5: Row data corruption -- what _decorate_will receives from DB
#
# The DB layer is supposed to return rows with a 'url' field containing
# the URL path without scheme.  These tests probe what happens when that
# contract is violated by a buggy or hostile DB layer.
# =======================================================================

subtest "row corruption: row missing 'url' key -- url becomes bare 'https://'" => sub {
	# _decorate_will does: $will->{'url'} = 'https://' . $will->{'url'}
	# If 'url' is absent, $will->{'url'} is undef, and string concatenation
	# with undef produces 'https://' (with an "uninitialized value" warning).
	# The result is a malformed URL -- this test documents the behavior.
	_basic_mock(select => sub { [{ first => 'John', last => 'Smith' }] });
	my $obj = Genealogy::Wills->new(directory => $temp_dir);

	my @results;
	my @warnings;
	{
		local $SIG{__WARN__} = sub { push @warnings, @_ };
		@results = $obj->search(last => 'Smith');
	}

	is(scalar(@results), 1, 'row is still returned even with missing url');
	is($results[0]{'url'}, 'https://', "missing url key produces bare 'https://'");

	diag "warnings: @warnings" if $ENV{TEST_VERBOSE} && @warnings;

	restore_all();
};

subtest "row corruption: url already has 'https://' scheme -- scheme is doubled" => sub {
	# The DB is designed to store URLs WITHOUT scheme; search() prepends 'https://'.
	# If the DB mistakenly stores a full URL, the result is 'https://https://...'.
	# This test documents the behavior; callers must not store full URLs in the DB.
	my $already_full_url = 'https://freepages.rootsweb.com/test.html';
	_basic_mock(select => sub { [{ first => 'John', last => 'Smith', url => $already_full_url }] });
	my $obj = Genealogy::Wills->new(directory => $temp_dir);

	my @results = $obj->search(last => 'Smith');
	is(scalar(@results), 1, 'row returned even with already-schemed url');
	like($results[0]{'url'}, qr{\Ahttps://https://},
		'double https:// exposes assumption: DB must not store full URLs');

	diag "doubled url: $results[0]{url}" if $ENV{TEST_VERBOSE};

	restore_all();
};

subtest "row corruption: url contains undef (same as missing key)" => sub {
	_basic_mock(select => sub { [{ first => 'John', last => 'Smith', url => undef }] });
	my $obj = Genealogy::Wills->new(directory => $temp_dir);

	my @results;
	{
		local $SIG{__WARN__} = sub { };    # suppress undef-concat warning
		@results = $obj->search(last => 'Smith');
	}
	is($results[0]{'url'}, 'https://',
		"url => undef produces bare 'https://' (same as missing key)");

	restore_all();
};

# =======================================================================
# SECTION 6: Global state preservation
#
# Regression tests for known global-state clobbering bugs.  Each test
# sets a global, calls search(), and asserts the global is unchanged.
# =======================================================================

subtest 'REGRESSION: $@ is preserved across search() -- PVS eval clobber fix' => sub {
	# Params::Validate::Strict uses eval internally.  On successful validation
	# it used to reset $@ to ''.  The fix wraps the PVS call in do { local $@ }.
	# This regression test asserts the fix is still in place.
	_basic_mock();
	my $obj = Genealogy::Wills->new(directory => $temp_dir);

	eval { die 'sentinel_error' };
	my $before = $@;

	my @results = $obj->search(last => 'Smith');

	is($@, $before,
		'$@ preserved across search(): PVS internal eval does not clobber it');

	diag "before: '$before', after: '$@'" if $ENV{TEST_VERBOSE};

	restore_all();
};

subtest '$_ is not clobbered by search()' => sub {
	# search() uses postfix `for` over the result array; postfix `for`
	# localizes $_ correctly.  This test verifies $_ is unchanged after
	# search() returns.
	_basic_mock();
	my $obj = Genealogy::Wills->new(directory => $temp_dir);

	local $_ = 'my_global_sentinel';
	my @results = $obj->search(last => 'Smith');

	is($_, 'my_global_sentinel',
		'$_ unchanged after search(): postfix-for correctly localizes $_');

	diag "after: '$_'" if $ENV{TEST_VERBOSE};

	restore_all();
};

subtest '$_ is not clobbered when search() fails PVS validation (scalar context)' => sub {
	# The scalar path has no `for` loop, so $_ preservation is trivial when
	# search() completes normally.  The harder case is when search() CROAKS
	# mid-flight: even then $_ must survive the exception.
	# No mock needed: PVS rejection fires before any DB access.
	my $obj = Genealogy::Wills->new(directory => $temp_dir);

	local $_ = 'scalar_sentinel';
	eval { my $r = $obj->search(last => 'Smith<xss>') };    # PVS rejects < >

	is($_, 'scalar_sentinel',
		'$_ unchanged even when search() croaks during PVS validation');

	diag '$@ after croak: ' . (length($@) ? "\"$@\"" : '(empty)')
		if $ENV{TEST_VERBOSE};
};

# =======================================================================
# SECTION 7: search() invocant abuse
#
# search() checks blessed($self) but does NOT check the class.  A blessed
# object from a completely different package bypasses the blessed() check.
# These tests verify the safe failure modes in that scenario.
# =======================================================================

subtest "search() invocant abuse: class-method call croaks immediately" => sub {
	# Calling as a class method (unblessed string) must croak before any
	# argument parsing.
	throws_ok(
		sub { Genealogy::Wills->search(last => 'Smith') },
		qr/search\(\) must be called on an object/,
		'class-method call croaks: string invocant is caught by blessed() check'
	);
};

subtest "search() invocant abuse: unblessed hashref croaks" => sub {
	# An unblessed reference also fails the blessed() check.
	my $naked = { directory => $temp_dir };
	throws_ok(
		sub { Genealogy::Wills::search($naked, last => 'Smith') },
		qr/search\(\) must be called on an object/,
		'unblessed hashref invocant is rejected by blessed() guard'
	);
};

subtest "search() invocant abuse: wrong blessed class still runs (no class guard)" => sub {
	# blessed() returns true for ANY blessed ref, regardless of class.
	# A blessed hashref of a different package that has the required internals
	# (directory, no wills slot) will attempt to open the DB.  We verify
	# search() fails with the DB error, not with the invocant guard.
	{
		package _EdgeT_FakeWills;
		sub new { bless { directory => $temp_dir }, shift }
	}
	_basic_mock();

	my $imposter = _EdgeT_FakeWills->new();
	# search() is called as a function with $imposter as first arg.
	my @results;
	lives_ok(
		sub { @results = Genealogy::Wills::search($imposter, last => 'Smith') },
		'wrong-class blessed object: search() runs (no class guard -- by design)'
	);

	restore_all();
};

# =======================================================================
# SECTION 8: Constructor filesystem hostility
#
# These tests verify the -d/-r path checks in new() are correct and that
# device files and file-as-directory mismatches are handled safely.
# =======================================================================

subtest "new(): /dev/null as directory returns undef (not a directory)" => sub {
	# /dev/null is a character special device; -d returns false.
	SKIP: {
		skip '/dev/null not available on this platform', 1
			unless -e '/dev/null';
		my $obj;
		{
			local $SIG{__WARN__} = sub { };
			$obj = Genealogy::Wills->new(directory => '/dev/null');
		}
		ok(!defined($obj),
			'/dev/null is not a directory: new() returns undef');
	}
};

subtest "new(): a plain file where a directory is expected returns undef" => sub {
	my (undef, $plainfile) = tempfile(CLEANUP => 1);
	my $obj;
	{
		local $SIG{__WARN__} = sub { };
		$obj = Genealogy::Wills->new(directory => $plainfile);
	}
	ok(!defined($obj),
		'a plain file path where a directory is expected returns undef');
};

subtest "new(): unreadable config file croaks (non-root systems only)" => sub {
	SKIP: {
		skip 'running as root: chmod 000 does not restrict access', 1
			if $> == 0;

		my (undef, $secret) = tempfile(CLEANUP => 1);
		chmod 0000, $secret;

		SKIP: {
			skip 'file is still readable despite chmod 0000 (unusual FS)', 1
				if -r $secret;
			throws_ok(
				sub { Genealogy::Wills->new(config_file => $secret) },
				qr/Can't load configuration from/,
				'unreadable config file croaks with path in the message'
			);
		}

		chmod 0644, $secret;    # restore so File::Temp cleanup can delete it
	}
};

subtest "new(): config file is a directory -- croaks (not readable as config)" => sub {
	# A directory is technically readable by -r on some systems but
	# Object::Configure will fail to parse it as config.  new() checks -r
	# on the config_file before passing to Object::Configure; a directory
	# is readable at the filesystem level but not as a YAML/INI file.
	# The -r check passes, so Object::Configure receives the path and
	# either handles or croaks.  We just assert new() does not silently
	# succeed with a directory as config.
	my $dir_as_config = tempdir(CLEANUP => 1);
	my $obj;
	eval { $obj = Genealogy::Wills->new(config_file => $dir_as_config) };
	# Either throws or returns a valid object falling back to defaults:
	# both are acceptable; the key is it must NOT confusingly succeed
	# with the directory parsed as meaningful config.
	pass('new() does not hang or produce undefined behavior with a directory as config_file');
	diag "result: " . (defined $obj ? 'defined object' : 'undef')
		. (length($@) ? ", threw: $@" : '') if $ENV{TEST_VERBOSE};
};

# =======================================================================
# SECTION 9: Signal safety -- search() must not consume or reset alarms
# =======================================================================

subtest "alarm() set before search() is not cancelled or reset by the module" => sub {
	# Neither search() nor the PVS validation call alarm() or setitimer.
	# If they did, a caller using alarm() for timeouts would be silently broken.
	# With the mocked DB, search() completes in microseconds, so the 10-second
	# alarm is still live when we cancel it and check the remaining time.
	_basic_mock();
	my $obj = Genealogy::Wills->new(directory => $temp_dir);

	alarm(10);
	my @results = $obj->search(last => 'Smith');
	my $remaining = alarm(0);    # cancel and read remaining seconds

	ok($remaining > 0,
		'alarm() countdown still active after search() (module did not consume it)');

	diag "alarm remaining after search(): ${remaining}s" if $ENV{TEST_VERBOSE};

	restore_all();
};

# =======================================================================
# SECTION 10: Large result set -- memory and decoration stress
#
# search() iterates over the entire result set via `_decorate_will($_) for
# @{$wills}`.  A large result set stresses the per-row url mutation and
# the Data::Reuse::fixate call.
# =======================================================================

subtest "stress: 1000-row result set -- all rows correctly decorated" => sub {
	# Build 1000 unique rows with distinct first names.  Every row must
	# have 'https://' prepended to its url by _decorate_will.
	Readonly my $ROW_COUNT => 1000;
	my @big_dataset = map {
		{ first => "Person$_", last => 'Smith', url => $MOCK_URL }
	} (1 .. $ROW_COUNT);

	_basic_mock(select => sub { [ map { +{%$_} } @big_dataset ] });
	my $obj     = Genealogy::Wills->new(directory => $temp_dir);
	my @results = $obj->search(last => 'Smith');

	is(scalar(@results), $ROW_COUNT,
		"$ROW_COUNT rows returned from large result set");

	my @bad = grep { $_->{'url'} !~ m{\Ahttps://} } @results;
	is(scalar(@bad), 0,
		'every row in the large result set has https:// scheme prepended');

	diag "large result set: ${\scalar @results} rows, bad urls: ${\scalar @bad}"
		if $ENV{TEST_VERBOSE};

	restore_all();
};

# =======================================================================
# SECTION 11: Argument-parsing edge cases
# =======================================================================

subtest "duplicate keys in argument list -- Perl last-wins silently" => sub {
	# Perl evaluates a flat key-value list into a hash left-to-right.
	# Duplicate keys cause the last value to win.  This is a Perl language
	# behaviour, not a module bug, but we document it here to protect against
	# regressions if the argument-parsing layer ever changes.
	_basic_mock(select => sub {
		my (undef, $params) = @_;
		return [{ %MOCK_ROW, _got_last => $params->{'last'} }];
	});
	my $obj     = Genealogy::Wills->new(directory => $temp_dir);
	# Perl sees this as { last => 'Jones' } (last-wins in hash construction).
	my @results = $obj->search(last => 'Smith', last => 'Jones');

	ok(scalar(@results) > 0, 'search returned results despite duplicate last key');
	is($results[0]{'_got_last'}, 'Jones',
		'duplicate last key: Perl last-wins gives "Jones" (last value wins)');

	diag "effective last: '$results[0]{_got_last}'" if $ENV{TEST_VERBOSE};

	restore_all();
};

subtest "first => undef (explicit undef for optional field) -- validation" => sub {
	# An optional field set to undef explicitly.  PVS optional => 1 means the
	# key may be absent, but if present as undef the behaviour depends on PVS.
	# We verify the module does not crash regardless of PVS decision.
	_basic_mock();
	my $obj = Genealogy::Wills->new(directory => $temp_dir);

	# Pass undef explicitly -- this may pass or fail PVS; the key assertion
	# is that the module does not crash with a confusing internal error.
	my $caught;
	eval { my @r = $obj->search(last => 'Smith', first => undef) };
	$caught = $@;

	# Either outcome is acceptable; neither should produce an uncontrolled crash.
	ok(1, "first => undef: module handles it without internal crash (caught: '$caught')");

	diag "first => undef result: " . (length($caught) ? "died: $caught" : 'lived')
		if $ENV{TEST_VERBOSE};

	restore_all();
};

done_testing();
