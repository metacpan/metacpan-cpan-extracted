use Forks::Super ':test';
use Test::More tests => 6;
use Carp;
use strict;
use warnings;

our $TOL = 1E-4 + ($Forks::Super::SysInfo::TIME_HIRES_TOL || 0.0);

#
# test that jobs respect their dependencies.
# a job won't start before another job starts that
# is in its "depend_start" list, and a job will
# wait for all of the jobs in its "depend_on"
# list to complete before starting.
#

$Forks::Super::MAX_PROC = 20;
my $pid1 = fork { sub => sub { sleep 5 } };
ok(isValidPid($pid1), "job 1 started");
my $j1 = Forks::Super::Job::get($pid1);

my $t = Time::HiRes::time();
my $pid2 = fork {sub => sub {sleep 5}, depend_on => $pid1, on_busy => 'block'};
my $j2 = Forks::Super::Job::get($pid2);
ok($j1->{state} eq "COMPLETE", "job 1 complete when job 2 starts");
my $pid3 = fork { sub => sub { } };
my $j3 = Forks::Super::Job::get($pid3);
$t = Time::HiRes::time() - $t;
okl($t >= 3.85, "job 2 took ${t}s to start expected >5s"); ### 3 ###

ok($j2->{state} eq "ACTIVE", "job 2 still running");
waitall;
ok($j1->{end} <= $j2->{start} + $TOL,
   "job 2 did not start before job 1 ended");
ok($j3->{start} + $TOL >= $j2->{start}, 
   "job 3 started after job 2")
  or diag("j2/j3 start: ", $j2->{start}, "/", $j3->{start}, " (TOL=$TOL)");

