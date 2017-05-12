#
#	Devel::RingBuffer test script
#
use vars qw($tests $loaded);
BEGIN {
	push @INC, './t';
	$tests = 5;

	$^W= 1;
	$| = 1;
	print "1..$tests\n";
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
#	12. Test Devel::RingBuffer...but how ?
#
use threads;
use threads::shared;
use Config;
use Time::HiRes qw(time sleep);

use Devel::RingBuffer;

use strict;
use warnings;

our $testtype = 'multithreaded + multiprocess';

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
unless ($Config{useithreads} && ($Config{useithreads} eq 'define') &&
	(!$ENV{DEVEL_RINGBUF_NOTHREADS})) {
	report_result(\$testno, 'skip', "This Perl is not configured to support threads.")
		foreach ($testno..$tests);
	exit;
}
report_result(\$testno, 1, 'load');

if ($^O eq 'MSWin32') {
	report_result(\$testno, 'skip', 'Win32 fork() emulation not supported')
		foreach ($testno..$tests);
	exit;
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
#	compute max number of children (1 ring per thread, 4 threads per process)
#
my $children = $ring->getCount() >> 2;
#my $children = 1;
#
#	start each process to run concurrent tests
#
my @pids = ();
my @from_child = ();
my @to_child = ();
my @from_parent = ();
my @to_parent = ();
my %children = ();
# we need pipes!
my ($from_parent, $to_parent, $from_child, $to_child);

foreach (0..$children-1) {
	pipe($from_parent[$_], $to_child[$_]) or die "Can't open pipe: $!";
	pipe($from_child[$_], $to_parent[$_]) or die "Can't open pipe: $!";
	select((select($to_child[$_]), $|=1)[0]);
	select((select($to_parent[$_]), $|=1)[0]);

	my $pid = fork();

	die "Can't fork child $_: $!" unless defined $pid;

	unless ($pid) {
		close $from_child[$_];
		close $to_child[$_];
		runproc($from_parent[$_], $to_parent[$_]);
		exit 1;
	}
	close $from_parent[$_];
	close $to_parent[$_];
	push @pids, $pid;
	$children{$pid} = 1;
}

#print STDERR "forked ", scalar @pids, " children\n";

my $child;
#
#	signal to run
#
print $_ "GO\n"
	foreach (@to_child);
#
#	and wait for completion
#
$child = <$_>
	foreach (@from_child);
#
#	read all the buffers
#
my $ok = 1;
my $msg = '';
my @bufmap = $ring->getMap();
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

my $truecount = 4 * scalar @pids;

if ($count == $truecount) {
	foreach my $r (@rings) {
		my ($pid, $tid, $slot, $depth) = $r->getHeader();
		my $offset = $r->getIndex();
		$ok = undef,
		$msg = "Unexpected header $pid, $tid, $slot, $depth for ring $offset",
		print STDERR $msg, "\n"
			unless defined($pid) && defined($tid) && defined($slot) && defined($depth) &&
				$children{$pid} && ($tid > 0) && ($tid < 5) && ($depth == 4) && ($slot == 3);

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
print $_ "GO\n"
	foreach (@to_child);
#
#	and wait for completion
#
$child = <$_>
	foreach (@from_child);
#
#	read updates
#
$ok = 1;
foreach (@rings) {
	my ($line, $timest, $entry) = $_->getSlot(3);
	my $offset = $_->getIndex();
	$ok = undef,
	$msg = "Unexpected update $line, $timest, $entry\n",
	print STDERR $msg
		unless defined($line) && defined($timest) && defined($entry) &&
			($line == 54321) && ($entry eq "this is the 3 slot of the $offset ring");
}
report_result(\$testno, $ok, 'read updated slots');
#
#	signal to run
#
print $_ "GO\n"
	foreach (@to_child);
#
#	and wait for completion
#
$child = <$_>
	foreach (@from_child);
#
#	verify freed slots
#
$ok = 1;
foreach (@rings) {
	my ($pid, $tid, $slot, $depth) = $_->getHeader();

	$ok = undef,
	last
		unless defined($pid) && defined($tid) && defined($slot) && defined($depth) &&
			$children{$pid} && ($tid > 0) && ($tid < 5) && ($slot == 1) && ($depth == 2);
}
report_result(\$testno, $ok, 'freed slots');
#
#	and wait for completion
#
print $_ "GO\n"
	foreach (@to_child);
waitpid($_, 0)
	foreach (@pids);

$ring->close();

sub runproc {
	my ($from, $to) = @_;
#
#	wait for signal to run
#
	my $parent = <$from>;
#
#	create threads
#
	my $children = 4;
	my @thrds = ();
	my $locker : shared = 0;

#print STDERR "Proc $$ spawning threads\n";

	push(@thrds, threads->create(\&runtest, $children, \$locker))
		foreach (1..$children);

#print STDERR "Proc $$ spawned threads\n";

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
#	signal completion
#
	print $to "DONE\n";
#print STDERR "proc $$ alloc/write complete, Waiting for main signal\n";
#
#	wait for all signal to run
#
	$parent = <$from>;
#print STDERR "proc $$ got main signal\n";
#
#	signal completion
#
	{
		lock($locker);
		$locker++;
		cond_broadcast($locker);
	}
#print STDERR "update started, Waiting for reply\n";
#
#	wait for signal to run
#
	{
		lock($locker);
		cond_wait($locker)
			while ($locker < ((2 * $children) + 2));
	}
#print STDERR "locker is $locker\n";
#
#	signal completion
#
	print $to "DONE\n";
#print STDERR "update done, Waiting for main reply\n";
#
#	wait for signal to run
#
	$parent = <$from>;
#
#	signal children to free slots
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
			while ($locker < ((3 * $children) + 3));
	}
#
#	signal completion
#
	print $to "DONE\n";
#print STDERR "update done, Waiting for main reply\n";
#
#	wait for signal to run
#
	$parent = <$from>;
#print STDERR "free started, Waiting for reply\n";
#
#	wait for thread completion
#
	{
		lock($locker);
		$locker++;
		cond_broadcast($locker);
	}
	$_->join()
		foreach (@thrds);
#
#	signal completion
#
	print $to "DONE\n";
#print STDERR "FINE\n";

	return 1;
}

sub runtest {
	my $children = shift;
	my $locker = shift;
#
#	wait for signal to run
#
my $tid = threads->self->tid;
#print STDERR "started $tid for proc $$\n";
	{
		lock($$locker);
		cond_wait($$locker)
			while ($$locker < 1);
	}
#
#	allocate some rings
#
	my @rings = ();

	push @rings, $ring->allocate();	# stores the buffer offset, not the index
	return undef unless defined($rings[-1]);
#print STDERR "Children is $children\n";

#	my @bufmap = $ring->getMap();

#print STDERR "Thread $tid has ", join(', ', @rings), " rings\n map is ", join(', ', @bufmap), "\n";
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
		lock($$locker);
		$$locker++;
		cond_broadcast($$locker);
	}
#
#	wait for all signal to run
#
	{
		lock($$locker);
		cond_wait($$locker)
			while ($$locker < ($children + 2));
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
		lock($$locker);
		$$locker++;
		cond_broadcast($$locker);
	}
#
#	wait for signal to run
#
#sleep 1;
	{
		lock($$locker);
		cond_wait($$locker)
			while ($$locker < ((2 * $children) + 3));
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
		lock($$locker);
		$$locker++;
		cond_broadcast($$locker);
	}
#
#	wait for signal to exit
#
#sleep 1;
	{
		lock($$locker);
		cond_wait($$locker)
			while ($$locker < ((3 * $children) + 4));
	}
	return 1;
}
