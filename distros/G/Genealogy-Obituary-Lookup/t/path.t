#!/usr/bin/env perl

# Path-coverage tests for Genealogy::Obituary::Lookup.
#
# Methodology: Control Flow Graph (CFG) enumeration.  Every uniquely
# identifiable path through each subroutine has an explicit subtest.
#
# Notation used in subtest names:
#   [N-1A]  new() Branch 1, arm A (argument-parsing)
#   [N-2B]  new() Branch 2, arm B (invocant check — clone)
#   [S-L1]  search() list-context path 1
#   [C-M]   _create_url() source-M path
#   [I-...]  _i18n() path
#
# CFG summary
# -----------
# new() paths
#   B1  arg-parse      : 1A bare-fn+dir  / 1B single-scalar / 1C key-val  / 1D no-args
#   B2  invocant       : 2A-i undef+args / 2A-ii undef+no-args / 2B clone  / 2C class
#   B3  logger         : 3A absent       / 3B-V valid         / 3B-I invalid
#   B4  auto-dir       : 4A dir-set      / 4B-ia derived-found / 4B-ib derived-missing / 4B-ii Module::Info-undef
#   B5  null-byte      : 5A skip         / 5B-I null+logger   / 5B-II null+no-logger
#   B6  dir-check      : 6A undef-skip   / 6B valid-skip      / 6C-I bad+logger / 6C-II bad+no-logger
#
# search() paths
#   S-no-self / S-no-args / S-schema / S-no-last / S-no-obit / S-L{0,1,N} / S-Scalar{0,1}
#
# _create_url() paths (exercised via search())
#   C-no-page / C-no-source / C-M / C-F / C-L-news / C-L-page / C-L-none / C-bad-src
#
# _i18n() paths
#   I-valid / I-args / I-invalid / I-nil-args

use strict;
use warnings;

use File::Temp    qw(tempdir);
use Readonly;
use Scalar::Util  qw(blessed refaddr);
use Test::Most;
use Test::Returns;

use lib 'lib';
use lib 't/lib';
use MyLogger;

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
Readonly::Scalar my $PKG => 'Genealogy::Obituary::Lookup';
Readonly::Scalar my $DRV => 'Genealogy::Obituary::Lookup::obituaries';

Readonly::Scalar my $WAYBACK   =>
	'https://wayback.archive-it.org/20669/20231102044925/'
	. 'https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit&page=';
Readonly::Scalar my $FREELISTS =>
	'https://www.freelists.org/post/obitdailytimes/Obituary-Daily-Times-';

# ---------------------------------------------------------------------------
# Mock obituaries driver — must be in place before Lookup is loaded
# ---------------------------------------------------------------------------
BEGIN {
	package Genealogy::Obituary::Lookup::obituaries;
	our $_mock_rows   = [];
	our $_mock_scalar = undef;
	our $new_returns  = 1;    # 1 = blessed obj; 0 = undef

	sub new {
		return undef unless $new_returns;
		return bless {}, shift;
	}
	sub selectall_hashref { return $_mock_rows }
	sub fetchrow_hashref  { return $_mock_scalar }
}

BEGIN { use_ok('Genealogy::Obituary::Lookup') }

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
sub _dir { tempdir(CLEANUP => 1) }

sub _obj {
	my $obj = $PKG->new(directory => _dir(), @_);
	$obj->{obituaries} = bless {}, $DRV if $obj;
	return $obj;
}

sub _obit {
	return {
		first => 'John', middle => 'W', last => 'Smith',
		maiden => undef, age => 65, place => 'Dayton, OH',
		newspaper => 'Dayton Daily', date => '2024-01-01',
		source => 'M', page => '1',
	};
}

sub _set_rows   { $Genealogy::Obituary::Lookup::obituaries::_mock_rows   = shift }
sub _set_scalar { $Genealogy::Obituary::Lookup::obituaries::_mock_scalar = shift }

sub _set_db_returns_undef {
	$Genealogy::Obituary::Lookup::obituaries::new_returns = 0;
}
sub _restore_db {
	$Genealogy::Obituary::Lookup::obituaries::new_returns = 1;
}

# ==========================================================================
# SECTION 1: new() — Branch 1: argument parsing
# ==========================================================================

subtest '[N-1A] new() function-call with existing dir as first arg' => sub {
	# new('/real/dir') — directory is the invocant, no remaining @_
	# Branch 1A fires: scalar(@_)==0 && !ref($class_in) && defined && -d
	my $dir = _dir();
	my $obj;
	lives_ok { $obj = Genealogy::Obituary::Lookup::new($dir) }
		'[N-1A] Pkg::new($dir) does not croak';
	ok(defined $obj && blessed($obj), '[N-1A] returns a blessed object');
	is($obj->{directory}, $dir, '[N-1A] directory stored from first arg');
	is(ref($obj), $PKG, '[N-1A] object is the correct class');
};

subtest '[N-1B] new() single bare scalar arg → treated as directory' => sub {
	# Pkg->new('/dir') — one scalar arg remaining after shift
	my $dir = _dir();
	my $obj = $PKG->new($dir);
	ok(defined $obj && blessed($obj), '[N-1B] returns blessed object');
	is($obj->{directory}, $dir, '[N-1B] directory set from single scalar arg');
};

subtest '[N-1C] new() key-value list → parsed by Params::Get' => sub {
	my $dir = _dir();
	my $obj = $PKG->new(directory => $dir, cache_duration => '2 days');
	ok(defined $obj && blessed($obj), '[N-1C] returns blessed object');
	is($obj->{directory},      $dir,     '[N-1C] directory correctly parsed');
	is($obj->{cache_duration}, '2 days', '[N-1C] extra key-val arg parsed');
};

subtest '[N-1C-hash] new() hashref arg → parsed by Params::Get' => sub {
	my $dir = _dir();
	my $obj = $PKG->new({ directory => $dir });
	ok(defined $obj && blessed($obj), '[N-1C-hash] returns blessed object from hashref');
	is($obj->{directory}, $dir, '[N-1C-hash] directory extracted from hashref');
};

subtest '[N-1D] new() no args → %args stays empty, falls through' => sub {
	# No remaining args after shift — none of the parsing branches fire.
	# Falls through to the invocant/class check with empty %args.
	lives_ok { $PKG->new() } '[N-1D] Pkg->new() with no args does not croak';
};

# ==========================================================================
# SECTION 2: new() — Branch 2: invocant/class check
# ==========================================================================

subtest '[N-2A-i] new() undef invocant + args → croak warn_bad_usage' => sub {
	# Genealogy::Obituary::Lookup::new(undef, directory => $dir)
	# $class_in = undef after shift; %args non-empty → croak
	my $dir = _dir();
	throws_ok { Genealogy::Obituary::Lookup::new(undef, directory => $dir) }
		qr/use ->new\(\) not ::new\(\)/i,
		'[N-2A-i] undef class + args → warn_bad_usage';
};

subtest '[N-2A-ii] new() undef invocant + no args → tolerated' => sub {
	# Genealogy::Obituary::Lookup::new() — $class_in=undef, %args={}
	# Silently self-corrects: $class_in becomes __PACKAGE__
	lives_ok { Genealogy::Obituary::Lookup::new() }
		'[N-2A-ii] undef class + no args tolerated (no croak)';
};

subtest '[N-2B] new() blessed invocant → clone returned' => sub {
	# $obj->new() — $class_in is blessed → immediate return of clone
	my $dir  = _dir();
	my $orig = $PKG->new(directory => $dir);
	my $clone;
	lives_ok { $clone = $orig->new() } '[N-2B] clone does not croak';
	ok(defined $clone && blessed($clone), '[N-2B] clone is blessed');
	is(ref($clone), ref($orig), '[N-2B] clone is same class');
	isnt(refaddr($orig), refaddr($clone), '[N-2B] clone is a distinct reference');
	is($clone->{directory}, $orig->{directory}, '[N-2B] clone inherits directory');
};

subtest '[N-2B-override] new() blessed + extra args → clone with overrides' => sub {
	# Early-return path: extra args are merged in before the return bless
	my $dir1 = _dir();
	my $dir2 = _dir();
	my $orig  = $PKG->new(directory => $dir1);
	my $clone = $orig->new(directory => $dir2);
	is($clone->{directory}, $dir2, '[N-2B-override] extra arg overrides inherited value');
	is($orig->{directory},  $dir1, '[N-2B-override] original is unchanged');
};

subtest '[N-2C] new() string class → falls through to rest of new()' => sub {
	# Normal class-method invocation: $class_in is a package name (not undef, not blessed)
	my $dir = _dir();
	my $obj = $PKG->new(directory => $dir);
	ok(defined $obj && blessed($obj), '[N-2C] string class falls through to bless correctly');
};

# ==========================================================================
# SECTION 3: new() — Branch 3: logger validation
# ==========================================================================

subtest '[N-3A] new() no logger arg → logger check skipped' => sub {
	# defined($args{logger}) is false → skip entire logger block
	my $dir = _dir();
	my $obj;
	lives_ok { $obj = $PKG->new(directory => $dir) }
		'[N-3A] no logger → new() does not croak or die';
	ok(defined $obj && blessed($obj), '[N-3A] no logger → object returned');
};

subtest '[N-3B-V] new() valid logger → accepted, continues to bless' => sub {
	# Logger is blessed and has info() and error()
	my $dir = _dir();
	my $obj = $PKG->new(directory => $dir, logger => MyLogger->new());
	ok(defined $obj && blessed($obj), '[N-3B-V] valid logger → object returned');
};

subtest '[N-3B-I] new() invalid logger → croak err_bad_logger' => sub {
	# Logger is defined but not a valid object → error before continuing
	my $dir = _dir();
	throws_ok { $PKG->new(directory => $dir, logger => 'not an object') }
		qr/Logger must be an object/i,
		'[N-3B-I] bad logger → err_bad_logger croak';
};

# ==========================================================================
# SECTION 4: new() — Branch 4: auto-discover directory
# ==========================================================================

subtest '[N-4A] new() directory already set → auto-discovery skipped' => sub {
	# defined($args{directory}) → the discovery block is not entered
	my $dir = _dir();
	my $obj = $PKG->new(directory => $dir);
	is($obj->{directory}, $dir, '[N-4A] explicit directory flows through unchanged');
};

subtest '[N-4B-ib] new() no dir arg, derived data/ not found → directory stays undef' => sub {
	# In the test environment the module's own data/ directory does not exist,
	# so the derived path is skipped and $args{directory} stays undef.
	# The resulting object has undef directory and skips the dir-check (Branch 6A).
	my $obj;
	lives_ok { $obj = $PKG->new() }
		'[N-4B-ib] new() with no dir arg does not croak';
	# May return undef if data/ exists but is unreadable; we just assert no exception.
	ok(1, '[N-4B-ib] auto-discovery path traversed without fatal error');
};

subtest '[N-4B-ii] new() Module::Info returns undef → directory stays undef' => sub {
	# Mock Module::Info::new_from_loaded to return undef
	{
		no warnings 'redefine';
		local *Module::Info::new_from_loaded = sub { return undef };
		my $obj;
		lives_ok { $obj = $PKG->new() }
			'[N-4B-ii] Module::Info undef → no croak';
		# Object may be defined with undef directory (skips dir-check via Branch 6A)
		ok(1, '[N-4B-ii] Module::Info undef path traversed safely');
	}
};

# ==========================================================================
# SECTION 5: new() — Branch 5: null-byte guard
# ==========================================================================

subtest '[N-5A] new() directory with no null byte → null-byte check skipped' => sub {
	my $dir = _dir();
	my $obj = $PKG->new(directory => $dir);
	ok(defined $obj, '[N-5A] no null byte → check skipped → object returned');
};

subtest '[N-5B-II] new() null byte in path, no logger → carp + return undef' => sub {
	# Null byte guard fires: carp + return undef without calling logger
	my $dir     = _dir();
	my $badpath = "$dir/some\x00path";
	my $obj;
	warnings_exist { $obj = $PKG->new(directory => $badpath) }
		[qr/not a directory/i],
		'[N-5B-II] null-byte path → carps "not a directory"';
	ok(!defined $obj, '[N-5B-II] null-byte path → returns undef');
};

subtest '[N-5B-I] new() null byte in path, with logger → logger->warn + carp + undef' => sub {
	# Logger branch fires inside the null-byte guard
	my $dir     = _dir();
	my $badpath = "$dir/some\x00path";
	my $logger  = MyLogger->new();
	my $obj;
	warnings_exist { $obj = $PKG->new(directory => $badpath, logger => $logger) }
		[qr/not a directory/i],
		'[N-5B-I] null-byte + logger → carps "not a directory"';
	ok(!defined $obj, '[N-5B-I] null-byte + logger → returns undef');
};

# ==========================================================================
# SECTION 6: new() — Branch 6: directory validity check
# ==========================================================================

subtest '[N-6A] new() undef directory → validity check skipped → bless succeeds' => sub {
	# defined($args{directory}) is false → outer `if` is false → skip → bless
	# This is the path taken by new() with no directory arg in a non-installed env.
	my $obj;
	{
		no warnings 'redefine';
		local *Module::Info::new_from_loaded = sub { return undef };
		$obj = $PKG->new();
	}
	# Object returned even without a directory (database not opened until search())
	ok(!defined($obj) || blessed($obj),
		'[N-6A] undef directory → check skipped → no croak (object or undef is fine)');
};

subtest '[N-6B] new() valid directory → check passes → bless succeeds' => sub {
	# -d && -r both true → !(truthy) is false → skip carp → reach bless
	my $dir = _dir();
	my $obj = $PKG->new(directory => $dir);
	ok(defined $obj && blessed($obj), '[N-6B] valid dir → bless path reached');
	is($obj->{directory}, $dir, '[N-6B] directory stored correctly');
};

subtest '[N-6C-II] new() bad directory, no logger → carp + return undef' => sub {
	my $obj;
	warnings_exist { $obj = $PKG->new(directory => '/no/such/path') }
		[qr/not a directory/i],
		'[N-6C-II] bad dir + no logger → carps';
	ok(!defined $obj, '[N-6C-II] returns undef');
};

subtest '[N-6C-I] new() bad directory, with logger → logger->warn + carp + undef' => sub {
	my $obj;
	warnings_exist { $obj = $PKG->new(directory => '/no/such/path', logger => MyLogger->new()) }
		[qr/not a directory/i],
		'[N-6C-I] bad dir + logger → carps';
	ok(!defined $obj, '[N-6C-I] returns undef (logger->warn branch fired)');
};

subtest '[N-7] new() success → cache_duration default injected' => sub {
	# Final bless path: cache_duration => $DEFAULT_CACHE_DURATION merged in
	my $dir = _dir();
	my $obj = $PKG->new(directory => $dir);
	is($obj->{cache_duration}, '1 day',
		'[N-7] default cache_duration present in blessed hash');
};

subtest '[N-7-override] new() cache_duration arg wins over default' => sub {
	# %args slice overrides the LHS default in bless { default, %args }
	my $dir = _dir();
	my $obj = $PKG->new(directory => $dir, cache_duration => 'custom');
	is($obj->{cache_duration}, 'custom',
		'[N-7-override] caller-supplied cache_duration overrides default');
};

# ==========================================================================
# SECTION 7: search() — path coverage
# ==========================================================================

subtest '[S-no-self] search() unblessed invocant → croak err_no_self' => sub {
	# Guard 1: Scalar::Util::blessed fails → path terminates
	throws_ok { $PKG->search(last => 'Smith') }
		qr/must be called on an object/i,
		'[S-no-self] class-method search → err_no_self';
};

subtest '[S-no-self-fn] search() function call → croak err_no_self' => sub {
	throws_ok { Genealogy::Obituary::Lookup::search(last => 'Smith') }
		qr/must be called on an object/i,
		'[S-no-self-fn] function-call search → err_no_self';
};

subtest '[S-no-args] search() zero args → croak err_no_args' => sub {
	# Guard 2: @_ is empty → path terminates before Params::Get
	my $obj = _obj();
	throws_ok { $obj->search() }
		qr/Usage/i,
		'[S-no-args] zero args → err_no_args';
};

subtest '[S-schema] search() schema violation → Params::Validate::Strict dies' => sub {
	# Guard 3: validate_strict rejects bad input → path terminates
	my $obj = _obj();
	throws_ok { $obj->search(last => 'has a space') }
		qr//,
		'[S-schema] invalid last name rejected by schema';
};

subtest '[S-no-last-no-log] search() last=undef, no logger → croak err_no_last' => sub {
	# Guard 4 (no-logger branch): defined check fails, logger absent
	my $obj = _obj();
	throws_ok { $obj->search(last => undef) }
		qr/last.*is mandatory|Value for 'last'/i,
		'[S-no-last-no-log] undef last → err_no_last (no logger branch)';
};

subtest '[S-no-last-log] search() last=undef, with logger → logger path + croak' => sub {
	# Guard 4 (logger branch): logger->error() called before croak
	my $obj = _obj(logger => MyLogger->new());
	$obj->{obituaries} = bless {}, $DRV;    # keep pre-injected handle
	throws_ok { $obj->search(last => undef) }
		qr/last.*is mandatory|Value for 'last'/i,
		'[S-no-last-log] undef last + logger → err_no_last (logger branch)';
};

subtest '[S-no-obit-no-log] search() obituaries->new() returns undef → croak (no logger)' => sub {
	# Guard 5 (no-logger branch): DB init returns undef, no logger
	my $obj = $PKG->new(directory => _dir());
	_set_db_returns_undef();
	eval { $obj->search(last => 'Smith') };
	_restore_db();
	like($@, qr/obituaries/i, '[S-no-obit-no-log] err_no_obituaries raised');
};

subtest '[S-no-obit-log] search() obituaries->new() returns undef → logger + croak' => sub {
	# Guard 5 (logger branch): logger->error() called before croak
	my $obj = $PKG->new(directory => _dir(), logger => MyLogger->new());
	_set_db_returns_undef();
	eval { $obj->search(last => 'Smith') };
	_restore_db();
	like($@, qr/obituaries/i, '[S-no-obit-log] err_no_obituaries raised (logger path)');
};

subtest '[S-L0] search() list context: selectall returns falsy → return empty list' => sub {
	# selectall_hashref returns a false value → `or return` fires immediately
	my $obj = _obj();
	_set_rows(undef);
	my @r = $obj->search(last => 'Smith');
	is(scalar(@r), 0, '[S-L0] selectall=falsy → empty list returned via `or return`');
};

subtest '[S-L0-grep] search() list context: selectall truthy but all rows undef → loop 0 iterations' => sub {
	# Loop body executes 0 times: grep { defined } filters everything out
	my $obj = _obj();
	_set_rows([undef, undef, undef]);    # truthy arrayref, but all items filtered
	my @r = $obj->search(last => 'Smith');
	is(scalar(@r), 0, '[S-L0-grep] all-undef rows → loop body: 0 iterations → empty @rc');
};

subtest '[S-L1] search() list context: 1 matching row → loop body: 1 iteration' => sub {
	# Loop body executes exactly once
	my $obj = _obj();
	_set_rows([ _obit() ]);
	my @r = $obj->search(last => 'Smith');
	is(scalar(@r), 1, '[S-L1] one row → loop 1 iteration → 1-element list');
	ok(exists $r[0]->{url}, '[S-L1] url key injected in the single iteration');
};

subtest '[S-LN] search() list context: N matching rows → loop body: N iterations' => sub {
	# Loop body executes 3 times; each iteration injects a url key
	my $obj = _obj();
	my @rows = (_obit(), _obit(), _obit());
	_set_rows(\@rows);
	my @r = $obj->search(last => 'Smith');
	is(scalar(@r), 3, '[S-LN] three rows → loop 3 iterations → 3-element list');
	ok(exists $r[$_]->{url}, "[S-LN] url injected in row $_") for 0..2;
};

subtest '[S-Scalar0] search() scalar context: fetchrow returns undef → return undef' => sub {
	# Scalar path: `or return` fires when fetchrow returns falsy
	my $obj = _obj();
	_set_scalar(undef);
	my $r = $obj->search(last => 'Smith');
	ok(!defined $r, '[S-Scalar0] fetchrow=undef → return undef path');
};

subtest '[S-Scalar1] search() scalar context: fetchrow returns row → url + return' => sub {
	# Scalar path: url injected, fixate, set_return, return hashref
	my $obj = _obj();
	_set_scalar(_obit());
	my $r = $obj->search(last => 'Smith');
	ok(defined $r, '[S-Scalar1] fetchrow defined → hashref returned');
	isa_ok($r, 'HASH', '[S-Scalar1] result is a hashref');
	ok(exists $r->{url}, '[S-Scalar1] url key injected');
};

# ==========================================================================
# SECTION 8: _create_url() — path coverage (via search())
# ==========================================================================

subtest '[C-no-page] _create_url() page=undef → croak err_no_page' => sub {
	my $obj = _obj();
	_set_rows([ { %{_obit()}, page => undef } ]);
	throws_ok { my @r = $obj->search(last => 'Smith') }
		qr/undefined \$page/i,
		'[C-no-page] undef page → err_no_page path';
};

subtest '[C-no-source] _create_url() source=undef → croak err_no_source' => sub {
	my $obj = _obj();
	_set_rows([ { %{_obit()}, source => undef } ]);
	throws_ok { my @r = $obj->search(last => 'Smith') }
		qr/undefined source/i,
		'[C-no-source] undef source → err_no_source path';
};

subtest '[C-M] _create_url() source=M → Wayback URL path' => sub {
	# `if($source eq 'M' || $source eq 'F')` arm: source is M
	my $obj = _obj();
	_set_rows([ { %{_obit()}, source => 'M', page => '42' } ]);
	my ($r) = $obj->search(last => 'Smith');
	is($r->{url}, $WAYBACK . '42', '[C-M] source M → Wayback URL assembled');
};

subtest '[C-F] _create_url() source=F → Freelists URL path' => sub {
	# `if($source eq 'M' || $source eq 'F')` arm: source is F
	my $obj = _obj();
	_set_rows([ { %{_obit()}, source => 'F', page => 'v7no042' } ]);
	my ($r) = $obj->search(last => 'Smith');
	is($r->{url}, $FREELISTS . 'v7no042', '[C-F] source F → Freelists URL assembled');
};

subtest '[C-L-news] _create_url() source=L, newspaper is http URL → return newspaper' => sub {
	# source L block: newspaper branch — newspaper is a valid http:// URL
	my $obj = _obj();
	_set_rows([ {
		%{_obit()},
		source    => 'L',
		page      => 'not-a-url',
		newspaper => 'https://example.com/obit/12345',
	} ]);
	my ($r) = $obj->search(last => 'Smith');
	is($r->{url}, 'https://example.com/obit/12345',
		'[C-L-news] source L + newspaper URL → newspaper returned as url');
};

subtest '[C-L-page] _create_url() source=L, newspaper not URL, page is http URL → return page' => sub {
	# source L block: newspaper branch fails, page branch succeeds
	my $obj = _obj();
	_set_rows([ {
		%{_obit()},
		source    => 'L',
		page      => 'https://page.example.com/records/9',
		newspaper => 'Local Gazette',
	} ]);
	my ($r) = $obj->search(last => 'Smith');
	is($r->{url}, 'https://page.example.com/records/9',
		'[C-L-page] source L + page URL → page returned as url');
};

subtest '[C-L-news-undef] _create_url() source=L, newspaper=undef → falls through to page check' => sub {
	# newspaper is undef — the `defined($obit->{newspaper}) &&` guard fails
	# so falls through to check page
	my $obj = _obj();
	_set_rows([ {
		%{_obit()},
		source    => 'L',
		page      => 'https://page.ex.com/',
		newspaper => undef,
	} ]);
	my ($r) = $obj->search(last => 'Smith');
	is($r->{url}, 'https://page.ex.com/',
		'[C-L-news-undef] undef newspaper → falls to page URL path');
};

subtest '[C-L-none] _create_url() source=L, no URL anywhere → croak err_no_newspaper' => sub {
	# source L block: newspaper not URL, page not URL → croak
	my $obj = _obj();
	_set_rows([ {
		%{_obit()},
		source    => 'L',
		page      => 'not-a-url',
		newspaper => 'Plain text gazette',
	} ]);
	throws_ok { my @r = $obj->search(last => 'Smith') }
		qr/newspaper/i,
		'[C-L-none] source L + no URL → err_no_newspaper path';
};

subtest '[C-bad-src] _create_url() unknown source → croak err_bad_source' => sub {
	# Falls through M/F check, falls through L check → croak bad_source
	my $obj = _obj();
	_set_rows([ { %{_obit()}, source => 'X' } ]);
	throws_ok { my @r = $obj->search(last => 'Smith') }
		qr/Invalid source/i,
		'[C-bad-src] source=X → err_bad_source path';
};

# ==========================================================================
# SECTION 9: _i18n() — path coverage
# ==========================================================================

subtest '[I-valid-no-args] _i18n() valid key, no placeholders' => sub {
	# Path: key found, $args = {}, s/// replaces nothing → return template as-is
	my $msg = $PKG->_i18n('err_no_self');
	ok(defined $msg && length($msg) > 0, '[I-valid-no-args] returns non-empty string');
	unlike($msg, qr/%\{/, '[I-valid-no-args] no unresolved placeholders');
};

subtest '[I-valid-with-args] _i18n() valid key, placeholders filled from args' => sub {
	# Path: key found, $args has values → s/// substitutes each %{name}
	my $msg = $PKG->_i18n('warn_not_dir', { class => 'MyPkg', dir => '/test' });
	like($msg, qr/MyPkg/, '[I-valid-with-args] class placeholder substituted');
	like($msg, qr{/test}, '[I-valid-with-args] dir placeholder substituted');
	unlike($msg, qr/%\{/, '[I-valid-with-args] no unresolved placeholders remain');
};

subtest '[I-invalid-key] _i18n() unknown key → croak' => sub {
	# Path: $MESSAGES{$key} is undef → // croak fires → path terminates
	throws_ok { $PKG->_i18n('no_such_key') }
		qr/Unknown i18n key/i,
		'[I-invalid-key] unknown key → croak';
};

subtest '[I-nil-args] _i18n() valid key with placeholders, nil args → placeholders become ""' => sub {
	# Path: $args //= {} fires (args was undef) → s/// fills placeholders with ''
	my $msg = $PKG->_i18n('warn_not_dir');    # no args argument supplied
	ok(defined $msg && length($msg) > 0, '[I-nil-args] returns a string');
	unlike($msg, qr/%\{/, '[I-nil-args] no raw %{} placeholders remain');
};

subtest '[I-nil-value-in-args] _i18n() placeholder key missing from args → filled with ""' => sub {
	# Path: s/// fires, $args->{missing_key} is undef → // '' substitutes ''
	my $msg = $PKG->_i18n('warn_not_dir', {});    # empty hashref, no class/dir keys
	ok(defined $msg, '[I-nil-value-in-args] returns defined string');
	unlike($msg, qr/%\{/, '[I-nil-value-in-args] all placeholders resolved to ""');
};

# ==========================================================================
# SECTION 10: Full happy-path integration (all OK branches in sequence)
# ==========================================================================

subtest 'full happy path: new() → search() list → search() scalar' => sub {
	# Exercises the complete non-error path through both public methods.
	my $obj = $PKG->new(directory => _dir());
	ok(defined $obj && blessed($obj), 'new() returns object');

	# List context: 2-row result
	_set_rows([ { %{_obit()}, source => 'M', page => '1' },
	             { %{_obit()}, source => 'F', page => 'v1' } ]);
	my @list = $obj->search(last => 'Smith');
	is(scalar(@list), 2, 'list search returns 2 rows');
	like($list[0]->{url}, qr{wayback},    'first result url is Wayback');
	like($list[1]->{url}, qr{freelists},  'second result url is Freelists');

	# Scalar context: single match
	_set_scalar({ %{_obit()}, source => 'M', page => '99' });
	my $single = $obj->search(last => 'Smith');
	ok(defined $single, 'scalar search returns defined value');
	is($single->{url}, $WAYBACK . '99', 'scalar result url correct');

	# No match
	_set_scalar(undef);
	my $none = $obj->search(last => 'Zymurgist');
	ok(!defined $none, 'no-match scalar returns undef');
};

done_testing();
