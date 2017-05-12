use Forks::Super ':test';
use Test::More tests => 7;
use strict;
use warnings;

# if this test hangs in Cygwin, install Win32::API ?

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
    if (!$Forks::Super::SysInfo::CONFIG{'getpgrp'}) {
	skip "pgid not supported", 7;
    }

    # kill forks to sub

    my $pid1 = fork { sub => $bgsub };
    my $pid2 = fork { sub => $bgsub };
    my $pid3 = fork { sub => $bgsub };
    my $j1 = Forks::Super::Job::get($pid1);

    ok(isValidPid($pid1) && isValidPid($pid2) && isValidPid($pid3),
       "launched $pid1,$pid2,$pid3 fork to sub");

    ok($pid1->{pgid}==$pid2->{pgid} && $pid1->{pgid}==$pid3->{pgid},
       "new processes have the same pgid");

    sleep 2;
    my $zero = Forks::Super::kill ('ZERO', $pid1, $pid2, $pid3);
    ok($zero == 3, "kill SIGZERO sent to the 3 bg jobs we launched")
	or diag("signal was sent to $zero/3 jobs");

    local $SIG{$QUIT} = sub { print "DON'T QUIT!\n" };
    my $y = Forks::Super::kill("-$QUIT", $pid1->{pgid});
    ok($y == 3, "kill signal to $pid1 with sent successfully $y==3 sub")
        or diag "\$y was $y";
    sleep 1;

    Forks::Super::Debug::use_Carp_Always();

    my $t = Time::HiRes::time();
    my $p = waitpid $pid1, 0, 20;
    $t = Time::HiRes::time() - $t;
    okl($t < 6,              ### 5 ### was 3, obs 4.4,5.44 on Cygwin
	"process $pid1 took ${t}s to reap sub, expected fast"); 
        # [sometimes it can take a while, though]

    ok($p == $pid1, "kill signal to $p==$pid1 successful sub");     ### 4 ###

    waitall;

    $zero = Forks::Super::kill ('ZERO', $pid1, $pid2, $pid3);
    ok($zero == 0, "kill SIGZERO now finds 0 jobs")
	or diag("successfully signalled $zero jobs with SIGZERO");
}

