use Forks::Super ':test';
use Test::More tests => 7;
use POSIX ':sys_wait_h';
use strict;
use warnings;

# Job::get, Job::getByName, and waitpid
$ENV{TEST_LENIENT} = 1 if $^O =~ /freebsd|midnightbsd/;

my ($pid,$pid1,$pid2,$pid3,$j1,$j2,$j3,$p,$q,$t,@j,$p1,$p2,$p3);
our $TOL = 1E-4 + ($Forks::Super::SysInfo::TIME_HIRES_TOL || 0.0);

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
ok($j1->{state} eq 'ACTIVE' && $j2->{state} eq 'DEFERRED',
   "jobs with apparent circular dependency in correct state");
my $t31 = Time::HiRes::time();
waitall();
my $t4 = Time::HiRes::time();
($t,$t2,$t3,$t31) = ($t4-$t,$t4-$t2,$t4-$t3,$t4-$t31);
okl($t > 4.75 && $t31 < 9.08,          ### 6 ### was 8.0 obs 9.03,4.81
   "Took ${t}s ${t2}s ${t3}s ${t31} for dependent jobs - expected ~6s"); 
ok($j1->{end} <= $j2->{start} + $TOL,
   "handled circular dependency");

