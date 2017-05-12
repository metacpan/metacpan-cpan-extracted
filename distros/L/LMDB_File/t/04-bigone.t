#!perl
use Test::More tests => 14;
use Test::Exception;
use strict;
use warnings;

use File::Temp;
use LMDB_File qw(:flags :cursor_op);

my $hastr = eval { require Time::HiRes; \&Time::HiRes::gettimeofday };

my $dir = File::Temp->newdir('mdbtXXXX', TMPDIR => 1, EXLOCK => 0);

my $mode = MDB_INTEGERKEY;
my $packer = 'I';
my $howmany = 2_000_000;

ok(my $env = LMDB::Env->new($dir,
	{ mapsize => 50*1024*1024, maxdbs => 2 }
    ), 'Env created'
);

{
    ok(my $txn = $env->BeginTxn, 'Txn created');
    ok(my $dbi = $txn->open('id1', $mode|MDB_CREATE), 'DB opened');
    isa_ok(my $db = LMDB_File->new($txn, $dbi), 'LMDB_File');
    is($db->flags & $mode, $mode, 'Flag setted');

    my $t0 = [ $hastr->() ] if $hastr;
    for( my $i = 0; $i < $howmany; $i++ ) {
	$txn->put($dbi, $i, pack($packer, $i) );
    }
    is($db->stat->{entries}, $howmany, '2M entries writen');
    diag(sprintf "Writen %d in %g seconds", $howmany, Time::HiRes::tv_interval($t0))
	if $hastr;
    $txn->commit;

    $db = $env->BeginTxn->OpenDB('id1');
    my $cur = $db->Cursor;
    my ($k, $d, $c);
    $t0 = [ $hastr->() ] if $hastr;
    for( my $i = 0; $i < $howmany; $i++ ) {
	$cur->_get($k, $d, $i ? MDB_PREV : MDB_LAST ); # Uses fast version
	unless($i) {
	    is($k, $howmany - 1, 'Last');
	    is(length($d), length(pack('L', 0)), 'Packed');
	    is(unpack($packer, $d), $k, 'Match');
	}
	$c+=$k;
    }
    diag(sprintf "Readed %d in %g seconds", $howmany, Time::HiRes::tv_interval($t0))
	if $hastr;
    is($c, ($howmany-1) * $howmany / 2, 'Sum OK');
    is($k, 0, 'First');
    ok($d, 'Has value');
    is(length($d), length(pack($packer, 1)), 'Packed');
    is(unpack('L', $d), 0, 'Match');
    my $stat = $db->stat;
    note "$_: $stat->{$_}" for(keys %{ $stat });
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
