use Forks::Super ':test';
use Test::More tests => 10;
use Time::HiRes;
use strict;
use warnings;

my $pid1 = fork { name => 'xxx', sub => sub { sleep 1 ; exit 1 } };
my $job1 = Forks::Super::Job::get($pid1);
waitpid $pid1, 0;

my $pid2 = $job1->reuse( sub => sub { sleep 1 ; exit 2 } );
ok(isValidPid($pid2), "reused job has valid pid");
ok($pid2 != $pid1, "reused job has new pid");
my $job2 = Forks::Super::Job::get($pid2);
ok(defined($job2), "reused job has job object");
ok($job2->{name} eq $job1->{name}, "reused job has old name");
ok($job2->is_started, "reused job has started");
waitpid $pid2, 0;

ok($job1->status != $job2->status, "reused job has new status");
ok($job1->status==256 && $job2->status==512, "jobs have correct status");

################################################################

my $t = Time::HiRes::time;
$pid1 = fork { sub => sub { sleep 1; exit 0 }, timeout => 3 };
$job1 = Forks::Super::Job::get($pid1);
waitpid $pid1,0;
my $t1 = Time::HiRes::time - $t;

$t = Time::HiRes::time;
$pid2 = $job1->reuse( sub => sub { sleep 10 } );
$job2 = Forks::Super::Job::get($pid2);
waitpid $pid2, 0;
my $t2 = Time::HiRes::time - $t;

ok($pid1 != $pid2, "reused job had different pid");
ok($job1->{status}==0 && $job2->{status}!=0, "reused job had NZEC");
okl($t2 >= 2 && $t2 < 6.5, "reused job timed out")                   ### 10 ###
   or diag("took ${t2}s, expected 2-5s");
