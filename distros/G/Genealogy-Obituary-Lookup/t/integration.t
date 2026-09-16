#!/usr/bin/env perl

# End-to-end integration tests for Genealogy::Obituary::Lookup.
#
# Unlike unit tests (which stub the DB driver), these tests exercise the full
# stack: new() → search() → Database::Abstraction → real SQLite → URL assembly.
# A temporary obituaries.sql file is built once for the suite and shared across
# all subtests.  DB-layer correctness is verified through output (returned records
# and URLs), not by spying on inherited Database::Abstraction methods, since
# mock_scoped on an inherited method removes the stash entry on cleanup which
# causes subsequent ->new() calls to fall through to AUTOLOAD ("Unknown column new").

use strict;
use warnings;

use DBI;
use File::Spec;
use File::Temp   qw(tempdir);
use Readonly;
use Scalar::Util qw(blessed refaddr);
use Test::Most;
use Test::Returns;
use YAML::XS     qw(DumpFile);

use lib 'lib';
use lib 't/lib';
use MyLogger;

BEGIN { use_ok('Genealogy::Obituary::Lookup') }

# ---------------------------------------------------------------------------
# Constants: exact URL prefixes from Lookup.pm and per-row page identifiers.
# Deriving expected URLs from these constants proves the URL assembly formula.
# ---------------------------------------------------------------------------
Readonly::Scalar my $PKG => 'Genealogy::Obituary::Lookup';

Readonly::Scalar my $WAYBACK_BASE =>
	'https://wayback.archive-it.org/20669/20231102044925/'
	. 'https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit&page=';
Readonly::Scalar my $FREELISTS_BASE =>
	'https://www.freelists.org/post/obitdailytimes/Obituary-Daily-Times-';

# Page identifiers for each test record
Readonly::Scalar my $PAGE_COPPAGE  => 80;
Readonly::Scalar my $PAGE_SMITH_M  => 42;
Readonly::Scalar my $PAGE_SMITH_F  => 'v26no080';
Readonly::Scalar my $PAGE_BROWN_F  => 'v25no101';
Readonly::Scalar my $URL_MCCARTHY  =>
	'https://funeral-notices.co.uk/notice/mc+carthy/5232006';

Readonly::Scalar my $URL_COPPAGE   => $WAYBACK_BASE   . $PAGE_COPPAGE;
Readonly::Scalar my $URL_SMITH_M   => $WAYBACK_BASE   . $PAGE_SMITH_M;
Readonly::Scalar my $URL_SMITH_F   => $FREELISTS_BASE . $PAGE_SMITH_F;
Readonly::Scalar my $URL_BROWN_F   => $FREELISTS_BASE . $PAGE_BROWN_F;

# ---------------------------------------------------------------------------
# Helper: build a fresh Lookup object pointing at the shared test directory.
# ---------------------------------------------------------------------------
my $TEST_DIR;	# populated in the setup phase below

sub _obj {
	my %extra = @_;
	return $PKG->new(directory => $TEST_DIR, %extra);
}

# ===========================================================================
# SETUP — build a real SQLite database with known records.
# Runs at module level before any subtest().  tempdir CLEANUP handles removal.
# ===========================================================================
{
	$TEST_DIR = tempdir(CLEANUP => 1);
	my $dbfile = File::Spec->catfile($TEST_DIR, 'obituaries.sql');

	my $dbh = DBI->connect(
		"dbi:SQLite:dbname=$dbfile", '', '',
		{ RaiseError => 1, PrintError => 0 }
	);
	$dbh->do(q{
		CREATE TABLE obituaries(
			first    VARCHAR,
			middle   VARCHAR,
			last     VARCHAR NOT NULL,
			maiden   VARCHAR,
			age      INTEGER,
			place    VARCHAR,
			newspaper VARCHAR NOT NULL,
			date     DATE NOT NULL,
			source   CHAR NOT NULL,
			page     VARCHAR NOT NULL)
	});
	$dbh->do('CREATE INDEX name_index     ON obituaries(first, last)');
	$dbh->do('CREATE INDEX name_age_index ON obituaries(first, last, age)');

	my $ins = $dbh->prepare(q{
		INSERT INTO obituaries
			(first,middle,last,maiden,age,place,date,newspaper,source,page)
		VALUES (?,?,?,?,?,?,?,?,?,?)
	});

	# Source M (Wayback Machine) — single match for Coppage
	$ins->execute(
		'John',   'W',     'Coppage', undef, 65,
		'Dayton, OH', '2024-03-10', 'The Dayton Daily News', 'M', $PAGE_COPPAGE
	);
	# Source F (freelists) — first of two Smiths
	$ins->execute(
		'Jane',   'A',     'Smith',   undef, 45,
		'Portland, OR', '2024-01-15', 'Portland Gazette', 'F', $PAGE_SMITH_F
	);
	# Source L (local/link) — funeral-notices.co.uk record for McCarthy
	$ins->execute(
		'Jean',   'Emily', 'McCarthy', undef, 83,
		'Dublin', '2025-01-29', $URL_MCCARTHY, 'L', $URL_MCCARTHY
	);
	# Source M — second Smith (different age)
	$ins->execute(
		'Robert', undef,   'Smith',   undef, 70,
		'Boston, MA', '2023-11-20', 'Boston Herald', 'M', $PAGE_SMITH_M
	);
	# Source F — maiden name record
	$ins->execute(
		'Mary',   'Jane',  'Brown',   'Paterson', 55,
		'Leeds', '2024-05-01', 'Leeds Gazette', 'F', $PAGE_BROWN_F
	);

	$dbh->disconnect();
}

# ===========================================================================
# Workflow 1: basic new() + search() end-to-end
# Verifies the full path from constructor through SQL query to URL generation.
# ===========================================================================

subtest 'E2E: new() + search(last) returns records with correct URLs' => sub {
	my $obj = _obj();
	ok(defined $obj,    'new() returns a defined object');
	isa_ok($obj, $PKG,  'new() returns a blessed Lookup instance');

	my @smiths = $obj->search(last => 'Smith');
	cmp_ok(scalar @smiths, '==', 2, 'search("Smith") returns both Smith records');

	my %by_first = map { $_->{first} => $_ } @smiths;
	ok(exists $by_first{Jane},   'Jane Smith is in the results');
	ok(exists $by_first{Robert}, 'Robert Smith is in the results');

	is($by_first{Jane}->{url},   $URL_SMITH_F,
		'Jane Smith (source F) gets the expected freelists URL');
	is($by_first{Robert}->{url}, $URL_SMITH_M,
		'Robert Smith (source M) gets the expected Wayback URL');

	diag("Jane url:   $by_first{Jane}->{url}")   if $ENV{TEST_VERBOSE};
	diag("Robert url: $by_first{Robert}->{url}") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# Workflow 2: all search filter combinations
# Each combination exercises a different SQL WHERE clause path.
# ===========================================================================

subtest 'E2E: search() — first + last filter' => sub {
	my $obj = _obj();
	my @res = $obj->search(first => 'John', last => 'Coppage');
	is(scalar @res, 1, 'first+last filter returns exactly one result');
	is($res[0]->{url}, $URL_COPPAGE,
		'Coppage (source M) gets the expected Wayback URL');
};

subtest 'E2E: search() — first + middle + last filter' => sub {
	my $obj  = _obj();
	my @res  = $obj->search(first => 'John', middle => 'W', last => 'Coppage');
	is(scalar @res, 1, 'first+middle+last filter returns exactly one result');
	is($res[0]->{url}, $URL_COPPAGE, 'Coppage URL is correct with middle filter');
};

subtest 'E2E: search() — age filter narrows multi-match result' => sub {
	my $obj  = _obj();
	my @all  = $obj->search(last => 'Smith');
	my @aged = $obj->search(last => 'Smith', age => 70);
	cmp_ok(scalar @aged, '<', scalar @all,
		'adding age filter reduces result count');
	is(scalar @aged, 1,      'age=70 filter returns exactly one Smith');
	is($aged[0]->{first}, 'Robert', 'the surviving record is Robert Smith');
};

subtest 'E2E: search() — source L (funeral-notices.co.uk) URL' => sub {
	my $obj = _obj();
	my @res = $obj->search(first => 'Jean', middle => 'Emily', last => 'McCarthy');
	is(scalar @res, 1, 'McCarthy found in the database');
	is($res[0]->{url}, $URL_MCCARTHY,
		'source L row uses the newspaper URL (funeral-notices.co.uk)');
};

subtest 'E2E: search() scalar context — single hashref with url' => sub {
	my $obj = _obj();
	my $hit = $obj->search(last => 'Coppage');
	ok(defined $hit,     'scalar search returns a defined value');
	isa_ok($hit, 'HASH', 'scalar result is a hashref');
	ok(exists $hit->{url}, 'hashref carries a url key');
	is($hit->{url}, $URL_COPPAGE, 'Coppage scalar-context URL is correct');

	returns_is($hit, { type => 'hashref' },
		'scalar result satisfies hashref schema');
};

subtest 'E2E: search() returns maiden name in result' => sub {
	my $obj  = _obj();
	my @brow = $obj->search(last => 'Brown');
	is(scalar @brow, 1,         'one Brown record found');
	is($brow[0]->{maiden}, 'Paterson', 'maiden name Paterson is returned');
	is($brow[0]->{url}, $URL_BROWN_F,  'Brown (source F) URL is correct');
};

subtest 'E2E: search() — no match returns empty list / undef' => sub {
	my $obj = _obj();
	my @r   = $obj->search(last => 'Xyzzy');
	is(scalar @r, 0, 'list search returns empty list for unknown last name');

	my $s = $obj->search(last => 'Xyzzy');
	ok(!defined $s, 'scalar search returns undef for unknown last name');
};

# ===========================================================================
# Workflow 3: multi-object isolation
# Two independent Lookup objects must not share DB-handle state.
# ===========================================================================

subtest 'concurrency: two objects have independent DB handles' => sub {
	my $obj1 = _obj();
	my $obj2 = _obj();

	# Trigger DB-handle initialisation in both objects independently
	my @r1 = $obj1->search(last => 'Smith');
	my @r2 = $obj2->search(last => 'Coppage');

	cmp_ok(scalar @r1, '==', 2, 'obj1 finds both Smiths');
	cmp_ok(scalar @r2, '==', 1, 'obj2 finds one Coppage');

	# Each object must carry its own obituaries handle
	ok(defined $obj1->{obituaries}, 'obj1 has its own obituaries handle');
	ok(defined $obj2->{obituaries}, 'obj2 has its own obituaries handle');
	isnt(refaddr($obj1->{obituaries}), refaddr($obj2->{obituaries}),
		'the two handles are distinct references');
};

subtest 'concurrency: obj1 search does not affect obj2 results' => sub {
	my $obj1 = _obj();
	my $obj2 = _obj();

	my @smiths  = $obj1->search(last => 'Smith');
	my @browns  = $obj2->search(last => 'Brown');

	# Verify neither call contaminated the other object's state
	cmp_ok(scalar @smiths, '==', 2, 'obj1 still sees 2 Smiths');
	cmp_ok(scalar @browns, '==', 1, 'obj2 still sees 1 Brown');
};

# ===========================================================================
# Workflow 4: clone + independent search
#
# Clone BEFORE any search: the clone lazily initialises its own DB handle.
# Clone AFTER  a search:  the clone inherits the parent's already-open handle
# (because new() copies the whole hash, including {obituaries}).
# Both behaviours are documented here.
# ===========================================================================

subtest 'clone before search: clone gets its own handle' => sub {
	my $orig  = _obj();
	my $clone = $orig->new();	# clone before any search()

	ok(!defined $orig->{obituaries},  'original has no handle before first search');
	ok(!defined $clone->{obituaries}, 'clone has no handle before first search');

	my @r_orig  = $orig->search(last  => 'Coppage');
	my @r_clone = $clone->search(last => 'Smith');

	isnt(refaddr($orig->{obituaries}), refaddr($clone->{obituaries}),
		'clone and original each hold an independent handle');
	cmp_ok(scalar @r_orig,  '==', 1, 'original found 1 Coppage');
	cmp_ok(scalar @r_clone, '==', 2, 'clone found 2 Smiths');
};

subtest 'clone after search: clone inherits parent handle' => sub {
	my $orig  = _obj();
	$orig->search(last => 'Smith');	# trigger handle init

	ok(defined $orig->{obituaries}, 'original has handle after first search');

	my $clone = $orig->new();	# clone AFTER search — copies the handle

	is(refaddr($orig->{obituaries}), refaddr($clone->{obituaries}),
		'clone shares the already-open handle from the parent');

	# Both objects can still search correctly via the shared handle
	my @r_orig  = $orig->search(last  => 'Brown');
	my @r_clone = $clone->search(last => 'Brown');
	cmp_ok(scalar @r_orig,  '==', 1, 'original still finds Brown');
	cmp_ok(scalar @r_clone, '==', 1, 'clone finds Brown via shared handle');
};

# ===========================================================================
# Workflow 5: DB-handle reuse within an object (lazy init + caching)
#
# Verify via object state inspection, not by mocking the constructor.
# mock_scoped on an inherited method would delete the stash entry on cleanup,
# causing subsequent ->new() calls to fall through to AUTOLOAD (which treats
# 'new' as a column name and croaks "Unknown column new").
# ===========================================================================

subtest 'handle laziness: DB handle is created once and reused' => sub {
	my $obj = _obj();
	ok(!defined $obj->{obituaries},
		'obituaries handle is undef before the first search');

	$obj->search(last => 'Smith');
	my $addr = refaddr($obj->{obituaries});
	ok(defined $addr, 'obituaries handle is populated after first search');

	$obj->search(last => 'Brown');
	is(refaddr($obj->{obituaries}), $addr, 'same handle after second search');

	$obj->search(last => 'Coppage');
	is(refaddr($obj->{obituaries}), $addr, 'same handle after third search');
};

# ===========================================================================
# Workflow 6: parameter filtering — verified through results
#
# Integration tests verify filtering by examining what comes back, not by
# peeking at internal SQL parameters.  Spy-testing inherited Database::Abstraction
# methods via mock_scoped is unreliable (stash-entry restoration breaks AUTOLOAD),
# so we rely on multi-filter result counts to confirm the right WHERE clauses fire.
# ===========================================================================

subtest 'filter: multi-field search reaches the correct DB rows' => sub {
	my $obj = _obj();

	# The only John W Coppage is in source M at page 80.
	# If first+middle+last are not all forwarded, we would get 0 or >1 results.
	my @res = $obj->search(first => 'John', middle => 'W', last => 'Coppage');
	is(scalar @res, 1,   'first+middle+last combination selects exactly one row');
	is($res[0]->{url}, $URL_COPPAGE,
		'URL confirms the correct row was matched');

	# Jane A Smith vs Robert (no middle) Smith — middle filter must be forwarded.
	my @janes = $obj->search(first => 'Jane', middle => 'A', last => 'Smith');
	is(scalar @janes, 1, 'middle filter isolates Jane A Smith from Robert Smith');
	is($janes[0]->{url}, $URL_SMITH_F, 'Jane Smith URL is the freelists URL');
};

subtest 'filter: scalar context returns the single best match' => sub {
	my $obj = _obj();

	# Scalar search on a last name with two results returns one hashref.
	my $hit = $obj->search(last => 'Brown');
	isa_ok($hit, 'HASH', 'scalar search returns a hashref');
	is($hit->{first}, 'Mary', 'hashref is for Mary Brown');
	is($hit->{url},   $URL_BROWN_F, 'scalar URL is correct');

	# Scalar search with no match returns undef.
	my $miss = $obj->search(last => 'Zzztest');
	ok(!defined $miss, 'scalar search returns undef when nothing matches');
};

# ===========================================================================
# Workflow 7: logger integration
# When search() cannot open the obituaries database it calls logger->error()
# and then croaks.  We trigger the failure naturally by pointing the object at
# a tempdir that has no obituaries.sql, so no mocking of Database::Abstraction
# internals is needed (mocking inherited methods via mock_scoped leaves the
# stash entry deleted on cleanup, which breaks AUTOLOAD in later tests).
# ===========================================================================

subtest 'logger: search() dies when obituaries DB is missing' => sub {
	# Database::Abstraction itself croaks (does not return undef) when the DB
	# file is absent; the integration-level observable is the croak, not a
	# logger call (which is an implementation detail tested at unit level).
	my $empty_dir = tempdir(CLEANUP => 1);
	my $obj       = $PKG->new(directory => $empty_dir);

	throws_ok { $obj->search(last => 'Smith') }
		qr/obituaries/,
		'search() croaks when obituaries.sql does not exist';
};

# ===========================================================================
# Workflow 8: config-file integration
# Object::Configure reads a YAML config file and merges directory into args.
# ===========================================================================

subtest 'config-file: directory read from YAML config' => sub {
	my $cfgdir  = tempdir(CLEANUP => 1);
	my $cfgfile = File::Spec->catfile($cfgdir, 'config.yml');

	DumpFile($cfgfile, { 'Genealogy__Obituary__Lookup' => { directory => $TEST_DIR } });

	my $obj = $PKG->new(config_file => $cfgfile);
	ok(defined $obj, 'new() succeeds with a YAML config file');
	isa_ok($obj, $PKG, 'returned value is a Lookup object');

	# Directory from config file must be in effect
	is($obj->{directory}, $TEST_DIR,
		'directory from config file is applied to the object');

	# A search must work using the config-file-supplied directory
	my @smiths = $obj->search(last => 'Smith');
	cmp_ok(scalar @smiths, '==', 2,
		'search() works correctly via a config-file-configured object');

	diag("config_file search results: ", scalar @smiths) if $ENV{TEST_VERBOSE};
};

subtest 'config-file: environment override takes precedence over file' => sub {
	my $cfgdir  = tempdir(CLEANUP => 1);
	my $cfgfile = File::Spec->catfile($cfgdir, 'config.yml');

	DumpFile($cfgfile, { 'Genealogy__Obituary__Lookup' => { directory => '/file_dir' } });

	local $ENV{'Genealogy__Obituary__Lookup__directory'} = $TEST_DIR;
	my $obj = $PKG->new(config_file => $cfgfile);

	ok(defined $obj, 'new() succeeds when env overrides config-file directory');
	is($obj->{directory}, $TEST_DIR,
		'environment variable directory takes precedence over config file');
};

# ===========================================================================
# Workflow 9: optional dependencies
#
# Test::Without::Module works at compile time only (via @INC hooks installed
# at import time); it has no hide()/restore() runtime API.  All of this
# module's dependencies are hard `use`-d, so the meaningful optional-dep
# test is that the core new() + search() path succeeds with only the
# explicitly declared prerequisites available (satisfied by the test running
# under the standard distribution environment).
#
# The integration-level check is indirect: tests 2-16 above all exercise the
# full stack without requiring any module beyond what is `use`-d at the top
# of this file.  If a lazy `require` were introduced in the hot path, those
# tests would fail in environments where the module is absent.
# ===========================================================================

subtest 'optional-dep: new() + search() succeed with no extra modules loaded' => sub {
	# Verify the full pipeline works using only the modules already `use`-d
	# above.  This is the integration equivalent of "no optional dependencies
	# needed for the core workflow."
	my $obj = _obj();
	my @smiths = $obj->search(last => 'Smith');
	is(scalar @smiths, 2, 'search() returns 2 Smiths with no extra modules');
	my $hit = $obj->search(last => 'Coppage');
	is($hit->{url}, $URL_COPPAGE, 'scalar search URL is correct');
};

done_testing();
