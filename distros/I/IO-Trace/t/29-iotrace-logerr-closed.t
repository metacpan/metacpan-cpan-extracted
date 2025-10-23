# Before 'make install' is performed this script should be runnable with
# 'make test'

#########################

use strict;
use warnings;
our (@filters, $test_points);
use Test::More tests => (@filters = qw[none iotrace strace]) * ($test_points = 22);
use POSIX qw(WNOHANG);
use IO::Handle;
use IPC::Open3 qw(open3);

# Test target close STDERR (fd 2) without separate trace log (Run 4 seconds)
my $test_prog = q{
    $|=1;                                    #LineA
    sub p{sleep 1}                           #LineB
    sub r{$_=<STDIN>//"(undef)";chomp;$_}    #LineC
    r;                                       #LineD
    p;print "OUT-ONE:$_\n";                  #LineE
    p;close STDERR;                          #LineF
    p;p;exit 0;                              #LineG
};

eval { require Time::HiRes; };
sub t { defined(\&Time::HiRes::time) ? sprintf("%10.6f",Time::HiRes::time()) : time() }

sub bits {
    my $fh = shift;
    alarm 5;
    vec (my $bits = "", fileno($fh), 1) = 1;
    $! = 0; # Reset errno
    return $bits;
}

sub canread {
    my $fh = shift;
    my $timeout = shift || 0.01;
    my $bits = bits($fh);
    return scalar select($bits, undef, undef, $timeout);
}

sub canwrite {
    my $fh = shift;
    my $timeout = shift || 0.01;
    my $bits = bits($fh);
    return scalar select(undef, $bits, undef, $timeout);
}

my $pid = 0;
$SIG{ALRM} = sub { require Carp; $pid and Carp::cluck("TIMEOUT ALARM TRIGGERED! Aborting execution PID=[$pid]") and kill TERM => $pid and sleep 1 and kill KILL => $pid; };

SKIP: for my $try (@filters) {
    my $prog = $try =~ /(\w+)$/ && $1;
    skip "no strace", $test_points if $prog eq "strace" and !-x "/usr/bin/strace"; # Skip strace tests if doesn't exist

    # run cases where STDERR is closed by the target first

    my @run = ($^X, "-e", $test_prog);
    # Ensure behavior of $test_prog is the same with or without tracing it.
    unshift @run, $try, -tt => -e => "execve,clone,openat,close,read,write" if $prog ne "none";
    unshift @run, $try, -tt => -s9000 => -o => "/tmp/strace.nolog.strace" if $prog eq "strace";

    alarm 5;
    my $line;
    # open3 needs real handles, at least for STDERR
    my $in_fh  = IO::Handle->new;
    my $out_fh = IO::Handle->new;
    my $err_fh = IO::Handle->new;
    $! = 0; # Reset errno
    $pid = open3($in_fh, $out_fh, $err_fh, @run) or die "open3: FAILED! $!\n";
    ok($pid, t." $prog: spawned [pid=$pid] $!");

    # If @run started properly, then its I/O should be writeable but not readable yet
    alarm 5;
    ok(canwrite($in_fh),  t." $prog: TOP: STDIN is writeable: $!");
    ok(!canread($out_fh), t." $prog: TOP: STDOUT is empty so far: $!");
    # Make sure its STDERR is clear before starting the real tests
    my $trace = "";
    my $smell_log = qr/^()/;
    alarm 5;
    my $quick = 0.9 + t;
    while (canread($err_fh, ($quick - t)) and sysread($err_fh, $trace, 8192, length $trace)) { last if $quick < t; }
    $smell_log = qr/(.*execve.{1,80})/ if $prog ne "none";
    ok($trace =~ $smell_log, t." $prog: TOP: trace log started great: $1");
    ok(!canread($err_fh), t." $prog: TOP: STDERR is empty so far: $!");

    # Test #LineD: <STDIN>
    alarm 5;
    ok((print $in_fh "uno!\n"),t." $prog: line1");

    # Test #LineE: p (PAUSE for a second); ONE
    # STDOUT should be empty for about a second waiting for the target to spawn up and read and sleep and echo back
    alarm 5;
    ok(!canread($out_fh), t." $prog: PRE: STDOUT is still empty: $!");
    alarm 5;
    ok(canread($out_fh,1.7), t." $prog: PRE: STDOUT ready: $!");
    alarm 5;
    chomp($line = <$out_fh>);
    ok($line, t." $prog: back1: $line");
    like($line, qr/uno/, t." $prog: MID: STDIN perfect read");

    # Quickly non-blocking-ly slurp up everything previously sent to STDERR so far
    alarm 5;
    $quick = 0.2 + t;
    while (canread($err_fh, $quick - t) and sysread($err_fh, $trace, 8192, length $trace)) { last if $quick < t; }
    $smell_log = qr/(.*write.*ONE:uno.*)/ if $prog ne "none";
    ok($trace =~ $smell_log, t." $prog: MID: trace log smells great: $1");

    # Test #LineF: p (PAUSE); close STDERR
    # STDERR should still be empty for a bit
    alarm 5;
    ok(!canread($err_fh), t." $prog: MID: STDERR is still empty: $!");
    # STDERR should remain empty for at least a second ...
    alarm 5;
    ok(!canread($err_fh, 0.7), t." $prog: MID: STDERR remains open after delay");

    # Tracer should log the explicit "close(2)" (but its actual STDERR should NOT actually close because -o wasn't used) so just in case, give plenty of time to spit it out
    alarm 5;
    ok(canread($err_fh, 0.6), t." $prog: END: STDERR woked in time");
    alarm 5;
    $quick = 0.2 + t;
    while (canread($err_fh, $quick - t) and sysread($err_fh, $trace, 8192, length $trace)) { last if $quick < t; }
    $smell_log = qr/(.*close\(2\).*)/ if $prog ne "none";
    ok($trace =~ $smell_log, t." $prog: END: target did close() STDERR");

    # STDOUT should still be open but empty
    alarm 5;
    ok(!canread($out_fh), t." $prog: MID: STDOUT still open after explicit STDERR close");

    # STDERR should still be open but empty iff target is being traced (not "none")
    my $stderr_still_open = !canread($err_fh);
    ok(($prog ne "none") eq $stderr_still_open, t." $prog: END: STDERR still open: $stderr_still_open");

    # Test #LineG: p;p;exit
    # STDOUT should implictly close once the process completes
    alarm 5;
    ok(canread($out_fh, 3.4), t." $prog: END: STDOUT closed: $!");
    alarm 5;
    ok(canread($err_fh, 0.2), t." $prog: END: STDERR closed: $!");

    # Slurp in the rest of trace log
    alarm 5;
    $quick = 0.2 + t;
    while (canread($err_fh, $quick - t) and sysread($err_fh, $trace, 8192, length $trace)) { last if $quick < t; }
    $smell_log = qr/(.*\+\+\+\s+exited with \d+\s\+\+\+.*)/ if $prog ne "none";
    ok($trace =~ $smell_log, t." $prog: END: trace completed perfectly: $1");

    alarm 5;
    my $died = waitpid($pid, 0);
    is($died, $pid, t." $prog: PID[$pid] DONE[$died]");
    is($?, 0, t." $prog: normal exit: $?");
}
