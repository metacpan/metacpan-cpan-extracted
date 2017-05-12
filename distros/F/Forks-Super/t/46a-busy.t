use Forks::Super ':test';
use Test::More tests => 13;
use strict;
use warnings;

#
# test that jobs don't launch when the system is
# "too busy" (which so far means that there are
# already too many active subprocesses). Jobs that
# are too busy to start can either block or fail.
#

#######################################################

sub sleepy { return sleep 3 }
my $sleepy = \&sleepy;

$Forks::Super::MAX_PROC = 3;
$Forks::Super::ON_BUSY = "block";

my $t0 = Time::HiRes::time();
my $pid1 = fork { sub => $sleepy };
my $pid2 = fork { sub => $sleepy };
my $t = Time::HiRes::time();
my $t1 = $t;
my $pid3 = fork { sub => $sleepy };
$t = Time::HiRes::time() - $t;
okl($t <= 1.97, "$$\\three forks fast return ${t}s expected <1s"); ### 1 ###
ok(isValidPid($pid1) && isValidPid($pid2) && isValidPid($pid3),
   "forks successful");

my $t2 = Time::HiRes::time();
my $pid4 = fork { sub => $sleepy };
my $t3 = Time::HiRes::time();
($t2,$t1,$t0) = ($t3-$t2, $t3-$t1, $t3-$t0);
okl($t2 >= 2 || ($t1 > 3.0),                                       ### 3 ###
    "blocked fork took ${t2}s ${t1}s ${t0}s expected >2s");
ok(isValidPid($pid4), "blocking fork returns valid pid $pid4");    ### 4 ###
waitall;

#######################################################

$Forks::Super::ON_BUSY = "fail";
$pid1 = fork { sub => $sleepy };  # ok 1/3
$pid2 = fork { sub => $sleepy };  # ok 2/3
$t = Time::HiRes::time();
$pid3 = fork { sub => $sleepy };  # ok 3/3
$t = Time::HiRes::time() - $t;
okl($t <= 1.9, "three forks no delay ${t}s expected <=1s");        ### 5 ###
ok(isValidPid($pid1) && isValidPid($pid2) && isValidPid($pid3),    ### 6 ###
   "three successful forks");


$t = Time::HiRes::time();
$pid4 = fork { sub => $sleepy };     # should fail .. already 3 procs
my $pid5 = fork { sub => $sleepy };  # should fail
my $u = Time::HiRes::time() - $t;
okl($u <= 1, "Took ${u}s expected fast fail 0-1s"); ### 7 ###
ok(!isValidPid($pid4) && !isValidPid($pid5), "failed forks");
waitall;
$t = Time::HiRes::time() - $t;

okl($t >= 2.15 && $t <= 6.75,                    ### 9 ### was 4 obs 6.75!,1.45
   "Took ${t}s for all jobs to finish; expected 3-4"); 

#######################################################

$Forks::Super::MAX_PROC = 2;
$Forks::Super::ON_BUSY = "fail";

my $pid6 = fork { sub => sub { sleep 5 } };
my $pid7 = fork { sub => sub { sleep 5 } };
my $pid8 = fork { sub => sub { sleep 5 } };
my $pid9 = fork { sub => sub { sleep 5 }, force => 1 };

ok(isValidPid($pid6) && isValidPid($pid7), 'ok to launch 2 jobs');
ok(!isValidPid($pid8), 'third job fails');
ok(isValidPid($pid9), 'fourth job ok with force => 1');
waitall;

#######################################################

$Forks::Super::MAX_PROC = 3;
$Forks::Super::ON_BUSY = "fail";

my $pid = fork { sub => 
	sub { # a subroutine that will make the processor busy for a while
	  my $z=0;
	  my $timeout = time + ($^O eq 'MSWin32' ? 15 : 45);
	  while (time < $timeout) {
	    $z += rand()-rand() 
	  }
	} };

$Forks::Super::MAX_LOAD = 0.001;
sleep 1;
SKIP: {
    my $load = Forks::Super::Job::get_cpu_load();
    if ($load < 0) {
	skip "get_cpu_load function not available", 1;
    }
    for (my $i=0; $i<5; $i++) {
	$load = Forks::Super::Job::get_cpu_load();
	print STDERR "Cpu load: $load\n";
	last if $load > 0.1;
	sleep $i+1;
    }
    if ($load < 0.01) {
	skip "test could not generate a cpu load on this machine", 1;
    }
    $pid2 = fork { sub => sub { sleep 4 } };
    ok(isValidPid($pid) && !isValidPid($pid2), 
       "$pid2 fail while system is loaded");
}

# on MSWin32 it is harder to gracefully kill a child process,
# but the CPU load measurement has less inertia so we don't
# have to let the process run as long

if ($^O eq 'MSWin32') {
    waitall;
} else {
    our $INT = $^O eq 'cygwin' ? 'TERM' : 'INT'; # see t/24a-kill.t
    if (ref $pid eq 'Forks::Super::Job') {
        kill $INT, $pid->{real_pid};
    } else {
	kill $INT,$pid;
    }
}
exit 0;
