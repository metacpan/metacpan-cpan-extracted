use Forks::Super ':test';
use Test::More tests => 6;
use POSIX ':sys_wait_h';
use Cwd;
use Carp;
use strict;
use warnings;

my $CWD = Cwd::getcwd();
if (0 && ${^TAINT}) {
    ($CWD) = $CWD =~ /(.*)/;
    if (0) {
        my $ipc_dir = Forks::Super::Job::Ipc::_choose_dedicated_dirname();
        if (! eval {$ipc_dir = Cwd::abs_path($ipc_dir)}) {
            $ipc_dir = Cwd::getcwd() . "/" . $ipc_dir;
        }
        ($ipc_dir) = $ipc_dir =~ /(.*)/;
        Forks::Super::Job::Ipc::set_ipc_dir($ipc_dir);
        ($^X) = $^X =~ /(.*)/;
        $ENV{PATH}='';
    }
}
if (${^TAINT}) {
    ($CWD) = $CWD =~ /(.*)/;
}

### to cmd

our $QUIT = $^O eq 'cygwin' ? 'TERM' : 'QUIT';

my $output = "$CWD/t/out/daemon3.$$.out";
my $pid = fork {
    daemon => 1,
    env => { LOG_FILE => $output, VALUE => 15 },
    name => 'daemon3',
    cmd => [ $^X, "$CWD/t/external-daemon.pl" ]
};
ok(isValidPid($pid), "$pid\\fork to cmd with daemon opt successful");
my $t = Time::HiRes::time;
my $p2 = wait;
$t = Time::HiRes::time - $t;
ok($p2 == -1 && $t <= 1.0,
   "wait on daemon not successful");
sleep 2;

SKIP: {
    if (!Forks::Super::Config::CONFIG('filehandles')) {
	sleep 13;
	sleep 5 if $^O eq 'MSWin32';
	skip "some daemon features won't work without file IPC", 4;
    }

    my $k = Forks::Super::kill 'ZERO', $pid;
    ok($k, "SIGZERO on daemon successful");
    ok($pid->{intermediate_pid},
       "intermediate pid $pid->{intermediate_pid} set on job");

    if (Forks::Super::Util::IS_WIN32ish &&
	!Forks::Super::Config::CONFIG_module('Win32::API')) {

	ok(1, "# suspend/resume daemon unavailable on $^O without Win32::API");

    } else {

	sleep 2;
	diag "gonna suspend job in state ",$pid->{state};
	$pid->suspend;
	sleep 4;
	sleep 2 if $^O eq 'MSWin32';
	my $s1 = -s $output;
	sleep 1;
	my $s2 = -s $output;
	for (1..3) {
	    $pid->resume;
	    sleep 1;
	    sleep 1 if $^O eq 'MSWin32';
	}
	my $s22 = -s $output;
	ok($s1 && $s1 == $s2 && $s2 != $s22,                  ### 5 ###
	   "suspend/resume on daemon ok $s1/$s2/$s22")
	    or diag("$s1/$s2/$s22");
    }

    sleep 2;
    my $k1 = Forks::Super::kill $QUIT, $pid;
    sleep 3;

    for (1..2) {
        # sometimes signal doesn't kill process the first time?
        sleep 1;
	if (!$pid->is_complete) {
	    diag("resending kill signal to $pid");
	    Forks::Super::kill('KILL', $pid);
	}
    }
    sleep 3;


    my $s3 = -s $output;
    sleep 2;

    # failure point in Cygwin where a zombie process is left and $k2 => 1
    my $k2 = Forks::Super::kill 'ZERO', $pid;

    my $s4 = -s $output;
    ok($s3==$s4 && $k1 && $k2<$k1, 
       "F::S::kill can terminate a daemon $s3/$s4/$k1/$k2")
      or diag("$s3/$s4/$k1/$k2");


    if ($k2>0) {
        if ($^O eq 'cygwin' && defined &Cygwin::pid_to_winpid) {
            my $wpid = Cygwin::pid_to_winpid($pid);
            diag("killing zombie in Cygwin",
	         system("TASKKILL /f /pid $wpid"));
        } else {
	    diag("Process $pid might be a zombie ...");
        }
    }
}

if ($ENV{KEEP}) {
    print STDERR "output in $output, $output.err\n";
} else {
    unlink $output,"$output.err";
}
