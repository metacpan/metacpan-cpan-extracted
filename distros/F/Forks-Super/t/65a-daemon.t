use Forks::Super ':test';
use Test::More tests => 12;
use Cwd;
use Carp;
use strict;
use warnings;

my $CWD = Cwd::getcwd();
if (${^TAINT}) {
    ($CWD) = $CWD =~ /(.*)/;
}

sub run_simple_daemon {
    my $output = $ENV{output} || "t/out/daemon.out";

    no warnings 'io';
    open my $fh, '>', $output
	or croak "Daemon error $!\n";
    select $fh;
    $| = 1;

    print "Starting $$.\n";
    for my $i (1 .. 60) {
	sleep 1;
	print $i x $i, "\n";
    }
    print "Ending $$.\n";
    close $fh;
}

SKIP: {

    if ($^O eq 'MSWin32') {
	skip "Can't daemon to sub in MSWin32", 12;
    }

### natural

    my $test_pid = $$;
    my $output = "$CWD/t/out/daemon1.$$.out";
    my $pid = fork {
	daemon => 1,
	env => { output => $output },
	name => 'daemon1'
    };
    if ($$ != $test_pid) {
	&run_simple_daemon;
	exit;
    }

    ok(isValidPid($pid), "fork with daemon opt successful")
	or diag("pid was '$pid'");
    my $t = Time::HiRes::time;
    my $p2 = wait;
    $t = Time::HiRes::time - $t;
    ok($p2 == -1 && $t <= 1.0,
       "wait on daemon not successful");
    sleep 4;

  SKIP: {
      if (!Forks::Super::Config::CONFIG('filehandles')) {
	  sleep 13;
	  skip "some daemon features won't work if file IPC is disabled", 7;
      }

      my $k = Forks::Super::kill 'ZERO', $pid;
      ok($k, "SIGZERO on daemon successful") or diag "\$k was $k, expected 1-2";
      ok($pid->{intermediate_pid}, "intermediate pid set on job");

      if (Forks::Super::Util::IS_WIN32ish && 
	  !Forks::Super::Config::CONFIG_module('Win32::API')) {

	  ok(1, "# suspend daemon unavailable on $^O without Win32::API");
	  ok(1, "# resume daemon unavailable on $^O without Win32::API");
      } else {

	  sleep 2;
	  $pid->suspend;
	  sleep 3;
	  ok($pid->is_suspended, "is_suspended ok on daemon")
	      or diag("job $pid state: ", $pid->state);
	  my $s1 = -s $output;
	  sleep 2;
	  my $s2 = -s $output;
	  $pid->resume;
	  okl($s1 && $s1 == $s2, "suspend/resume on daemon ok")
	      or diag("expected $s1/$s2 to be the same");
	  sleep 1;
      }
      ok(0 == $pid->is_suspended, "is_suspended ok on daemon");
      ok(0 != $pid->is_active, "is_active for daemon");

      my $k1 = Forks::Super::kill 'TERM', $pid;
      sleep 3;
      my $s3 = -s $output;
      sleep 2;
      my $k2 = Forks::Super::kill 'ZERO', $pid;
      my $s4 = -s $output;
      ok($s3==$s4 && $k1 && !$k2, "F::S::kill can terminate a daemon")
	  or diag("$s3/$s4/$k1/$k2");
      unlink $output, "$output.err" unless $ENV{KEEP};
    }

    ok(!defined($pid->status), "Can't retrieve status for a daemon"); ### 10 ###
    ok(0 != $pid->is_daemon, "is_daemon returns true for daemon");    

=change v0.55  $pid->is_complete can now be "guessed" for daemon
    ok(0 == $pid->is_complete, "Can't retrieve is_complete for daemon");
=cut

    ok(0 != $pid->is_started, "is_started ok for daemon");            ### 12 ###

    #TODO:
    #ok(0 == $pid->is_active, "is_active==0 for completed daemon");
}

__END__

tests on a daemon process:

    if we can inspect process table, note that daemon is not a child process
                                     note that daemon has no parent

    file-based IPC works
    job status =~ /DAEMON/
    cannot wait on a daemon process
    natural, to sub, to cmd
