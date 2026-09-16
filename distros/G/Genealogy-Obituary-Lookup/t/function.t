#!/usr/bin/env perl

# White-box function tests for all .pm files under lib/.
#
# Strategy: the real Genealogy::Obituary::Lookup::obituaries driver requires a
# built SQLite database.  We shadow its interface methods in a BEGIN block so
# the real file's @ISA assignment loads cleanly without triggering Database::
# Abstraction's constructor or any filesystem look-up.  Package variables
# $_mock_rows / $_mock_scalar let individual subtests control what the
# "database" returns without re-mocking the whole driver.

use strict;
use warnings;

use File::Temp	qw(tempdir);
use Readonly;
use Scalar::Util	qw(blessed refaddr);
use Test::Memory::Cycle;
use Test::Mockingbird;
use Test::Most;
use Test::Returns;

use lib 'lib';
use lib 't/lib';
use MyLogger;

# ---------------------------------------------------------------------------
# Constants — no magic strings scattered through the test body
# ---------------------------------------------------------------------------
Readonly::Scalar my $PKG    => 'Genealogy::Obituary::Lookup';
Readonly::Scalar my $DRV    => 'Genealogy::Obituary::Lookup::obituaries';

Readonly::Scalar my $WAYBACK_RE  => qr{wayback\.archive-it\.org};
Readonly::Scalar my $FREELISTS_RE => qr{freelists\.org};

Readonly::Scalar my $FUNERAL_URL =>
	'https://funeral-notices.co.uk/notice/test/9999999';

# Wayback page number used by mock rows; must appear at the end of the URL.
Readonly::Scalar my $MOCK_PAGE_M  => 42;
Readonly::Scalar my $MOCK_PAGE_F  => 'v26no080';

# ---------------------------------------------------------------------------
# Mock obituaries driver.
#
# Placed in a BEGIN block so the symbols exist before 'use Genealogy::Obituary
# ::Lookup' triggers 'use Genealogy::Obituary::Lookup::obituaries' at compile
# time.  The real obituaries.pm only sets @ISA — it never redefines these subs
# — so our stubs survive the require().
# ---------------------------------------------------------------------------
BEGIN {
	package Genealogy::Obituary::Lookup::obituaries;

	# Test subtests write to these vars to control mock return values.
	our $_mock_rows   = [];
	our $_mock_scalar = undef;

	sub new                { bless {}, shift }
	sub selectall_hashref  { return $_mock_rows }
	sub fetchrow_hashref   { return $_mock_scalar }
}

BEGIN { use_ok('Genealogy::Obituary::Lookup') }

# ---------------------------------------------------------------------------
# Helper: build a fresh Lookup object backed by a temporary directory.
# Using a tempdir avoids relying on the presence of a built database.
# ---------------------------------------------------------------------------
sub _new_obj {
	my %extra = @_;
	my $dir = tempdir(CLEANUP => 1);
	return $PKG->new(directory => $dir, %extra);
}

# ---------------------------------------------------------------------------
# Subtest: _i18n — message template look-up and placeholder substitution
#
# _i18n has no caller-privacy guard (unlike _create_url), so we call it as a
# class method directly to exercise it in isolation.
# ---------------------------------------------------------------------------
subtest '_i18n — known key returns a non-empty string' => sub {
	my $msg = $PKG->_i18n('err_no_last');
	ok(length($msg) > 0,     '_i18n returns a non-empty string for a known key');
	unlike($msg, qr/%\{/,    'no unresolved %{...} placeholders remain');
};

subtest '_i18n — placeholder interpolation' => sub {
	my $msg = $PKG->_i18n('err_no_args', {package => 'My::Pkg'});
	like($msg,   qr/My::Pkg/, '%{package} placeholder is substituted');
	unlike($msg, qr/%\{/,     'no raw placeholders remain after substitution');
};

subtest '_i18n — missing placeholder arg degrades to empty string' => sub {
	# Template is '%{class}: %{dir} is not a directory'.
	# Supplying only 'class' leaves 'dir' blank rather than crashing.
	my $msg = $PKG->_i18n('warn_not_dir', {class => 'Foo'});
	like($msg,   qr/Foo/,       'supplied placeholder class is filled');
	unlike($msg, qr/%\{dir\}/,  'missing placeholder is replaced with empty string');
};

subtest '_i18n — unknown key croaks with descriptive message' => sub {
	throws_ok { $PKG->_i18n('no_such_key_xyzzy') }
		qr/Unknown i18n key/,
		'_i18n croaks when the key is not in %MESSAGES';
};

# ---------------------------------------------------------------------------
# Subtest group: new() — constructor behaviour
# ---------------------------------------------------------------------------
subtest 'new() — explicit valid directory produces a blessed object' => sub {
	my $obj = _new_obj();
	ok(defined $obj,     'new() returns a defined value for a valid directory');
	isa_ok($obj, $PKG);
	ok(defined $obj->{directory}, 'directory is stored on the object');

	# cache_duration must default to '1 day' (from the Readonly constant)
	is($obj->{cache_duration}, '1 day',
		'cache_duration is initialised to the module default');

	diag("new() directory: $obj->{directory}") if $ENV{TEST_VERBOSE};
};

subtest 'new() — non-existent directory carps and returns undef' => sub {
	# new() must not die — bad directories are a runtime misconfiguration,
	# not a programmer error.  Return undef so callers can handle it gracefully.
	# Carp::carp emits two warnings (call site + caller frame), so use
	# warnings_exist (any-match) rather than warning_like (exact-one-match).
	my $bad;
	warnings_exist { $bad = $PKG->new(directory => '/no/such/path/$$') }
		[qr/is not a directory/],
		'new() emits a carp-level warning for a bad directory';
	ok(!defined $bad, 'new() returns undef for a non-existent directory');
};

subtest 'new() — valid logger object is accepted' => sub {
	my $lg  = MyLogger->new();
	my $obj = _new_obj(logger => $lg);
	ok(defined $obj,           'object is constructed with a valid logger');
	# Object::Configure may wrap the logger in Log::Abstraction; check the
	# interface rather than the exact class.
	ok(defined $obj->{logger}, 'logger is stored on the object');
	ok($obj->{logger}->can('info') && $obj->{logger}->can('warn') && $obj->{logger}->can('error'),
		'stored logger responds to info(), warn() and error()');
};

subtest 'new() — unblessed logger value croaks (err_bad_logger)' => sub {
	# Logger validation now runs BEFORE Object::Configure can wrap the value,
	# so an unblessed ref is correctly rejected as a programmer error.
	throws_ok { _new_obj(logger => {}) }
		qr/Logger must/,
		'new() croaks with err_bad_logger when an unblessed ref is passed as logger';
};

subtest 'new() — single scalar arg is treated as the directory' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $obj = $PKG->new($dir);
	ok(defined $obj,         'single-arg new() accepts the directory');
	is($obj->{directory}, $dir, 'directory is correctly recorded');
};

subtest 'new() — clone merges new args over existing state' => sub {
	my $orig  = _new_obj();
	my $clone = $orig->new();
	ok(defined $clone,   'clone() returns a defined object');
	isa_ok($clone, $PKG, 'clone is an instance of the same class');
	isnt(refaddr($orig), refaddr($clone),
		'clone is a distinct reference (not the same object)');
	is($clone->{directory}, $orig->{directory},
		'clone inherits directory from the original');
};

subtest 'new() — clone can override inherited fields' => sub {
	my $dir2  = tempdir(CLEANUP => 1);
	my $orig  = _new_obj();
	my $clone = $orig->new(directory => $dir2);
	is($clone->{directory}, $dir2,
		'explicit arg on clone overrides the original field');
};

subtest 'new() — function-style ::new() with no args is tolerated' => sub {
	# Legacy callers occasionally invoke ::new() without an invocant.
	# The module must not die; it should self-correct to the package name.
	my $obj;
	lives_ok { $obj = Genealogy::Obituary::Lookup::new() }
		'function-style ::new() with no args does not croak';
	# $obj may be undef if no auto-discovered data dir exists; that is fine.
};

# ---------------------------------------------------------------------------
# Subtest group: search() — input validation
# ---------------------------------------------------------------------------
subtest 'search() — unblessed invocant croaks with err_no_self' => sub {
	throws_ok {
		Genealogy::Obituary::Lookup::search('not_an_object', last => 'Smith')
	} qr/must be called on an object/,
		'search() as plain function croaks with err_no_self message';
};

subtest 'search() — zero arguments croaks with usage message' => sub {
	my $obj = _new_obj();
	throws_ok { $obj->search() }
		qr/Usage:/,
		'search() with no args croaks with the usage string';
};

subtest 'search() — missing last name croaks' => sub {
	my $obj = _new_obj();
	# Passing only 'first' without 'last' must be rejected.
	# Params::Validate::Strict raises "Required parameter 'last' is missing".
	throws_ok { $obj->search(first => 'John') }
		qr/last.*missing|mandatory/i,
		'search() without last croaks citing the missing mandatory field';
};

# ---------------------------------------------------------------------------
# Subtest group: search() — list-context return values
# ---------------------------------------------------------------------------
subtest 'search() — list context returns hashrefs each with a url key' => sub {
	$Genealogy::Obituary::Lookup::obituaries::_mock_rows = [
		{ first => 'John', last => 'Smith', source => 'M', page => $MOCK_PAGE_M },
		{ first => 'Jane', last => 'Smith', source => 'F', page => $MOCK_PAGE_F },
	];

	my $obj     = _new_obj();
	my @results = $obj->search(last => 'Smith');

	is(scalar @results, 2, 'two mock rows yield two results');

	ok(exists $results[0]{url}, 'first result carries a url key');
	ok(exists $results[1]{url}, 'second result carries a url key');

	like($results[0]{url}, $WAYBACK_RE,
		'source M produces a Wayback Machine URL');
	like($results[0]{url}, qr/\Q$MOCK_PAGE_M\E$/,
		'source M URL ends with the page number');

	like($results[1]{url}, $FREELISTS_RE,
		'source F produces a freelists.org URL');
	like($results[1]{url}, qr/\Q$MOCK_PAGE_F\E/,
		'source F URL contains the volume identifier');

	returns_is(\@results, {type => 'arrayref'},
		'returns_is: list-context result coerces to a valid arrayref');

	diag("list result[0] url: $results[0]{url}") if $ENV{TEST_VERBOSE};
};

subtest 'search() — undef rows in DB result are filtered out' => sub {
	# Database::Abstraction occasionally returns undef sentinels.
	# search() must remove them via grep { defined }.
	$Genealogy::Obituary::Lookup::obituaries::_mock_rows = [
		{ first => 'John', last => 'Smith', source => 'M', page => 1 },
		undef,
	];

	my $obj     = _new_obj();
	my @results = $obj->search(last => 'Smith');

	is(scalar @results, 1,       'undef sentinel is stripped from results');
	ok(defined $results[0],      'remaining result is defined');
};

subtest 'search() — no matching rows yields an empty list' => sub {
	$Genealogy::Obituary::Lookup::obituaries::_mock_rows = [];

	my $obj     = _new_obj();
	my @results = $obj->search(last => 'Xyzzy');

	is(scalar @results, 0, 'empty DB result yields empty list in list context');
};

# ---------------------------------------------------------------------------
# Subtest group: search() — scalar-context return values
# ---------------------------------------------------------------------------
subtest 'search() — scalar context returns a hashref with url' => sub {
	$Genealogy::Obituary::Lookup::obituaries::_mock_scalar = {
		first => 'Eric', last => 'Baal', source => 'M', page => 96,
	};

	my $obj    = _new_obj();
	my $result = $obj->search(last => 'Baal');

	ok(defined $result,  'scalar context returns a defined value on match');
	isa_ok($result, 'HASH', 'scalar result is a hashref');
	like($result->{url}, $WAYBACK_RE,  'scalar result has a Wayback URL');
	like($result->{url}, qr/96$/,      'scalar URL ends with the page number');

	returns_is($result, {type => 'hashref'},
		'returns_is: scalar-context result satisfies the hashref schema');

	diag("scalar result url: $result->{url}") if $ENV{TEST_VERBOSE};
};

subtest 'search() — scalar context returns undef when no row matches' => sub {
	$Genealogy::Obituary::Lookup::obituaries::_mock_scalar = undef;

	my $obj    = _new_obj();
	my $result = $obj->search(last => 'Xyzzy');

	ok(!defined $result, 'undef from DB yields undef in scalar context');
};

# ---------------------------------------------------------------------------
# Subtest: search() — lazy DB initialisation
#
# The obituaries handle is created once per object on the first search() call
# and then reused.  We verify both properties.
# ---------------------------------------------------------------------------
subtest 'search() — obituaries handle is lazily initialised' => sub {
	$Genealogy::Obituary::Lookup::obituaries::_mock_rows = [
		{ first => 'Test', last => 'User', source => 'M', page => 1 },
	];

	my $obj = _new_obj();
	ok(!defined $obj->{obituaries},
		'obituaries key is absent before the first search()');

	$obj->search(last => 'User');
	ok(defined $obj->{obituaries},
		'obituaries handle is populated after the first search()');

	my $handle_first = $obj->{obituaries};
	$obj->search(last => 'User');
	is($obj->{obituaries}, $handle_first,
		'the same handle is reused on subsequent calls (no re-init)');
};

subtest 'search() — croaks when obituaries->new returns undef' => sub {
	# Simulate a missing or unreadable database file.
	my $guard = mock_scoped(
		$DRV, 'new', sub { undef }
	);

	my $obj = _new_obj();

	throws_ok { $obj->search(last => 'Smith') }
		qr/Can't open the obituaries database/,
		'search() croaks with err_no_obituaries when the DB handle is undef';
};

# ---------------------------------------------------------------------------
# Subtest group: _create_url() — privacy enforcement and URL construction
#
# _create_url() enforces the (caller)[0] eq __PACKAGE__ guard, so we can only
# verify its logic indirectly by driving search() with controlled mock rows.
# ---------------------------------------------------------------------------
subtest '_create_url() — direct external call is refused' => sub {
	throws_ok {
		Genealogy::Obituary::Lookup::_create_url({ source => 'M', page => 1 })
	} qr/private method/,
		'_create_url() croaks when invoked from outside the package';
};

subtest '_create_url() — source L: newspaper URL takes precedence over page' => sub {
	$Genealogy::Obituary::Lookup::obituaries::_mock_rows = [{
		first     => 'Joyce',
		last      => 'Diver',
		source    => 'L',
		page      => $FUNERAL_URL,
		newspaper => $FUNERAL_URL,
	}];

	my $obj  = _new_obj();
	my ($hit) = $obj->search(last => 'Diver');

	is($hit->{url}, $FUNERAL_URL,
		'source L returns newspaper URL when newspaper begins with https://');
};

subtest '_create_url() — source L: page URL used when newspaper is not a URL' => sub {
	$Genealogy::Obituary::Lookup::obituaries::_mock_rows = [{
		first     => 'Joyce',
		last      => 'Diver',
		source    => 'L',
		page      => $FUNERAL_URL,
		newspaper => 'Some Local Paper',	# not a URL
	}];

	my $obj   = _new_obj();
	my ($hit) = $obj->search(last => 'Diver');

	is($hit->{url}, $FUNERAL_URL,
		'source L falls back to page URL when newspaper is not an https:// URL');
};

subtest '_create_url() — source L with no valid URL croaks' => sub {
	$Genealogy::Obituary::Lookup::obituaries::_mock_rows = [{
		first     => 'Joyce',
		last      => 'Diver',
		source    => 'L',
		page      => 'not-a-url',
		newspaper => 'Some Local Paper',
	}];

	my $obj = _new_obj();

	# Force list context so search() uses _mock_rows (not _mock_scalar).
	throws_ok { my @res = $obj->search(last => 'Diver') }
		qr/undefined newspaper/,
		'_create_url() croaks (err_no_newspaper) when source L has no valid URL';
};

subtest '_create_url() — missing page croaks' => sub {
	$Genealogy::Obituary::Lookup::obituaries::_mock_rows = [{
		first  => 'Test',
		last   => 'User',
		source => 'M',
		page   => undef,
	}];

	my $obj = _new_obj();

	throws_ok { my @res = $obj->search(last => 'User') }
		qr/undefined \$page/,
		'_create_url() croaks (err_no_page) when page is undef';
};

subtest '_create_url() — missing source croaks' => sub {
	$Genealogy::Obituary::Lookup::obituaries::_mock_rows = [{
		first  => 'Test',
		last   => 'User',
		source => undef,
		page   => 1,
	}];

	my $obj = _new_obj();

	throws_ok { my @res = $obj->search(last => 'User') }
		qr/undefined source/,
		'_create_url() croaks (err_no_source) when source is undef';
};

subtest '_create_url() — unknown source value croaks with source in message' => sub {
	$Genealogy::Obituary::Lookup::obituaries::_mock_rows = [{
		first  => 'Test',
		last   => 'User',
		source => 'X',
		page   => 1,
	}];

	my $obj = _new_obj();

	throws_ok { my @res = $obj->search(last => 'User') }
		qr/Invalid source.*X/,
		'_create_url() croaks (err_bad_source) naming the invalid source value';
};

# ---------------------------------------------------------------------------
# Subtest: Genealogy::Obituary::Lookup::obituaries — class structure
#
# The driver module is a thin subclass with no independent logic.  We verify
# the ISA relationship and VERSION rather than re-testing inherited behaviour.
# ---------------------------------------------------------------------------
subtest 'obituaries — ISA and VERSION' => sub {
	use_ok($DRV);

	ok($DRV->isa('Database::Abstraction'),
		"$DRV inherits from Database::Abstraction");

	ok(defined $Genealogy::Obituary::Lookup::obituaries::VERSION,
		"$DRV declares a VERSION");

	ok(defined &{"${DRV}::new"},
		'new() is defined (either mock stub or inherited)');

	diag("$DRV VERSION: $Genealogy::Obituary::Lookup::obituaries::VERSION")
		if $ENV{TEST_VERBOSE};
};

# ---------------------------------------------------------------------------
# Subtest group: memory cycles
#
# Verify that neither the Lookup object nor search() results contain circular
# references that would prevent Perl's reference-count GC from freeing them.
# ---------------------------------------------------------------------------
subtest 'memory cycles — new() object has no circular references' => sub {
	my $obj = _new_obj();
	memory_cycle_ok($obj,
		'freshly constructed Lookup object is cycle-free');
};

subtest 'memory cycles — object remains cycle-free after search()' => sub {
	$Genealogy::Obituary::Lookup::obituaries::_mock_rows = [
		{ first => 'Cycle', last => 'Test', source => 'M', page => 1 },
	];

	my $obj = _new_obj();
	$obj->search(last => 'Test');	# triggers lazy DB init

	memory_cycle_ok($obj,
		'Lookup object remains cycle-free after DB handle is initialised');
};

subtest 'memory cycles — list search() results are cycle-free' => sub {
	$Genealogy::Obituary::Lookup::obituaries::_mock_rows = [
		{ first => 'Alice', last => 'Cycle', source => 'M', page => 2 },
		{ first => 'Bob',   last => 'Cycle', source => 'F', page => 'v26no001' },
	];

	my $obj     = _new_obj();
	my @results = $obj->search(last => 'Cycle');

	memory_cycle_ok(\@results,
		'list of search() result hashrefs is cycle-free');
};

subtest 'memory cycles — scalar search() result is cycle-free' => sub {
	$Genealogy::Obituary::Lookup::obituaries::_mock_scalar = {
		first => 'Scalar', last => 'Cycle', source => 'M', page => 3,
	};

	my $obj    = _new_obj();
	my $result = $obj->search(last => 'Cycle');

	memory_cycle_ok($result, 'scalar search() result hashref is cycle-free');
};

done_testing();
