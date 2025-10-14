# Before 'make install' is performed this script should be runnable with
# 'make test'

#########################

use strict;
use warnings;
our (@filters, $test_points);
use Test::More tests => 1 + (@filters = qw[none hooks/iotrace strace]) * ($test_points = 36);
use File::Temp ();
use POSIX qw(WNOHANG);
use IO::Handle;
use IPC::Open3 qw(open3);

# Test behavior when file descriptors are closed.
my $test_prog = q{
    $|=1;                                    #LineA
    sub p{sleep 1}                           #LineB
    sub r{$_=<STDIN>//"(undef)";chomp;$_}    #LineC
    p;r;                                     #LineD
    p;print "OUT-ONE:$_\n";                  #LineE
    p;r;                                     #LineF
    p;warn "ERR-TWO:$_\n";                   #LineG
    p;close STDIN;                           #LineH
    p;r;                                     #LineI
    p;print "OUT-BORK:$_\n";                 #LineJ
    p;close STDOUT;                          #LineK
    p;warn "ERR-BORK:$_\n";                  #LineL
    p;p;                                     #LineM
    exit 0;                                  #LineN
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

    my @run = ($^X, "-e", $test_prog);
    # Ensure behavior of $test_prog is the same with or without tracing it.
    unshift @run, $try, -e => "execve,clone,openat,close,read,write", -o => "$tmp" if $prog ne "none";

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

    # If @run started properly, then its I/O should be writeable and readable
    alarm 5;
    # Test #LineD: p; (PAUSE for a second)
    ok(canwrite($in_fh),  t." $prog: TOP: STDIN is writeable: $!");
    ok(!canread($out_fh), t." $prog: TOP: STDOUT is empty so far: $!");
    ok(!canread($err_fh), t." $prog: TOP: STDERR is empty so far: $!");

    # Test #LineD: <STDIN>
    alarm 5;
    ok((print $in_fh "uno!\n"),t." $prog: line1");

    # Test #LineE: p (PAUSE for a second)
    # STDOUT should still be empty
    alarm 5;
    ok(!canread($out_fh), t." $prog: PRE: STDOUT is still empty: $!");

    # Test #LineE: ONE
    alarm 5;
    ok(canread($out_fh,2.8), t." $prog: PRE: STDOUT ready: $!");
    alarm 5;
    chomp($line = <$out_fh>);
    ok($line, t." $prog: back1: $line");

    # Test #LineF: <STDIN>
    alarm 5;
    ok((print $in_fh "dos!\n"),t." $prog: line2");

    # Test #LineG: p (PAUSE for a second)
    # STDERR should still be empty
    alarm 5;
    ok(!canread($err_fh), t." $prog: PRE: STDERR is still empty: $!");

    # Test #LineG: TWO
    chomp($line = <$err_fh>);
    ok($line, t." $prog: back2: $line");

    # Test #LineH: p
    # If we're quick enough, we should be able to slip a few bytes through before STDIN is closed. The bytes will remain in the kernel buffers briefly but should never actually be read. It will just be lost with the pipe is closed.
    ok(canwrite($in_fh), t." $prog: MID: STDIN is still writeable: $!");
    # Act like packets are written even though should be lost when the pipe is closed.
    ok((print $in_fh "COMPLETELY LOST PACKETS!\n"), t." $prog: line3");
    ok(!$got_piped, t." $prog: STDIN Not PIPED: $got_piped");

    # Test #LineH: close STDIN
    # Test #LineI: <STDIN> [hopefully (undef)]
    # Test #LineJ: STDOUT-BORK
    alarm 5;
    chomp($line = <$out_fh>);
    ok($line, t." $prog: back3 last out: $line");
    # Verify "#LineH" and "#LineI" worked from program side by looking for "(undef)"
    like($line, qr{undef}, t." $prog: its STDIN finished");

    # Test #LineH: close STDIN
    # Since #LineJ already ran, we know #LineH must certainly be done by now.
    alarm 5;
    ok($in_fh->opened, t." $prog: our side thinks STDIN still is open");
    ok(!$got_piped,  t." $prog: STDIN Still Not PIPED: $got_piped");
    # Attempt to write again to its STDIN to make sure it breaks this time.
    $! = 0; # Reset errno
    ok(!(print $in_fh "PIPE CRASH!\n"), t." $prog: line4: $!");
    ok($got_piped,  t." $prog: Got PIPED: $got_piped");
    $got_piped = 0;
    # Nothing left for its STDIN, so close it. Since some of the bytes sent to its STDIN weren't consumed, the close() should fail with "Broken Pipe":
    ok(!close($in_fh),  t." $prog: explicit close STDIN after broken write: $!");
    ok(!$in_fh->opened, t." $prog: STDIN not open anymore");

    # Test #LineK: p (PAUSE for one second)
    # If the STDIN test crashing happened quickly enough
    # Then STDOUT should still be open.
    alarm 5;
    ok(!canread($out_fh), t." $prog: STDOUT buffer empty but still opened: $!");

    # Test #LineK: close STDOUT
    # STDOUT should be slapped closed within 1 second
    alarm 5;
    ok(canread($out_fh, 1.9), t." $prog: EOF STDOUT buffer awoke: $!");

    # Then STDOUT should immediately hit EOF
    alarm 5;
    $line = <$out_fh>;
    ok(!$line, t." $prog: back4 eof out: ".($line || "(eof)"));

    # Nothing left for its STDOUT, so close it.
    alarm 5;
    ok(close($out_fh), t." $prog: close stdout");

    # Test #LineL: STDERR-BORK
    alarm 5;
    chomp($line = <$err_fh>);
    ok($line, t." $prog: back5: $line");
    like($line, qr{undef}, t." $prog: err finished");

    # Test #LineM: p;p; (PAUSE for a couple seconds)
    # Quick probe to make sure prog is still alive
    alarm 5;
    my $died = waitpid(-1, WNOHANG);
    ok($died<=0, t." $prog: PID[$pid] still running: $died");

    # If the PAUSE is working, then STDERR should still be open.
    alarm 5;
    $! = 0;
    ok($err_fh->opened, t." $prog: STDERR is still open: $!");
    ok(!canread($err_fh), t." $prog: STDERR buffer empty: $!");

    # Test #LineN: exit 0
    # EOF ERR: When prog completes, its STDERR should be implicitly closed.
    alarm 5;
    # Block waiting for STDERR to be closed ...
    $line = <$err_fh>;
    ok(!$line, t." $prog: back6 eof err: ".($line || "(eof)"));

    # Nothing left for its STDERR, so close it.
    alarm 5;
    ok(close($err_fh), t." $prog: close stderr");
    # Give up a little bit of time slice back to the kernel to allow enough time send me the SIGCHLD after the child's exit implicitly closed its handles.
    is(select(undef, undef, undef, 0.01), 0, t." $prog: Waited for SIGCHLD");

    # Test #LineN: exit 0
    # Once STDERR is implicitly closed, we know the prog should be done, and exit value should be 0
    alarm 5;
    $died = waitpid(-1, WNOHANG);
    is($died, $pid, t." $prog: PID[$pid] DONE[$died]");
    is($?, 0, t." $prog: normal exit: $?");
}
