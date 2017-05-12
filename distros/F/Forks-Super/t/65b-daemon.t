use Forks::Super ':test';
use Test::More tests => 8;
use Cwd;
use Carp;
use Config;
use strict;
use warnings;



sub diagmidnightbsd {
    diag @_ if $^O eq 'midnightbsd' || $^O eq "dragonfly";
}


our $CWD = &Cwd::getcwd;
diagmidnightbsd "\$CWD is $CWD";
($CWD) = $CWD =~ /(.*)/ if ${^TAINT};

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


if (!defined $CWD) {
  SKIP: {
      skip "Can't run daemon tests without knowing current directory", 8;
    }
    exit;
}

SKIP: {

    if ($^O eq 'MSWin32') {
	skip "Can't daemon to sub in MSWin32", 8;
    }

### to sub

    my $output = "$CWD/t/out/daemon2.$$.out";
    diagmidnightbsd "\$output is $output";
    my $pid = fork {
	daemon => 1,
	env => { output => $output },
	name => 'daemon2',
	sub => \&run_simple_daemon
    };
    diagmidnightbsd "fork => $pid";
    ok(isValidPid($pid), "fork to sub with daemon opt successful");
    my $t = Time::HiRes::time;
    diagmidnightbsd "waiting $t";
    my $p2 = wait;
    $t = Time::HiRes::time - $t;
    diagmidnightbsd "wait took ${t}s";
    ok($p2 == -1 && $t <= 1.0, "wait on daemon not successful");
    sleep 4;

  SKIP: {
      if (!Forks::Super::Config::CONFIG('filehandles')) {
	  sleep 13;
	  skip "some daemon features won't work if file IPC is disabled", 4;
      }

      my $k = Forks::Super::kill 'ZERO', $pid;
      ok($k, "SIGZERO on daemon successful");
      ok($pid->{intermediate_pid}, "intermediate pid set on job");

      if (Forks::Super::Util::IS_WIN32ish &&
	  !Forks::Super::Config::CONFIG_module('Win32::API')) {

 	  ok(1, "# suspend/resume daemon unavailable on $^O w/o Win32::API");
     } else {

	  sleep 2;
	  $pid->suspend;
	  sleep 3;
	  my $s1 = -s $output;
	  sleep 2;
	  my $s2 = -s $output;
	  $pid->resume;
	  ok($s1 && $s1 == $s2, "suspend/resume on daemon ok")
	      or diag("$s1/$s2");
	  sleep 1;
      }

      my $k1 = Forks::Super::kill 'TERM', $pid;
      sleep 3;
      my $s3 = -s $output;
      sleep 2;
      my $k2 = Forks::Super::kill 'ZERO', $pid;
      my $s4 = -s $output;
      ok($s3==$s4 && $k1 && !$k2, "F::S::kill can terminate a daemon")
	  or diag("$s3/$s4/$k1/$k2");
      unlink $output,"$output.err" unless $ENV{KEEP};
    }

    # F::S respects MAX_PROC when launching a daemon process
    $Forks::Super::MAX_PROC = 1;
    $Forks::Super::ON_BUSY = 'fail';
    my $not_a_daemon = fork { sub => sub { sleep 5 } };
    my $daemon = fork { sub => sub { sleep 5 }, daemon => 1 };
    ok(!isValidPid($daemon), "respect MAX_PROC when launching a daemon");
    ref($daemon) && $daemon->kill('TERM');
    ref($not_a_daemon) && $not_a_daemon->kill('TERM');
    waitall;

    if ($Config{PERL_VERSION} <= 7) {
	skip "last test doesn't pass for Perl v<=5.7", 1;
    }

    # daemons don't count against MAX_PROC
    my $daemon2 = fork { sub => sub { sleep 5 }, daemon => 1 };
    my $not_daemon2 = fork { sub => sub { sleep 5 } };
    ok(isValidPid($not_daemon2), "daemon does not count against MAX_PROC");
    ref($daemon2) && $daemon2->kill('TERM');
    ref($not_daemon2) && $not_daemon2->kill('TERM');
    waitall;
}

__END__

tests on a daemon process:

    if we can inspect process table, note that daemon is not a child process
                                     note that daemon has no parent

    file-based IPC works
    job status =~ /DAEMON/
    cannot wait on a daemon process
    natural, to sub, to cmd
