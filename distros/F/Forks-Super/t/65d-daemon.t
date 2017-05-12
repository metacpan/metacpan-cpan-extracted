use Forks::Super ':test';
use Test::More tests => 6;
use Cwd;
use Carp;
use strict;
use warnings;

our $CWD = &Cwd::getcwd;
if (${^TAINT}) {
    ($CWD) = $CWD =~ /(.*)/;
}

### to cmd

my $output = "$CWD/t/out/daemon4.$$.out";
my $pid = fork {
    daemon => 1,
    env => { LOG_FILE => $output, VALUE => 10 },
    name => 'daemon3',
    exec => [ $^X, "$CWD/t/external-daemon.pl" ]
};
ok(isValidPid($pid), "fork to exec with daemon opt successful");
my $t = Time::HiRes::time;
my $p2 = wait;
$t = Time::HiRes::time - $t;
ok($p2 == -1 && $t <= 1.0,
   "wait on daemon not successful");
sleep 2;


SKIP: {
    if (!Forks::Super::Config::CONFIG('filehandles')) {
	sleep 13;
	skip "some daemon features won't work without file IPC", 4;
    }

    my $k = Forks::Super::kill 'ZERO', $pid;
    ok($k, "SIGZERO on daemon successful");
    ok($pid->{intermediate_pid}, "intermediate pid set on job");


    if (Forks::Super::Util::IS_WIN32ish &&
	!Forks::Super::Config::CONFIG_module('Win32::API')) {

	ok(1, "# suspend/resume daemon unavailable on $^O without Win32::API");

    } else {

	sleep 3;
	$pid->suspend;
	sleep 3;
	my $s1 = -s $output;
	sleep 1;
	my $s2 = -s $output;
	for (1..3) {
	    $pid->resume;
	    sleep 1;
	}
	my $s22 = -s $output;
	ok($s1 == $s2 && $s2 != $s22,
	   "suspend/resume on daemon ok $s1/$s2/$s22")
	    or diag("$s1/$s2");
    }

    sleep 1;
    $Forks::Super::Debug::DEBUG = 0;

    my $k1 = Forks::Super::kill 'TERM', $pid;
    sleep 4;
    my $s3 = -s $output;
    sleep 2;
    my $k2 = Forks::Super::kill 'ZERO', $pid;
    my $s4 = -s $output;
    ok($s3==$s4 && $k1 && !$k2, "F::S::kill can terminate a daemon")
	or diag("$s3/$s4/$k1/$k2");
}

unlink $output,"$output.err" unless $ENV{KEEP};
