use Forks::Super ':test';
use Test::More tests => 6;
use strict;
use warnings;

#
# test different options for child processes that
# try to call fork.
#

$Forks::Super::CHILD_FORK_OK = 0;
my $pid1 = fork();
if ($pid1 == 0) {
    &try_to_fork_from_child;
    exit 0;
}
my $p = waitpid $pid1,0;
ok($p == $pid1, "waitpid reaped child");
ok(23 == $? >> 8, "child failed to fork as Expected STATUS");


$Forks::Super::CHILD_FORK_OK = 1;
my $pid2 = fork();
if ($pid2 == 0) {
    &try_to_fork_from_child;
    exit 0;
}
$p = waitpid $pid2, 0;
ok($p == $pid2, "blocking waitpid");
ok(0 == $?, "child fork was allowed STATUS $?, expected 0");

$Forks::Super::CHILD_FORK_OK = -1;
my $pid3 = fork();
if ($pid3 == 0) {
    &try_to_fork_from_child;
    exit 0;
}
$p = wait;
ok($p == $pid3, "blocking wait");
ok(25 == $? >> 8, "child fork used CORE::fork STATUS $?")       ### 6 ###
	or diag("Expected 25<<8, was $?");



sub try_to_fork_from_child {
    my $child_fork_pid = fork();
    if (not defined($child_fork_pid)  or  !isValidPid($child_fork_pid)) {
	# child fork failed.
	exit 23;
    }
    if (isValidPid($child_fork_pid)) {
	my $j = Forks::Super::Job::get($child_fork_pid);
	if (not defined $j) {
	    # normal (CORE::) fork. No child job created.
	    exit 25;
	}
    }
}
