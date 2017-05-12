#
#	IPC::Mmap test script
#
use vars qw($tests $loaded);
BEGIN {
	push @INC, './t';
	$tests = 3;

	print STDERR "
 *** NOTE: this test may fail on older versions of Perl due to
 *** problems with the Win32 fork() emulation.
 "
 		if ($^O eq 'MSWin32');

	$^W= 1;
	$| = 1;
	print "1..$tests\n";
}

END {print "not ok 1\n" unless $loaded;}

#use threads;
#use threads::shared;
use Time::HiRes qw(time usleep);
use IPC::Mmap;

use strict;
use warnings;

our $testtype = 'single thread, multiprocess';
my $testno = 1;

sub report_result {
	my ($result, $testmsg, $okmsg, $notokmsg) = @_;

	if ($result) {

		$okmsg = '' unless $okmsg;
		print STDOUT (($result eq 'skip') ?
			"ok $testno # skip $testmsg for $testtype\n" :
			"ok $testno # $testmsg $okmsg for $testtype\n");
	}
	else {
		$notokmsg = '' unless $notokmsg;
		print STDOUT
			"not ok $testno # $testmsg $notokmsg for $testtype\n";
	}
	$testno++;
}

$loaded = 1;
#
#	create w/ filename, but wo/ a backing file
#	(works for both Win32 and POSIX)
#
sub create_mmap {
	my $mmap = ($^O eq 'MAWin32') ?
		IPC::Mmap->new('test2_mmap.tmp', 10000,
			PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANON) :
		IPC::Mmap->new('test2_mmap.tmp', 10000,
			PROT_READ|PROT_WRITE, MAP_SHARED|MAP_FILE);
	return $mmap;
}

my $mmap = create_mmap;
report_result(defined($mmap), 'create from filename');

unless (defined($mmap)) {
#	skip the rest
	report_result('skip', 'no mmap, skipping')
		while ($testno < $tests);
	exit 1;
}

#my $thrdlock : shared = 0;	# to coordinate threads
#
#	create 2 threads; 1st writes, 2nd reads
#	lock the mmap first to control sequencing
#
$mmap->lock();
my $writer = fork();

die "Can't fork writer" unless defined($writer);

unless ($writer) {
	write_mmap();
	exit 1;
}

$mmap->unlock();

#race condition - will the writer be always faster than the reader?
#let's give it a little time, say 10milliseconds
usleep(10000);

my $reader = fork();

die "Can't fork reader" unless defined($reader);

unless ($reader) {
	read_mmap();
	exit 1;
}

waitpid($writer, 0);
waitpid($reader, 0);

sub read_mmap {
	my $mmap = create_mmap;
	$mmap->lock();
	my $value;
	my $result = $mmap->read($value, 100, 2000);
	report_result((defined($result) && ($result == 2000) &&
		defined($value) && (length($value) == $result) &&
		($value eq ('K' x 2000))),
		'read thread', '', 'length of value: ' . length($value) .
			' value: ' . substr($value, 0, 20) );
	$mmap->unlock();

	sleep 3;
#
#	unpack something
#
	$mmap->lock();
	my @vals = $mmap->unpack(1000, 36, 'l n S d a20');
	report_result((scalar @vals == 5) &&
		($vals[0] == 123456) && ($vals[1] == 2345) && ($vals[2] == 5432) &&
		($vals[3] == 123.456789) && ($vals[4] eq ('Z' x 20)), 'unpack()');
	$mmap->unlock();

	return 1;
}

sub write_mmap {
#
#	no result report here, else Test harness will get confused
#
	my $mmap = create_mmap;
	my $result = $mmap->lock();
	$result = $mmap->write('K' x 2000, 100);
	$result = $mmap->unlock();

	sleep 2;
#
#	pack something
#
	$mmap->lock();
	$result = $mmap->pack(1000, 'l n S d a20', 123456, 2345, 5432, 123.456789, 'Z' x 20);
	$mmap->unlock();
#
#	Win32 needs some settle time before we close the mmap
#
	sleep 2;
#	$mmap->lock();
#	$mmap->unlock();

	return 1;
}
