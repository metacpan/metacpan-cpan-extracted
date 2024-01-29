#!perl
use strict;
use warnings;
use Test::More tests => 174;
use Test::Exception;
use Encode;

use File::Temp;
use LMDB_File qw(:envflags :cursor_op);

# The tests needs 'C' LC_MESSAGES
eval { require POSIX; POSIX::setlocale(POSIX::LC_ALL(), 'C'); };

throws_ok {
    LMDB::Env->new("NoSuChDiR");
} qr/No such|cannot find/, 'Directory must exists';

my $dir = File::Temp->newdir('mdbtXXXX', TMPDIR => 1, EXLOCK => 0);
ok(-d $dir, "Created $dir");
my $testdir = "TestDir";

throws_ok {
    LMDB::Env->new($dir, { flags => MDB_RDONLY });
} qr/No such|cannot find/, 'RO must exists';

{
    my $env = new_ok('LMDB::Env' => [ $dir ], "Create Environment")
	or BAIL_OUT("Can't create environment, test the LMDB library first!");
    ok(-e "$dir/data.mdb", 'Data file created exists');
    ok(-e "$dir/lock.mdb", 'Lock file created exists');
    $env->get_path(my $dummy);
    is($dir, $dummy, 'get_path');

    # Environment flags
    {
	$env->get_flags($dummy);
	my $expflags = 
	    $^O =~ /openbsd/ ? MDB_WRITEMAP : # Forced, sorry
	    0x0; # None set
	is($dummy, $expflags, 'Flags setted'); # Using private
    }
    ok($env->id, 'Env ID: ' . $env->id);

    # Basic Environment info
    isa_ok(my $envinfo = $env->info, 'HASH', 'Get Info');
    ok(exists $envinfo->{$_}, "Info has $_")
	for qw(mapaddr mapsize last_pgno last_txnid maxreaders numreaders);
    ok(!exists $envinfo->{SomeOther}, 'Not in info');

    is($envinfo->{mapaddr}, 0, 'Not mapfixed');
    is($envinfo->{mapsize}, 1024 * 1024, 'Stock mapsize');
    is($envinfo->{maxreaders}, 126, 'Default maxreders');
    is($envinfo->{numreaders}, 0, 'No readers');

    isa_ok(my $stat = $env->stat, 'HASH', 'Get Stat');
    ok(exists $stat->{$_}, "Stat has $_")
	for qw(psize depth branch_pages leaf_pages overflow_pages entries);
    # psize differs on various platforms
    #is($stat->{psize}, 4096, 'Default psize');
    is($stat->{$_}, 0, "$_ = 0, empty")
	for qw(depth branch_pages leaf_pages overflow_pages entries);

    # Check Internals
    {
	my @envid = keys %LMDB::Env::Envs;
	is(scalar(@envid), 1, 'One Environment');
	is($envid[0],  $$env, 'The active one');
	my $ed = $LMDB::Env::Envs{$$env};
	isa_ok($ed, 'ARRAY');
	is(scalar @{ $ed }, 4, 'Size');
	isa_ok($ed->[0], 'ARRAY', 'Txns');
	isa_ok($ed->[1], 'ARRAY', 'DCmps');
	isa_ok($ed->[2], 'ARRAY', 'Cmps');
	isa_ok(\$ed->[3], 'SCALAR', 'OFlags');
    }

    # Check Env refcounts
    is(Internals::SvREFCNT($$env), 1, 'Env Inactive');

    isa_ok(my $txn = $env->BeginTxn, 'LMDB::Txn', 'Transaction');
    ok($txn->_id > 0, 'Expected');
    is($txn->_id, $$txn, "Txn Id ($$txn)");
    is(Internals::SvREFCNT($$txn), 1, 'Txn active');

    is(Internals::SvREFCNT($$env), 2, 'Env Active');
    throws_ok {
	$txn->OpenDB('NAMED');
    } qr/limit reached/, 'No named allowed';

    SKIP: {
	skip "Unsuported with MDB_WRITEMAP", 2 if $dummy & MDB_WRITEMAP;
	isa_ok(my $sub = $env->BeginTxn, 'LMDB::Txn', 'Subtransaction');
	is(Internals::SvREFCNT($$env), 3, 'Env Active');
    }

    is(Internals::SvREFCNT($$env), 2, 'Back normal');
    {
	isa_ok(my $eclone = $txn->env, 'LMDB::Env', 'Got Env');
	is($env->id, $eclone->id, "The same env ID ($$env)");
	is(Scalar::Util::refaddr($env), Scalar::Util::refaddr($eclone), 'Same refaddr');
	is(Internals::SvREFCNT($$env),  3, 'Refcounted');
    }
    is(Internals::SvREFCNT($$env), 2, 'Back normal');
    lives_ok {
	$txn->commit;
	is(Internals::SvREFCNT($$env), 1, 'Env free');
    } 'Null Commit';
    throws_ok {
	$txn->commit;
    } qr/Terminated/, 'Terminated';
    is($$txn, 0, 'Nullified');
    is($txn->_id, 0, 'The same');

    ok($txn = $env->BeginTxn, 'Recreated');

    # Open main DB
    isa_ok(my $DB = $txn->OpenDB, 'LMDB_File', 'DBI created');
    is($DB->Alive, 1, 'The first');
    is($DB->flags, 0, 'Main DBI Flags');
    is($env->info->{numreaders}, 0, "I'm not a reader");

    is(Internals::SvREFCNT($$txn), 2, 'DB Keeps Txn');

    is($txn->OpenDB->Alive, $DB->Alive, 'Just a clone');

    # Put some data
    my %data;
    my $c;
    foreach('A' .. 'Z') {
	$c = ord($_) - ord('A') + 1;
	my $k = $_ x 4;
	my $v = sprintf('Datum #%d', $c);
	$data{$k} = $v; # Keep a copy, for testing
	if($c < 4) {
	    is($DB->put($k, $v), $v, "Put $k");
	    is($DB->stat->{entries}, $c, "Entry $c");
	} else {
	    # Don't be verbose
	    $DB->put($k, $v);
	}
    }
    is($c, 26, 'All in');

    # Check data in random HASH order
    $c = 5; # Don't be verbose
    while(my($k, $v) = each %data) {
	is($DB->get($k), $v, "Get $k") if(--$c >= 0);
    }

    {	# Check UTF8 Handling
	use utf8;
	use Devel::Peek;
	my $unicode = "♠♡♢♣"; # U+2660 .. U+2663 
	is(length $unicode, 4, 'Four unicode characters');
	my $invariant = "áéíóú";
	my $latin1 = Encode::encode('Latin1', $invariant);
	# Without explicit help of LMDB_File we need extra care
	is($DB->put('UNIC', $unicode), $unicode, 'Put unicode');
	my $data = $DB->get('UNIC');
	isnt($data, $unicode, 'Not the same!');
	{ use bytes; ok($data eq $unicode, 'Ugly!'); }
	# Use Latin1
	is($DB->put('UNIC2', $latin1), $latin1, 'Put latin1');
	$data = $DB->get('UNIC2');
	is($data, $latin1, 'By chance');
	# But beware
	is($data, $invariant, 'By perl magic');
	{ use bytes; ok($data ne $invariant, 'ne OK!?'); }

	# Safe only if use explicit encode/decode
	my $encoded = Encode::encode_utf8($unicode);
	is($DB->put('ENC1', $encoded), $encoded, 'Put encoded');
	$data = $DB->get('ENC1');
	isnt($data, $unicode, 'Need decode');
	is(Encode::decode_utf8($data), $unicode, 'Decode');
	is(Encode::decode('Latin1', $DB->get('UNIC2')), $invariant, 'Should');

	# Easier with explicit help
	is($DB->UTF8(1), 0, 'Was off');

	is($DB->put('UNIC', $unicode), $unicode, 'Just put in');
	is($DB->get('UNIC'), $unicode, 'Just get out');
	$data = do { use bytes; $DB->get('UNIC'); };
	is($data, $encoded, 'Handy');
	{
	    # Be permisive
	    my $warn;
	    local $SIG{__WARN__} = sub { $warn = shift };
	    $data = $DB->get('UNIC2');
	    like($warn, qr/Malformed/, 'Warning emited');
	    ok(!utf8::is_utf8($data), 'No UTF8');
	    is($data, $latin1, 'But just works');
	    $warn = '';

	    # Can correct that.
	    is($DB->put('UNIC2', $latin1), $latin1, 'Just put encoded');
	    ok(!utf8::is_utf8($latin1), 'Orig not touched');
	    $data = $DB->get('UNIC2');
	    is($data, $invariant, 'Must be');
	    { use bytes; ok($data eq $invariant, 'No suprises'); }
	    is($data, $latin1, 'Just get out encoded');
	    { use bytes; ok($data ne $latin1, 'Expected'); }
	    ok($warn eq '', 'No more warnings');
	}

	is($DB->get('ENC1'), $unicode, 'Safe played');
	is($DB->get('AAAA'), $data{'AAAA'}, 'Unaltered');

	$DB->del($_) for qw(UNIC UNIC2 ENC1);
    }

    # Commit
    lives_ok { $txn->commit; }  'Commited';

    # Commit terminates transaction and DB
    ok(!$DB->Alive, "Not Alive");
    is($DB->Txn, undef, "No Txn");
    is($DB->dbi, 1, "Last memory of dbi");
    throws_ok {
	$DB->get('SOMEKEY');
    } qr/Not an active/, 'Commit invalidates DB';
    throws_ok {
	$txn->OpenDB;
    } qr/Not an alive/, 'Commit finalized txn';
    lives_ok {
	my $warn;
	local $SIG{__WARN__} = sub { $warn = shift };
	$txn->abort;
	like($warn, qr/Terminated/, 'Warning emited');
	is($txn->_id, 0, 'Expected 0');
	is($$txn, 0, 'A ghost...');
	$warn = ''; # Clean;
	undef $txn;
	ok(!$warn, 'No warnings');
    } 'but blessed';

    is(Internals::SvREFCNT($$env), 1, 'Env Inactive');
    is($env->info->{numreaders}, 0, 'No readers yet');

    # Test copy method
    throws_ok {
	$env->copy($testdir);
    } qr/No such/, 'Copy needs a directory';
    throws_ok {
	$env->copy($dir);
    } qr/file exists|error/i, 'An empty one, not myself';

    SKIP: {
	skip "Need a local directory", 2 unless(-d $testdir or mkdir $testdir);
	is($env->copy($testdir), 0, 'Copied');
	my $size = -s "$testdir/data.mdb";
	ok($size, "Data file created, $size");
    }
    $testdir = $dir unless -s "$testdir/data.mdb";

    {
	open(my $fd, '>', "$testdir/other.mdb");
        is($env->copyfd($fd), 0, 'Copied to HANDLE');
	#is($env->info->{numreaders}, 1, 'A reader');
    }

    isa_ok($DB = LMDB_File->new($env->BeginTxn(MDB_RDONLY), 1),
	'LMDB_File', 'DBI fast opened RO');

    throws_ok {
	$DB->put('0000', 'Datum #0');
    } qr/Permission denied/, 'Read only transaction';

    is($env->info->{numreaders}, 1, "I'm a reader");
    is($DB->stat->{entries}, 26, 'Has my data');

    # Read using cursors
    isa_ok(my $cursor = $DB->Cursor, 'LMDB::Cursor', 'A cursor');
    is($cursor->dbi, $DB->Alive, 'Get DBI');

    $cursor->get(my $key, my $datum, MDB_FIRST);
    is($key, 'AAAA', 'First key');
    is($datum, 'Datum #1', 'First datum');
    throws_ok {
	$cursor->get($key, $datum, MDB_PREV);
    } qr/NOTFOUND/, 'No previous key';
    $cursor->get($key, $datum, MDB_NEXT);
    is($key, 'BBBB', 'Next key');
    is($datum, 'Datum #2', 'Next datum');
    $cursor->get($key, $datum, MDB_LAST);
    is($key, 'ZZZZ', 'Last key');
    is($datum, 'Datum #26', 'Last datum');
    $cursor->get($key, $datum, MDB_PREV);
    is($key, 'YYYY', 'Previous key');
    is($datum, 'Datum #25', 'Previous datum');
    $key = $datum = '';
    $cursor->get($key, $datum, MDB_GET_CURRENT);
    is($key, 'YYYY', 'Current key');
    is($datum, 'Datum #25', 'Current datum');

    throws_ok {
	# Most cursor_ops need to return the key
	$cursor->get('CCCC', $datum, MDB_GET_CURRENT);
    } qr/read-only value/, 'Need lvalue';
    lives_ok {
	# Some accept a constant
	$cursor->get('CCCC', $datum, MDB_SET);
    } 'Can be constant';
    is($datum, 'Datum #3', 'lookup datum');

    throws_ok {
	$cursor->get($key = 'ZABC', $datum, MDB_SET);
    } qr/NOTFOUND/, 'Not found';
    $cursor->get($key, $datum, MDB_SET_RANGE);
    is($key, 'ZZZZ', 'Got last key');
    is($datum, 'Datum #26', 'Got last datum');
    throws_ok {
	$cursor->get($key, $datum, MDB_NEXT);
    } qr/NOTFOUND/, 'No next key';
}
is(scalar keys %LMDB::Env::Envs, 0, 'No environment open');
{
    # Using TIE interface
    my $h;
    isa_ok(
	tie(%$h, 'LMDB_File', "$testdir/other.mdb" => {
		flags => MDB_NOSUBDIR,
		mapsize => 2 * 1024 * 1024,
	    }),
	'LMDB_File', 'Tied'
    );
    { # Consistency checks
	isa_ok(my $DB = tied %$h, 'LMDB_File', 'The same');
	isa_ok(my $txn = $DB->Txn, 'LMDB::Txn', 'Has Txn');
	isa_ok(my $env = $txn->env, 'LMDB::Env');
        is($env->info->{mapsize}, 2 * 1024 * 1024, 'mapsize increased');
	is($DB->dbi, 1,  'The default one');
    }

    # Check optimized scalar
    ok(scalar %$h, 'Has data');
    is($h->{EEEE}, 'Datum #5', 'FETCH');
    is($h->{ABCS}, undef, 'No data');
    my @keys = keys %{$h};
    is(scalar @keys, 26, 'Size');
    is_deeply(['A'..'Z'], [ map substr($_, 0, 1), @keys ], 'All in');

    ok(exists $h->{ZZZZ}, 'Exists');
    is(delete $h->{ZZZZ}, 'Datum #26', 'Deleted #26');
    ok(!exists $h->{ZZZZ}, 'Really deleted');
    is(scalar %$h, 25, 'Reduced');

    is($h->{ZZZZ} = 'New data', 'New data', 'STORE');
    is(scalar %$h, 26, 'Stored');
    is($h->{ZZZZ}, 'New data', 'Really stored');
    %$h = ();
    ok(!scalar %$h, 'Emptied');
    %$h = (a => 1, b => 2, c=>3);
    is(scalar %$h, 3, 'Loaded');

    # Check each
    while(my($k, $v) = each %$h) {
	is(ord($k)-96,$v, "Match for $k");
    }

    untie %$h;
}

END {
    unless($ENV{KEEP_TMPS}) {
	for($testdir, $dir) {
	    unlink glob("$_/*");
	    rmdir or warn "rm $_: $!\n";
	    #warn "Removed $_\n";
	}
    }
}
