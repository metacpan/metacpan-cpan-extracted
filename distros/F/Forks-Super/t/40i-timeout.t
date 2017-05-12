use Forks::Super ':test';
use Test::More tests => 9;
use strict;
use warnings;

SKIP: {
    if (!Forks::Super::Config::CONFIG_module("DateTime::Format::Natural")) {
	skip "natural language test requires DateTime::Format::Natural module", 9;
    }

    my $pid = fork { timeout => "in 5 seconds", sub => sub { sleep 10 } };
    my $pp = waitpid $pid, 0;
    my $job = Forks::Super::Job::get($pid);
    my $elapsed = $job->{end} - $job->{start};

    ok(isValidPid($pid) && $pid == $pp, 
       "created task with natural language timeout");
    okl($elapsed >= 4.0 && $elapsed <= 7.5,                      ### 2 ###
	"natural language timeout was respected ${elapsed}s, expected ~5s");
    ok($job->{status} != 0, "natural language timeout had nonzero exit code");

    $pid = fork { timeout => "in 10 seconds", 
		  child_fh => "out",
		  sub => sub { 
		      my $e = Forks::Super::Job->this->{_expiration};
		      print STDOUT "$e\n";
		      sleep 4;
		  } };
    $pp = waitpid $pid, 0;
    $job = Forks::Super::Job::get($pid);
    $elapsed = $job->{end} - $job->{start};
    ok(isValidPid($pid) && $pid == $pp,
       "created another task with natural language timeout");
    ok($job->{status} == 0, "natural language timeout had zero exit code");
    my $e = $job->read_stdout();
    chomp $e;
    ok($e > $job->{end}, "job ended $job->{end} before expiration $e");

    my $output = "t/out/40i-$$.out";
    $pid = fork { expiration => "6 Mondays from now",
		  child_fh => "out",
		  sub => sub { 
		      my $j = Forks::Super::Job->this;
		      my $d = $j->{_timeout};
		      print STDOUT "$d\n";
		      sleep 1;
		  } };
    $job = Forks::Super::Job::get($pid);
    my $d = $job->read_stdout(block => 1);
    chomp $d;
    ok($d > 5 * 7 * 86400 && $d < 7 * 7 * 86400,          ### 7 ###
       "task created with looooong natural language expiration $d seconds");

    $pid = fork { timeout => "last week",
		  child_fh => "out",
		  sub => sub {
		      print STDOUT "foo\n";
		  }
    };
    $job = Forks::Super::Job::get($pid);
    wait;
    $d = $job->read_stdout() || "";
    ok($job->{status} != 0, 
       "job not launched because expiration was expressed "
       ."as a past time in natural language");
    ok($d !~ /foo/, "job with expiration in the past did not get started");

    # also expect "Failed to open < ./.fhfork<nnnn>/.fh_003 after 10 tries",
    # "config_fh_parent(): could not open file handle to read child STDOUT"
    # warnings, since the child doesn't ever get started.

    waitall;

}  # end SKIP
