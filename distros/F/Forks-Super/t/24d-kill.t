use Forks::Super ':test', MAX_PROC => 5, ON_BUSY => 'queue';
use Test::More tests => 5;
use strict;
use warnings;

SKIP: {
    if ($^O eq "MSWin32" && !Forks::Super::Config::CONFIG("Win32::API")) {
	skip "kill is unsafe on MSWin32 without Win32::API", 5;
    }

    # signal fork to cmd jobs

    my @cmd = ($^X, "t/sleeper.pl");
    my $pid1 = fork { cmd => \@cmd };
    my $pid2 = fork { cmd => \@cmd };
    my $pid3 = fork { cmd => \@cmd };
    my $j1 = Forks::Super::Job::get($pid1);

    ok(isValidPid($pid1) && isValidPid($pid2) && isValidPid($pid3),
       "launched $pid1,$pid2,$pid3 fork to cmd");

    my $y = Forks::Super::kill('TERM', $j1);
    ok($y == 1, "kill signal to $pid1 sent successfully $y==1 cmd");
    sleep 1;

    # sometimes the signal is delivered but the process doesn't end?
    # resend to make sure it gets delivered, otherwise later tests will fail
    $pid1->terminate if !$pid1->is_complete;


    Forks::Super::Debug::use_Carp_Always();

    my $t = Time::HiRes::time();
    my $p = waitpid $pid1, 0, 20;
    $t = Time::HiRes::time() - $t;
    okl($t < 6,                                                  ### 3 ###
       "process $pid1 took ${t}s to reap cmd, expected fast"); 
       # [sometimes it can take a while, though]

    ok($p == $pid1, "kill signal to $p==$pid1 successful cmd"); ### 4 ###

    my $z = Forks::Super::kill_all('KILL');
    ok($z == 2, "kill_all signal to $z==$pid2,$pid3 successful cmd"); ### 5 ###
    sleep 1;
}  # end SKIP
