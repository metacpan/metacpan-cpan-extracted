use Forks::Super ':test', 'overload';
use Test::More tests => 56;
use strict;
use warnings;

# return value from Forks::Super::fork
# can be an overloaded Forks::Super::Job object
# that should behave like a numerical pid
# but can also invoke the F::S::J methods
# like $job->status, etc.

my $job_pid = fork();
if (!defined $job_pid) {
    die "fork() returned undefined value.\n";
}
if ($job_pid == 0) {
    # child.
    exit;
}

ok(ref $job_pid eq 'Forks::Super::Job', 
   "fork returns Forks::Super::Job object in overloaded mode");

my $pid = $job_pid->{pid};
ok($pid != 0 && ref $pid eq '', "can access member of Job object")
        or diag "\$pid=$pid, ref=",ref($pid);
ok($job_pid->is_started, "can access method of Job object ");

# arithmetic operations
ok($pid + 10 == $job_pid + 10, "+ operation");
ok($pid - 10 == $job_pid - 10, "- operation");
ok(99999 - $job_pid == 99999 - $job_pid, "- operation");
ok($pid * 5 == 5 * $job_pid, "* operation");
ok($pid / 14 == $job_pid / 14, "/ operation");
ok($pid % 16 == $job_pid % 16, "% operation");
ok(($pid & 1023) == ($job_pid & 1023), "& operation");
ok($pid ** 2 == $job_pid ** 2, "** operation");
ok(1.001 ** $pid == 1.001 ** $job_pid, "** operation");
ok(($pid | 757) - (757 | $job_pid) == 0, "| operation");
ok($job_pid =~ /-?\d+/, "regex operation ok");
ok(($pid ^ 1254) - ($job_pid ^ 1254) == 0, "^ operation ok");
SKIP: {
    if ($job_pid < 0) {
	skip "bit shift operation on negative job id", 2;
    }
    ok($job_pid << 4 == $pid * 16, "<< operation ok  $job_pid >> 4 == $pid*16");
    ok($job_pid >> 3 == int($pid/8), ">> operation ok $job_pid << 3 == $pid/8");
}
ok(abs($job_pid) == abs($pid), "abs operation ok");
ok($pid == $job_pid, "== operation ok");
ok($job_pid == $pid, "== operation ok");
ok($job_pid != 52.6, "!= operation ok");
ok($job_pid > $pid - 1, "> operation ok");
ok($job_pid >= $pid - 1, ">= operation ok");
ok($job_pid <= $pid, "<= operation ok");
ok($job_pid < $pid + 3, "< operation ok");
ok(~$job_pid, "~ operation ok");
ok((~$job_pid ^ (~0)) == ~~(0+$job_pid), "~ operation ok");


# string operations
ok(0 == ($pid cmp $job_pid), "cmp operation");
ok($job_pid lt $pid . "x", "lt operation");
ok("zz$pid" gt $job_pid, "gt operation");
ok($job_pid ne "foo", "ne operation");
ok($job_pid eq $job_pid, "eq operation");
ok(length($job_pid x 4) == 4 * length($pid), "x operation");

ok(atan2($job_pid,1) == atan2($pid,1), "atan2 operation");

# unary operations
ok(cos($job_pid) == cos($pid), "cos operation");
ok(sin($job_pid) == sin($pid), "sin operation");
ok(exp($job_pid) eq exp($pid), "exp operation");
if ($pid > 0) {
    ok(log($job_pid) == log($pid), "log operation");
    ok(sqrt($job_pid) == sqrt($pid), "sqrt operation");
} else {
    ok(1, "skip log operation on negative pid");
    ok(1, "skip sqrt operation on negative pid");
}
ok(int($job_pid) == $pid, "int operation");

# assignment operators ... should fail.
my $job = $job_pid;
ok(ref $job eq 'Forks::Super::Job', "= operation ok");
$job += 1;
ok(ref $job eq '', "+= removes Forks::Super::Job reference");

$job = $job_pid; $job x= 1;
ok(ref $job eq '', "x= removes Forks::Super::Job reference");

$job = $job_pid;
$job--;
ok(ref $job eq '', "-- operation removes Forks::Super::Job reference");


my $state = eval { $job_pid->state };
ok(!$@ && defined($state), "->state() method");

my $pid2 = waitpid $job_pid, 0;
ok($pid2 == $pid, "waitpid on job object ok");
ok(ref $pid2 eq 'Forks::Super::Job',
   "waitpid return value is also overloaded");

my $status = eval { $job_pid->status };
ok(!$@ && $status eq "0", "->status() method");

##################################################################

ok($Forks::Super::Job::OVERLOAD_ENABLED != 0,
   "\$OVERLOAD_ENABLED is set");
Forks::Super::Job::disable_overload();
ok($Forks::Super::Job::OVERLOAD_ENABLED == 0,
   "FSJ::disable_overload resets \$OVERLOAD_ENABLED");

$job_pid = fork { sub => sub { sleep 1 } };
ok(!ref($job_pid),
   "overload disabled fork returns simple number");

$state = eval { $job_pid->{state} };
ok(!defined($state) && $@,
   "job member not accessible through fork return when overload disabled");

##################################################################

Forks::Super::Job::enable_overload();
ok($Forks::Super::Job::OVERLOAD_ENABLED != 0,
   "\$OVERLOAD_ENABLED is set on renable");
$job_pid = fork { sub => sub { sleep 1 } };
ok(ref($job_pid), "reenabled overload fork returns ref to FSJ");

Forks::Super::Job::disable_overload();
ok($Forks::Super::Job::OVERLOAD_ENABLED == 0,
   "\$OVERLOAD_ENABLED is unset on redisable");
$job_pid = fork { sub => sub { sleep 1 } };
ok(!ref($job_pid), "redisabled overload fork returns simple num");

waitall;
