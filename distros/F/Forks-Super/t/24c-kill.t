use Forks::Super ':test', MAX_PROC => 5, ON_BUSY => 'queue';
use Test::More tests => 7;
use strict;
use warnings;

# as of v0.30, the kill and kill_all functions are not very well speced out.
# these tests should pass in the current incarnation, though.

our $QUIT = $^O eq 'cygwin' ? 'TERM' : 'QUIT';

SKIP: {
    if ($^O eq "MSWin32" && !Forks::Super::Config::CONFIG("Win32::API")) {
	skip "kill is unsafe on MSWin32 without Win32::API", 7;
    }

    # signal fork to exec job

    my @cmd = ($^X, "t/sleeper.pl");
    my $pid1 = fork { exec => \@cmd };
    my $pid2 = fork { exec => \@cmd };
    my $pid3 = fork { exec => \@cmd };
    my $j1 = Forks::Super::Job::get($pid1);

    ok(isValidPid($pid1) && isValidPid($pid2) && isValidPid($pid3),
       "launched $pid1,$pid2,$pid3 fork to exec");

    my $zero = Forks::Super::kill('ZERO', $pid1, $pid2, $pid3);
    ok($zero==3, "successfully sent SIGZERO to 3 exec procs")
	or diag("signalled $zero procs, expected 3");

    my $y = Forks::Super::kill($QUIT, $pid1);
    ok($y == 1, "kill signal to $pid1 sent successfully $y==1 exec")
	or diag("signalled $y procs, expected 1");

    # sometimes the signal is delivered but the process doesn't end?
    # resend to make sure it gets delivered, otherwise later tests will fail
    for (1..3) {
	sleep 1;
	Forks::Super::kill($QUIT, $pid1) unless $pid1->is_complete;
    }
    for (1..3) {
	last if $pid1->is_complete;
	Forks::Super::kill('KILL',$pid1);
	Forks::Super::kill('CONT',$pid1);
	sleep 1;
    }
# $pid1->wait;

    #Forks::Super::Debug::use_Carp_Always();

    # in v0.53, F::S::kill can return 2 when signalling a single process ...
    # use the !! idiom to track the actual number of processes signalled
    #$zero = Forks::Super::kill('ZERO', $pid1, $pid2, $pid3);

    my $k1 = Forks::Super::kill('ZERO', $pid1);
    my $k2 = Forks::Super::kill('ZERO', $pid2);
    my $k3 = Forks::Super::kill('ZERO', $pid3);
    $zero = !!$k1 + 2*!!$k2 + 4*!!$k3;
    my $zero1 = $k1 + 4*$k2 + 16*$k3;

    ok($zero==6 && $zero1==20,
       "successfully sent SIGZERO to 2 exec procs")               ### 17 ###
	or diag("\$zero was $zero, expected 6, \$zero1 was $zero1");

    my $t = Time::HiRes::time();
    my $p = waitpid $pid1, 0, 20;
    $t = Time::HiRes::time() - $t;
    okl($t < 6,                                                   ### 18 ###
	"process $pid1 took ${t}s to reap exec, expected fast"); 
        # [sometimes it can take a while, though]

    ok($p == $pid1, "kill signal to $p==$pid1 successful exec");

    my $z = Forks::Super::kill_all('TERM');
    ok($z == 2, "kill_all signal to $z==$pid2,$pid3 successful exec");
    sleep 1;

    waitall;
}  # end SKIP
