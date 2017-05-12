use Forks::Super ':test';
use Test::More tests => 8;
use Carp;
use strict;
use warnings;

our $TOL = $Forks::Super::SysInfo::TIME_HIRES_TOL || 1.0E-6;

#
# test that jobs respect their dependencies.
# a job won't start before another job starts that
# is in its "depend_start" list, and a job will
# wait for all of the jobs in its "depend_on"
# list to complete before starting.
#

$Forks::Super::MAX_PROC = 2;
$Forks::Super::ON_BUSY = "queue";

ok( isValidPid(  fork( {sub => sub { sleep 2 }} ) ) , "fork successful");
my $pid1 = fork { sub => sub { sleep 3 } };
my $j1 = Forks::Super::Job::get($pid1);
ok($j1->{state} eq "ACTIVE", "first job running");

my $pid2 = fork { sub => sub { sleep 3 }, queue_priority => 0 };
my $j2 = Forks::Super::Job::get($pid2);
ok($j2->{state} eq "DEFERRED", "job 2 waiting");

my $pid3 = fork { sub => sub { sleep 1 }, depend_on => $pid2, 
	       queue_priority => 1 };
my $j3 = Forks::Super::Job::get($pid3);
ok($j3->{state} eq "DEFERRED", "job 3 waiting");

my $pid4 = fork { sub => sub { sleep 2 }, 
		  depend_start => $pid2, queue_priority => -1 };
my $j4 = Forks::Super::Job::get($pid4);
ok($j4->{state} eq "DEFERRED", "job 4 waiting");

# without calling run_queue(), first set of jobs might 
# finish before queue is examined
Forks::Super::Deferred::run_queue();

waitall;
ok($j4->{start} + $TOL >= $j2->{start}, 
   "job 4 respected depend_start for job2");
ok($j3->{start} + $TOL >= $j2->{end},                      ### 7 ###
   "job 3 respected depend_on for job2")
    or diag("expected $j3->{start}/", $j3->{start}-$^T,
	    " >= ",$j2->{end}-$^T,"/$j2->{end}");
ok($j4->{start} - $TOL < $j3->{start}, 
   "low priority job 4 start before job 3");

