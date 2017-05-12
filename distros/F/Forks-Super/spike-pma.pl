use strict;
use warnings;
use POSIX ':sys_wait_h';

# spike script to see if Forks::Super should use the poor man's
# alarm on this system.
# exit 0 if regular alarm is sufficient
# exit non-zero if regular alarm doesn't work for some reason
#
# if tests t/40a, t/40d, and t/40g don't work for you but t/40j does,
# run this script and report the output and exit status of this script
# to me at  mob@cpan.org .

if ($^O eq 'MSWin32') {
    $? = 4 << 8;
    die "This test is not for MSWin32";
}

my $p;
$SIG{CHLD} = sub {
    $p = waitpid -1, &WNOHANG;
};

my $t0 = time;
my $pid = CORE::fork();
if ($pid == 0) {
    sleep 1;
    local $SIG{ALRM} = sub { print STDERR "ZZZCLD SIGALRM\n";die "Child timeout\n" };
    alarm 3;
    eval {
        sleep 15;
        print STDERR "ZZZCLD sleep completed\n";
        exit 0;
    };
    print STDERR "ZZZCLD eval fail \$\@=$@\n";
    exit 5;
}

for (1..25) {
    my $nk = CORE::kill 'ZERO', $pid;
    print STDERR "ZZZPAR nk($pid,$_)=$nk\n";
    last unless $nk;
    if ($_ == 30) {
        kill -9, $pid;
    }
    sleep 1;
}
$p ||= wait;

my $t1 = time;

# Expect:
#    $pid and $p are the same
#    elapsed time is 4 or 5. Maaaaaybe 3 or 6.
#    $? (exit code of child) is 1280
#    exit code of this script is 0 (check $? in calling shell)

print STDERR "pid=$pid wait=$p elapsed=",$t1-$t0," \$?=$?\n";
if ($p != $pid)    { exit 1; }
if ($? == 0)       { exit 2; }
if ($t1-$t0 >= 10) { exit 3; }
if ($? != 5<<8)    { exit 4; }
exit 0;
