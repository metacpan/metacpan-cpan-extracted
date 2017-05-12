use Forks::Super ':test';
use Test::More tests => 9;
use strict;
use warnings;

# exercise IPC in a daemon

if ($^O eq 'MSWin32') {
    for (1..9) {
	ok(1, 'skip damon/sub test on MSWin32');
    }
    exit;
}

my $job = fork {
    daemon => 1,
    child_fh => 'all',
    sub => sub {
	sleep 4; # should we block instead of this?
	while (<STDIN>) {
	    last if $_ eq "__EOF__\n";
	    print STDERR $_;
	    print STDOUT $_ ** 2, "\n";
	    sleep 2;
	}
    }
};

ok($job, "$$\\daemon launched");
ok($job->write_stdin("4\n"), "write to daemon stdin ok");
ok($job->write_stdin("5\n"), "write to daemon stdin ok");
my $x1 = $job->read_stdout(block => 1);
my $x2 = $job->read_stderr();
ok($x1 == 16, "read from daemon stdout ok");
ok($x2 == 4, "read from daemon stderr ok") or diag $x2;
$x1 = $job->read_stdout(block => 1);
ok($x1 == 25, "2nd read from daemon stdout ok");
ok(Forks::Super::kill('ZERO', $job->signal_pids), "daemon is alive");
$job->write_stdin("__EOF__\n");
$job->close_fh('stdin');

$x2 = $job->read_stderr();
ok($x2 == 5, "read from daemon stderr after stdout closed ok") or diag $x2,$job->read_stderr;
sleep 4;
ok(!Forks::Super::kill('ZERO', $job->{real_pid}), "daemon is not alive")
    or diag('could not signal ',$job->{real_pid});
