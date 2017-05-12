#
#	IPC::Mmap test script
#
use Config;
use vars qw($tests $loaded);
BEGIN {
	push @INC, './t';
	$tests = 7;

	$^W= 1;
	$| = 1;
	print "1..$tests\n";
	unless ($Config{usethreads} && (!$ENV{DEVEL_RINGBUF_NOTHREADS})) {
		print "ok $_ # skip your Perl is not configured for threads\n"
			foreach (1..$tests);
		exit;
	}
}

END {print "not ok 1\n" unless $loaded;}

use threads;
use threads::shared;
use Time::HiRes qw(time);
use IPC::Mmap;

use strict;
use warnings;

our $testtype = 'multithread, single process';
my $testno : shared = 1;

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

#
#	prelims: use shared test count for eventual
#	threaded tests
#
$loaded = 1;

unless ($Config{useithreads} && ($Config{useithreads} eq 'define')) {
	report_result('skip', "This Perl is not configured to support threads.")
		foreach ($testno..$tests);
	exit 1;
}
#
#	create w/ filename, but wo/ a backing file
#	(works for both Win32 and POSIX)
#
my $mmap = ($^O eq 'MSWin32') ?
	IPC::Mmap->new('test2_mmap.tmp', 10000,
		PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANON) :
	IPC::Mmap->new('test2_mmap.tmp', 10000,
		PROT_READ|PROT_WRITE, MAP_SHARED|MAP_FILE);
report_result(defined($mmap), 'create from filename');

unless (defined($mmap)) {
#	skip the rest
	report_result('skip', 'no mmap, skipping')
		while ($testno < $tests);
	exit 1;
}

my $thrdlock : shared = 0;	# to coordinate threads
#
#	create 2 threads; 1st writes, 2nd reads
#	lock the mmap first to control sequencing
#
my $writer;
	$writer = threads->create(\&write_mmap);

my $reader = threads->create(\&read_mmap);

$writer->join();
$reader->join();

sub read_mmap {
	my $value;
	my $result;
#
#	wait forwriter
#
	{
		lock($thrdlock);
		cond_wait($thrdlock)
			while ($thrdlock != 1);

		$result = $mmap->read($value, 100, 2000);
		report_result((defined($result) && ($result == 2000) &&
			defined($value) && (length($value) == $result) &&
			($value eq ('A' x 2000))),
		'read thread', '', "result is $result length of value: " . length($value) .
			' value: ' . substr($value, 0, 20) );
#
#	tell writer to continue
#
		$thrdlock++;
		cond_broadcast($thrdlock);
	}
#
#	wait for writer
#
	{
		lock($thrdlock);
		cond_wait($thrdlock)
			while ($thrdlock != 3);
#
#	unpack something
#
	my @vals = $mmap->unpack(1000, 36, 'l n S d a20');
	report_result((scalar @vals == 5) &&
		($vals[0] == 123456) && ($vals[1] == 2345) && ($vals[2] == 5432) &&
		($vals[3] == 123.456789) && ($vals[4] eq ('Z' x 20)), 'unpack()');
#
#	tell writer to continue
#
		$thrdlock++;
		cond_broadcast($thrdlock);
	}
	return 1;
}

sub write_mmap {
	my $result;
#
#	wait for parent to release
#
	{
		lock($thrdlock);
#
#	lock it
#
		$result = $mmap->lock();
		report_result($result, 'writer lock mmap area');
#
#	write to it: no length
#
		$result = $mmap->write('A' x 2000, 100);
		report_result((defined($result) && ($result == 2000)), 'simple write');

		$result = $mmap->unlock();
		report_result($result, 'writer unlock mmap area');
#
#	and acknowledge
#
		$thrdlock++;
		cond_broadcast($thrdlock);
	}
#
#	wait for reader
#
	{
		lock($thrdlock);
		cond_wait($thrdlock)
			while ($thrdlock != 2);
#
#	pack something
#
		$mmap->lock();
		$result = $mmap->pack(1000, 'l n S d a20', 123456, 2345, 5432, 123.456789, 'Z' x 20);
		report_result(defined($result) && ($result == 36), 'pack()');
		$mmap->unlock();
		$thrdlock++;
		cond_broadcast($thrdlock);
	}
	{
		lock($thrdlock);
		cond_wait($thrdlock)
			while ($thrdlock != 4);
	}
	return 1;
}
