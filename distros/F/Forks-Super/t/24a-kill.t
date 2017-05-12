use Forks::Super ':test', MAX_PROC => 5, ON_BUSY => 'queue';
use Test::More tests => 8;
use strict;
use warnings;

# on Cygwin, the OS sometimes sends this script SIGTTIN

# can this be trapped? I don't think so.
if (exists $SIG{TTIN}) {
  $SIG{TTIN} = sub { print STDERR "trapped SIGTTIN\n" };
}

# XXX - with t/forked_harness.pl (make fasttest) on Cygwin w/ Windows 7,
#       SIGQUIT and SIGINT suspend the whole process group for some reason,
#       but SIGTERM does not. Have to look into that. But for now,
#       we can pass this test using SIGTERM.
#       
our $QUIT = $^O eq 'cygwin' ? 'TERM' : 'QUIT';

my $bgsub = sub {
    # In case process doesn't know it's supposed to exit on SIGQUIT:
    $SIG{$QUIT} = sub { die "$$ received SIG$QUIT\n" };
    sleep 15;
};

SKIP: {
    if ($^O eq "MSWin32" && !Forks::Super::Config::CONFIG("Win32::API")) {
	skip "kill is unsafe on MSWin32 without Win32::API", 7;
    }

    # kill forks to sub

    my $pid1 = fork { sub => $bgsub };
    my $pid2 = fork { sub => $bgsub };
    my $pid3 = fork { sub => $bgsub };
    my $j1 = Forks::Super::Job::get($pid1);

    ok(isValidPid($pid1) && isValidPid($pid2) && isValidPid($pid3),
       "launched $pid1,$pid2,$pid3 fork to sub");

    sleep 2;
    my $zero = Forks::Super::kill ('ZERO', $pid1, $pid2, $pid3);
    ok($zero == 3, "kill SIGZERO sent to the 3 bg jobs we launched")
	or diag("signal was sent to $zero/3 jobs");


    my $y = Forks::Super::kill($QUIT, $j1);
    ok($y == 1, "kill signal to $pid1 with sent successfully $y==1 sub");
    sleep 1;

    Forks::Super::Debug::use_Carp_Always();

    my $t = Time::HiRes::time();
    my $p = waitpid $pid1, 0, 20;
    $t = Time::HiRes::time() - $t;
    okl($t < 6,              ### 3 ### was 3, obs 4.4,5.44 on Cygwin
	"process $pid1 took ${t}s to reap sub, expected fast"); 
        # [sometimes it can take a while, though]

    ok($p == $pid1, "kill signal to $p==$pid1 successful sub");     ### 4 ###
    $zero = Forks::Super::kill ('ZERO', $pid1, $pid2, $pid3);
    ok($zero == 2, "kill SIGZERO now finds 2 jobs");

    my $z = Forks::Super::kill_all('TERM');
    ok($z == 2, "kill_all signal to $z==$pid2,$pid3 successful sub");
    sleep 1;

    waitall;

    $zero = Forks::Super::kill ('ZERO', $pid1, $pid2, $pid3);
    ok($zero == 0, "kill SIGZERO now finds 0 jobs")
	or diag("successfully signalled $zero jobs with SIGZERO");
}

