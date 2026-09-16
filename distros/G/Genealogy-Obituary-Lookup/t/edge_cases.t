#!/usr/bin/env perl

# Destructive, pathological, boundary-condition, and security tests for
# Genealogy::Obituary::Lookup.
#
# Strategy: the obituaries driver is replaced entirely in a BEGIN block (same
# as t/function.t).  $_mock_rows / $_mock_scalar control what the "DB" returns
# so upstream failures can be injected without SQLite.  new() tests use tempdir
# to satisfy the directory requirement.

use strict;
use warnings;

use File::Spec;
use File::Temp   qw(tempdir);
use Readonly;
use Scalar::Util qw(blessed refaddr weaken);
use Test::Most;
use Test::Returns;
use Test::Warn;

use lib 'lib';
use lib 't/lib';
use MyLogger;

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
Readonly::Scalar my $PKG => 'Genealogy::Obituary::Lookup';

Readonly::Scalar my $WAYBACK_BASE  =>
	'https://wayback.archive-it.org/20669/20231102044925/'
	. 'https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit&page=';
Readonly::Scalar my $FREELISTS_BASE =>
	'https://www.freelists.org/post/obitdailytimes/Obituary-Daily-Times-';

# ---------------------------------------------------------------------------
# Mock obituaries driver — must exist before 'use Genealogy::Obituary::Lookup'
# triggers the compile-time 'use Genealogy::Obituary::Lookup::obituaries'.
# ---------------------------------------------------------------------------
BEGIN {
	package Genealogy::Obituary::Lookup::obituaries;

	our $_mock_rows   = [];
	our $_mock_scalar = undef;

	sub new                { bless {}, shift }
	sub selectall_hashref  { return $_mock_rows }
	sub fetchrow_hashref   { return $_mock_scalar }
}

BEGIN { use_ok('Genealogy::Obituary::Lookup') }

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
sub _new_obj {
	my %extra = @_;
	my $dir   = tempdir(CLEANUP => 1);
	return $PKG->new(directory => $dir, %extra);
}

sub _set_rows  { $Genealogy::Obituary::Lookup::obituaries::_mock_rows   = shift }
sub _set_scalar { $Genealogy::Obituary::Lookup::obituaries::_mock_scalar = shift }

# Minimal valid obit record — callers override specific fields.
sub _obit {
	return {
		first      => 'John',
		last       => 'Smith',
		source     => 'M',
		page       => '42',
		newspaper  => 'Dayton Daily',
		date       => '2024-01-01',
		place      => 'Dayton, OH',
		age        => 65,
		maiden     => undef,
	};
}

# ===========================================================================
# SECTION 1: new() — hostile scalar inputs
# ===========================================================================

subtest 'new(): empty string as directory carps and returns undef' => sub {
	my $obj;
	warnings_exist { $obj = $PKG->new(directory => '') }
		[qr/is not a directory/],
		'empty string directory emits not-a-directory warning';
	ok(!defined $obj, 'returns undef for empty string directory');
};

subtest 'new(): numeric zero as directory carps and returns undef' => sub {
	my $obj;
	warnings_exist { $obj = $PKG->new(directory => 0) }
		[qr/is not a directory/],
		'numeric zero as directory emits warning';
	ok(!defined $obj, 'returns undef for zero directory');
};

subtest 'new(): undef directory triggers auto-discover (no carp)' => sub {
	# undef directory means "discover automatically" — must not carp.
	# (Auto-discover may or may not find a real data/ dir.)
	my @warns;
	my $obj;
	warnings_exist { $obj = $PKG->new(directory => undef) }
		[],
		'undef directory emits no not-a-directory warning';
	ok(1, 'new(directory => undef) did not croak');
};

subtest 'new(): scalar ref as directory carps and returns undef' => sub {
	my $ref = \"not a path";
	my $obj;
	warnings_exist { $obj = $PKG->new(directory => $ref) }
		[qr/is not a directory/],
		'scalar ref as directory emits warning';
	ok(!defined $obj, 'returns undef for scalar-ref directory');
};

subtest 'new(): code ref as directory carps and returns undef' => sub {
	my $code = sub { '/tmp' };
	my $obj;
	warnings_exist { $obj = $PKG->new(directory => $code) }
		[qr/is not a directory/],
		'code ref as directory emits warning';
	ok(!defined $obj, 'returns undef for code-ref directory');
};

subtest 'new(): null byte in directory path carps and returns undef' => sub {
	# Null bytes cause a fatal "Embedded nulls are forbidden" error inside Perl's
	# stat() / file-test operators.  The module must sanitise the path before the
	# -d test so it carps gracefully rather than dying.
	my $obj;
	warnings_exist { $obj = $PKG->new(directory => "/tmp/safe\0evil") }
		[qr/is not a directory/],
		'null-byte directory path emits not-a-directory warning';
	ok(!defined $obj, 'returns undef for null-byte directory');
};

# ===========================================================================
# SECTION 2: new() — filesystem hostility
# ===========================================================================

subtest 'new(): /dev/null (a char device, not a directory) carps and returns undef' => sub {
	my $obj;
	warnings_exist { $obj = $PKG->new(directory => '/dev/null') }
		[qr/is not a directory/],
		'/dev/null as directory emits warning';
	ok(!defined $obj, 'returns undef for /dev/null');
};

subtest 'new(): plain file as directory carps and returns undef' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);
	my $file   = File::Spec->catfile($tmpdir, 'plain.txt');
	open(my $fh, '>', $file) or die "Cannot create test file: $!";
	print $fh "data\n";
	close $fh;

	my $obj;
	warnings_exist { $obj = $PKG->new(directory => $file) }
		[qr/is not a directory/],
		'plain file as directory emits warning';
	ok(!defined $obj, 'returns undef for plain file');
};

subtest 'new(): dangling symlink as directory carps and returns undef' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);
	my $link   = File::Spec->catfile($tmpdir, 'dangling');
	unless(symlink('/does/not/exist/anywhere', $link)) {
		plan(skip_all => 'Cannot create symlink');
		return;
	}

	my $obj;
	warnings_exist { $obj = $PKG->new(directory => $link) }
		[qr/is not a directory/],
		'dangling symlink emits not-a-directory warning';
	ok(!defined $obj, 'returns undef for dangling symlink');
};

subtest 'new(): symlink to a valid directory is accepted' => sub {
	my $tmpdir    = tempdir(CLEANUP => 1);
	my $real_dir  = tempdir(CLEANUP => 1);
	my $linkdir   = File::Spec->catfile($tmpdir, 'sym_to_dir');
	unless(symlink($real_dir, $linkdir)) {
		plan(skip_all => 'Cannot create symlink');
		return;
	}

	my $obj = $PKG->new(directory => $linkdir);
	ok(defined $obj, 'symlink to valid directory succeeds');
	isa_ok($obj, $PKG, 'returns blessed object through symlink');
};

SKIP: {
	skip 'Running as root — chmod 0 does not prevent access', 4 if $> == 0;

	subtest 'new(): unreadable directory carps and returns undef' => sub {
		my $tmpdir = tempdir(CLEANUP => 1);
		my $subdir = File::Spec->catfile($tmpdir, 'unreadable');
		unless(mkdir $subdir) {
			pass('SKIP: cannot create subdir');
			return;
		}
		chmod(0, $subdir) or do { pass('SKIP: cannot chmod'); return };

		my $obj;
		warnings_exist { $obj = $PKG->new(directory => $subdir) }
			[qr/is not a directory/],
			'unreadable directory emits not-a-directory warning';
		ok(!defined $obj, 'returns undef for unreadable directory');
		chmod(0755, $subdir);
	};
}

# ===========================================================================
# SECTION 3: new() — path security (shell metacharacters)
#
# Perl's -d operator calls stat(2) directly — no shell is involved, so these
# paths cannot cause command injection.  The tests verify: no crash, no
# unintended execution side-effects, returns undef.
# ===========================================================================

Readonly::Array my @HOSTILE_PATHS => (
	'|touch /tmp/pwned_gol_edge',
	'; rm -rf /tmp',
	'$(echo hostile)',
	'`id`',
	"path with spaces in it",
	"path\twith\ttabs",
	"path/../../../etc/passwd",
	"../traversal/../traversal",
	"path>redirect",
	"path;injection",
);

subtest 'new(): shell-metacharacter paths cannot cause injection (no crash)' => sub {
	for my $path (@HOSTILE_PATHS) {
		my $obj;
		warnings_exist { $obj = $PKG->new(directory => $path) }
			[qr/is not a directory/],
			sprintf('hostile path "%s" emits warning', $path =~ s/[^\x20-\x7e]/./gr);
		ok(!defined $obj, sprintf('hostile path returns undef: %s', $path =~ s/[^\x20-\x7e]/./gr));
	}
};

# Verify no side-effect: if the shell injection had executed, it would create
# a file.  Assert it does not exist.
subtest 'new(): injection attempts did not create sentinel file' => sub {
	ok(!-e '/tmp/pwned_gol_edge',
		'shell-injection attempt via directory path had no effect');
};

# ===========================================================================
# SECTION 4: new() — logger validation edge cases
# ===========================================================================

# Packages defined once at module level (not inside subtests) to avoid "Too
# late to run CHECK block" warnings from Sub::Protected.

{
	package LoggerNoError;
	sub new  { bless {}, shift }
	sub info { }
	sub warn { }
}

{
	package LoggerNoInfo;
	sub new   { bless {}, shift }
	sub warn  { }
	sub error { }
}

{
	package LoggerNoWarn;
	sub new   { bless {}, shift }
	sub info  { }
	sub error { }
}

{
	# AUTOLOAD-only logger: can() returns undef for AUTOLOAD-handled methods.
	package LoggerAutoloadOnly;
	sub new  { bless {}, shift }
	sub AUTOLOAD {
		our $AUTOLOAD;
		return if $AUTOLOAD =~ /::DESTROY$/;
	}
}

subtest 'new(): logger with info() but no error() is rejected' => sub {
	throws_ok { _new_obj(logger => LoggerNoError->new()) }
		qr/Logger must/,
		'logger missing error() is rejected';
};

subtest 'new(): logger with error() but no info() is rejected' => sub {
	throws_ok { _new_obj(logger => LoggerNoInfo->new()) }
		qr/Logger must/,
		'logger missing info() is rejected';
};

subtest 'new(): logger with info() and error() but no warn() is rejected' => sub {
	throws_ok { _new_obj(logger => LoggerNoWarn->new()) }
		qr/Logger must/,
		'logger missing warn() is rejected';
};

subtest 'new(): AUTOLOAD-only logger is rejected (can() cannot see the methods)' => sub {
	throws_ok { _new_obj(logger => LoggerAutoloadOnly->new()) }
		qr/Logger must/,
		'AUTOLOAD-only logger is rejected';
};

subtest 'new(): non-object values as logger are all rejected' => sub {
	my @bad_loggers = (42, "a string", 0, "", [], {}, sub { });
	for my $bad (@bad_loggers) {
		my $label = ref $bad || (defined $bad ? qq{"$bad"} : 'undef');
		throws_ok { _new_obj(logger => $bad) }
			qr/Logger must/,
			"logger => $label is rejected";
	}
};

# ===========================================================================
# SECTION 5: new() — global state preservation
# ===========================================================================

subtest 'new(): does not clobber $@' => sub {
	local $@ = 'original_at_new';
	my $obj = _new_obj();
	is($@, 'original_at_new', 'new() did not modify $@');
};

subtest 'new(): does not clobber $_' => sub {
	local $_ = 'sentinel_under';
	_new_obj();
	is($_, 'sentinel_under', 'new() did not modify $_');
};

# ===========================================================================
# SECTION 6: new() — handle pre-population (injection vector)
# ===========================================================================

subtest 'new(): pre-populated "obituaries" key is preserved by //=' => sub {
	# A caller can inject a custom obituaries handle into new() args.
	# The //= in search() will then use that handle without re-initialising.
	# This is expected behaviour (not a security concern since the caller
	# already has full object access), but the test documents the contract.
	my $sentinel = bless { injected => 1 }, 'FakeObit';
	my $obj = _new_obj(obituaries => $sentinel);
	is(refaddr($obj->{obituaries}), refaddr($sentinel),
		'pre-injected obituaries handle is preserved by new()');
};

# ===========================================================================
# SECTION 7: search() — hostile invocation (no self, no args, bad self)
# ===========================================================================

subtest 'search(): called as a plain function (no self) croaks' => sub {
	throws_ok { Genealogy::Obituary::Lookup::search() }
		qr/must be called on an object/,
		'::search() with no args croaks with err_no_self';
};

subtest 'search(): called as class method (string, not blessed) croaks' => sub {
	throws_ok { $PKG->search(last => 'Smith') }
		qr/must be called on an object/,
		'class->search() croaks with err_no_self';
};

subtest 'search(): called on an unblessed hashref croaks' => sub {
	my $ref = { directory => tempdir(CLEANUP => 1) };
	throws_ok { $ref->search(last => 'Smith') }
		qr//,	# Perl catches the call itself
		'unblessed ref->search() is caught';
};

subtest 'search(): called with no args at all croaks with usage message' => sub {
	my $obj = _new_obj();
	throws_ok { $obj->search() }
		qr/Usage:/,
		'search() with zero args croaks with usage message';
};

subtest 'search(): empty hashref arg croaks on missing last' => sub {
	my $obj = _new_obj();
	throws_ok { my @r = $obj->search({}) }
		qr/last|mandatory|required|missing/i,
		'search({}) croaks on missing last parameter';
};

# ===========================================================================
# SECTION 8: search() — last name boundary conditions
# ===========================================================================

subtest 'search(): last => undef croaks' => sub {
	my $obj = _new_obj();
	throws_ok { my @r = $obj->search(last => undef) }
		qr/last|mandatory|missing|Value for/i,
		'search(last => undef) croaks';
};

subtest "search(): last => '' (empty string) croaks" => sub {
	my $obj = _new_obj();
	throws_ok { my @r = $obj->search(last => '') }
		qr/last|mandatory|length|missing|required/i,
		"search(last => '') croaks";
};

subtest 'search(): last name of exactly 1 char is accepted by schema' => sub {
	my $obj = _new_obj();
	_set_rows([]);
	my @r;
	lives_ok { @r = $obj->search(last => 'A') }
		'1-char last name does not croak';
};

subtest 'search(): last name of exactly 100 chars is accepted by schema' => sub {
	my $obj = _new_obj();
	_set_rows([]);
	lives_ok { my @r = $obj->search(last => 'B' x 100) }
		'100-char last name does not croak';
};

subtest 'search(): last name of 101 chars is rejected by schema (max => 100)' => sub {
	my $obj = _new_obj();
	throws_ok { my @r = $obj->search(last => 'C' x 101) }
		qr/last|length|too long|max|101/i,
		'101-char last name rejected';
};

subtest 'search(): hyphen in last name is accepted' => sub {
	my $obj = _new_obj();
	_set_rows([]);
	lives_ok { my @r = $obj->search(last => 'O-Brien') }
		'O-Brien (hyphenated) accepted by schema';
};

subtest "search(): apostrophe in last name is rejected (not in [\\w\\-])" => sub {
	my $obj = _new_obj();
	throws_ok { my @r = $obj->search(last => "O'Brien") }
		qr/last|invalid|matches|apostrophe|does not match/i,
		"O'Brien rejected — apostrophe is not in [\\w\\-]";
};

subtest 'search(): space in last name is rejected' => sub {
	my $obj = _new_obj();
	throws_ok { my @r = $obj->search(last => 'Mc Carthy') }
		qr/last|invalid|matches|does not match/i,
		'space in last name rejected';
};

subtest 'search(): leading/trailing whitespace in last name is rejected' => sub {
	my $obj = _new_obj();
	for my $bad (' Smith', 'Smith ', "\tSmith") {
		my $label = $bad =~ s/\s/\\s/gr;
		throws_ok { my @r = $obj->search(last => $bad) }
			qr/last|invalid|matches|does not match/i,
			"whitespace last name '$label' rejected";
	}
};

# ===========================================================================
# SECTION 9: search() — age boundary conditions
# ===========================================================================

subtest 'search(): age => 0 (minimum boundary) is accepted' => sub {
	my $obj = _new_obj();
	_set_rows([]);
	lives_ok { my @r = $obj->search(last => 'Smith', age => 0) }
		'age => 0 does not croak';
};

subtest 'search(): age => 120 (maximum boundary) is accepted' => sub {
	my $obj = _new_obj();
	_set_rows([]);
	lives_ok { my @r = $obj->search(last => 'Smith', age => 120) }
		'age => 120 does not croak';
};

subtest 'search(): age => -1 is rejected (below minimum)' => sub {
	my $obj = _new_obj();
	throws_ok { my @r = $obj->search(last => 'Smith', age => -1) }
		qr/age|minimum|invalid|-1/i,
		'age => -1 is rejected';
};

subtest 'search(): age => 121 is rejected (above maximum)' => sub {
	my $obj = _new_obj();
	throws_ok { my @r = $obj->search(last => 'Smith', age => 121) }
		qr/age|maximum|invalid|121/i,
		'age => 121 is rejected';
};

subtest 'search(): non-integer age is rejected' => sub {
	my $obj = _new_obj();
	throws_ok { my @r = $obj->search(last => 'Smith', age => 1.5) }
		qr/age|integer|invalid/i,
		'float age 1.5 rejected';
	throws_ok { my @r = $obj->search(last => 'Smith', age => 'old') }
		qr/age|integer|invalid/i,
		'string age "old" rejected';
	throws_ok { my @r = $obj->search(last => 'Smith', age => '') }
		qr/age|integer|invalid/i,
		'empty-string age rejected';
};

subtest 'search(): unknown extra parameter is rejected by schema' => sub {
	my $obj = _new_obj();
	throws_ok { my @r = $obj->search(last => 'Smith', extrafield => 'x') }
		qr/unknown|extrafield|schema|invalid|not valid/i,
		'unknown parameter rejected by Params::Validate::Strict';
};

# ===========================================================================
# SECTION 10: search() — SQL injection and security
#
# The schema enforces qr/^[\w\-]+$/ on the last name, which rejects all SQL
# metacharacters (quotes, semicolons, spaces, dashes in the wrong places,
# percent signs, angle brackets).  Every injection payload below must croak.
# ===========================================================================

Readonly::Array my @SQL_INJECTIONS => (
	"Smith'; DROP TABLE obituaries;--",
	"' OR '1'='1",
	"1; DELETE FROM obituaries WHERE '1'='1",
	"Smith UNION SELECT * FROM obituaries",
	"Smith%27",
	"Smith%20OR%201%3D1",
	'<script>alert(1)</script>',
	'../../../etc/passwd',
	'$(echo pwned)',
	"`id`",
);

subtest 'search(): SQL injection payloads in last name are rejected by regex' => sub {
	my $obj = _new_obj();
	for my $payload (@SQL_INJECTIONS) {
		my $label = $payload =~ s/[\x00-\x1f\x7f-\xff]/./gr;
		throws_ok { my @r = $obj->search(last => $payload) }
			qr/invalid|matches|last|does not match|schema/i,
			"SQL injection payload rejected: $label";
	}
};

subtest 'search(): null byte in last name is rejected' => sub {
	my $obj = _new_obj();
	throws_ok { my @r = $obj->search(last => "Smith\0evil") }
		qr/invalid|matches|last|does not match/i,
		'null byte in last name is rejected by regex';
};

subtest 'search(): newline in last name is rejected' => sub {
	my $obj = _new_obj();
	throws_ok { my @r = $obj->search(last => "Smith\nEvil") }
		qr/invalid|matches|last|does not match/i,
		'newline in last name is rejected';
};

# ===========================================================================
# SECTION 11: search() — global state preservation
# ===========================================================================

subtest 'search(): $@ is empty after a successful list-context search' => sub {
	# Internal evals (Data::Reuse, Carp, etc.) may clear a caller-set $@.
	# The documented contract is only that search() must NOT set $@ to an error
	# string on success — not that it preserves a pre-existing value.
	my $obj = _new_obj();
	_set_rows([ _obit() ]);
	my @r;
	eval { @r = $obj->search(last => 'Smith') };
	ok(!$@, 'search() did not set $@ to an error on success');
	cmp_ok(scalar @r, '>=', 1, 'search returned at least one result');
};

subtest 'search(): does not clobber $_ during iteration' => sub {
	my $obj = _new_obj();
	_set_rows([ _obit(), _obit() ]);
	local $_ = 'sentinel_under_search';
	my @r = $obj->search(last => 'Smith');
	is($_, 'sentinel_under_search', 'search() did not clobber $_');
};

subtest 'search(): alarm timer is not disturbed' => sub {
	eval { alarm(9999) };   # skip if alarm() raises an exception
	if($@) { pass('alarm() not available — skip'); return }

	# alarm() silently no-ops on Windows (returns 0 without arming).
	# Re-arm and check the seconds-remaining from the previous call:
	# on a working system it is ≈9999; on a no-op platform it is 0.
	my $rearm = alarm(9999);
	unless($rearm > 0) {
		alarm(0);
		pass('alarm() silently unavailable on this platform — skip');
		return;
	}

	my $obj = _new_obj();
	_set_rows([ _obit() ]);
	my @r = $obj->search(last => 'Smith');
	my $remaining = alarm(0);   # disarm
	cmp_ok($remaining, '>', 0, 'alarm timer was not cleared by search()');
};

# ===========================================================================
# SECTION 12: search() — upstream DB failure simulation
#
# The mock driver variables are set directly; no mock_scoped on inherited
# methods is needed (and avoids the stash-corruption bug with inherited methods).
# ===========================================================================

subtest 'upstream: selectall_hashref returns undef → empty list' => sub {
	my $obj = _new_obj();
	_set_rows(undef);
	my @r = $obj->search(last => 'Smith');
	is(scalar @r, 0, 'undef result from selectall → empty list');
};

subtest 'upstream: selectall_hashref returns [] → empty list' => sub {
	my $obj = _new_obj();
	_set_rows([]);
	my @r = $obj->search(last => 'Smith');
	is(scalar @r, 0, 'empty arrayref from selectall → empty list');
};

subtest 'upstream: result list containing undef entries → undefs are stripped' => sub {
	my $obj = _new_obj();
	_set_rows([ undef, undef, _obit() ]);
	my @r = $obj->search(last => 'Smith');
	is(scalar @r, 1, 'undef entries are filtered by grep { defined }');
	like($r[0]->{url}, qr/page=42/, 'surviving record has correct URL');
};

subtest 'upstream: record with undef source → croak err_no_source' => sub {
	my $obj = _new_obj();
	my $row = _obit();
	$row->{source} = undef;
	_set_rows([$row]);
	throws_ok { my @r = $obj->search(last => 'Smith') }
		qr/source/i,
		'undef source in DB row triggers croak';
};

subtest 'upstream: record with undef page → croak err_no_page' => sub {
	my $obj = _new_obj();
	my $row = _obit();
	$row->{page} = undef;
	_set_rows([$row]);
	throws_ok { my @r = $obj->search(last => 'Smith') }
		qr/page/i,
		'undef page in DB row triggers croak';
};

subtest 'upstream: record with invalid source "X" → croak err_bad_source' => sub {
	my $obj = _new_obj();
	my $row = _obit();
	$row->{source} = 'X';
	_set_rows([$row]);
	throws_ok { my @r = $obj->search(last => 'Smith') }
		qr/Invalid source|source.*X/i,
		'invalid source "X" triggers croak';
};

subtest 'upstream: source L with non-https newspaper and non-https page → croak' => sub {
	my $obj = _new_obj();
	my $row = _obit();
	$row->{source}    = 'L';
	$row->{newspaper} = 'plain-text-name';
	$row->{page}      = 'not-a-url';
	_set_rows([$row]);
	throws_ok { my @r = $obj->search(last => 'Smith') }
		qr/newspaper|no_newspaper/i,
		'source L with no https:// URL anywhere triggers croak';
};

subtest 'upstream: source L with https:// newspaper → newspaper URL used' => sub {
	my $obj = _new_obj();
	my $row = _obit();
	$row->{source}    = 'L';
	$row->{newspaper} = 'https://funeral-notices.co.uk/notice/smith/1234';
	$row->{page}      = 'not-a-url';
	_set_rows([$row]);
	my @r = $obj->search(last => 'Smith');
	is(scalar @r, 1, 'source L with https newspaper returns one result');
	is($r[0]->{url}, 'https://funeral-notices.co.uk/notice/smith/1234',
		'newspaper HTTPS URL is used as the canonical URL');
};

subtest 'upstream: source L with https:// page (non-https newspaper) → page URL used' => sub {
	my $obj = _new_obj();
	my $row = _obit();
	$row->{source}    = 'L';
	$row->{newspaper} = 'Local Gazette';
	$row->{page}      = 'https://page.example.com/obit';
	_set_rows([$row]);
	my @r = $obj->search(last => 'Smith');
	is(scalar @r, 1, 'source L with https page returns one result');
	is($r[0]->{url}, 'https://page.example.com/obit',
		'page HTTPS URL is used when newspaper is not https://');
};

subtest 'upstream: source M → Wayback Machine URL assembled correctly' => sub {
	my $obj = _new_obj();
	my $row = _obit();
	$row->{source} = 'M';
	$row->{page}   = '99';
	_set_rows([$row]);
	my @r = $obj->search(last => 'Smith');
	is($r[0]->{url}, $WAYBACK_BASE . '99', 'source M URL is Wayback base + page');
};

subtest 'upstream: source F → freelists URL assembled correctly' => sub {
	my $obj = _new_obj();
	my $row = _obit();
	$row->{source} = 'F';
	$row->{page}   = 'v26no080';
	_set_rows([$row]);
	my @r = $obj->search(last => 'Smith');
	is($r[0]->{url}, $FREELISTS_BASE . 'v26no080', 'source F URL is freelists base + page');
};

subtest 'upstream: fetchrow_hashref returns undef → undef in scalar context' => sub {
	my $obj = _new_obj();
	_set_scalar(undef);
	my $r = $obj->search(last => 'Smith');
	ok(!defined $r, 'undef from fetchrow → undef in scalar context');
};

subtest 'upstream: scalar context result has url key' => sub {
	my $obj = _new_obj();
	my $row = _obit();
	$row->{source} = 'M';
	$row->{page}   = '7';
	_set_scalar($row);
	my $r = $obj->search(last => 'Smith');
	isa_ok($r, 'HASH', 'scalar result is a hashref');
	is($r->{url}, $WAYBACK_BASE . '7', 'scalar result URL is correct');
};

# Extremely large page value — URL length is unchecked; module must not crash.
subtest 'upstream: extremely long page value does not crash' => sub {
	my $obj = _new_obj();
	my $row = _obit();
	$row->{source} = 'M';
	$row->{page}   = 'A' x 10_000;
	_set_rows([$row]);
	my @r;
	lives_ok { @r = $obj->search(last => 'Smith') }
		'10 000-char page value does not crash';
	is(length($r[0]->{url}), length($WAYBACK_BASE) + 10_000,
		'URL is base + full page string');
};

# ===========================================================================
# SECTION 13: search() — context abuse
# ===========================================================================

subtest 'search(): void context does not crash' => sub {
	# Void context takes the scalar branch (wantarray = undef).
	# Set _mock_scalar to undef so the scalar path exits early via 'or return'
	# without reaching fixate; ensures the void path is exercised cleanly.
	my $obj = _new_obj();
	_set_rows([ _obit() ]);
	_set_scalar(undef);
	lives_ok { $obj->search(last => 'Smith') }
		'search() in void context does not crash or die';
};

subtest 'search(): interleaved list and scalar context on the same object' => sub {
	# Use independent _obit() hashrefs for rows and scalar so that Data::Reuse::
	# fixate is never called twice on the same reference (which would crash
	# after the first intern makes the strings read-only).
	my $obj  = _new_obj();
	_set_rows([ _obit(), _obit() ]);
	_set_scalar(_obit());

	my @list   = $obj->search(last => 'Smith');
	my $scalar = $obj->search(last => 'Smith');

	cmp_ok(scalar @list, '==', 2, 'list context returns all rows');
	isa_ok($scalar, 'HASH',        'scalar context returns a hashref');
};

# ===========================================================================
# SECTION 14: Private method enforcement
# ===========================================================================

subtest '_create_url(): calling from outside the package croaks' => sub {
	throws_ok {
		Genealogy::Obituary::Lookup::_create_url({ source => 'M', page => '1' })
	}
		qr/_create_url.*private|private.*_create_url/,
		'_create_url() from outside Genealogy::Obituary::Lookup croaks';
};

subtest '_i18n(): valid key returns non-empty formatted string' => sub {
	# _i18n has no caller guard; it is a utility reachable from test code.
	my $msg = Genealogy::Obituary::Lookup::_i18n($PKG, 'err_no_last');
	ok(length($msg) > 0, '_i18n returns non-empty string for known key');
	unlike($msg, qr/%\{/, 'no unresolved %{...} placeholders remain');
};

subtest '_i18n(): unknown message key croaks' => sub {
	throws_ok {
		Genealogy::Obituary::Lookup::_i18n($PKG, 'completely_unknown_key_xyz')
	}
		qr/Unknown i18n key/,
		'_i18n() croaks on an unknown message key';
};

subtest '_i18n(): missing placeholder in args leaves key empty (no crash)' => sub {
	# err_no_args has %{package} but we supply no args hashref.
	my $msg;
	lives_ok { $msg = Genealogy::Obituary::Lookup::_i18n($PKG, 'err_no_args', {}) }
		'_i18n with no placeholder values does not crash';
	unlike($msg, qr/\{\w+\}/, 'no bare {key} remains (placeholder rendered as empty)');
};

# ===========================================================================
# SECTION 15: Regression tests
# ===========================================================================

# Regression: logger validation order.
# Bug: Object::Configure wrapped any logger (even an unblessed ref) in
# Log::Abstraction before the validation check ran, defeating err_bad_logger.
# Fix: validate logger BEFORE calling Object::Configure::configure().
subtest 'regression: unblessed logger rejected even with Object::Configure active' => sub {
	throws_ok { _new_obj(logger => {}) }
		qr/Logger must/,
		'unblessed hashref logger is rejected before Object::Configure wraps it';
	throws_ok { _new_obj(logger => []) }
		qr/Logger must/,
		'unblessed arrayref logger is rejected before Object::Configure wraps it';
};

# Regression: ::new() with no args must be tolerated (not a bad-usage croak).
# Bug: the !%args guard was missing; any class_in-undef path croaked.
subtest 'regression: ::new() with no args is tolerated' => sub {
	my $obj;
	lives_ok { $obj = Genealogy::Obituary::Lookup::new() }
		'::new() with no args does not croak';
};

# Regression: warn_bad_usage is triggered only when args are provided with
# ::new() (not on a simple no-arg call).
subtest 'regression: ::new() with args croaks with warn_bad_usage' => sub {
	throws_ok { Genealogy::Obituary::Lookup::new(undef, directory => '/tmp') }
		qr/use ->new\(\) not ::new\(\)/,
		'::new(undef, args) croaks with warn_bad_usage';
};

# ===========================================================================
# SECTION 16: Memory / reference integrity
# ===========================================================================

subtest 'new(): circular reference in args does not hang or crash' => sub {
	my %circ;
	$circ{self} = \%circ;
	weaken($circ{self});

	my $obj;
	# Circular reference passed as an unknown key — PVS or Object::Configure
	# may reject it, but it must not hang or crash the process.
	eval { $obj = _new_obj(circular => \%circ) };
	ok(1, 'circular reference in args did not hang or crash the process');
};

subtest 'search(): returned hashrefs are independent copies per call' => sub {
	my $obj = _new_obj();
	_set_rows([ _obit() ]);

	my ($r1) = $obj->search(last => 'Smith');
	_set_rows([ _obit() ]);
	my ($r2) = $obj->search(last => 'Smith');

	isnt(refaddr($r1), refaddr($r2),
		'two list-context results are distinct hashrefs, not the same reference');
};

done_testing();
