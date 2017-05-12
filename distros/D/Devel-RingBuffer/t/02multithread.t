#
#	Devel::RingBuffer test script
#
use vars qw($tests $loaded);
use Config;

BEGIN {
	push @INC, './t';
	$tests = 5;

	$^W= 1;
	$| = 1;
	print "1..$tests\n";
	unless ($Config{useithreads} && (!$ENV{DEVEL_RINGBUF_NOTHREADS})) {
		print STDOUT "ok $_ # skip your Perl doesn't support threads for multithreaded, single process\n"
			foreach (1..5);
		exit;
	}
}

END {print "not ok 1\n" unless $loaded;}

#
#	tests:
#	1. load OK
#	2. Create new ringbuffer
#	3. Allocate a few rings
#	4. Write to a few slots
#	5. Open the ringbuffer
#	6. Collect the map
#	7. Read the rings
#	8. Read the slots
#	9. Repeat all using threads
#	10. Repeat all using processes
#	11. Repeat all using threads in processes
#
use threads;
use threads::shared;
use Config;
use Time::HiRes qw(time sleep);

use Devel::RingBuffer;
use strict;
use warnings;

our $testtype = 'multithreaded, single process';

sub report_result {
	my ($testno, $result, $testmsg, $okmsg, $notokmsg) = @_;

	if ($result) {

		$okmsg = '' unless $okmsg;
		print STDOUT (($result eq 'skip') ?
			"ok $$testno # skip $testmsg for $testtype\n" :
			"ok $$testno # $testmsg $okmsg for $testtype\n");
	}
	else {
		$notokmsg = '' unless $notokmsg;
		print STDOUT
			"not ok $$testno # $testmsg $notokmsg for $testtype\n";
	}
	$$testno++;
}

my $testno = 1;
$loaded = 1;
report_result(\$testno, 1, 'load');

unless ($Config{useithreads} && ($Config{useithreads} eq 'define')) {
	report_result(\$testno, 'skip', "This Perl is not configured to support threads.")
		foreach ($testno..$tests);
	exit 1;
}
#
#	create a ring buffer using defaults
#
my $ring = Devel::RingBuffer->new(TraceOnCreate => 1);

report_result(\$testno, defined($ring), 'create a default ring');

unless ($ring) {
	report_result(\$testno, 'skip', 'no ring, can\'t proceeed')
		foreach ($testno..$tests);
	exit 1;
}
#
#	start each thread to run concurrent tests
#
my $locker : shared = 0;

my $children = $ring->getCount() >> 2;
#my $children = 1;
my $ringfile = $ring->getName();
my @thrds = ();
my %tids = ();
push(@thrds, threads->create(\&runtest)),
$tids{$thrds[-1]->tid()} = 1
	foreach (1..$children);
#
#	signal to run
#
{
	lock($locker);
	$locker = 1;
	cond_broadcast($locker);
}
#
#	and wait for completion
#
{
	lock($locker);
	cond_wait($locker)
		while ($locker < $children+1);
}
#
#	read all the buffers
#
my $ok = 1;
my $msg = '';
my @bufmap = $ring->getMap();
#print join(', ', @bufmap), "\n";
my $count = 0;
my @rings = ();
#print STDERR "map length is ", scalar @bufmap, "\n";
#sleep 3;	# settle time ?
foreach (0..$#bufmap) {
	push(@rings, $ring->getRing($_)),
	$count++
		unless $bufmap[$_];
}
#print STDERR "rings are ", join(', ', @rings), "\n";
my $truecount = 4 * $children;

#	print STDERR "in main: ring $_ address is ", $rings[$_]->getAddress(), "\n"
#		foreach (0..$#rings);

if ($count == $truecount) {
	foreach my $r (@rings) {
		my ($pid, $tid, $slot, $depth) = $r->getHeader();
		my $offset = $r->getIndex();
		$ok = undef,
		$msg = "Unexpected header $pid, $tid, $slot, $depth for ring $offset",
		print STDERR $msg, "\n"
			unless defined($pid) && defined($tid) && defined($slot) && defined($depth) &&
				($pid == $$) && $tids{$tid} && ($depth == 4) && ($slot == 3);

		for (0..3) {
			my ($line, $timest, $entry) = $r->getSlot($_);
			$ok = undef,
			$msg = "Unexpected entry $line, $entry for slot $_ header $pid, $tid, $slot, $depth for ring $offset",
		print STDERR $msg, "\n"
				unless defined($line) && defined($timest) && defined($entry) &&
					($line == 12345) && ($entry eq "this is the $_ slot of the $offset ring");
		}
	}
}
else {
	$ok = undef;
	$msg = "Only alloc'd $count buffers\n";
}
report_result(\$testno, $ok, 'read slots', '', $msg);
#
#	signal to run
#
{
	lock($locker);
	$locker++;
	cond_broadcast($locker);
}
#
#	and wait for updates
#
{
	lock($locker);
	cond_wait($locker)
		while ($locker < (2 * ($children + 1)));
}
#
#	read updates
#
$ok = 1;
foreach (@rings) {
	my ($line, $timest, $entry) = $_->getSlot(3);
	my $offset = $_->getIndex();
	$ok = undef, last
		unless defined($line) && defined($timest) && defined($entry) &&
			($line == 54321) && ($entry eq "this is the 3 slot of the $offset ring");
}
report_result(\$testno, $ok, 'read updated slots');
#
#	signal to run
#
{
	lock($locker);
	$locker++;
	cond_broadcast($locker);
}
#
#	and wait for frees
#
{
	lock($locker);
	cond_wait($locker)
		while ($locker < (3 * ($children + 1)));
}
#
#	verify freed slots
#
$ok = 1;
foreach (@rings) {
	my ($pid, $tid, $slot, $depth) = $_->getHeader();
	my $offset = $_->getIndex();

#	print STDERR "ring $offset has $pid, $tid, $slot, $depth\n";
	$ok = undef,
	last
		unless defined($pid) && defined($tid) && defined($slot) && defined($depth) &&
			($pid == $$) && $tids{$tid} && ($slot == 1) && ($depth == 2);
}
report_result(\$testno, $ok, 'freed slots');
#
#	and wait for completion
#
#	signal to run
#
{
	lock($locker);
	$locker++;
	cond_broadcast($locker);
}
#
#	dumbshit Perl threads doesn't completely garbage collect
#	before indicating join() back to the parent, so if
#	we don't wait here we get a segfault
#
sleep 1;

$_->join()
	foreach (@thrds);

$ring->close();

unlink $ringfile;


sub runtest {
#
#	wait for signal to run
#
my $tid = threads->self->tid;
	{
		lock($locker);
		cond_wait($locker)
			while ($locker < 1);
	}
#
#	allocate some rings
#
	my @rings = ();

	foreach (1..4) {
		push @rings, $ring->allocate();
		last unless defined($rings[-1]);
	}
#	print STDERR "in thread: ring $_ address is ", $rings[$_]->getAddress(), "\n"
#		foreach (0..$#rings);
#	my @bufmap = $ring->getMap();

#print STDERR "Thread $tid has ", join(', ', @rings), " rings\n map is ", join(', ', #@bufmap), "\n";
#
#	write some stuff to the rings
#
	foreach my $r (@rings) {
		$r->nextSlot("this is the $_ slot of the " . $r->getIndex() . ' ring'),
		$r->updateSlot(12345)
			for (0..3);
	}
#print STDERR "Thread $tid wrote ", scalar @rings, " rings\n";
#
#	signal completion
#
	{
		lock($locker);
		$locker++;
		cond_broadcast($locker);
	}
#
#	wait for all signal to run
#
	{
		lock($locker);
		cond_wait($locker)
			while ($locker < ($children + 2));
	}
#
#	update them
#
	$_->updateSlot(54321)
		foreach (@rings);
#print STDERR "Thread $tid updated ", scalar @rings, " rings\n";
#
#	signal completion
#
	{
		lock($locker);
		$locker++;
		cond_broadcast($locker);
	}
#
#	wait for signal to run
#
	{
		lock($locker);
		cond_wait($locker)
			while ($locker < ((2 * $children) + 3));
	}
#
#	free some slots
#
	foreach (@rings) {
		$_->freeSlot();
		$_->freeSlot();
	}
#print STDERR "Thread $tid freed slots\n";
#	@bufmap = $ring->getMap();
#	print STDERR "$tid map is ", join(', ', @bufmap), "\n";
#
#	signal completion
#
	{
		lock($locker);
		$locker++;
		cond_broadcast($locker);
	}
#
#	wait for signal to exit
#
	{
		lock($locker);
		cond_wait($locker)
			while ($locker < ((3 * $children) + 4));
	}

	return 1;
}
