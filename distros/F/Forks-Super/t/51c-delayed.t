use Forks::Super ':test';
use Test::More tests => 4;
use strict;
use warnings;

SKIP: {

    if (!Forks::Super::Config::CONFIG_module("DateTime::Format::Natural")) {
	skip "natural language test requires DateTime::Format::Natural module", 4;
    }

my $t = Time::HiRes::time();
my $pid = fork { delay => "in 5 seconds", sub => sub { sleep 3 } };
my $pp = waitpid $pid, 0;
my $job = Forks::Super::Job::get($pid);
my $elapsed = $job->{start} - $t;

ok(!isValidPid($pid,-1) && $pp == $pid || $pp == $job->{real_pid}, 
   "created task with natural language delay");
okl($elapsed >= 4 && $elapsed <= 6.2, "natural language delay was respected")
    or diag("took ${elapsed}s, expected 4-6");

my $future = "in 6 seconds";
$t = Time::HiRes::time();
$pid = fork { start_after => $future,
		child_fh => "out",
		sub => sub { 
		  my $e = Forks::Super::Job->this->{start_after};
		  print STDOUT "$e\n";
		  sleep 4;
		} };
$pp = waitpid $pid, 0;
$job = Forks::Super::Job::get($pid);
$elapsed = $job->{start} - $t;
ok(!isValidPid($pid,-1) && $pid == $pp || $pp == $job->{real_pid}, 
   "created another task with natural language start_after");
ok($elapsed >= 5 && $elapsed <= 7, 
   "natural language start_after was respected");

waitall;

}
