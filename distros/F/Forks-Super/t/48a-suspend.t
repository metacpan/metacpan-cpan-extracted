use Forks::Super ':test';
use Test::More tests => 17;
use strict;
use warnings;

SKIP: {
    if (&Forks::Super::Util::IS_WIN32ish && 
	!Forks::Super::Config::CONFIG_module("Win32::API")) {

	skip "suspend/resume not supported on $^O - install Win32::API", 17;
    }

my $pid = fork {
    sub => sub {
	for (my $i=0; $i<7; $i++) {
	    sleep 1;
	}
    } };

my $j = Forks::Super::Job::get($pid);
ok(isValidPid($pid) && $j->{state} eq "ACTIVE", "$$\\created $pid");
sleep 3;
if ($^O eq 'MSWin32') {
    diag("Calling suspend method for $j. This is pid $$.");
}
$j->suspend;
ok($j->{state} eq "SUSPENDED", "job was suspended");
sleep 5;
my $t = Time::HiRes::time();
$j->resume;
ok($j->{state} eq "ACTIVE", "job was resumed");
waitpid $pid,0;
$t = Time::HiRes::time() - $t;
ok($t >= 1.95, "\"time stopped\" while job was suspended, ${t} >= 3s");

#############################################################################

# to test:
# if only suspended jobs are left:
# waitpid|action=wait runs indefinitely
# waitpid|action=fail returns Forks::Super::Wait::ONLY_SUSPENDED_JOBS_LEFT
# waitpid|action=resume restarts the job

$pid = fork { 
    sub => sub { 
	$SIG{STOP} = sub {
	    die "Trapped a signal $_[0] that shouldn\'t be trappable ...\n"
	};
	sleep 1 for (1..6) 
    } 
};
$j = Forks::Super::Job::get($pid);
sleep 3;
$j->suspend;

$Forks::Super::Wait::WAIT_ACTION_ON_SUSPENDED_JOBS = 'wait';
$t = Time::HiRes::time();
my $p = wait 5.0;
$t = Time::HiRes::time() - $t;
ok($p == &Forks::Super::Wait::TIMEOUT,                     ### 5 ###
   "wait|wait times out $p==TIMEOUT");
okl($t > 4.95,                                              ### 6 ###
   "wait|wait times out ${t}s, expected ~5s");
ok($j->{state} eq 'SUSPENDED',                             ### 7 ###
   "wait|wait does not resume job");

$Forks::Super::Wait::WAIT_ACTION_ON_SUSPENDED_JOBS = 'fail';
$t = Time::HiRes::time();
$p = wait 5.0;
$t = Time::HiRes::time() - $t;
ok($p == &Forks::Super::Wait::ONLY_SUSPENDED_JOBS_LEFT,    ### 8 ###
   "wait|fail returns invalid");
okl($t < 1.95, "fast fail ${t}s expected <1s");
ok($j->{state} eq 'SUSPENDED',                             ### 10 ###
   "wait|fail does not resume job");

$Forks::Super::Wait::WAIT_ACTION_ON_SUSPENDED_JOBS = 'resume';
$t = Time::HiRes::time();
$p = wait 10.0;
$t = Time::HiRes::time() - $t;
ok($p == $pid,                                             ### 11 ###
   "wait|resume makes a process complete");
okl($t > 0.95 && $t < 9,                                    ### 12 ###
   "job completes before wait timeout ${t}s, expected 3-4s"); # obs 0.9995
ok($j->{state} eq "REAPED", "job is complete");

##################################################################

# if you suspend a job more than once, and then resume it,
# it should resume. In the basic Windows API, you'd need to 
# call resume more than once, too.

$pid = fork { sub => sub { sleep 1 for (1..4) } };
$j = Forks::Super::Job::get($pid);
sleep 1;
ok($j->{state} eq 'ACTIVE', "created bg job, currently active");
$j->suspend;
ok($j->{state} eq 'SUSPENDED', "suspended bg job successfully");
$j->suspend;  # re-suspending a job generates a warning.
$j->suspend;
$j->suspend;
$j->suspend;
ok($j->{state} eq 'SUSPENDED', "multiply-suspended bg job successfully");
sleep 1;
$j->resume;
ok($j->{state} eq 'ACTIVE', "single resume reactivated bg job");
waitall;



}  # end SKIP

#############################################################################

# ACTIVE + SIGSTOP --> SUSPENDED
# DEFERRED + SIGSTOP --> SUSPENDED-DEFERRED
# SUSPENDED + SIGCONT --> ACTIVE
# SUSPENDED-DEFERRED + SIGCONT -> DEFERRED or ACTIVE
# MSWin32 check STOP+STOP+STOP+STOP+CONT --> ACTIVE

