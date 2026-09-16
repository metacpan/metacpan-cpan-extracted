#!/usr/bin/env perl

# Black-box unit tests for the public API of Genealogy::Obituary::Lookup.
#
# Covers every documented message and return state for new() and search() as
# specified in the module POD.  The test concludes with a ledger assertion that
# fails explicitly for any POD-documented state that was not exercised.
#
# DB strategy: Genealogy::Obituary::Lookup::obituaries is stubbed in a BEGIN
# block (same technique as t/function.t).  The real obituaries.pm only sets
# @ISA and never redefines these stubs, so they survive the require().

use strict;
use warnings;

use File::Temp   qw(tempdir);
use Readonly;
use Scalar::Util qw(blessed);
use Test::Mockingbird;
use Test::Most;
use Test::Returns;

use lib 'lib';
use lib 't/lib';
use MyLogger;

# ---------------------------------------------------------------------------
# Constants — no magic numbers or strings in the test body
# ---------------------------------------------------------------------------
Readonly::Scalar my $PKG => 'Genealogy::Obituary::Lookup';
Readonly::Scalar my $DRV => 'Genealogy::Obituary::Lookup::obituaries';

Readonly::Scalar my $WAYBACK_BASE =>
	'https://wayback.archive-it.org/20669/20231102044925/https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit&page=';
Readonly::Scalar my $FREELISTS_BASE =>
	'https://www.freelists.org/post/obitdailytimes/Obituary-Daily-Times-';

Readonly::Scalar my $PAGE_M => 99;
Readonly::Scalar my $PAGE_F => 'v26no001';
Readonly::Scalar my $URL_M  => $WAYBACK_BASE  . $PAGE_M;
Readonly::Scalar my $URL_F  => $FREELISTS_BASE . $PAGE_F;
Readonly::Scalar my $URL_L  => 'https://funeral-notices.co.uk/notice/test/9999999';

# ---------------------------------------------------------------------------
# API ledger: every message key and return state documented in the POD.
# Each subtest deletes the relevant entry as it exercises that code path.
# The final assertion confirms the ledger is empty (nothing was missed).
# ---------------------------------------------------------------------------
my %LEDGER = (
	# new() — messages (POD section "MESSAGES" under =head2 new)
	'warn_not_dir'       => 'new(): bad directory carps and returns undef',
	'warn_bad_usage'     => 'new(): ::new() called as function with args croaks',
	'err_bad_logger'     => 'new(): logger lacking info()/error() croaks',

	# new() — return states (POD "OUTPUT" under =head2 new)
	'new_success'        => 'new(): blessed Lookup object on valid directory',
	'new_undef'          => 'new(): undef when directory is not readable',
	'new_clone'          => 'new(): $obj->new() returns a distinct blessed clone',
	'new_single_arg'     => 'new(): single bare string arg treated as directory',
	'new_fn_no_args'     => 'new(): ::new() with no args is tolerated',

	# search() — messages (POD "MESSAGES" under =head2 search)
	'err_no_self'        => 'search(): non-object invocant → croak',
	'err_no_args'        => 'search(): zero args → croak',
	'err_no_last'        => 'search(): missing last name → croak',
	'err_no_obituaries'  => 'search(): obituaries->new() fails → croak',
	'err_no_page'        => 'search(): undef page in row → croak',
	'err_no_source'      => 'search(): undef source in row → croak',
	'err_bad_source'     => 'search(): unknown source value → croak',
	'err_no_newspaper'   => 'search(): source L with no URL → croak',

	# search() — return states (POD "OUTPUT" under =head2 search)
	'list_match_M'       => 'search() list: source M row has Wayback URL',
	'list_match_F'       => 'search() list: source F row has freelists URL',
	'list_no_match'      => 'search() list: no matching rows → empty list',
	'list_strips_undef'  => 'search() list: undef DB sentinels are filtered out',
	'scalar_match'       => 'search() scalar: matching row → hashref with url',
	'scalar_no_match'    => 'search() scalar: no match → undef',
	'url_source_L_news'  => 'source L: newspaper URL used when it is https://',
	'url_source_L_page'  => 'source L: page URL used when newspaper is not https://',
);

# ---------------------------------------------------------------------------
# Stub the DB driver before the module loads it at compile time.
# ---------------------------------------------------------------------------
BEGIN {
	package Genealogy::Obituary::Lookup::obituaries;
	our $_mock_rows   = [];
	our $_mock_scalar = undef;
	sub new               { bless {}, shift }
	sub selectall_hashref { return $_mock_rows }
	sub fetchrow_hashref  { return $_mock_scalar }
}

BEGIN { use_ok('Genealogy::Obituary::Lookup') }

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
# Build a fresh Lookup object pointing at a throwaway tempdir.
sub _obj {
	my %extra = @_;
	my $dir   = tempdir(CLEANUP => 1);
	return $PKG->new(directory => $dir, %extra);
}

# Prime the DB stub for list-context calls.
sub _set_rows {
	$Genealogy::Obituary::Lookup::obituaries::_mock_rows = shift;
}

# Prime the DB stub for scalar-context calls.
sub _set_scalar {
	$Genealogy::Obituary::Lookup::obituaries::_mock_scalar = shift;
}

# ===========================================================================
# new() subtests
# ===========================================================================

subtest 'new(): explicit valid directory returns blessed object' => sub {
	my $obj = _obj();
	ok(defined $obj,  'new() returns defined value for valid directory');
	isa_ok($obj, $PKG, 'returned value is a blessed Lookup object');
	delete $LEDGER{'new_success'};
};

subtest 'new(): single bare-string arg treated as directory' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $obj = $PKG->new($dir);
	ok(defined $obj,  'new($dir) succeeds');
	isa_ok($obj, $PKG, 'returned object is a Lookup instance');
	delete $LEDGER{'new_single_arg'};
};

subtest 'new(): bad directory emits warn_not_dir and returns undef' => sub {
	# Carp::carp emits two warnings (call site + caller frame), so
	# warnings_exist (any-match) is used rather than warning_like (exact-one).
	my $obj;
	warnings_exist { $obj = $PKG->new(directory => '/no/such/path/$$') }
		[qr/is not a directory/],
		'new() emits the warn_not_dir carp warning for a non-existent directory';
	ok(!defined $obj, 'new() returns undef when the directory does not exist');
	delete $LEDGER{'warn_not_dir'};
	delete $LEDGER{'new_undef'};
};

subtest 'new(): ::new() as function with no args is tolerated' => sub {
	# POD says: "If called as a function (::new) with no args, tolerate and
	# self-correct; croak if args were given."
	my $obj;
	lives_ok { $obj = Genealogy::Obituary::Lookup::new() }
		'::new() with no args does not croak';
	delete $LEDGER{'new_fn_no_args'};
};

subtest 'new(): ::new() as function with args croaks (warn_bad_usage)' => sub {
	# Trigger by passing undef as the first arg so $class_in is undef,
	# then providing extra key-value args to make %args non-empty.
	my $dir = tempdir(CLEANUP => 1);
	throws_ok { Genealogy::Obituary::Lookup::new(undef, directory => $dir) }
		qr/use ->new\(\)/,
		'::new() as function with args croaks with warn_bad_usage';
	delete $LEDGER{'warn_bad_usage'};
};

subtest 'new(): bad logger croaks (err_bad_logger)' => sub {
	# Logger validation runs before Object::Configure can wrap the value, so
	# a blessed object without info()/error() is correctly rejected.
	throws_ok { _obj(logger => bless {}, 'BadLogger') }
		qr/Logger must/,
		'new() croaks with err_bad_logger when the logger lacks the required interface';
	delete $LEDGER{'err_bad_logger'};
};

subtest 'new(): $obj->new() returns a distinct blessed clone' => sub {
	my $orig  = _obj();
	my $clone = $orig->new();
	ok(defined $clone,    'clone() returns a defined value');
	isa_ok($clone, $PKG,  'clone is a Lookup instance');
	isnt($orig, $clone,   'clone is a distinct reference, not the same object');
	delete $LEDGER{'new_clone'};
};

subtest 'new(): clone can override an inherited field' => sub {
	my $dir2  = tempdir(CLEANUP => 1);
	my $orig  = _obj();
	my $clone = $orig->new(directory => $dir2);
	ok(defined $clone,    'clone with override is defined');
	isa_ok($clone, $PKG,  'clone with override is a Lookup instance');
};

# ===========================================================================
# search() — argument-validation subtests
# ===========================================================================

subtest 'search(): non-object invocant croaks (err_no_self)' => sub {
	throws_ok {
		Genealogy::Obituary::Lookup::search('not_an_object', last => 'Smith')
	} qr/must be called on an object/,
		'search() as a plain function croaks with err_no_self message';
	delete $LEDGER{'err_no_self'};
};

subtest 'search(): zero arguments croaks (err_no_args)' => sub {
	my $obj = _obj();
	throws_ok { $obj->search() }
		qr/Usage:/,
		'search() with no args croaks with the usage message';
	delete $LEDGER{'err_no_args'};
};

subtest 'search(): missing last name croaks (err_no_last)' => sub {
	# Params::Validate::Strict raises "Required parameter 'last' is missing".
	my $obj = _obj();
	throws_ok { $obj->search(first => 'John') }
		qr/last.*missing|mandatory/i,
		'search() without a last name croaks';
	delete $LEDGER{'err_no_last'};
};

# ===========================================================================
# search() — DB initialisation failure
# ===========================================================================

subtest 'search(): obituaries->new() fails → croak (err_no_obituaries)' => sub {
	# Simulate a corrupt or missing SQLite file by returning undef from new().
	my $guard = mock_scoped($DRV, 'new', sub { undef });
	my $obj   = _obj();
	throws_ok { $obj->search(last => 'Smith') }
		qr/Can't open the obituaries database/,
		'search() croaks with err_no_obituaries when the DB cannot be opened';
	delete $LEDGER{'err_no_obituaries'};
};

# ===========================================================================
# search() — list-context return states
# ===========================================================================

subtest 'search() list: source M row has Wayback URL' => sub {
	_set_rows([{ first => 'Alice', last => 'Smith', source => 'M', page => $PAGE_M }]);
	my @res = _obj()->search(last => 'Smith');
	is(scalar @res, 1,        'one row returned');
	ok(exists $res[0]{url},   'result has a url key');
	is($res[0]{url}, $URL_M,  'source M URL is the expected Wayback Machine URL');
	delete $LEDGER{'list_match_M'};
};

subtest 'search() list: source F row has freelists URL' => sub {
	_set_rows([{ first => 'Bob', last => 'Jones', source => 'F', page => $PAGE_F }]);
	my @res = _obj()->search(last => 'Jones');
	is(scalar @res, 1,        'one row returned');
	ok(exists $res[0]{url},   'result has a url key');
	is($res[0]{url}, $URL_F,  'source F URL is the expected freelists URL');
	delete $LEDGER{'list_match_F'};
};

subtest 'search() list: no matching rows returns empty list' => sub {
	_set_rows([]);
	my @res = _obj()->search(last => 'Xyzzy');
	is(scalar @res, 0, 'empty DB result yields an empty list');
	delete $LEDGER{'list_no_match'};
};

subtest 'search() list: undef DB sentinels are stripped from results' => sub {
	# Database::Abstraction can return undef sentinels; search() must filter them.
	_set_rows([
		{ first => 'Carol', last => 'Brown', source => 'M', page => 1 },
		undef,
	]);
	my @res = _obj()->search(last => 'Brown');
	is(scalar @res, 1,   'undef sentinel is removed');
	ok(defined $res[0],  'remaining element is defined');
	delete $LEDGER{'list_strips_undef'};
};

# ===========================================================================
# search() — scalar-context return states
# ===========================================================================

subtest 'search() scalar: returns hashref with url on match' => sub {
	_set_scalar({ first => 'Dave', last => 'Green', source => 'M', page => $PAGE_M });
	my $res = _obj()->search(last => 'Green');
	ok(defined $res,         'scalar context returns a defined value on match');
	isa_ok($res, 'HASH',     'scalar result is a hashref');
	ok(exists $res->{url},   'scalar result carries a url key');
	is($res->{url}, $URL_M,  'source M scalar URL is the expected Wayback URL');
	delete $LEDGER{'scalar_match'};
};

subtest 'search() scalar: no match returns undef' => sub {
	_set_scalar(undef);
	my $res = _obj()->search(last => 'Xyzzy');
	ok(!defined $res, 'scalar context returns undef when no row matches');
	delete $LEDGER{'scalar_no_match'};
};

# ===========================================================================
# search() / _create_url — error paths (driven through list context)
# "my @r = ..." forces list context so the list path in search() is taken,
# which is where _create_url() is invoked row-by-row.
# ===========================================================================

subtest 'search(): undef page in DB row croaks (err_no_page)' => sub {
	_set_rows([{ first => 'X', last => 'Y', source => 'M', page => undef }]);
	my $obj = _obj();
	throws_ok { my @r = $obj->search(last => 'Y') }
		qr/undefined \$page/,
		'search() propagates err_no_page croak when a row has no page';
	delete $LEDGER{'err_no_page'};
};

subtest 'search(): undef source in DB row croaks (err_no_source)' => sub {
	_set_rows([{ first => 'X', last => 'Y', source => undef, page => 1 }]);
	my $obj = _obj();
	throws_ok { my @r = $obj->search(last => 'Y') }
		qr/undefined source/,
		'search() propagates err_no_source croak when a row has no source';
	delete $LEDGER{'err_no_source'};
};

subtest 'search(): unknown source value croaks (err_bad_source)' => sub {
	_set_rows([{ first => 'X', last => 'Y', source => 'Z', page => 1 }]);
	my $obj = _obj();
	throws_ok { my @r = $obj->search(last => 'Y') }
		qr/Invalid source.*Z/,
		'search() propagates err_bad_source, naming the invalid source value';
	delete $LEDGER{'err_bad_source'};
};

subtest 'search(): source L with no valid URL croaks (err_no_newspaper)' => sub {
	_set_rows([{
		first     => 'X',
		last      => 'Y',
		source    => 'L',
		page      => 'not-a-url',
		newspaper => 'The Daily Bugle',
	}]);
	my $obj = _obj();
	throws_ok { my @r = $obj->search(last => 'Y') }
		qr/undefined newspaper/,
		'search() propagates err_no_newspaper for source L with no https:// URL';
	delete $LEDGER{'err_no_newspaper'};
};

subtest 'search(): source L uses newspaper URL when it begins with https://' => sub {
	_set_rows([{
		first     => 'X',
		last      => 'Y',
		source    => 'L',
		page      => 'https://fallback.example.com/obit/1',
		newspaper => $URL_L,
	}]);
	my ($res) = _obj()->search(last => 'Y');
	is($res->{url}, $URL_L,
		'source L returns the newspaper URL when it starts with https://');
	delete $LEDGER{'url_source_L_news'};
};

subtest 'search(): source L falls back to page URL when newspaper is not https://' => sub {
	_set_rows([{
		first     => 'X',
		last      => 'Y',
		source    => 'L',
		page      => $URL_L,
		newspaper => 'The Local Gazette',
	}]);
	my ($res) = _obj()->search(last => 'Y');
	is($res->{url}, $URL_L,
		'source L falls back to the page URL when newspaper is not an https:// URL');
	delete $LEDGER{'url_source_L_page'};
};

# ===========================================================================
# Global state integrity
# ===========================================================================

subtest 'search() does not clobber $_' => sub {
	_set_rows([{ first => 'X', last => 'Smith', source => 'M', page => 1 }]);
	local $_ = 'sentinel';
	my @r = _obj()->search(last => 'Smith');
	is($_, 'sentinel', 'search() leaves $_ unchanged after a successful query');
};

subtest 'new() does not clobber $_' => sub {
	local $_ = 'sentinel';
	my $obj = _obj();
	is($_, 'sentinel', 'new() leaves $_ unchanged after constructing an object');
};

# ===========================================================================
# Returns schema validation
# ===========================================================================

subtest 'search() scalar result satisfies hashref Returns schema' => sub {
	_set_scalar({ first => 'X', last => 'Smith', source => 'M', page => $PAGE_M });
	my $res = _obj()->search(last => 'Smith');
	returns_is($res, { type => 'hashref' },
		'scalar search() result satisfies the hashref Returns schema');
};

subtest 'search() list result can be described as an arrayref' => sub {
	_set_rows([
		{ first => 'A', last => 'B', source => 'M', page => 1 },
		{ first => 'C', last => 'D', source => 'F', page => 'v25no001' },
	]);
	my @res = _obj()->search(last => 'B');
	returns_is(\@res, { type => 'arrayref' },
		'list search() results coerce to a valid arrayref');
};

# ===========================================================================
# API ledger — must be the last subtest
# Fails with an explicit message for every documented state that was skipped.
# ===========================================================================

subtest 'API ledger: all documented messages and return states exercised' => sub {
	my @remaining = sort keys %LEDGER;
	if(@remaining) {
		fail("UNTESTED: $_ — $LEDGER{$_}") for @remaining;
	} else {
		pass('All documented messages and return states have been exercised');
	}
	done_testing(@remaining ? scalar @remaining : 1);
};

done_testing();
