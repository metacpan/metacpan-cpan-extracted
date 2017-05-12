use Forks::Super ':test';
use Test::More tests => 10;
use strict;
use warnings;

#
# test that "delay" and "start_after" options are
# respected by the fork() call. Delayed jobs should
# go directly to the job queue.
#

$Forks::Super::ON_BUSY = "block";

my $now = Time::HiRes::time();

my $t = Time::HiRes::time();
my $p1 = fork { sub => sub { sleep 3 } , delay => 5, on_busy => 'block' };
$t = Time::HiRes::time() - $t;
okl($t >= 4, "delayed job blocked took ${t}s expected >=5s");
ok(isValidPid($p1), "delayed job blocked and ran");
my $j1 = Forks::Super::Job::get($p1);
ok($j1->{state} eq "ACTIVE", "state of delayed job is ACTIVE");

my $future = Time::HiRes::time() + 10;
$t = Time::HiRes::time();
my $p2 = fork { sub => sub { sleep 3 } , start_after => $future, 
	on_busy => 'block' };
$t = Time::HiRes::time() - $t;
okl($t >= 4, "start_after job blocked took ${t}s expected ~10s");
ok(isValidPid($p2), "start_after job blocked and ran");
my $j2 = Forks::Super::Job::get($p2);
ok($j2->{state} eq "ACTIVE", "job ACTIVE after delay");

waitall;

ok($j1->{start} >= $now + 5, "job start was delayed");
ok($j2->{start} >= $future, "job start was delayed");
ok($j1->{start} - $j1->{created} >= 5,
   "job 1 waited >=5 seconds before starting");
my $j2_wait = $j2->{start} - $j2->{created};
ok($j2_wait >= 9, "job 2 waited $j2_wait >=9 seconds before starting");
