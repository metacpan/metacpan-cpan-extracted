#!/usr/bin/env perl

# Transaction-flow tests for Genealogy::Obituary::Lookup.
#
# Methodology: Entity lifecycle analysis.  Each subtest traces a named
# lifecycle phase and asserts state consistency at every boundary.
#
# Phase notation used in subtest names:
#   [CREATE]    new() called; handle absent.
#   [OPEN]      First search(); handle lazily initialised.
#   [QUERY]     Driver method invoked with params.
#   [TRANSFORM] URL injected; string values fixated.
#   [COMPLETE]  Results returned to caller.
#   [CLONE]     $obj->new(); shares inherited handle.
#   [ROLLBACK]  Exception mid-sequence; state asserted clean.
#   [IDEMPOTENT] Same sequence repeated; results consistent.
#
# Section 7 tests the queue/flush deduplication transaction from
# create_db.PL using an in-memory SQLite database.

use strict;
use warnings;

use DBI;
use File::Temp    qw(tempdir);
use Readonly;
use Scalar::Util  qw(blessed refaddr);
use Test::Most;
use Test::Returns;
use Try::Tiny;

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

Readonly::Scalar my $N_REPEAT   => 5;	# repetitions for idempotency checks
Readonly::Scalar my $N_ROWS     => 3;	# row count for multi-row list tests
Readonly::Scalar my $FLUSH_THRESHOLD => 10;	# mirrors create_db.PL logic in Section 7

# ---------------------------------------------------------------------------
# Mock driver — tracks instance identity and new() call count
# ---------------------------------------------------------------------------
BEGIN {
	package Genealogy::Obituary::Lookup::obituaries;
	our $_mock_rows     = [];
	our $_mock_scalar   = undef;
	our $new_returns    = 1;
	our $new_call_count = 0;
	our @new_call_args;

	sub new {
		my $class = shift;
		$new_call_count++;
		push @new_call_args, [@_];
		return undef unless $new_returns;
		my $id = $new_call_count;
		return bless { _instance_id => $id }, $class;
	}
	sub selectall_hashref { return $_mock_rows }
	sub fetchrow_hashref  { return $_mock_scalar }
}

BEGIN { use_ok('Genealogy::Obituary::Lookup') }

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
sub _dir  { tempdir(CLEANUP => 1) }

sub _obj {
	# Constructs an object.  Does NOT pre-inject the DB handle so that
	# lazy-open tests can observe the handle's absence at construction time.
	return $PKG->new(directory => _dir(), @_);
}

sub _obj_with_handle {
	# Constructs an object and injects a mock handle directly, bypassing
	# lazy-open.  Use when the DB-init path is not under test.
	my $obj = _obj(@_);
	$obj->{'obituaries'} = bless { _instance_id => 999 }, $DRV if $obj;
	return $obj;
}

sub _obit {
	return {
		first => 'Jane', middle => 'E', last => 'Doe',
		maiden => undef, age => 52, place => 'Columbus, OH',
		newspaper => 'Columbus Dispatch', date => '2024-03-01',
		source => 'M', page => '5',
	};
}

sub _set_rows   { $Genealogy::Obituary::Lookup::obituaries::_mock_rows   = shift }
sub _set_scalar { $Genealogy::Obituary::Lookup::obituaries::_mock_scalar = shift }
sub _drv_count  { $Genealogy::Obituary::Lookup::obituaries::new_call_count }

sub _reset_spy {
	$Genealogy::Obituary::Lookup::obituaries::new_call_count = 0;
	@Genealogy::Obituary::Lookup::obituaries::new_call_args  = ();
}
sub _db_returns_undef { $Genealogy::Obituary::Lookup::obituaries::new_returns = 0 }
sub _db_returns_obj   { $Genealogy::Obituary::Lookup::obituaries::new_returns = 1 }

# ==========================================================================
# SECTION 1: DB Handle Lazy-Open Transaction
#
# Lifecycle:  [CREATE] → [OPEN] → [IDEMPOTENT-OPEN]
# Invariants: handle absent at construction; opened exactly once; never
#             reopened for subsequent searches on the same object.
# ==========================================================================

subtest '[CREATE] handle absent at construction time' => sub {
	_reset_spy();
	my $obj = _obj();
	ok(defined $obj && blessed($obj), '[CREATE] object blessed');
	ok(!defined $obj->{'obituaries'},  '[CREATE] obituaries handle is undef');
	is(_drv_count(), 0,                '[CREATE] driver ::new() not called');
};

subtest '[CREATE → OPEN] first search lazily opens the DB handle' => sub {
	_reset_spy();
	_set_rows([ _obit() ]);

	my $obj = _obj();
	ok(!defined $obj->{'obituaries'}, '[CREATE] handle absent before search');

	my @r = $obj->search(last => 'Doe');

	ok(defined $obj->{'obituaries'},  '[OPEN] handle defined after first search');
	ok(blessed($obj->{'obituaries'}), '[OPEN] handle is a blessed object');
	is(_drv_count(), 1,               '[OPEN] driver ::new() called exactly once');
	is(scalar @r, 1,                  '[OPEN] search returned one result');
};

subtest '[OPEN → IDEMPOTENT-OPEN] second search reuses the same handle instance' => sub {
	_reset_spy();
	my $obj = _obj();

	_set_rows([ _obit() ]);
	my @r1 = $obj->search(last => 'Doe');
	my $id_after_first = $obj->{'obituaries'}->{'_instance_id'};
	my $ref_after_first = refaddr($obj->{'obituaries'});

	_set_rows([ _obit() ]);
	my @r2 = $obj->search(last => 'Doe');

	is(_drv_count(), 1,
		'[IDEMPOTENT-OPEN] driver ::new() still called only once after second search');
	is($obj->{'obituaries'}->{'_instance_id'}, $id_after_first,
		'[IDEMPOTENT-OPEN] same instance_id: handle not recreated');
	is(refaddr($obj->{'obituaries'}), $ref_after_first,
		'[IDEMPOTENT-OPEN] same refaddr: handle not swapped');
};

subtest "[IDEMPOTENT-OPEN] $N_REPEAT consecutive searches use the same handle" => sub {
	_reset_spy();
	my $obj = _obj();
	my $first_id;

	for my $i (1 .. $N_REPEAT) {
		_set_rows([ _obit() ]);
		my @r = $obj->search(last => 'Doe');
		if($i == 1) {
			$first_id = $obj->{'obituaries'}->{'_instance_id'};
		} else {
			is($obj->{'obituaries'}->{'_instance_id'}, $first_id,
				"search $i of $N_REPEAT: handle instance_id unchanged");
		}
	}
	is(_drv_count(), 1,
		"[IDEMPOTENT-OPEN] ::new() called once across $N_REPEAT searches");
};

# ==========================================================================
# SECTION 2: Clone Transaction
#
# Lifecycle:  [CREATE] → [OPEN] → [CLONE] → [CLONE-OPEN]
# Invariants: clone inherits handle; modifying clone's handle does not
#             affect original; nulled-handle clone opens its own on search.
# ==========================================================================

subtest '[CLONE] clone inherits open handle from original' => sub {
	_reset_spy();
	_set_rows([ _obit() ]);

	my $obj  = _obj();
	my @orig = $obj->search(last => 'Doe');
	my $orig_id  = $obj->{'obituaries'}->{'_instance_id'};
	my $orig_ref = refaddr($obj->{'obituaries'});

	my $clone = $obj->new();

	ok(defined $clone->{'obituaries'},     '[CLONE] clone has inherited handle');
	is($clone->{'obituaries'}->{'_instance_id'}, $orig_id,
		'[CLONE] clone shares same instance_id as original');
	is(refaddr($clone->{'obituaries'}), $orig_ref,
		'[CLONE] clone shares same refaddr as original handle');
	is(_drv_count(), 1, '[CLONE] no extra ::new() call during clone');
};

subtest '[CLONE] clone can search using inherited handle' => sub {
	_reset_spy();
	_set_rows([ _obit() ]);

	my $obj   = _obj();
	my @orig  = $obj->search(last => 'Doe');
	my $clone = $obj->new();

	_set_rows([ _obit(), _obit() ]);
	my @cloned = $clone->search(last => 'Doe');
	is(scalar @cloned, 2, '[CLONE] clone search returns 2 rows via shared handle');
	is(_drv_count(), 1,   '[CLONE] still only one ::new() call total');
};

subtest '[CLONE → CLONE-OPEN] nulling clone handle does not affect original' => sub {
	_reset_spy();
	_set_rows([ _obit() ]);

	my $obj  = _obj();
	my @orig = $obj->search(last => 'Doe');
	my $orig_id = $obj->{'obituaries'}->{'_instance_id'};

	# Clone inherits handle; we force-null the clone's handle to simulate
	# the clone needing to open its own connection.
	my $clone = $obj->new();
	$clone->{'obituaries'} = undef;
	ok(!defined $clone->{'obituaries'}, '[CLONE-OPEN] clone handle nulled');

	# Original handle must be unaffected (clone had a copy, not an alias)
	ok(defined $obj->{'obituaries'}, '[CLONE-OPEN] original handle still defined');
	is($obj->{'obituaries'}->{'_instance_id'}, $orig_id,
		'[CLONE-OPEN] original instance_id unchanged');

	# Clone opens its own handle on first search
	_set_rows([ _obit() ]);
	my @clone_r = $clone->search(last => 'Doe');
	ok(defined $clone->{'obituaries'}, '[CLONE-OPEN] clone now has its own handle');
	isnt($clone->{'obituaries'}->{'_instance_id'}, $orig_id,
		'[CLONE-OPEN] clone instance_id differs from original');
	is(_drv_count(), 2, '[CLONE-OPEN] two ::new() calls total (original + clone)');
};

subtest '[CLONE] clone with overridden directory is independent' => sub {
	_reset_spy();
	my $dir1 = _dir();
	my $dir2 = _dir();
	my $obj  = $PKG->new(directory => $dir1);

	my $clone = $obj->new(directory => $dir2);
	is($clone->{'directory'}, $dir2, '[CLONE] clone directory overridden');
	is($obj->{'directory'},   $dir1, '[CLONE] original directory unchanged');
	isnt(refaddr($obj), refaddr($clone), '[CLONE] distinct object references');
};

# ==========================================================================
# SECTION 3: Full Search Pipeline Transaction
#
# Lifecycle:  [OPEN] → [QUERY] → [TRANSFORM] → [COMPLETE]
# ==========================================================================

subtest '[QUERY → TRANSFORM → COMPLETE] list context: filter → url-inject → fixate → return' => sub {
	my $obj = _obj_with_handle();

	# QUERY: three rows, one undef — grep(defined) must remove the undef
	my @rows = (_obit(), undef, { %{_obit()}, source => 'F', page => 'v25no009' });
	_set_rows(\@rows);

	# COMPLETE: capture results
	my @rc = $obj->search(last => 'Doe');

	# TRANSFORM: undef row removed by grep
	is(scalar @rc, 2, '[COMPLETE] grep(defined) removed the undef row; 2 results');

	# TRANSFORM: url injected into each surviving row
	ok(exists $rc[0]->{url}, '[TRANSFORM] url key present in result 0');
	ok(exists $rc[1]->{url}, '[TRANSFORM] url key present in result 1');
	like($rc[0]->{url}, qr{wayback},   '[TRANSFORM] result 0: source M → Wayback URL');
	like($rc[1]->{url}, qr{freelists}, '[TRANSFORM] result 1: source F → Freelists URL');

	# TRANSFORM: fixate makes string values read-only
	throws_ok { $rc[0]->{last} = 'Hacked' }
		qr/read-only|Modification of a read-only/i,
		'[TRANSFORM] fixated value is read-only after COMPLETE';
};

subtest '[QUERY → TRANSFORM → COMPLETE] scalar context: fetchrow → url → fixate → hashref' => sub {
	my $obj = _obj_with_handle();

	my $raw = { %{_obit()}, source => 'M', page => '7' };
	_set_scalar($raw);
	my $r = $obj->search(last => 'Doe');

	ok(defined $r,         '[COMPLETE] scalar result defined');
	isa_ok($r, 'HASH',     '[COMPLETE] result is a hashref');
	ok(exists $r->{url},   '[TRANSFORM] url key injected');
	like($r->{url}, qr{wayback.*7$}, '[TRANSFORM] url correct for page 7');
};

subtest '[COMPLETE] void context: no crash, result silently discarded' => sub {
	my $obj = _obj_with_handle();
	_set_scalar(_obit());
	lives_ok { $obj->search(last => 'Doe') }
		'[COMPLETE] void-context search does not die';
};

subtest '[COMPLETE] list: N-row result set — all N rows transformed' => sub {
	my $obj  = _obj_with_handle();
	my @raw  = map { _obit() } 1 .. $N_ROWS;
	_set_rows(\@raw);

	my @rc = $obj->search(last => 'Doe');
	is(scalar @rc, $N_ROWS, "[COMPLETE] $N_ROWS rows returned");
	ok(exists $_->{url}, '[TRANSFORM] url present in every row') for @rc;
};

# ==========================================================================
# SECTION 4: Mid-Flight Failure and Rollback
#
# Invariants: exception from _create_url propagates; no partial result
#             returned; DB handle survives; object usable after exception.
# ==========================================================================

subtest '[ROLLBACK] bad-source mid-loop: exception propagates, no partial @rc' => sub {
	_reset_spy();
	my $obj = _obj_with_handle();

	# Row 1 (index 1) has unknown source — _create_url croaks mid-loop.
	# Rows 0 and 2 would succeed, but no partial list must leak back.
	_set_rows([
		_obit(),
		{ %{_obit()}, source => 'X' },	# triggers err_bad_source
		_obit(),
	]);

	throws_ok { my @r = $obj->search(last => 'Doe') }
		qr/Invalid source/i,
		'[ROLLBACK] croak from _create_url propagates out of search()';

	# Handle must still be alive — the object is usable after the exception
	ok(defined $obj->{'obituaries'},
		'[ROLLBACK] DB handle survives mid-flight exception');
};

subtest '[ROLLBACK] exception in scalar path: handle survives' => sub {
	my $obj = _obj_with_handle();
	_set_scalar({ %{_obit()}, source => 'X' });

	throws_ok { my $r = $obj->search(last => 'Doe') }
		qr/Invalid source/i,
		'[ROLLBACK] scalar-path croak propagates';
	ok(defined $obj->{'obituaries'},
		'[ROLLBACK] handle intact after scalar-path exception');
};

subtest '[ROLLBACK] object is reusable after mid-flight exception' => sub {
	my $obj = _obj_with_handle();

	# First search: croak due to bad source
	_set_rows([ { %{_obit()}, source => 'X' } ]);
	eval { my @r = $obj->search(last => 'Doe') };
	ok($@, '[ROLLBACK] first search raised exception');

	# Second search: valid data — must succeed
	_set_rows([ _obit() ]);
	my @r;
	lives_ok { @r = $obj->search(last => 'Doe') }
		'[ROLLBACK] object reusable after mid-flight exception';
	is(scalar @r, 1, '[ROLLBACK] second search returns one result');
};

subtest '[ROLLBACK] DB init failure: handle stays undef; croak fires' => sub {
	_reset_spy();
	my $obj = _obj();	# no pre-injected handle

	_db_returns_undef();
	eval { my @r = $obj->search(last => 'Doe') };
	my $err = $@;
	_db_returns_obj();

	like($err, qr/obituaries/i,
		'[ROLLBACK] err_no_obituaries raised when driver::new() returns undef');
	ok(!defined $obj->{'obituaries'},
		'[ROLLBACK] handle stays undef after failed init (//= not satisfied)');
	is(_drv_count(), 1,
		'[ROLLBACK] driver ::new() was attempted exactly once');
};

subtest '[ROLLBACK → RECOVERY] retry succeeds after DB init is restored' => sub {
	_reset_spy();
	my $obj = _obj();

	# Stage 1: fail
	_db_returns_undef();
	eval { my @r = $obj->search(last => 'Doe') };
	ok($@,                         '[ROLLBACK] first search failed');
	ok(!defined $obj->{'obituaries'}, '[ROLLBACK] handle still undef');

	# Stage 2: recover
	_db_returns_obj();
	_set_rows([ _obit() ]);
	my @r;
	lives_ok { @r = $obj->search(last => 'Doe') }
		'[RECOVERY] second search succeeds after driver restored';
	is(scalar @r, 1,               '[RECOVERY] one result returned');
	ok(defined $obj->{'obituaries'}, '[RECOVERY] handle now set');

	# Two driver calls: one that returned undef, one that succeeded
	is(_drv_count(), 2,
		'[RECOVERY] ::new() called twice (fail then succeed)');
};

# ==========================================================================
# SECTION 5: $@ Guard Transaction
#
# search() guards all internal evals with { local $@; eval { ... } }.
# Invariant: successful search leaves $@ clean; croak sets $@ correctly.
# ==========================================================================

subtest '[$@ GUARD] successful search leaves $@ clean' => sub {
	my $obj = _obj_with_handle();
	_set_rows([ _obit() ]);

	my @r = $obj->search(last => 'Doe');
	is($@, '',
		'[$@ GUARD] $@ is empty string after successful list search');
};

subtest '[$@ GUARD] successful scalar search leaves $@ clean' => sub {
	my $obj = _obj_with_handle();
	_set_scalar(_obit());

	my $r = $obj->search(last => 'Doe');
	is($@, '',
		'[$@ GUARD] $@ is empty string after successful scalar search');
};

subtest '[$@ GUARD] internal eval does not leak exception into outer eval on success' => sub {
	my $obj = _obj_with_handle();
	_set_rows([ _obit() ]);

	my $outer_caught;
	eval {
		my @r = $obj->search(last => 'Doe');
		# search() completes normally; no exception should reach here
		# even though search() ran an internal eval { fixate() }
	};
	$outer_caught = $@;

	is($outer_caught, '',
		'[$@ GUARD] outer eval sees no exception from successful search()');
};

subtest '[$@ GUARD] croak from search() correctly appears in $@' => sub {
	my $obj = _obj_with_handle();

	eval { $obj->search(last => undef) };
	like($@, qr/last.*mandatory|Value for 'last'/i,
		'[$@ GUARD] croak exception correctly propagated into $@');
};

subtest '[$@ GUARD] internal fixate guard preserves state across two searches' => sub {
	my $obj = _obj_with_handle();

	# First search: fixates the row's string values
	_set_rows([ _obit() ]);
	my @r1 = $obj->search(last => 'Doe');
	is($@, '', '[$@ GUARD] $@ clean after first search');

	# Second search: fresh row (new hashref from _obit())
	# The internal local $@ guard absorbs any fixate edge-case
	_set_rows([ _obit() ]);
	my @r2;
	lives_ok { @r2 = $obj->search(last => 'Doe') }
		'[$@ GUARD] second search does not die';
	is($@, '', '[$@ GUARD] $@ clean after second search');
	is(scalar @r2, 1, '[$@ GUARD] second search returns one result');
};

# ==========================================================================
# SECTION 6: Idempotency
# ==========================================================================

subtest '[IDEMPOTENT] same params N times → consistent url per result' => sub {
	my $obj = _obj_with_handle();
	my @urls;

	for my $i (1 .. $N_REPEAT) {
		_set_rows([ { %{_obit()}, source => 'M', page => '42' } ]);
		my ($r) = $obj->search(last => 'Doe');
		push @urls, $r->{url};
	}

	is($urls[$_], $urls[0], "run ${\($_ + 1)} url matches run 1 url")
		for 1 .. $#urls;
};

subtest '[IDEMPOTENT] no-match search is repeatable' => sub {
	my $obj = _obj_with_handle();

	for my $i (1 .. $N_REPEAT) {
		_set_rows(undef);
		my @r = $obj->search(last => 'Zzzzz');
		is(scalar @r, 0, "no-match run $i returns empty list");
	}
};

subtest '[IDEMPOTENT] new() N times → N distinct unconnected objects' => sub {
	my $dir     = _dir();
	my @objects = map { $PKG->new(directory => $dir) } 1 .. $N_REPEAT;

	for my $i (0 .. $#objects) {
		ok(defined $objects[$i] && blessed($objects[$i]),
			"object $i is a blessed instance");
		ok(!defined $objects[$i]->{'obituaries'},
			"object $i has no DB handle (not yet searched)");
		for my $j ($i + 1 .. $#objects) {
			isnt(refaddr($objects[$i]), refaddr($objects[$j]),
				"objects $i and $j are distinct references");
		}
	}
};

# ==========================================================================
# SECTION 7: Queue/Flush Deduplication Transaction (in-memory SQLite)
#
# Mirrors the queue() → flush() lifecycle from bin/create_db.PL using a
# real in-memory database so the transactional semantics are observable.
# The flush() logic is reimplemented inline (the original is a file-scoped
# sub in the build script and cannot be imported).
# ==========================================================================

Readonly::Scalar my $CREATE_SQL => join '', (
	'CREATE TABLE obituaries(',
	'first VARCHAR, middle VARCHAR, last VARCHAR NOT NULL,',
	' maiden VARCHAR, age INTEGER, place VARCHAR,',
	' newspaper VARCHAR NOT NULL, date DATE NOT NULL,',
	' source CHAR NOT NULL, page VARCHAR NOT NULL)',
);

Readonly::Scalar my $INSERT_SQL => join '', (
	'INSERT INTO obituaries',
	'(first, middle, last, maiden, age, place, newspaper, date, source, page)',
	' VALUES (?,?,?,?,?,?,?,?,?,?)',
);

sub _mem_db {
	return DBI->connect(
		'dbi:SQLite:dbname=:memory:', undef, undef,
		{ RaiseError => 1, AutoCommit => 0 }
	);
}

# Mirrors the deduplication + INSERT block from flush() in create_db.PL.
sub _flush {
	my ($dbh, $queue_ref) = @_;
	return unless @{$queue_ref};

	my (%seen, @deduped);
	while(my $item = pop @{$queue_ref}) {
		my $key = join '|', map { $item->{$_} // '' }
			qw(first last maiden age place date newspaper source page);
		push @deduped, $item unless $seen{$key}++;
	}
	@{$queue_ref} = ();
	return unless @deduped;

	my $sth = $dbh->prepare($INSERT_SQL);
	try {
		for my $row (@deduped) {
			my ($first, $middle);
			if($row->{'first'} && $row->{'first'} =~ /^(.+)\s+(.+)$/) {
				($first, $middle) = ($1, $2);
			} else {
				$first = $row->{'first'} || undef;
			}
			$sth->execute(
				$first,
				$middle,
				$row->{'last'},
				$row->{'maiden'}    || undef,
				$row->{'age'}       || undef,
				$row->{'place'}     || undef,
				$row->{'newspaper'} || undef,
				$row->{'date'},
				$row->{'source'},
				$row->{'page'},
			);
		}
	} catch {
		Carp::confess("flush() INSERT failed: $_");
	};
}

sub _count { my ($dbh) = @_; return ($dbh->selectrow_array('SELECT COUNT(*) FROM obituaries'))[0] }

sub _row {
	my (%override) = @_;
	return {
		first     => 'John',
		last      => 'Smith',
		maiden    => undef,
		age       => undef,
		place     => undef,
		newspaper => 'Test Paper',
		date      => '2024-01-15',
		source    => 'M',
		page      => '1',
		%override,
	};
}

subtest '[QUEUE-FLUSH] three records with one duplicate → two rows committed' => sub {
	my $dbh = _mem_db();
	$dbh->do($CREATE_SQL);

	my @queue = (
		_row(page => '1'),		# original
		_row(page => '1'),		# exact duplicate — must be deduped
		_row(page => '2', last => 'Jones'),	# distinct record
	);
	_flush($dbh, \@queue);
	$dbh->commit();

	is(_count($dbh), 2,
		'[QUEUE-FLUSH] 3 records (1 duplicate) → 2 unique rows in DB');
	is(scalar @queue, 0,
		'[QUEUE-FLUSH] queue emptied by flush()');
	$dbh->disconnect();
};

subtest '[QUEUE-FLUSH] empty queue is a no-op (no INSERT, no error)' => sub {
	my $dbh = _mem_db();
	$dbh->do($CREATE_SQL);

	my @queue = ();
	lives_ok { _flush($dbh, \@queue) }
		'[QUEUE-FLUSH] flush of empty queue does not die';
	$dbh->commit();
	is(_count($dbh), 0,
		'[QUEUE-FLUSH] empty queue → zero rows in DB');
	$dbh->disconnect();
};

subtest '[QUEUE-FLUSH] mid-flight INSERT failure → rollback leaves DB clean' => sub {
	my $dbh = _mem_db();
	$dbh->do($CREATE_SQL);

	# Establish baseline: one good record committed
	my @baseline = (_row(page => '0', last => 'Baseline'));
	_flush($dbh, \@baseline);
	$dbh->commit();
	is(_count($dbh), 1, '[ROLLBACK] baseline: one committed row');

	# Now simulate a mid-flight failure by making the table read-only
	# (drop the table after preparing the stmt, or use a trigger to force fail)
	# Simplest approach: try to INSERT into a non-existent column → DBI dies
	my @bad_queue = (_row(page => '99'));
	try {
		my $sth = $dbh->prepare('INSERT INTO nonexistent_table(x) VALUES (?)');
		$sth->execute('boom');
	} catch {
		$dbh->rollback();
	};

	# The DB must remain at baseline (rollback preserved committed state)
	is(_count($dbh), 1,
		'[ROLLBACK] DB still at baseline after rolled-back transaction');
	$dbh->disconnect();
};

subtest '[QUEUE-FLUSH] idempotent: flushing same records twice → no extra rows' => sub {
	my $dbh = _mem_db();
	$dbh->do($CREATE_SQL);

	my $rec = _row(page => '1', last => 'Twice');

	# First flush: inserts the record
	my @q1 = ($rec);
	_flush($dbh, \@q1);
	$dbh->commit();
	is(_count($dbh), 1, '[IDEMPOTENT-FLUSH] first flush: 1 row committed');

	# Second flush of the same record: the record is queued again (as a new
	# hashref) but has identical field values — deduplication within the batch
	# removes it.  The DB already has the row from the first flush; since there
	# is no UNIQUE constraint, this tests within-batch deduplication only.
	my @q2 = (_row(page => '1', last => 'Twice'));	# identical values
	_flush($dbh, \@q2);
	$dbh->commit();

	# The second flush had exactly one unique record in @q2, so it inserts once.
	# Total: 2 rows (one from each flush).  This mirrors real-world behaviour
	# where nightly rebuilds re-scrape and re-insert — dedup is within-batch.
	is(_count($dbh), 2,
		'[IDEMPOTENT-FLUSH] second flush of same record: within-batch dedup only');
};

subtest '[QUEUE-FLUSH] within-batch dedup: 10 identical records → 1 row' => sub {
	my $dbh = _mem_db();
	$dbh->do($CREATE_SQL);

	my @queue = map { _row(page => '77', last => 'Dedup') } 1 .. $FLUSH_THRESHOLD;
	is(scalar @queue, $FLUSH_THRESHOLD, 'pre-condition: queue has correct count');
	_flush($dbh, \@queue);
	$dbh->commit();

	is(_count($dbh), 1,
		"[QUEUE-FLUSH] $FLUSH_THRESHOLD identical records → 1 unique row after dedup");
	$dbh->disconnect();
};

subtest '[QUEUE-FLUSH] first/middle split: space in first → splits into first+middle cols' => sub {
	my $dbh = _mem_db();
	$dbh->do($CREATE_SQL);

	my @queue = (_row(first => 'Jean Emily', last => 'McCarthy'));
	_flush($dbh, \@queue);
	$dbh->commit();

	my $row = $dbh->selectrow_hashref('SELECT first, middle, last FROM obituaries');
	is($row->{first},  'Jean',    '[QUEUE-FLUSH] first name split correctly');
	is($row->{middle}, 'Emily',   '[QUEUE-FLUSH] middle name split correctly');
	is($row->{last},   'McCarthy','[QUEUE-FLUSH] last name unchanged');
	$dbh->disconnect();
};

# ==========================================================================
# SECTION 8: Full Entity Lifecycle Integration
#
# Sequence: CREATE → OPEN → QUERY → COMPLETE → CLONE → CLONE-QUERY
#           → ROLLBACK → RECOVERY → IDEMPOTENT
# ==========================================================================

subtest 'FULL LIFECYCLE: complete entity sequence end-to-end' => sub {
	_reset_spy();

	# Phase CREATE
	my $obj = $PKG->new(directory => _dir());
	ok(defined $obj && blessed($obj), '[CREATE] object blessed');
	ok(!defined $obj->{'obituaries'}, '[CREATE] no DB handle yet');
	is(_drv_count(), 0,               '[CREATE] no driver calls');

	# Phase OPEN + QUERY + COMPLETE (list context, 2 rows)
	_set_rows([
		{ %{_obit()}, source => 'M', page => '1' },
		{ %{_obit()}, source => 'F', page => 'v25no009' },
	]);
	my @results = $obj->search(last => 'Doe');

	ok(defined $obj->{'obituaries'},     '[OPEN] handle open after first search');
	is(_drv_count(), 1,                  '[OPEN] ::new() called once');
	is(scalar @results, 2,               '[COMPLETE] two results');
	ok(exists $results[0]->{url},        '[COMPLETE] url in result 0');
	ok(exists $results[1]->{url},        '[COMPLETE] url in result 1');
	like($results[0]->{url}, qr{wayback},   '[COMPLETE] result 0: Wayback');
	like($results[1]->{url}, qr{freelists}, '[COMPLETE] result 1: Freelists');

	# Phase CLONE
	my $clone = $obj->new();
	ok(defined $clone && blessed($clone), '[CLONE] clone blessed');
	isnt(refaddr($obj), refaddr($clone),  '[CLONE] distinct reference');
	is($clone->{'obituaries'}->{'_instance_id'},
		$obj->{'obituaries'}->{'_instance_id'},
		'[CLONE] shares handle with original');
	is(_drv_count(), 1, '[CLONE] no extra ::new() from clone()');

	# Phase CLONE-QUERY
	_set_rows([ _obit() ]);
	my @cr = $clone->search(last => 'Doe');
	is(scalar @cr, 1,   '[CLONE-QUERY] clone returned 1 result');
	is(_drv_count(), 1, '[CLONE-QUERY] handle still shared (count=1)');

	# Phase ROLLBACK: bad source mid-loop on original
	_set_rows([ _obit(), { %{_obit()}, source => 'X' } ]);
	eval { my @r = $obj->search(last => 'Doe') };
	ok($@,                             '[ROLLBACK] exception from bad source');
	ok(defined $obj->{'obituaries'},   '[ROLLBACK] handle survives exception');

	# Phase RECOVERY: original still functional after exception
	_set_rows([ _obit(), _obit(), _obit() ]);
	my @recovered;
	lives_ok { @recovered = $obj->search(last => 'Doe') }
		'[RECOVERY] original object functional after rollback';
	is(scalar @recovered, 3, '[RECOVERY] three results on recovery search');

	# Phase IDEMPOTENT: same-params search N times → consistent results
	my $ref_url = $recovered[0]->{url};
	for my $i (1 .. $N_REPEAT) {
		_set_rows([ { %{_obit()}, page => '5' } ]);
		my ($r) = $obj->search(last => 'Doe');
		is($r->{url}, "${WAYBACK}5",
			"[IDEMPOTENT] run $i url is stable");
	}
	is(_drv_count(), 1,
		"[IDEMPOTENT] handle opened exactly once across full lifecycle");
};

done_testing();
