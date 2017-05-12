use vars qw($tests);
BEGIN {
	push @INC, './t';
	$tests = 2;

	$^W= 1;
	$| = 1;
	print STDERR "*** Note: this test executes for approx. 35 secs\n";
	print "1..$tests\n";
}

use Config;

#
# forks a child to run system('perl -d:STrace somescript.pl'),
#	which this process monitors
#
$ENV{DEVEL_RINGBUF_FILE} = 'plstrace_test.trace';

our $testtype = 'full monitor';

my $ringcnt = 8;

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

my $cmd = ($Config{useithreads} && (!$ENV{DEVEL_RINGBUF_NOTHREADS})) ?
	(($^O eq 'MSWin32') ?
		"perl -w -d:STrace t\\tracetest.pl -t $ringcnt" :
		"perl -w -d:STrace t/tracetest.pl -t $ringcnt") :

	(($^O eq 'MSWin32') ?
		"perl -w -d:STrace t\\tracetestnt.pl -p $ringcnt" :
		"perl -w -d:STrace t/tracetestnt.pl -p $ringcnt");

#print STDERR "\n*** Running $cmd\n";

my $child1 = fork();

die "Can't fork tracing child: $!" unless defined $child1;

unless ($child1) {
	system($cmd);
	exit 1;
}
#
#	wait a while for things to get rolling
#
sleep 5;
monitor();

waitpid($child1, 0);

sub monitor {
	require Devel::STrace::Monitor;

	report_result(\$testno, 1, 'load');
#
#	process args
#
	my $interval = 10;
	my $duration = 30;
	my $file = $ENV{DEVEL_RINGBUF_FILE};

	my $view = Devel::STrace::Monitor->open($file)
		|| die $@;

#	print STDERR "Started $file\n";
	my ($started, $lastrefresh) = (time(), time());
	my $rings = $ringcnt;
	$rings++
		if ($Config{useithreads} && (!$ENV{DEVEL_RINGBUF_NOTHREADS}));
	my $ok = 1;
	my %keys = ();
	while ((time() - $started) < $duration) {
#		print "
#***********************************************
#*** At ", scalar localtime(), "
#";
		my $lastkey = '';
#
#	dump the current traces (for specified pid[:tid] if provided)
#
		$view->refresh();
		$view->trace(
			sub {
				my ($key, $slot, $depth, $line, $time, $entry) = @_;
				$keys{$key} = 1,
				$lastkey = $key
#				print STDERR "\n**************************************\n"
					unless ($lastkey eq $key);
				if ($time) {
					my $frac = ($time - int($time)) * 1000000;
					$frac=~s/\..*$//;
					my @parts = split(/\s+/, scalar localtime($time));
					pop @parts;	# get rid of year
#					print STDERR "$key($depth) : $slot : $entry:$line at ",
#						join(' ', @parts), '.', $frac, "\n";
				}
				else {
#					print STDERR "$key($depth) : $slot : $entry:$line (No timestamp)\n";
				}
			}
		);
#
#	verify we got hte number of distinct keys we expected
#
		unless ($rings == scalar keys %keys) {
#			print STDERR "rings is $rings and keys is ", scalar keys %keys, "\n";
#			$ok = undef, last
			$ok = undef;
		}

		sleep $interval;
	}
	report_result(\$testno, $ok, 'monitor test');
}
