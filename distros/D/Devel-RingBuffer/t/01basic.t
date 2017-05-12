#
#	Devel::RingBuffer test script
#
use vars qw($tests $loaded);
BEGIN {
	push @INC, './t';
	$tests = 21;

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
use Config;
use Time::HiRes qw(time);
use Devel::RingBuffer;

use strict;
use warnings;

our $testtype = 'basic single thread, single process';

$ENV{DEVEL_RINGBUF_FILE} = 'ringbuf_test.trace';

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
#
#	create a ring buffer using defaults
#
my $ring = Devel::RingBuffer->new(TraceOnCreate => 1, StopOnCreate => 1);

report_result(\$testno, defined($ring), 'create a default ring');

unless ($ring) {
	report_result(\$testno, 'skip', 'no ring, can\'t proceeed')
		foreach ($testno..$tests);
	exit 1;
}

report_result(\$testno, ($ring->getTraceOnCreate() == 1), 'getTraceOnCreate');
report_result(\$testno, ($ring->getStopOnCreate() == 1), 'getStopOnCreate');
#
#	allocate some rings
#
my @rings = ();

foreach (1..4) {
	push @rings, $ring->allocate();	# stores the buffer offset, not the index
	last unless defined($rings[-1]);
}
report_result(\$testno, defined($rings[-1]), 'allocate 4 rings');

unless (scalar @rings == 4) {
	report_result(\$testno, 'skip', 'no allocated rings, can\'t proceeed')
		foreach ($testno..$tests);
	exit 1;
}
#
#	verify the headers
#
my $ok = 1;
foreach (@rings) {
	my ($pid, $tid, $current, $depth) = $_->getHeader();
	$ok = undef, last
		unless (defined($pid) && defined($tid) && ($pid == $$) && ($tid == 0));
#		unless (defined($pid) && defined($tid) && ($pid == $$) && ($tid == threads->tid()));
}
report_result(\$testno, $ok, 'get headers');
#
#	write some stuff to the rings
#
$ok = 1;
foreach my $r (@rings) {
	my $depth = 0;
	$depth = $r->nextSlot("this is the $_ slot of the $r ring"),
	$r->updateSlot(12345)
		for (0..3);
	$ok = undef, last
		unless ($depth == 4);
}
report_result(\$testno, $ok, 'write slots');
#
#	read it back
#
$ok = 1;
foreach my $r (@rings) {
	my ($pid, $tid, $slot, $depth) = $r->getHeader();

	$ok = undef, last
		unless defined($pid) && defined($tid) && defined($slot) && defined($depth) &&
			($pid == $$) && ($tid == 0) && ($depth == 4) && ($slot == 3);
#			($pid == $$) && ($tid == threads->tid()) && ($depth == 4) && ($slot == 3);

	foreach (0..3) {
		my ($line, $timest, $entry) = $r->getSlot($_);
		$ok = undef, last
			unless defined($line) && defined($timest) && defined($entry) &&
				($line == 12345) && ($entry eq "this is the $_ slot of the $r ring");
	}
	last
		unless $ok;
}
report_result(\$testno, $ok, 'read slots');
#
#	update them
#
$ok = 1;
$_->updateSlot(54321)
	foreach (@rings);
#
#	read it back
#
$ok = 1;
foreach (@rings) {
	my ($line, $timest, $entry) = $_->getSlot(3);
	$ok = undef, last
		unless defined($line) && defined($timest) && defined($entry) &&
			($line == 54321) && ($entry eq "this is the 3 slot of the $_ ring");
}
report_result(\$testno, $ok, 'read updated slots');
#
#	free some slots
#
$ok = 1;
foreach (@rings) {
	$_->freeSlot();
	$_->freeSlot();
	my ($pid, $tid, $slot, $depth) = $_->getHeader();
	$ok = undef, last
		unless defined($pid) && defined($tid) && defined($slot) && defined($depth) &&
			($pid == $$) && ($tid == 0) && ($slot == 1) && ($depth == 2);
#			($pid == $$) && ($tid == threads->tid()) && ($slot == 1) && ($depth == 2);
}
report_result(\$testno, $ok, 'freed slots');
#
#	send and recv a command
#
$ok = 1;
foreach (@rings) {
	eval {
		$_->postCommand('ABC', 'this is a command message');
	};
	$ok = undef, last
		if $@;
}
report_result(\$testno, $ok, 'postCommand');

if ($ok) {
	foreach (@rings) {
		my ($cmd, $msg) = $_->checkCommand();
		$ok = undef, last
			unless defined($cmd) && defined($msg) &&
				($cmd eq 'ABC') && ($msg eq 'this is a command message');
	}
	report_result(\$testno, $ok, 'checkCommand');
}
else {
	report_result(\$testno, 'skip', 'checkCommand', 'postCommand failed');
}

if ($ok) {
	foreach (@rings) {
		eval {
			$_->postResponse('XYZ', 'this is a response message');
		};
		$ok = undef, last
			if $@;
	}
	report_result(\$testno, $ok, 'postResponse');
}
else {
	report_result(\$testno, 'skip', 'postResponse', 'checkCommand failed');
}

if ($ok) {
	foreach (@rings) {
		my ($cmd, $msg) = $_->checkResponse();
		$ok = undef, last
			unless defined($cmd) && defined($msg) &&
				($cmd eq 'XYZ') && ($msg eq 'this is a response message');
	}
	report_result(\$testno, $ok, 'checkResponse');
}
else {
	report_result(\$testno, 'skip', 'checkResponse', 'postResponse failed');
}
#
#	set and get some watches
#
$ok = 1;
my @watches = ();
foreach (@rings) {
	push @watches, $_->addWatch('this is an expression to evaluate');
	$ok = undef, last
		unless defined($watches[-1]);
}
report_result(\$testno, $ok, 'addWatch');

if ($ok) {
	foreach (0..$#rings) {
		my $expr = $rings[$_]->getWatchExpr($watches[$_]);
		$ok = undef, last
			unless defined($expr) && ($expr eq 'this is an expression to evaluate');
	}
	report_result(\$testno, $ok, 'getWatchExpr');
}
else {
	report_result(\$testno, 'skip', 'getWatchExpr', 'addWatch failed');
}

if ($ok) {
	foreach (0..$#rings) {
		my $next = $rings[$_]->setWatchResult($watches[$_], 'this is a watch result');
		$ok = undef, last
			unless defined($next) && ($next == $watches[$_] + 1);
	}
	report_result(\$testno, $ok, 'setWatchResult');
}
else {
	report_result(\$testno, 'skip', 'setWatchResult', 'getWatchExpr failed');
}

if ($ok) {
	foreach (0..$#rings) {
		my ($status, $result, $error) = $rings[$_]->getWatchResult($watches[$_]);
		$ok = undef, last
			unless defined($result) && ($result eq 'this is a watch result');
	}
	report_result(\$testno, $ok, 'getWatchResult');
}
else {
	report_result(\$testno, 'skip', 'getWatchResult', 'setWatchResult failed');
}

if ($ok) {
	foreach (0..$#rings) {
#		eval {
			$rings[$_]->freeWatch($watches[$_]);
#		};
#		$ok = undef, last
#			if defined($@);
	}
	report_result(\$testno, $ok, 'freeWatch', '', $@);
}
else {
	report_result(\$testno, 'skip', 'freeWatch', 'prior watch operation failed');
}
#
#	set and get a global msg
#	use separate thread to read so we don't get hung
#
if ($Config{useithreads} && (!$ENV{DEVEL_RINGBUF_NOTHREADS})) {
	require ThreadFacade;
	ThreadFacade::run($ring, \$testno, \&report_result);
}
else {
	report_result(\$testno, 'skip', "your Perl doesn't support threads");
	report_result(\$testno, 'skip', "your Perl doesn't support threads");
}
#$ring->close();

