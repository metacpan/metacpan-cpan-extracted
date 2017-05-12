#!/usr/bin/perl -w

use lib qw(.. . lib ../lib);
eval "use Sync";
print $@;
use Fcntl;
use Time::HiRes qw(time);
use Carp qw(confess);
use strict;
use Getopt::Long;
my $INSERTS = 25;
my $PIDS    = 4;
my $BASE    = $INSERTS * $PIDS;
my $parent = $$;
$SIG{__DIE__} = \&confess;
srand(0);

$MLDBM::UseDB = $MLDBM::UseDB; # supress warning
use vars qw($opt_cache $opt_number $opt_bundle);
&GetOptions('c' => \$opt_cache, 'n=i' => \$opt_number, 'bundle=i' => \$opt_bundle);

if(! $opt_number or $opt_number < $BASE) { 
    $opt_number = $BASE;
}
$opt_number = int( $opt_number / $BASE ) * $BASE;

if($^O =~ /win32/i) {
    $PIDS = 1;
}

if($opt_number) {
    $opt_number /= $PIDS;
} else {
    $opt_number = $INSERTS;
}

print "NUMBER OF PROCESSES IN TEST: $PIDS\n";
for my $SIZE (50, 500, 5000, 20000, 50000) {
    print "\n=== INSERT OF $SIZE BYTE RECORDS ===\n";
    for my $DB ('SDBM_File', 'MLDBM::Sync::SDBM_File', 'GDBM_File', 'DB_File', 'Tie::TextDir .04') {
	eval "use $DB";
	next if $@;
	if($DB eq 'SDBM_File' and $SIZE > 100) { 
	    print " (skipping test for SDBM_File 100 byte limit)\n";
	    next;
	};
	if($DB eq 'MLDBM::Sync::SDBM_File' and ($SIZE * $opt_number * $PIDS) > (1 * 1024 * 1024)) {
	    print " (skipping test for MLDBM::Sync db size > 1M)\n";
	    next;
	}
	my $real_db = $DB;
	$real_db =~ s/\s+\.\d+$//isg;
	local $MLDBM::UseDB = $real_db;
	my $file_suffix = $real_db;
	$file_suffix =~ s/\W/_/isg;
	my %mldbm;
	my $sync = tie(%mldbm, 'MLDBM::Sync', "MLDBM_SYNC_BENCH_".$file_suffix, O_CREAT|O_RDWR, 0666)
	  || die("can't tie to /tmp/bench_mldbm: $!");
	if($opt_cache) {
	    $sync->SyncCacheSize('1000K');
	}
	%mldbm = ();
	my $time = time;
	if($PIDS > 1) { # 4 processes in all
	    fork; fork;
	}
	my $bundle = 0;
	for(0..($opt_number-1)) {
	    my $rand;
	    for(1..($SIZE/10)) {
		$rand .= '<td>'.rand().rand();
		last if length($rand) > $SIZE;
	    }
	    $rand = substr($rand, 0, $SIZE);
	    my $key = "$$.$_";
# add lock & unlock to increase performance
#	    $sync->Lock;
	    if($opt_bundle && ( ! ($_ % $opt_bundle ))) {
#		print "LOCK $$ $_\n";
		$bundle++;
		$sync->UnLock;
		$sync->Lock;
	    }
	    $mldbm{$key} = $rand;
	    ($mldbm{$key} eq $rand) || warn("can't fetch written value for $key => $mldbm{$key} === $rand");
#	    $sync->UnLock;
	}
	$opt_bundle && $sync->UnLock;
	if($^O !~ /win32/i) { while(wait != -1) {} }
	if($$ == $parent) {
	    my $total_time = time() - $time;
	    my $num_keys = scalar(keys %mldbm);
	    ($num_keys % $INSERTS) && warn("error, $num_keys should be a multiple of $INSERTS");
	    my $bundles_print = $bundle ? "locks/pid=$bundle" : '';
	    printf "  Time for $num_keys writes + $num_keys reads for  %-24s %6.2f seconds  %8d bytes $bundles_print\n", $DB, $total_time, $sync->SyncSize;
	} else {
	    exit;
	}
	%mldbm = ();
    }
}
