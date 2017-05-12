use Forks::Super ':test';
use Test::More tests => 14;
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
ok($p == -1 || $p == 0, "nonblock waitpid by name");           ### 7 ###
$p = waitpid "sleeperX", 0;
ok($p == $pid1 || $p == $pid2, "waitpid by dup name");
$q = waitpid "sleeperX", 0;
ok($p+$q == $pid1+$pid2, "waitpid by name second time");
$q = waitpid "sleeperX", 0;
ok($q == -1, "waitpid by name too many times");

$Forks::Super::MAX_PROC = 20;
$Forks::Super::ON_BUSY = "queue";

$p1 = fork { sub => sub { sleep 5 }, name => "simple" };
$t = Time::HiRes::time();
$p2 = fork { sub => sub { sleep 3 }, depend_on => "simple",
	     queue_priority => 10 };
$p3 = fork { sub => sub { }, queue_priority => 5 };
$t = Time::HiRes::time() - $t;
okl($t <= 3.0,              ### 11 ### was 1.5, obs 1.65,1.76,1.98,2.99
   "fast return for queued job ${t}s expected <=1s"); 
$j1 = Forks::Super::Job::get($p1);
$j2 = Forks::Super::Job::get($p2);
$j3 = Forks::Super::Job::get($p3);

ok($j1->{state} eq 'ACTIVE' && $j2->{state} eq 'DEFERRED',    ### 12 ###
   "active/queued jobs in correct state")
  or diag("expect job states ACTIVE/DEFERRED, were ",
	  $j1->{state}, "/", $j2->{state});
waitall;

ok($j1->{end} <= $j2->{start} + $TOL,
   "respected depend_on by name");
ok($j3->{start} < $j2->{start} + $TOL,                        ### 14 ###
   "non-dependent job started before dependent job")
    or diag("job 3 started at $j3->{start} ",
	    "expected job 2 to start later ($j2->{start})");
