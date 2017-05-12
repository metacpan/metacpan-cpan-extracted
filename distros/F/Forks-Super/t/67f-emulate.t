use Forks::Super ':test_emulate';
use Test::More tests => 21;
use POSIX ':sys_wait_h';
use strict;
use warnings;

# Job::get, Job::getByName, and waitpid

my ($pid,$pid1,$pid2,$pid3,$j1,$j2,$j3,$p,$q,$t,@j,$p1,$p2,$p3);
our $TOL = $Forks::Super::SysInfo::TIME_HIRES_TOL || 0.0;

$pid = fork { sub => sub {sleep 2}, name => "sleeper" };
$j1 = Forks::Super::Job::get($pid);
$j2 = Forks::Super::Job::get("sleeper");
ok($j1 eq $j2, "$$\\job get by name");
$p = waitpid "sleeper", 0;
ok($p == $pid, "waitpid by name");

$j3 = Forks::Super::Job::get("bogus name");
ok(!defined $j3, "job get by bogus name");
$p = waitpid "bogus name", 0;
ok($p == -1, "waitpid bogus name");

$pid1 = fork { sub => sub { sleep 3 }, name => "sleeperX" };
$pid2 = fork { sub => sub { sleep 3 }, name => "sleeperX" };
@j = Forks::Super::Job::getByName("sleeperX");
ok(@j == 2,"getByName dup");
@j = Forks::Super::Job::getByName("bogus");
ok(@j == 0, "getByName bogus");
$p = waitpid "sleeperX", WNOHANG;
ok($p == $pid1 || $p == $pid2, "nonblock waitpid by name emulation");
$q = waitpid "sleeperX", 0;
ok($q == $pid1 || $q == $pid2, "waitpid by dup name");
ok($p+$q == $pid1+$pid2, "waitpid by name second time");
my $r = waitpid "sleeperX", 0;
ok($r == -1, "waitpid by name too many times");

$Forks::Super::MAX_PROC = 20;
$Forks::Super::ON_BUSY = "queue";

$p1 = fork { sub => sub { sleep 5 }, name => "simple" };
$t = Time::HiRes::time();
$p2 = fork { sub => sub { sleep 3 }, depend_on => "simple",
	     queue_priority => 10 };
$p3 = fork { sub => sub { }, queue_priority => 5 };
$t = Time::HiRes::time() - $t;
okl($t > 1.5,              ### 11 ### was 1.5, obs 1.65,1.76,1.98,2.99
    "dependency already satisfied for emulated job");
$j1 = Forks::Super::Job::get($p1);
$j2 = Forks::Super::Job::get($p2);
$j3 = Forks::Super::Job::get($p3);

ok($j1->{state} eq 'COMPLETE' && $j2->{state} eq 'COMPLETE',    ### 12 ###
   "emulated jobs are in completed state")
  or diag("expect job states COMPLETE/COMPLETE, were ",
	  $j1->{state}, "/", $j2->{state});
waitall;

ok($j1->{end} <= $j2->{start} + $TOL,
   "respected depend_on by name");
ok($j3->{start} >= $j2->{end} - $TOL,                   ### 14 ###
   "emulated jobs execute in order")
    or diag("job 3 started at $j3->{start} ",
	    "expected job 2 to start earlier ($j2->{start})");


# Job::get, Job::getByName, and waitpid
$ENV{TEST_LENIENT} = 1 if $^O =~ /freebsd|midnightbsd/;

$TOL = 1E-4 + ($Forks::Super::SysInfo::TIME_HIRES_TOL || 0.0);

# named dependency
# first job doesn't really have any dependencies, should start right away
# second job depends on first job

$Forks::Super::MAX_PROC = 20;
$Forks::Super::ON_BUSY = "queue";

$p1 = fork { sub => sub { sleep 3 }, name => "simple2", delay => 3 };
$t = Time::HiRes::time();
$p2 = fork { sub => sub { sleep 3 }, 
	depend_start => "simple2", queue_priority => 10 };
$t = Time::HiRes::time() - $t;
$p3 = fork { sub => sub {}, queue_priority => 5 };
okl($t <= 1.5, "fast return for queued job ${t}s expected <= 1s"); ### 15 ###
$j1 = Forks::Super::Job::get($p1);
$j2 = Forks::Super::Job::get($p2);
$j3 = Forks::Super::Job::get($p3);
ok($j1->{state} eq 'DEFERRED' && $j2->{state} eq 'DEFERRED',
   "active/queued jobs in correct state");
waitall;
ok($j1->{start} <= $j2->{start} + $TOL,
   "respected start dependency by name")
	or diag("expected j1<=j2 start, ", $j1->{start}, " <= ",
		$j2->{start});
ok($j3->{start} < $j2->{start} + $TOL, 
   "non-dependent job started before dependent job");

$t = Time::HiRes::time();
$p1 = fork { sub => sub {sleep 3}, name => "circle1", depend_on => "circle2" };
my $t2 = Time::HiRes::time();
$p2 = fork { sub => sub {sleep 3}, name => "circle2", depend_on => "circle1" };
my $t3 = Time::HiRes::time();
$j1 = Forks::Super::Job::get($p1);
$j2 = Forks::Super::Job::get($p2);
ok($j1->{state} eq 'COMPLETE' && $j2->{state} eq 'COMPLETE',
   "jobs with circ dependency are COMPLETE in emulation mode")
    or diag $j1->{state}, $j2->{state};
my $t31 = Time::HiRes::time();
waitall();
my $t4 = Time::HiRes::time();
($t,$t2,$t3,$t31) = ($t4-$t,$t4-$t2,$t4-$t3,$t4-$t31);
okl($t > 4.75 && $t31 < 9.08,          ### 6 ### was 8.0 obs 9.03,4.81
   "Took ${t}s ${t2}s ${t3}s ${t31} for dependent jobs - expected ~6s"); 
ok($j1->{end} <= $j2->{start} + $TOL,
   "handled circular dependency");

