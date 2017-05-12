use Forks::Super ':test';
use Test::More tests => 9;
use Carp;
use strict;
use warnings;
no warnings 'once';

# This test has an intermittent race condition in which the child
# can get and stay suspended, causing the test to hang or time out.
# That is more a feature of this test than of the Forks::Super module,
# so if that happens, run the test again.


if ($^O eq 'MSWin32') {
    Forks::Super::Config::CONFIG_module("Win32::API");
    if ($Win32::API::VERSION && $Win32::API::VERSION < 0.71) {
	warn qq[

Win32::API v$Win32::API::VERSION found. v>=0.71 may be required
to pass this test and use the features exercised by this test.

];
    }
}




my $file = "t/out/48b.$$.out";
$Forks::Super::Util::DEFAULT_PAUSE = 0.5;

our ($DEBUG, $DEVNULL);
$DEBUG = $ENV{DEBUG} ? *STDERR : do {open($DEVNULL,'>',"$file.debug");$DEVNULL};

END {
    if ($$ == $Forks::Super::MAIN_PID) {
	unlink $file, "$file.tmp", "$file.debug";
	unless ($ENV{DEBUG}) {
	    close $DEVNULL;
	    unlink "$file.debug";
	}
    }
}

#
# a suspend callback function:
# return -1 if an active job should be suspended
# return +1 if a suspended job should be resumed
# return 0 if a job should be left in whatever state it is in
#
sub child_suspend_callback_function {
    my ($job) = @_;
    my $d = (time - $::T) % 20;
    no warnings 'unopened';
    print $DEBUG "callback: \$d=$d ";
    if ($d < 5) {
	print $DEBUG " :  noop\n";
	return 0;
    }
    if ($d < 10) {
	print $DEBUG " :  suspend\n";
	return -1;
    }
    if ($d < 15) {
	print $DEBUG " :  noop\n";
	return 0;
    }
    print $DEBUG " :  resume\n";
    return +1;
}

sub read_value {
    no warnings 'unopened';
    my $fh;
    for (1..10) {
	last if open $fh, '<', $file;
	sleep 1;
    }
    my @F = <$fh>;
    close $fh;
    my $F = pop @F;
    $F = pop @F if $F !~ /\S/;
    print $DEBUG "read_value is $F\n";
    return $F;
}

sub write_value {
    my ($value) = @_;

    no warnings 'unopened', 'io';

    # don't suspend while we're in the middle of changing the ipc file
    open my $fh, '>>', $file;
    print $DEBUG "write_value $value\n";
    print $fh $value . "\n";
    close $fh;
    print $DEBUG "write_value: sync\n";
    return;
}

$Forks::Super::Deferred::QUEUE_MONITOR_FREQ = 2;

if (Forks::Super::Util::IS_WIN32ish
        && !Forks::Super::Config::CONFIG_module("Win32::API")) {
    ok(1, "# skip suspend/resume not supported on $^O") for 1..9;
    exit;
}

my $t0 = $::T = Time::HiRes::time();
my $pid = fork { 
    suspend => 'child_suspend_callback_function',
    sub => sub {
	for (my $i = 1; $i <= 8; $i++) {
	    Time::HiRes::sleep(0.5);
	    write_value($i);
	    Time::HiRes::sleep(0.5);
	}
    },
    timeout => 45
};
my $t1 = 0.5 * ($t0 + Time::HiRes::time());
my $job = Forks::Super::Job::get($pid);

local $SIG{STOP} = sub { croak "SIG$_[0] received in PARENT process" };
if (exists $SIG{TSTP}) {
    $SIG{TSTP} = $SIG{STOP};
}

# sub should proceed normally for 5 seconds
# then process should be suspended
# process should stay suspended for 10 seconds
# then process should resume and run for 5-10 seconds

Forks::Super::Util::pause($t1 + 2.0 - Time::HiRes::time());

ok($job->{state} eq 'ACTIVE', "$$\\job has started")
      or diag("job state was ", $job->{state}, " expected ACTIVE");



# www.cpantesters.org/cpan/report/25b3453c-a320-11e0-8b35-dd57e1de4735:
#    job was COMPLETE at this point, not ACTIVE?
if ($job->{state} eq 'COMPLETE') {
    my $waitpid = waitpid $job, 0;
    my $status = $job->{status};
    diag("ack. job is COMPLETE when it should be active? waitpid:$waitpid ",
	 "status:$status. Don't expect the rest of this test to go well.");
}



my $w = read_value();
ok($w > 0 && $w < 5,                                          ### 2 ###
   "job is incrementing value, expect 0 < val:$w < 5");

my $pause_time = $t1 + 8.0 - Time::HiRes::time();
while ($pause_time > 2) {
    diag("pausing $pause_time ...");
    Forks::Super::Util::pause(2);
    $pause_time -= 2;
}
if ($pause_time > 0) {
    Forks::Super::Util::pause($pause_time);
}
$w = read_value();
ok($job->{state} eq 'SUSPENDED', "job is suspended  w=$w")
      or diag("job state was ", $job->{state}, " expected SUSPENDED");
if (!defined $w) {
    warn "read_value() did not return a value. Retrying ...\n";
    sleep 1;
    $w = read_value();
}

ok($w >= 3, "job is incrementing value, expect val:$w >= 4"); ### 4 ###

Forks::Super::Util::pause($t1 + 11.0 - Time::HiRes::time());
ok($job->{state} eq 'SUSPENDED', "job is still suspended")    ### 5 ###
      or diag("job state was ", $job->{state}, " expected SUSPENDED");
my $x = read_value();
ok($x == $w, "job has stopped increment value, expect val:$x == $w");

Forks::Super::Util::pause($t1 + 18.0 - Time::HiRes::time());
ok($job->{state} eq 'ACTIVE' || $job->{state} eq 'COMPLETE',  ### 7 ###
     "job has resumed state=" . $job->{state})
      or diag("job state was ", $job->{state}, " expected COMPLETE or ACTIVE");
$x = read_value();
if (!defined $x) {
    warn "read_value() did not return a value. Retrying ...\n";
    sleep 1;
    $x = read_value();
}
ok($x > $w,                                                   ### 8 ###
     "job has resumed incrementing value, expect val:$x > $w");

my $p = wait 4.0;
if (!isValidPid($p)) {
    $job->resume;
    $p = wait 2.0;
    if (!isValidPid($p)) {
	$job->resume;
	$p = wait 2.0;
	if (!isValidPid($p)) {
	    $job->resume;
	    $p = wait 2.0;
	    if (!isValidPid($p)) {
		$job->resume;
		$p = wait 2.0;
		if (!isValidPid($p)) {
		    diag("Killing unresponsive job $job");
		    $job->kill('CONT');
		    $job->kill('KILL');
		    $job->resume;
		}
	    }
	}
    }
}

ok($p == $pid, "job has completed");
