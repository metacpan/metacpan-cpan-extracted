# Before 'make install' is performed this script should be runnable with
# 'make test'

#########################

use strict;
use warnings;
our (@filters, $test_points);
use Test::More tests => 1 + (@filters = qw[none iotrace strace]) * ($test_points = 41);
use Errno qw(EPIPE);
use File::Temp ();
use POSIX qw(WNOHANG);
use IO::Handle;
use IPC::Open3 qw(open3);

# Test target closing all handles prior to exiting (Run 9 seconds)
my $test_prog = q{
    $|=1;                                    #LineA
    sub p{sleep 1}                           #LineB
    sub r{$_=<STDIN>//"(undef)";chomp;$_}    #LineC
    r;                                       #LineD
    p;print "OUT-ONE:$_\n";                  #LineE
    p;warn "ERR-TWO:$_\n";                   #LineF
    p;close STDIN;                           #LineG
    p;close STDOUT;                          #LineH
    p;close STDERR;                          #LineI
    p;p;exit 0;                              #LineJ
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
my $got_piped = 0;
$SIG{PIPE} = sub { $got_piped = 1; };
alarm 5;
my $tmp = File::Temp->new( UNLINK => 1, SUFFIX => '.trace' );
ok("$tmp", t." tracefile[$tmp]");

SKIP: for my $try (@filters) {
    my $prog = $try =~ /(\w+)$/ && $1;
    skip "no strace", $test_points if $prog eq "strace" and !-x "/usr/bin/strace"; # Skip strace tests if doesn't exist

    # run cases where STDIN,STDOUT,STDERR are all closed by the target first

    my @run = ($^X, "-e", $test_prog);
    # Ensure behavior of $test_prog is the same with or without tracing it.
    unshift @run, $try, -tt => -e => "execve,clone,openat,close,read,write", -o => "$tmp" if $prog ne "none";

    alarm 5;
    my $line;
    # open3 needs real handles, at least for STDERR
    my $in_fh  = IO::Handle->new;
    my $out_fh = IO::Handle->new;
    my $err_fh = IO::Handle->new;
    $got_piped = 0;
    $! = 0; # Reset errno
    $pid = open3($in_fh, $out_fh, $err_fh, @run) or die "open3: FAILED! $!\n";
    ok($pid, t." $prog: spawned [pid=$pid] $!");

    # If @run started properly, then its I/O should be writeable but not readable yet
    alarm 5;
    ok(canwrite($in_fh),  t." $prog: TOP: STDIN is writeable: $!");
    ok(!canread($out_fh), t." $prog: TOP: STDOUT is empty so far: $!");
    ok(!canread($err_fh), t." $prog: TOP: STDERR is empty so far: $!");

    # Test #LineD: <STDIN>
    alarm 5;
    ok((print $in_fh "uno!\n"),t." $prog: line1");

    # Test #LineE: p (PAUSE for a second); ONE
    # STDOUT should be empty for about a second waiting for the target to spawn up and read and sleep and echo back
    alarm 5;
    ok(!canread($out_fh), t." $prog: PRE: STDOUT is still empty: $!");
    alarm 5;
    ok(canread($out_fh,2.7), t." $prog: PRE: STDOUT ready: $!");
    alarm 5;
    chomp($line = <$out_fh>);
    ok($line, t." $prog: back1: $line");
    like($line, qr/uno/, t." $prog: MID: STDIN perfect read");

    # Test #LineF: p (PAUSE)
    # STDERR should still be empty
    alarm 5;
    ok(!canread($err_fh), t." $prog: MID: STDERR is still empty: $!");

    # Test #LineF: TWO
    # STDERR should remain empty for about 1 seconds ...
    alarm 5;
    ok(canread($err_fh,1.2),t." $prog: MID: STDERR ready: $!");
    alarm 5;
    chomp($line = <$err_fh>);
    ok($line, t." $prog: back2: $line");

    # Test #LineG: p
    # STDOUT and STDERR should both still be empty
    alarm 5;
    ok(!canread($out_fh), t." $prog: MID: STDOUT still empty: $!");
    ok(!canread($err_fh), t." $prog: MID: STDERR still empty: $!");

    # Test #LineG: close STDIN
    alarm 5;
    $! = 0;
    ok(!$!, t." $prog: MID: STDIN No Errno: $!");
    # Quickly jam something into its STDIN while it's still open, but this should get lost.
    ok((print $in_fh "dos!\n"),t." $prog: line2: $!");
    ok(!$!, t." $prog: MID: STDIN Still No Errno: $!");
    ok(!$got_piped, t." $prog: STDIN Not PIPED: $got_piped");
    ok(!canread($in_fh),  t." $prog: STDIN still sleeping: $!");

    # STDIN should be closed within a second, which should wake up its file descriptor.
    alarm 5;
    ok(canread($in_fh, 1.3),  t." $prog: STDIN woke up: $!");
    # Haven't touched the woke STDIN yet, so not PIPED yet.
    ok(!$!, t." $prog: MID: STDIN Still No EPIPE: $!");
    ok(!$got_piped, t." $prog: STDIN Still Not PIPED: $got_piped");
    # The PIPE must be broken now that canread, so writing should fail:
    ok(!(print $in_fh "PIPE CRASH!\n"), t." $prog: line3: $!");
    is(0+$!, EPIPE, t." $prog: MID: STDIN Got EPIPE: $!");
    ok($got_piped,  t." $prog: Got PIPED: $got_piped");
    $got_piped = 0;
    $! = 0;
    ok(!close($in_fh),  t." $prog: explicit close STDIN should fail after broken write: $!");
    is(0+$!, EPIPE, t." $prog: END: close STDIN with broken buffer got EPIPE: $!");

    # Test #LineH: p;close STDOUT
    # STDOUT should still be empty
    alarm 5;
    ok(!canread($out_fh), t." $prog: END: STDOUT still empty: $!");
    # STDOUT should remain empty for about 1 seconds ...
    alarm 5;
    ok(canread($out_fh,1.8),t." $prog: END: STDOUT ready: $!");
    alarm 5;
    $line = <$out_fh>;
    ok(!$line, t." $prog: back3 eof out: $! ".($line || "(eof)"));

    # Test #LineI: p;close STDERR
    # STDERR should still be empty
    alarm 5;
    ok(!canread($err_fh), t." $prog: END: STDERR still empty: $!");
    # STDERR should remain empty for about 1 seconds, but due to strace flaw it might wait until exit ...
    alarm 5;
    SKIP: {
        my $detect_stderr_closed = canread($err_fh,1.2);
        skip t." $prog: END: STDERR ready: ERRNO[$!]: Known FLAW in 'strace' prevents close()ing its STDERR when its process does!", 1 if $prog eq "strace" and !$detect_stderr_closed;
        ok($detect_stderr_closed,t." $prog: END: STDERR ready: $!");
    }
    alarm 5;
    # Patiently wait for its STDERR to close.
    $line = <$err_fh>;
    ok(!$line, t." $prog: back4 eof err: $! ".($line || "(eof)"));

    # Test #LineJ: p;p; (Double PAUSE 2 seconds)
    # Prog should keep running for about 2 more seconds...
    alarm 5;
    # Brief delay in case 'strace' is done and needs another kernel tick to finish exiting.
    select undef,undef,undef, 0.1;
    $? = $! = 0;
    my $died = waitpid(-1, WNOHANG);
    SKIP: {
        skip t." $prog: still running: Known FLAW in 'strace' fails to honor STDERR closing in its process! PID[$pid] WAITPID[$died] CHILD_ERROR[$?] ERRNO[$!]", 6 if $prog eq "strace" and $died > 0 and !$?;

        is($died, 0, t." $prog: PID[$pid] still running any pid: $died $!");
        is($?, -1, t." $prog: did not exit immediately: $?");

        # Should still be running even after a brief pause
        alarm 5;
        select undef,undef,undef, 0.3;
        alarm 5;
        $? = $! = 0;
        $died = waitpid($pid, WNOHANG);
        is($died, 0, t." $prog: PID[$pid] still running target pid: $died $!");
        is($?, -1, t." $prog: did not exit after brief pause: $?");

        # Give plenty of time to complete exit
        alarm 5;
        select undef,undef,undef, 1.9;

        # Test #LineJ: exit
        alarm 5;
        $? = $! = 0;
        $died = waitpid(-1, WNOHANG);
        is($died, $pid, t." $prog: PID[$pid] DONE[$died]");
        is($?, 0, t." $prog: normal exit: $?");
    }

    # Patiently wait for target process to complete w/ Wait-YES-HANG instead of Wait-NO-HANG
    alarm 5;
    $? = $! = 0;
    $died = waitpid($pid, 0);
    is($died, -1, t." $prog: PID[$pid] Already reaped [$died]");
    is($?, -1, t." $prog: already exited: $?");
}
