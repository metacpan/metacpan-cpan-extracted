#!perl
use strict;
use warnings;
use utf8;
use Test::More tests => 53;
use Test::Exception;
#use Test::ZeroCopy;
use B;
use Benchmark qw(:hireswallclock);
use Config;
#use Devel::Peek;
#$Devel::Peek::pv_limit = 20;

use File::Temp;
use LMDB_File qw(:flags :cursor_op);

my $dir = File::Temp->newdir('mdbtXXXX', TMPDIR => 1, EXLOCK => 0);
ok(-d $dir, "Created test dir $dir");
my $large1 = '0123456789' x 100_000;
my $val;
{
    my $env = LMDB::Env->new($dir, {
        mapsize => 100 * 1024 * 1024
    });
    ok(my $DB = $env->BeginTxn->OpenDB, 'Open unamed');
    is($DB->dbi, 1, 'Opened');
    is($DB->put('A' => $large1), $large1, 'Put large value');
    $DB->Txn->commit;

    $DB = LMDB_File->new($env->BeginTxn(MDB_RDONLY), 1);
    is($DB->ReadMode, 0, 'In normal read mode');
    $DB->get('A', $val);
    is(length($val), 1_000_000, '1MB');
    is($val, $large1, 'The value is there');
    ok(my $inspec = B::svref_2object(\$val), 'Inspected');
    ok($inspec->isa('B::PV'), 'Is a PV');
    ok($inspec->LEN > 0, 'Perl owned');
    #Dump($val);

    my $t = timeit(50, sub { $DB->get('A', $val) for (1..1000); });
    diag("Normal mode in ", timestr($t));

    is($DB->ReadMode(1),  0, 'Previous mode returned');
    is($DB->ReadMode, 1, 'In fast read mode');
    $DB->get('A', my $fval);
    #Dump($fval);
    is(length($fval), 1_000_000, '1MB');
    is($fval, $large1, 'The value is there');
    ok($inspec = B::svref_2object(\$fval), 'Inspected');
    ok($inspec->isa('B::PVMG'), 'Is a PVMG');
    is($inspec->LEN, 0, 'Not perl owned');
    is($fval, $val, 'Same value');
    #isnt_zerocopy($fval, $val, 'Diferent buffer');
    throws_ok {
	$fval = 'Hola';
    } qr/read-only/, 'Is ReadOnly';

    $t = timeit(50, sub { $DB->get('A', $val) for (1..1000); });
    diag("Fast mode in ", timestr($t));
    is($fval, $val, 'Same value');
    #is_zerocopy($fval, $val, 'Same buffer');
    my $oval = $DB->Rget('A');
    is($$oval, $val, 'Same value by ref');
    #is_zerocopy($$oval, $val, 'Same buffer by ref');

    $DB = undef;
    $DB = LMDB_File->new($env->BeginTxn(MDB_RDONLY), 1);
    is($DB->ReadMode, 1, 'Preserved fast read mode');
    $DB->get('A', $fval);
    #Dump($fval);
    TODO: {
	local $TODO = 'End of Txn should invalidate fastmode magic vars';
	ok(!defined($val), 'Was invalidated');
	# Commented until fixed ZeroCopy
	#isnt_zerocopy($fval, $val, 'New Txn, so different buffer');
    }
    my $count = $fval =~ tr/5/5/;
    is($count, 100_000, 'fives');
    throws_ok {
	$count = $fval =~ tr/5/E/;
    } qr/read-only/, 'Is RO';
}
{
    # Change environment to MDB_WRITEMAP.
    my $env = LMDB::Env->new($dir, { flags => MDB_WRITEMAP });
    ok(my $DB = $env->BeginTxn->OpenDB, 'Open unamed in WM');
    is($DB->ReadMode(1), 0, 'No fast read mode preserved');
    $DB->get('A', my $fval);
    #Dump($fval);
    # According to cpantesters on Mac OS X and Debian's libc-2.3.6 the
    # same address for mmap is used!!
    #isnt_zerocopy($fval, $val, 'New Env, so diferent buffer');
    $DB->get('A', $val);
    for($fval) { # A twist
	#Dump($_);
	is($_, $large1, 'The value is there');
	my $count;
	lives_ok {
	    $count = tr/5/E/;
	} 'Now R/W!';
	is($count, 100_000, 'fives replaced');
	is(tr/5/5/, 0, 'No more fives');
	#is_zerocopy($_, $val, 'Same buffer yet');
	isnt($_, $large1, 'The value has changed');
	{ # Test for warning when indirect writes
	    my $warn;
	    local $SIG{__WARN__} = sub { $warn = shift };
	    $_ = 'Z' x 9;
	    like($warn, qr/not recommended/, 'Warn emited');
	    is(length, 1_000_000, 'Length unchanged');
	    $warn = '';
	    is(s/123/ABC/g, 99_999, 'Lots changed');
	    is($warn, '', 'No warn emited');
	    # Try to extend/grow
	    $_ .= 'hi';
	    like($warn, qr/Truncating/, 'Truncating warning emited');
	    is(length, 1_000_000, 'Length unchanged');
	    is(substr($_, -1, 1), '9', 'Last byte is 9');
	}
	#is_zerocopy($_, $val, 'Same buffer yet');
    }
    SKIP: {
	skip 'Need ASCII platform', 1 unless 65 == ord 'A';
	for(substr($fval, 20, 9)) {
	    $_ |= ('p' x 9);
	    is(uc, 'PQRSTUVWX', 'Bits changed');
	}
    }
    lives_ok {
	$DB->Txn->commit();
    } 'Changes commited';
    isnt($DB->Alive, 'Because Txn terminated');

    ($DB->Txn = $env->BeginTxn)->AutoCommit(1); #Nice hack
    is($DB->Alive, 1, 'Alive again');
    is($DB->ReadMode, 1, 'Preserved');
    $DB->get('A', $fval);
    is($fval =~ tr/A/A/, 99_998, 'Changes preserved');
    $fval =~ s/9/\n/g;
    {
	local $LMDB_File::DEBUG = 1;
	my $warn; local $SIG{__WARN__} = sub { $warn .= shift };
	$DB->Txn = undef; # Commit, another hack
	like($warn, qr/commiting/, 'In AutoCommit');
	like($warn, qr/commited/, 'Commited');
    }
    $DB->Txn = $env->BeginTxn(MDB_RDONLY);
    SKIP: {
	skip 'Need perlio and PerlIO::scalar', 6
	    unless PerlIO::Layer->find('perlio') &&
	    $Config{'extensions'} =~ m|PerlIO/scalar|;

	# Try a nice trick
	require IO::File;
	my $io = IO::File->new($DB->Rget('A'), 'r');
	isa_ok($io, 'IO::File');
	is($io->getline, 'Z' x 9 . "\n");
	is($io->getline, "0ABC4E678\n");
	is($io->getline, "pqrstuvwx\n");
	my($c, $l) = (3, 30); #So far
	while(<$io>) { $c++; $l += length; }
	is($c, 100_000, 'All read');
	is($l, 1_000_000, 'Complete');
    }
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
