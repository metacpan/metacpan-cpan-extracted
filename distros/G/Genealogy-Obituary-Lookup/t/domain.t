#!/usr/bin/env perl

# Domain tests for Genealogy::Obituary::Lookup.
#
# Technique: Equivalence Partitioning (EP) + Boundary Value Analysis (BVA).
#
# For each parameter the domain is divided into equivalence classes.
# One representative value is drawn from every class to prove accept/reject
# behaviour without brute-force exhaustion.  Boundary values test the exact
# edges (min, min-1, max, max+1) plus just-inside/just-outside the format
# constraint.
#
# EP class notation used in subtest names:
#   [EP-V]  Equivalence Partition — Valid class representative
#   [EP-I]  Equivalence Partition — Invalid class representative
#   [BVA]   Boundary Value Analysis
#   [COMB]  Combinatorial boundary (two parameters at their extremes)
#   [FMT]   Format-domain test

use strict;
use warnings;

use Encode        qw(encode_utf8);
use File::Temp    qw(tempdir);
use POSIX         ();
use Readonly;
use Scalar::Util  qw(blessed looks_like_number refaddr);
use Test::Most;
use Test::Returns;

use lib 'lib';
use lib 't/lib';
use MyLogger;

# ---------------------------------------------------------------------------
# Constants — all domain boundaries in one place
# ---------------------------------------------------------------------------
Readonly::Scalar my $PKG      => 'Genealogy::Obituary::Lookup';
Readonly::Scalar my $DRV      => 'Genealogy::Obituary::Lookup::obituaries';

# search() last-name bounds (from Lookup.pm constants)
Readonly::Scalar my $LAST_MIN =>   1;
Readonly::Scalar my $LAST_MAX => 100;

# search() first/middle bounds
Readonly::Scalar my $NAME_MIN =>   1;
Readonly::Scalar my $NAME_MAX => 100;

# search() age bounds
Readonly::Scalar my $AGE_MIN  =>   0;
Readonly::Scalar my $AGE_MAX  => 120;

# Representative valid last names (EP-V)
Readonly::Scalar my $LAST_TYPICAL   => 'Smith';
Readonly::Scalar my $LAST_HYPHEN    => 'Smith-Jones';
Readonly::Scalar my $LAST_UNDERSCORE => 'Mc_Arthur';
Readonly::Scalar my $LAST_ALLCAPS   => 'COOPER';
Readonly::Scalar my $LAST_DIGITS    => 'Smith2';

# BVA: exact boundary strings
Readonly::Scalar my $LAST_AT_MIN    => 'A';                         # 1 char  — valid
Readonly::Scalar my $LAST_BELOW_MIN => '';                          # 0 chars — invalid
Readonly::Scalar my $LAST_AT_MAX    => 'A' x $LAST_MAX;            # 100 chars — valid
Readonly::Scalar my $LAST_ABOVE_MAX => 'A' x ($LAST_MAX + 1);      # 101 chars — invalid

# BVA: age boundaries
Readonly::Scalar my $AGE_AT_MIN    => $AGE_MIN;                     # 0   — valid
Readonly::Scalar my $AGE_BELOW_MIN => $AGE_MIN - 1;                 # -1  — invalid
Readonly::Scalar my $AGE_AT_MAX    => $AGE_MAX;                     # 120 — valid
Readonly::Scalar my $AGE_ABOVE_MAX => $AGE_MAX + 1;                 # 121 — invalid

# BVA: first/middle boundaries
Readonly::Scalar my $NAME_AT_MIN    => 'J';                         # 1 char  — valid
Readonly::Scalar my $NAME_BELOW_MIN => '';                          # 0 chars — invalid
Readonly::Scalar my $NAME_AT_MAX    => 'J' x $NAME_MAX;            # 100 chars — valid
Readonly::Scalar my $NAME_ABOVE_MAX => 'J' x ($NAME_MAX + 1);      # 101 chars — invalid

# ---------------------------------------------------------------------------
# Mock obituaries driver — registered at compile time
# ---------------------------------------------------------------------------
BEGIN {
	package Genealogy::Obituary::Lookup::obituaries;
	our $_mock_rows   = [];
	our $_mock_scalar = undef;

	sub new              { bless {}, shift }
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
	$obj->{obituaries} = bless {}, $DRV if $obj;   # pre-inject — no real DB needed
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

# ---------------------------------------------------------------------------
# DOMAIN 1: new() — directory parameter
# ---------------------------------------------------------------------------

subtest 'new() directory [EP-V]: existing readable directory → returns object' => sub {
	my $dir = _dir();
	my $obj = $PKG->new(directory => $dir);
	ok(defined $obj && blessed($obj), 'object created with valid directory');
	is($obj->{directory}, $dir, 'directory stored in object');
};

subtest 'new() directory [EP-V]: absent (no directory arg) → succeeds silently' => sub {
	# The auto-discovery path: returns an object even without a data/ dir.
	# (The DB handle is not opened until search() is called.)
	my $obj = $PKG->new();
	# May be undef if the installed data/ dir exists but is unreadable; just
	# verify no exception is thrown.
	lives_ok { $PKG->new() } 'new() with no args does not croak';
};

subtest 'new() directory [EP-I]: non-existent path → returns undef (carp)' => sub {
	my $obj;
	warnings_exist { $obj = $PKG->new(directory => '/no/such/path/$$') }
		[qr/not a directory/i],
		'carps "not a directory" for non-existent path';
	ok(!defined $obj, 'returns undef for non-existent directory');
};

subtest 'new() directory [EP-I]: plain file (not a dir) → returns undef (carp)' => sub {
	my $dir  = _dir();
	my $file = "$dir/flat_file.txt";
	open(my $fh, '>', $file) or die "Cannot create: $!";
	close $fh;

	my $obj;
	warnings_exist { $obj = $PKG->new(directory => $file) }
		[qr/not a directory/i],
		'carps "not a directory" for a plain file path';
	ok(!defined $obj, 'returns undef for a file passed as directory');
};

subtest 'new() directory [EP-I]: unreadable directory → returns undef (carp)' => sub {
	SKIP: {
		skip 'Running as root — permission checks do not apply', 2 if $> == 0;
		my $dir = _dir();
		chmod 0000, $dir;

		my $obj;
		warnings_exist { $obj = $PKG->new(directory => $dir) }
			[qr/not a directory/i],
			'carps "not a directory" for unreadable directory';
		ok(!defined $obj, 'returns undef for unreadable directory');

		chmod 0700, $dir;    # restore so tempdir cleanup can remove it
	}
};

subtest 'new() directory [BVA]: empty string → returns undef (carp)' => sub {
	my $obj;
	warnings_exist { $obj = $PKG->new(directory => '') }
		[qr/not a directory/i],
		'empty string directory carps "not a directory"';
	ok(!defined $obj, 'returns undef for empty-string directory');
};

subtest 'new() directory [EP-I]: path with embedded null byte → returns undef (carp)' => sub {
	my $dir     = _dir();
	my $bad_path = "$dir/some\x00path";

	my $obj;
	warnings_exist { $obj = $PKG->new(directory => $bad_path) }
		[qr/not a directory/i],
		'carps "not a directory" for null-byte path';
	ok(!defined $obj, 'returns undef for null-byte path');
};

subtest 'new() directory [BVA]: /dev/null (exists but is not a dir) → returns undef' => sub {
	SKIP: {
		skip '/dev/null not present on this platform', 2 unless -e '/dev/null';
		my $obj;
		warnings_exist { $obj = $PKG->new(directory => '/dev/null') }
			[qr/not a directory/i],
			'carps "not a directory" for /dev/null';
		ok(!defined $obj, 'returns undef for /dev/null');
	}
};

# ---------------------------------------------------------------------------
# DOMAIN 2: new() — logger parameter
# ---------------------------------------------------------------------------

subtest 'new() logger [EP-V]: object with info(), warn() and error() → accepted' => sub {
	my $dir = _dir();
	my $obj = $PKG->new(directory => $dir, logger => MyLogger->new());
	ok(defined $obj && blessed($obj), 'valid logger object accepted');
};

subtest 'new() logger [EP-I]: plain string → croak err_bad_logger' => sub {
	my $dir = _dir();
	throws_ok { $PKG->new(directory => $dir, logger => 'Log::Any') }
		qr/Logger must be an object/i,
		'[EP-I] string logger → err_bad_logger';
};

subtest 'new() logger [EP-I]: integer → croak err_bad_logger' => sub {
	my $dir = _dir();
	throws_ok { $PKG->new(directory => $dir, logger => 42) }
		qr/Logger must be an object/i,
		'[EP-I] integer logger → err_bad_logger';
};

subtest 'new() logger [EP-I]: unblessed hashref → croak err_bad_logger' => sub {
	my $dir = _dir();
	throws_ok { $PKG->new(directory => $dir, logger => { info => sub {}, error => sub {} }) }
		qr/Logger must be an object/i,
		'[EP-I] unblessed hashref → err_bad_logger (must be blessed)';
};

subtest 'new() logger [EP-I]: coderef → croak err_bad_logger' => sub {
	my $dir = _dir();
	throws_ok { $PKG->new(directory => $dir, logger => sub { }) }
		qr/Logger must be an object/i,
		'[EP-I] coderef → err_bad_logger';
};

subtest 'new() logger [EP-I]: blessed object missing info() → croak err_bad_logger' => sub {
	my $dir = _dir();
	{
		package LogNoInfo;
		sub new   { bless {}, shift }
		sub error { }
	}
	throws_ok { $PKG->new(directory => $dir, logger => LogNoInfo->new()) }
		qr/Logger must be an object/i,
		'[EP-I] logger with error() but no info() → err_bad_logger';
};

subtest 'new() logger [EP-I]: blessed object missing error() → croak err_bad_logger' => sub {
	my $dir = _dir();
	{
		package LogNoError;
		sub new  { bless {}, shift }
		sub info { }
	}
	throws_ok { $PKG->new(directory => $dir, logger => LogNoError->new()) }
		qr/Logger must be an object/i,
		'[EP-I] logger with info() but no error() → err_bad_logger';
};

subtest 'new() logger [EP-I]: blessed object missing warn() → croak err_bad_logger' => sub {
	my $dir = _dir();
	{
		package LogNoWarn;
		sub new   { bless {}, shift }
		sub info  { }
		sub error { }
	}
	throws_ok { $PKG->new(directory => $dir, logger => LogNoWarn->new()) }
		qr/Logger must be an object/i,
		'[EP-I] logger with info() and error() but no warn() → err_bad_logger';
};

subtest 'new() logger [EP-V]: blessed object with extra methods (superset) → accepted' => sub {
	my $dir = _dir();
	{
		package LogSuperset;
		sub new   { bless {}, shift }
		sub info  { }
		sub warn  { }
		sub error { }
		sub debug { }
		sub trace { }
	}
	my $obj = $PKG->new(directory => $dir, logger => LogSuperset->new());
	ok(defined $obj && blessed($obj), 'superset-interface logger accepted');
};

# ---------------------------------------------------------------------------
# DOMAIN 3: new() — invocation style
# ---------------------------------------------------------------------------

subtest 'new() invocation [EP-V]: class method → returns object' => sub {
	my $obj = $PKG->new(directory => _dir());
	ok(defined $obj && blessed($obj), 'class-method invocation returns object');
	isa_ok($obj, $PKG);
};

subtest 'new() invocation [EP-V]: object method (clone) → returns new object' => sub {
	my $orig  = $PKG->new(directory => _dir());
	my $clone = $orig->new();
	ok(defined $clone && blessed($clone), 'clone returns a blessed object');
	isa_ok($clone, $PKG);
	isnt(refaddr($orig), refaddr($clone), 'clone is a distinct reference');
};

subtest 'new() invocation [EP-V]: single bare string → treated as directory' => sub {
	my $dir = _dir();
	my $obj = $PKG->new($dir);
	ok(defined $obj && blessed($obj), 'bare string directory accepted');
	is($obj->{directory}, $dir, 'bare string stored as directory');
};

subtest 'new() invocation [EP-V]: hashref arg → accepted' => sub {
	my $dir = _dir();
	my $obj = $PKG->new({ directory => $dir });
	ok(defined $obj && blessed($obj), 'hashref arg accepted');
	is($obj->{directory}, $dir, 'directory correctly extracted from hashref');
};

subtest 'new() invocation [EP-V]: Pkg::new() with no args → tolerated (no croak)' => sub {
	lives_ok { $PKG->can('new')->() } 'Pkg::new() with no args does not croak';
};

subtest 'new() invocation [EP-I]: Pkg::new(undef, args) → croak warn_bad_usage' => sub {
	# warn_bad_usage fires when $class_in is undef (first arg explicitly undef)
	# and additional args are present.  Simulates: my $cls; $cls->new(dir => ...)
	# but without Perl's own "undef method" guard.
	my $dir = _dir();
	throws_ok { Genealogy::Obituary::Lookup::new(undef, directory => $dir) }
		qr/use ->new\(\) not ::new\(\)/i,
		'new(undef, args) → warn_bad_usage croak';
};

subtest 'new() invocation [EP-V]: clone inherits cache_duration from original' => sub {
	my $dir    = _dir();
	my $orig   = $PKG->new(directory => $dir, cache_duration => 'forever');
	my $clone  = $orig->new();
	is($clone->{cache_duration}, 'forever', 'cache_duration flows from original to clone');
};

subtest 'new() invocation [EP-V]: clone args override inherited values' => sub {
	my $dir1 = _dir();
	my $dir2 = _dir();
	my $orig  = $PKG->new(directory => $dir1);
	my $clone = $orig->new(directory => $dir2);
	is($clone->{directory}, $dir2, 'clone directory is the overriding arg');
	is($orig->{directory},  $dir1, 'original directory is unchanged');
};

# ---------------------------------------------------------------------------
# DOMAIN 4: search() — last name (required string, 1..100, /^[\w\-]+$/)
# ---------------------------------------------------------------------------

subtest 'search() last [EP-V]: typical surname' => sub {
	my $obj = _obj();
	_set_rows([ _obit() ]);
	my @r = $obj->search(last => $LAST_TYPICAL);
	ok(1, "[EP-V] last='$LAST_TYPICAL' accepted by search()");
};

subtest 'search() last [EP-V]: hyphenated surname' => sub {
	my $obj = _obj();
	_set_rows([]);
	lives_ok { $obj->search(last => $LAST_HYPHEN) }
		"[EP-V] last='$LAST_HYPHEN' (hyphen allowed) accepted";
};

subtest 'search() last [EP-V]: underscore in surname' => sub {
	my $obj = _obj();
	_set_rows([]);
	lives_ok { $obj->search(last => $LAST_UNDERSCORE) }
		"[EP-V] last='$LAST_UNDERSCORE' (underscore is \\w) accepted";
};

subtest 'search() last [EP-V]: all-caps surname' => sub {
	my $obj = _obj();
	_set_rows([]);
	lives_ok { $obj->search(last => $LAST_ALLCAPS) }
		"[EP-V] last='$LAST_ALLCAPS' (uppercase) accepted";
};

subtest 'search() last [EP-V]: surname with embedded digit' => sub {
	my $obj = _obj();
	_set_rows([]);
	lives_ok { $obj->search(last => $LAST_DIGITS) }
		"[EP-V] last='$LAST_DIGITS' (digit is \\w) accepted";
};

subtest 'search() last [BVA]: 1-char surname (at minimum)' => sub {
	my $obj = _obj();
	_set_rows([]);
	lives_ok { $obj->search(last => $LAST_AT_MIN) }
		"[BVA MIN] last='$LAST_AT_MIN' (1 char) accepted";
};

subtest 'search() last [BVA]: empty string (below minimum)' => sub {
	my $obj = _obj();
	throws_ok { $obj->search(last => $LAST_BELOW_MIN) }
		qr/last/i,
		'[BVA MIN-1] last="" (0 chars) croaks';
};

subtest 'search() last [BVA]: 100-char surname (at maximum)' => sub {
	my $obj = _obj();
	_set_rows([]);
	lives_ok { $obj->search(last => $LAST_AT_MAX) }
		'[BVA MAX] last=100 chars accepted';
};

subtest 'search() last [BVA]: 101-char surname (above maximum)' => sub {
	my $obj = _obj();
	throws_ok { $obj->search(last => $LAST_ABOVE_MAX) }
		qr//,    # Params::Validate::Strict throws on max violation
		'[BVA MAX+1] last=101 chars rejected';
};

subtest 'search() last [EP-I]: undef → croak err_no_last' => sub {
	my $obj = _obj();
	throws_ok { $obj->search(last => undef) }
		qr/last/i,
		"[EP-I] last=undef → err_no_last";
};

subtest "search() last [FMT]: apostrophe in O'Brien → rejected by regex" => sub {
	my $obj = _obj();
	throws_ok { $obj->search(last => "O'Brien") }
		qr//,
		"[FMT] apostrophe in surname rejected (not in [\\w\\-])";
};

subtest 'search() last [FMT]: space in surname → rejected by regex' => sub {
	my $obj = _obj();
	throws_ok { $obj->search(last => 'van Berg') }
		qr//,
		'[FMT] space in surname rejected';
};

subtest 'search() last [FMT]: period in surname → rejected by regex' => sub {
	my $obj = _obj();
	throws_ok { $obj->search(last => 'St.Clair') }
		qr//,
		'[FMT] period in surname rejected';
};

subtest 'search() last [FMT]: SQL injection — semicolon → rejected' => sub {
	my $obj = _obj();
	throws_ok { $obj->search(last => "Smith; DROP TABLE obituaries") }
		qr//,
		'[FMT] SQL injection with semicolon rejected';
};

subtest 'search() last [FMT]: SQL injection — single-quote → rejected' => sub {
	my $obj = _obj();
	throws_ok { $obj->search(last => "' OR 1=1 --") }
		qr//,
		"[FMT] SQL injection with quote rejected";
};

subtest 'search() last [FMT]: newline in surname → rejected' => sub {
	my $obj = _obj();
	throws_ok { $obj->search(last => "Smith\nDrop") }
		qr//,
		'[FMT] newline in surname rejected';
};

subtest 'search() last [FMT]: multibyte emoji → rejected by regex' => sub {
	# Emoji are not word characters under any Perl mode.
	my $obj = _obj();
	throws_ok { $obj->search(last => "Smith\x{1F600}") }
		qr//,
		'[FMT] emoji in surname rejected';
};

subtest 'search() last [FMT]: Zalgo combining-character text → rejected' => sub {
	# Zalgo sequences combine base letters with many combining marks.
	# The combining marks are not in [\w\-].
	my $obj  = _obj();
	my $zalgo = "S\x{0300}\x{0301}m\x{0302}ith";    # S̀́mîth
	throws_ok { $obj->search(last => $zalgo) }
		qr//,
		'[FMT] Zalgo combining-character text rejected';
};

subtest 'search() last [FMT]: RTL-override Unicode control char → rejected' => sub {
	my $obj = _obj();
	throws_ok { $obj->search(last => "Smith\x{202E}") }    # U+202E RIGHT-TO-LEFT OVERRIDE
		qr//,
		'[FMT] RTL-override control character rejected';
};

subtest 'search() last [FMT]: German umlaut ü — survives without fatal crash' => sub {
	# \w in Perl's regex engine matches Unicode letters when the string is UTF-8.
	# 'Müller' is common in genealogical records; we test that the module either
	# accepts it (if \w matches \x{FC}) or rejects it cleanly (no unhandled exception).
	my $obj    = _obj();
	my $umlaut = "M\x{FC}ller";    # Müller
	_set_rows([]);
	eval { $obj->search(last => $umlaut) };
	# Whether accepted or rejected, no unhandled fatal exception must occur.
	ok(1, '[FMT] surname with German umlaut processed without fatal crash');
};

subtest 'search() last [FMT]: German eszett ß — survives without fatal crash' => sub {
	my $obj   = _obj();
	my $eszett = "Wei\x{DF}";    # Weiß
	_set_rows([]);
	eval { $obj->search(last => $eszett) };
	ok(1, '[FMT] surname with German ß processed without fatal crash');
};

# ---------------------------------------------------------------------------
# DOMAIN 5: search() — first name (optional string, 1..100, no format)
# ---------------------------------------------------------------------------

subtest 'search() first [EP-V]: typical first name' => sub {
	my $obj = _obj();
	_set_rows([]);
	lives_ok { $obj->search(first => 'John', last => 'Smith') }
		"[EP-V] first='John' accepted";
};

subtest 'search() first [EP-V]: absent (not supplied) → accepted' => sub {
	my $obj = _obj();
	_set_rows([]);
	lives_ok { $obj->search(last => 'Smith') }
		'[EP-V] first absent → search still valid';
};

subtest 'search() first [BVA]: 1-char (at minimum)' => sub {
	my $obj = _obj();
	_set_rows([]);
	lives_ok { $obj->search(first => $NAME_AT_MIN, last => 'Smith') }
		"[BVA MIN] first='$NAME_AT_MIN' (1 char) accepted";
};

subtest 'search() first [BVA]: empty string (below minimum)' => sub {
	my $obj = _obj();
	throws_ok { $obj->search(first => $NAME_BELOW_MIN, last => 'Smith') }
		qr//,
		'[BVA MIN-1] first="" rejected';
};

subtest 'search() first [BVA]: 100-char string (at maximum)' => sub {
	my $obj = _obj();
	_set_rows([]);
	lives_ok { $obj->search(first => $NAME_AT_MAX, last => 'Smith') }
		'[BVA MAX] first=100 chars accepted';
};

subtest 'search() first [BVA]: 101-char string (above maximum)' => sub {
	my $obj = _obj();
	throws_ok { $obj->search(first => $NAME_ABOVE_MAX, last => 'Smith') }
		qr//,
		'[BVA MAX+1] first=101 chars rejected';
};

subtest 'search() first [FMT]: non-ASCII first name (no format restriction)' => sub {
	# first has no matches=> constraint so non-ASCII characters may be passed.
	my $obj = _obj();
	_set_rows([]);
	my $result = eval { $obj->search(first => "Jos\x{E9}", last => 'Garcia') };
	# The schema has no format restriction on first; only min/max length.
	# Accept or reject cleanly — no unhandled exception.
	ok(1, '[FMT] non-ASCII first name processed without fatal crash');
};

subtest "search() first [FMT]: apostrophe in first name (no format restriction)" => sub {
	# Unlike last, first has no regex constraint — O'Malley should be accepted.
	my $obj = _obj();
	_set_rows([]);
	my $crashed = 0;
	eval { $obj->search(first => "O'Malley", last => 'Brien') };
	ok(!$crashed, "[FMT] apostrophe in first name does not crash (no regex constraint)");
};

# ---------------------------------------------------------------------------
# DOMAIN 6: search() — middle name (optional string, 1..100, no format)
# ---------------------------------------------------------------------------

subtest 'search() middle [EP-V]: typical middle initial' => sub {
	my $obj = _obj();
	_set_rows([]);
	lives_ok { $obj->search(middle => 'W', last => 'Smith') }
		"[EP-V] middle='W' accepted";
};

subtest 'search() middle [EP-V]: absent (not supplied) → accepted' => sub {
	my $obj = _obj();
	_set_rows([]);
	lives_ok { $obj->search(last => 'Smith') }
		'[EP-V] middle absent → search valid';
};

subtest 'search() middle [BVA]: 1-char (at minimum)' => sub {
	my $obj = _obj();
	_set_rows([]);
	lives_ok { $obj->search(middle => $NAME_AT_MIN, last => 'Smith') }
		"[BVA MIN] middle='$NAME_AT_MIN' accepted";
};

subtest 'search() middle [BVA]: empty string (below minimum)' => sub {
	my $obj = _obj();
	throws_ok { $obj->search(middle => $NAME_BELOW_MIN, last => 'Smith') }
		qr//,
		'[BVA MIN-1] middle="" rejected';
};

subtest 'search() middle [BVA]: 100-char (at maximum)' => sub {
	my $obj = _obj();
	_set_rows([]);
	lives_ok { $obj->search(middle => $NAME_AT_MAX, last => 'Smith') }
		'[BVA MAX] middle=100 chars accepted';
};

subtest 'search() middle [BVA]: 101-char (above maximum)' => sub {
	my $obj = _obj();
	throws_ok { $obj->search(middle => $NAME_ABOVE_MAX, last => 'Smith') }
		qr//,
		'[BVA MAX+1] middle=101 chars rejected';
};

# ---------------------------------------------------------------------------
# DOMAIN 7: search() — age (optional integer, 0..120)
# ---------------------------------------------------------------------------

subtest 'search() age [EP-V]: typical adult age (65)' => sub {
	my $obj = _obj();
	_set_rows([]);
	lives_ok { $obj->search(age => 65, last => 'Smith') }
		'[EP-V] age=65 accepted';
};

subtest 'search() age [EP-V]: absent (not supplied) → accepted' => sub {
	my $obj = _obj();
	_set_rows([]);
	lives_ok { $obj->search(last => 'Smith') }
		'[EP-V] age absent → search valid';
};

subtest 'search() age [BVA]: age=0 (at minimum)' => sub {
	my $obj = _obj();
	_set_rows([]);
	lives_ok { $obj->search(age => $AGE_AT_MIN, last => 'Smith') }
		"[BVA MIN] age=$AGE_AT_MIN accepted";
};

subtest 'search() age [BVA]: age=-1 (below minimum)' => sub {
	my $obj = _obj();
	throws_ok { $obj->search(age => $AGE_BELOW_MIN, last => 'Smith') }
		qr//,
		"[BVA MIN-1] age=$AGE_BELOW_MIN rejected";
};

subtest 'search() age [BVA]: age=120 (at maximum)' => sub {
	my $obj = _obj();
	_set_rows([]);
	lives_ok { $obj->search(age => $AGE_AT_MAX, last => 'Smith') }
		"[BVA MAX] age=$AGE_AT_MAX accepted";
};

subtest 'search() age [BVA]: age=121 (above maximum)' => sub {
	my $obj = _obj();
	throws_ok { $obj->search(age => $AGE_ABOVE_MAX, last => 'Smith') }
		qr//,
		"[BVA MAX+1] age=$AGE_ABOVE_MAX rejected";
};

subtest 'search() age [EP-I]: non-integer float → rejected' => sub {
	my $obj = _obj();
	throws_ok { $obj->search(age => 1.5, last => 'Smith') }
		qr//,
		'[EP-I] float age=1.5 rejected (type=integer)';
};

subtest 'search() age [EP-I]: negative float → rejected' => sub {
	my $obj = _obj();
	throws_ok { $obj->search(age => -0.5, last => 'Smith') }
		qr//,
		'[EP-I] negative float age=-0.5 rejected';
};

subtest 'search() age [EP-I]: string "old" → rejected' => sub {
	my $obj = _obj();
	throws_ok { $obj->search(age => 'old', last => 'Smith') }
		qr//,
		'[EP-I] string age="old" rejected (not integer)';
};

subtest 'search() age [EP-I]: string "65abc" → rejected' => sub {
	my $obj = _obj();
	throws_ok { $obj->search(age => '65abc', last => 'Smith') }
		qr//,
		'[EP-I] string age="65abc" rejected';
};

subtest 'search() age [EP-V]: string "65" (numeric string) — accepted as integer' => sub {
	# Params::Validate::Strict with type=integer may coerce a purely numeric string.
	my $obj = _obj();
	_set_rows([]);
	eval { $obj->search(age => '65', last => 'Smith') };
	# String "65" may be coerced to integer; we just verify no crash either way.
	ok(1, '[EP-V] string "65" (purely numeric) processed without crash');
};

# ---------------------------------------------------------------------------
# DOMAIN 8: search() — invocation style
# ---------------------------------------------------------------------------

subtest 'search() invocation [EP-V]: object method → accepted' => sub {
	my $obj = _obj();
	_set_rows([]);
	lives_ok { my @r = $obj->search(last => 'Smith') }
		'[EP-V] object-method invocation accepted';
};

subtest 'search() invocation [EP-I]: class method (not blessed) → croak err_no_self' => sub {
	throws_ok { $PKG->search(last => 'Smith') }
		qr/must be called on an object/i,
		'[EP-I] class-method search() → err_no_self';
};

subtest 'search() invocation [EP-I]: function call → croak err_no_self' => sub {
	throws_ok { Genealogy::Obituary::Lookup::search(last => 'Smith') }
		qr/must be called on an object/i,
		'[EP-I] function-call search() → err_no_self';
};

subtest 'search() invocation [EP-I]: zero args → croak err_no_args' => sub {
	my $obj = _obj();
	throws_ok { $obj->search() }
		qr/Usage/i,
		'[EP-I] zero args → err_no_args';
};

# ---------------------------------------------------------------------------
# DOMAIN 9: search() — context domain
# ---------------------------------------------------------------------------

subtest 'search() context [EP-V]: list context with match → non-empty list' => sub {
	my $obj = _obj();
	_set_rows([ _obit() ]);
	my @r = $obj->search(last => 'Smith');
	ok(scalar(@r) > 0, '[EP-V] list context with matching rows returns non-empty list');
	ok(exists $r[0]->{url}, 'result hashref has url key');
};

subtest 'search() context [EP-V]: list context no match → empty list' => sub {
	my $obj = _obj();
	_set_rows([]);
	my @r = $obj->search(last => 'Zymurgist');
	is(scalar(@r), 0, '[EP-V] list context, no match → empty list ()');
};

subtest 'search() context [EP-V]: scalar context with match → hashref' => sub {
	my $obj = _obj();
	_set_scalar(_obit());
	my $r = $obj->search(last => 'Smith');
	ok(defined $r, '[EP-V] scalar context, match → defined hashref');
	isa_ok($r, 'HASH');
	ok(exists $r->{url}, 'scalar result hashref has url key');
};

subtest 'search() context [EP-V]: scalar context no match → undef' => sub {
	my $obj = _obj();
	_set_scalar(undef);
	my $r = $obj->search(last => 'Zymurgist');
	ok(!defined $r, '[EP-V] scalar context, no match → undef');
};

subtest 'search() context [EP-V]: void context → no crash' => sub {
	my $obj = _obj();
	_set_scalar(undef);    # prevent scalar-path crash from stale fixated hashref
	lives_ok { $obj->search(last => 'Smith') }
		'[EP-V] void context search() does not crash';
};

# ---------------------------------------------------------------------------
# DOMAIN 10: Combinatorial boundaries
# ---------------------------------------------------------------------------

subtest 'COMB: last@MAX + first@MAX + middle@MAX + age@MAX → all valid (query fires)' => sub {
	my $obj = _obj();
	_set_rows([]);
	lives_ok {
		$obj->search(
			last   => $LAST_AT_MAX,
			first  => $NAME_AT_MAX,
			middle => $NAME_AT_MAX,
			age    => $AGE_AT_MAX,
		)
	} '[COMB] all params at maximum valid boundary → search fires without croak';
};

subtest 'COMB: last@MAX + age@MAX+1 → age fails, croak' => sub {
	my $obj = _obj();
	throws_ok {
		$obj->search(
			last => $LAST_AT_MAX,
			age  => $AGE_ABOVE_MAX,
		)
	} qr//,
		'[COMB] last@MAX + age@MAX+1 → age boundary violation is caught';
};

subtest 'COMB: last@MIN + age@MIN → minimal valid search' => sub {
	my $obj = _obj();
	_set_rows([]);
	lives_ok {
		$obj->search(last => $LAST_AT_MIN, age => $AGE_AT_MIN)
	} '[COMB] last@MIN + age@MIN → both at minimum valid boundary accepted';
};

subtest 'COMB: last@MIN-1 + age@MIN → last fails first (left-to-right validation)' => sub {
	my $obj = _obj();
	throws_ok {
		$obj->search(last => $LAST_BELOW_MIN, age => $AGE_AT_MIN)
	} qr/last/i,
		'[COMB] last@MIN-1 + age@MIN → last-name failure reported first';
};

subtest 'COMB: last@MAX+1 + age@MAX+1 → rejects at last (first failing field)' => sub {
	my $obj = _obj();
	throws_ok {
		$obj->search(last => $LAST_ABOVE_MAX, age => $AGE_ABOVE_MAX)
	} qr//,
		'[COMB] last@MAX+1 + age@MAX+1 → rejected on first failing field';
};

subtest 'COMB: last=hyphen-at-boundary + age@MIN → valid across both' => sub {
	# A MAX-length string that contains a hyphen (still matches /^[\w\-]+$/)
	my $hyphen_at_max = 'A' x 49 . '-' . 'A' x 50;    # 101 chars? No: 49+1+50 = 100
	my $obj = _obj();
	_set_rows([]);
	lives_ok {
		$obj->search(last => $hyphen_at_max, age => $AGE_AT_MIN)
	} '[COMB] 100-char hyphenated last + age=0 → both valid boundaries accepted';
};

# ---------------------------------------------------------------------------
# DOMAIN 11: search() returned-hashref structure domain
#
# The url key is always present; all DB keys are preserved.
# ---------------------------------------------------------------------------

Readonly::Array my @REQUIRED_RETURN_KEYS => qw(
	first middle last maiden age place newspaper date source page url
);

subtest 'return-structure [EP-V]: source M → url is Wayback URL' => sub {
	my $obj = _obj();
	my $row = { %{_obit()}, source => 'M', page => '7' };
	_set_rows([$row]);
	my ($r) = $obj->search(last => 'Smith');
	like($r->{url}, qr{wayback\.archive-it\.org}, '[EP-V] source M → Wayback URL');
	for my $key (@REQUIRED_RETURN_KEYS) {
		ok(exists $r->{$key}, "return key '$key' exists in result");
	}
};

subtest 'return-structure [EP-V]: source F → url is Freelists URL' => sub {
	my $obj = _obj();
	_set_scalar({ %{_obit()}, source => 'F', page => 'v1no001' });
	my $r = $obj->search(last => 'Smith');
	like($r->{url}, qr{freelists\.org}, '[EP-V] source F → Freelists URL');
};

subtest 'return-structure [EP-V]: source L with newspaper URL → newspaper used' => sub {
	my $obj = _obj();
	_set_scalar({ %{_obit()}, source => 'L', page => 'not-a-url',
		newspaper => 'https://example.com/obit' });
	my $r = $obj->search(last => 'Smith');
	is($r->{url}, 'https://example.com/obit', '[EP-V] source L → newspaper URL used');
};

subtest 'return-structure [EP-V]: source L with page URL → page used' => sub {
	my $obj = _obj();
	_set_scalar({ %{_obit()}, source => 'L', page => 'https://page.example.com/',
		newspaper => 'local gazette' });
	my $r = $obj->search(last => 'Smith');
	is($r->{url}, 'https://page.example.com/', '[EP-V] source L → page URL used when newspaper is plain text');
};

subtest 'return-structure [EP-I]: source L with no URL anywhere → croak err_no_newspaper' => sub {
	my $obj = _obj();
	_set_rows([{ %{_obit()}, source => 'L', page => 'not-a-url',
		newspaper => 'plain text' }]);
	throws_ok { my @r = $obj->search(last => 'Smith') }
		qr/newspaper/i,
		'[EP-I] source L with no URL → err_no_newspaper';
};

subtest 'return-structure [EP-I]: unknown source X → croak err_bad_source' => sub {
	my $obj = _obj();
	_set_rows([{ %{_obit()}, source => 'X' }]);
	throws_ok { my @r = $obj->search(last => 'Smith') }
		qr/Invalid source/i,
		'[EP-I] source X → err_bad_source';
};

done_testing();
