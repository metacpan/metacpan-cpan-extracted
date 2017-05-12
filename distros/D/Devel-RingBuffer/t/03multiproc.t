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
#
use Time::HiRes qw(time sleep);
use Devel::RingBuffer;

use strict;
use warnings;

our $testtype = 'single threaded, multiprocess';

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

my $testno : shared = 1;
$loaded = 1;
report_result(\$testno, 1, 'load');

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
#	compute max number of children (4 rings per child)
#
my $children = $ring->getCount() >> 2;
#my $children = 1;
my $ringfile = $ring->getName();
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
#		print STDERR "\nin child $$\n";
		runtest($from_parent[$_], $to_parent[$_]);
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
#print STDERR "started kids\n";
#
#	and wait for completion
#
$child = <$_>
	foreach (@from_child);
#print STDERR "kids finished\n";

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
				$children{$pid} && ($tid == 0) && ($depth == 4) && ($slot == 3);

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
	$ok = undef, last
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
#	my $offset = $_->getIndex();

	$ok = undef,
	last
		unless defined($pid) && defined($tid) && defined($slot) && defined($depth) &&
			$children{$pid} && ($tid == 0) && ($slot == 1) && ($depth == 2);
}
report_result(\$testno, $ok, 'freed slots');
#
#	and wait for completion
#
print $_ "GO\n"
	foreach (@to_child);

waitpid($_, 0)
	foreach (@pids);

#print STDERR "lets close\n";

$ring->close();

unlink $ringfile;

sub runtest {
	my ($from, $to) = @_;
#
#	wait for signal to run
#
	my $parent = <$from>;
#
#	allocate some rings
#
	my @rings = ();

	foreach (1..4) {
#		print STDERR "\nalloc ring in child $$\n";
		push @rings, $ring->allocate();	# stores the buffer offset, not the index
#		print STDERR "\nring alloc'd in child $$\n";
		last unless defined($rings[-1]);
	}
#print STDERR "Process $$ has ", join(', ', @rings), " rings\n";
#
#	write some stuff to the rings
#
	foreach my $r (@rings) {
		$r->nextSlot("this is the $_ slot of the " . $r->getIndex() . ' ring'),
		$r->updateSlot(12345)
			for (0..3);
	}
#print STDERR "Process $$ wrote ", scalar @rings, " rings\n";
#
#	signal completion
#
	print $to "DONE\n";
#print STDERR "Process $$ singalled\n";
#
#	wait for all signal to run
#
	$parent = <$from>;
#
#	update them
#
#print STDERR "Process $$ updating ", scalar @rings, " rings\n";
	$_->updateSlot(54321)
		foreach (@rings);
#print STDERR "Process $$ updated ", scalar @rings, " rings\n";
#
#	signal completion
#
	print $to "DONE\n";
#
#	wait for signal to run
#
	$parent = <$from>;
#
#	free some slots
#
	foreach (@rings) {
		$_->freeSlot();
		$_->freeSlot();
	}
#print STDERR "Process $$ freed slots\n";
#
#	signal completion
#
	print $to "DONE\n";
#
#	wait for signal to finish
#
	$parent = <$from>;
	return 1;
}
