#!perl
use Test::More tests => 50;
use Test::Exception;
use strict;
use warnings;
use utf8;

use File::Temp;

use LMDB_File qw(:flags :cursor_op);

my $dir = File::Temp->newdir('mdbtXXXX', TMPDIR => 1, EXLOCK => 0);
ok(-d $dir, "Created test dir $dir");
my $env = LMDB::Env->new($dir, { maxdbs => 5 });
{
    is($env->BeginTxn->OpenDB->stat->{entries}, 0, 'Empty');
}
{
    my $txn = $env->BeginTxn;
    my $mdb = $txn->OpenDB;
    ok($mdb, "Main DB Opened");
    is($mdb->stat->{entries}, 0, 'Empty');
    throws_ok {
	$txn->OpenDB('SOME');
    } qr/NOTFOUND/, 'No created yet';
    my $DB = $txn->OpenDB('SOME', MDB_CREATE);
    ok($DB, "SOME DB Opened");
    is($mdb->stat->{entries}, 1, 'Created');
}
{
    my $txn = $env->BeginTxn;
    is($txn->OpenDB->stat->{entries}, 0, 'Empty');
    throws_ok {
	$txn->OpenDB('SOME');
    } qr/NOTFOUND/, 'No preserved';
}
{
    my $txn = $env->BeginTxn;
    $txn->AutoCommit(1);
    ok(my $odb = $txn->OpenDB({dbname => 'ONE', flags => MDB_CREATE}), 'ONE Created');
    is($odb->[1], 2, 'First One');
    $odb->put(Test => 'Hello World');
    $odb->put(Test2 => 'A simple string');
    is($odb->stat->{entries}, 2, 'In there');
}
{
    my $txn = $env->BeginTxn;
    ok(my $db = $txn->OpenDB({dbname => 'TWO', flags => MDB_CREATE}), 'TWO Created');
    is($db->[1], 3, 'Second One');
    is($db->stat->{entries}, 0, 'Empty');
    ok(!$db->get('Test'), "No in this");
}
{
    my $txn = $env->BeginTxn;
    ok(my $odb = $txn->OpenDB('ONE'), 'Preserved');
    is($odb->stat->{entries}, 2, "With 2 keys");
    is($odb->get('Test'), 'Hello World', 'In there');
    is(LMDB_File->open($txn)->stat->{entries}, 1, 'ONE DB');
    throws_ok {
	$odb->open('TWO');
    } qr/NOTFOUND/, 'NO TWO DB';
    lives_ok { $odb->drop; } 'ONE emptied';
    is($odb->stat->{entries}, 0, 'Removed');
}
{
    my $txn = $env->BeginTxn;
    # A case insensitive DB
    ok(my $DBN = $txn->OpenDB('CI', MDB_CREATE), 'CI Created');
    $DBN->set_compare(sub { lc($a) cmp lc($b) });

    # A Reversed key order DB
    ok(my $DBR = $DBN->open('RK', MDB_CREATE|MDB_REVERSEKEY), 'RK Created');

    my %data;
    my $c;
    foreach('A' .. 'Z') {
	$c = ord($_) - ord('A') + 1;
	my $k = $_ . chr(ord('Z')+1-$c);
	my $v = sprintf('Datum #%d', $c);
	$data{$k} = $v;
	if($c < 4) {
	    is($DBN->put($k, $v), $v, "Put in CI $k");
	    is($DBN->stat->{entries}, $c, "Entry CI $c");
	    is($DBR->put($k, $v), $v, "Put in RK $k");
	    is($DBR->stat->{entries}, $c, "Entry RK $c");
	} else {
	    # Don't be verbose
	    $DBN->put($k, $v);
	    $DBR->put($k, $v);
	}
    }
    is($c, 26, 'All in');
    # Check data in random HASH order
    $c = 5; # Don't be verbose
    while(my($k, $v) = each %data) {
	is($DBN->get(lc $k), $v, "Get CI \L$k");
	is($DBR->get($k), $v, "Get RK $k");
	--$c or last;
    }
    my $ordkey = [ sort keys %data ];
    tie %data, $DBN;
    is_deeply( $ordkey, [ keys %data ], 'Ordered');
    untie %data;
    tie %data, $DBR;
    is_deeply( $ordkey, [ reverse keys %data ], 'Reversed' );
    untie %data;
}
END {
    unless($ENV{KEEP_TMPS}) {
        for($dir) {
            unlink glob("$_/*");
            rmdir $_;
            #warn "Removed $_\n";
        }
    }
}
