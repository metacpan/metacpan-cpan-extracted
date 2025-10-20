# Before 'make install' is performed this script should be runnable with
# 'make test'

#########################

use strict;
use warnings;
our (@filters, $test_points);
use Test::More tests => 1 + (@filters = qw[none iotrace strace]) * ($test_points = 49);
use Errno qw(EPIPE);
use File::Temp ();
use POSIX qw(WNOHANG);
use IO::Handle;
use IPC::Open3 qw(open3);

# Test if target will fork into background before closing all handles (Run 6 seconds)
my $test_prog = q{
    $|=1;                                    #LineA
    sub p{sleep 1}                           #LineB
    sub r{$_=<STDIN>//"(undef)";chomp;$_}    #LineC
    r;                                       #LineD
    p;print "OUT-ONE:$_\n";                  #LineE
    p;exit 0 if fork;                        #LineF
    p;r;close STDIN;                         #LineG
    p;print"OUT-TWO<$$>:$_\n";close STDOUT;  #LineH
    p;warn "ERR-THREE:$_\n";close STDERR;    #LineI
    p;exit 0;                                #LineJ
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
$SIG{ALRM} = sub { require Carp; $pid and Carp::cluck("TIMEOUT ALARM TRIGGERED! Aborting execution PID=[$pid]") and kill TERM => -$pid and sleep 1 and kill KILL => -$pid; };
my $got_piped = 0;
$SIG{PIPE} = sub { $got_piped = 1; };
alarm 5;
my $tmp = File::Temp->new( UNLINK => 1, SUFFIX => '.trace' );
ok("$tmp", t." tracefile[$tmp]");

SKIP: for my $try (@filters) {
    my $prog = $try =~ /(\w+)$/ && $1;
    skip "no strace", $test_points if $prog eq "strace" and !-x "/usr/bin/strace"; # Skip strace tests if doesn't exist

    # run case where target backgrounds first before closing STDIN,STDOUT,STDERR

    my @run = ($^X, "-e", $test_prog);
    # Ensure behavior of $test_prog is the same with or without tracing it.
    unshift @run, $try, -f => -tt => -e => "execve,clone,openat,close,read,write", -o => "$tmp" if $prog ne "none";

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
    # Test #LineD: <STDIN>
    ok(canwrite($in_fh),  t." $prog: TOP: STDIN is writeable: $!");
    ok(!canread($out_fh), t." $prog: TOP: STDOUT is empty so far: $!");
    ok(!canread($err_fh), t." $prog: TOP: STDERR is empty so far: $!");
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

    # Test #LineF: p;exit if fork
    alarm 5;
    # Wait long enough to the process a chance to exit
    select undef,undef,undef, 1.2;

    # Test #LineG: p;<STDIN>;close STDIN;
    # STDOUT and STDERR should both still be empty even though the process exited.
    alarm 5;
    ok(!canread($out_fh), t." $prog: MID: STDOUT backgrounded empty: $!");
    ok(!canread($err_fh), t." $prog: MID: STDERR backgrounded empty: $!");
    alarm 5;
    $! = 0;
    ok(!$!, t." $prog: MID: STDIN No Errno: $!");
    ok((print $in_fh "dos!\n"),t." $prog: line2: $!");
    ok(!canread($in_fh),  t." $prog: STDIN still sleeping: $!");

    # Quickly jam something into its STDIN while it's still open, but this should get lost.
    # Test #LineH: p;TWO;close STDOUT
    # STDOUT should still be empty
    alarm 5;
    ok(!canread($out_fh), t." $prog: MID: STDOUT still sleeping: $!");
    # STDOUT should remain empty for about 2 seconds, including LineG & LineH sleeps...
    alarm 5;
    ok(canread($out_fh,2.6),t." $prog: MID: STDOUT background ready: $!");
    alarm 5;
    chomp($line = <$out_fh>);
    ok($line, t." $prog: back2 out: [$!]: $line");
    like($line, qr/dos/, t." $prog: MID: STDIN and STDOUT perfect read after fork");
    ok($line =~ /<(\d+)>/, t." $prog: MID: Smelled GrandKid=$1");
    my $grandchild = $1;
    like($grandchild, qr/^\d+$/, t." $prog: MID: Extracted Valid GrandChild PID=[$grandchild]") or $grandchild = $pid;
    alarm 5;
    # STDOUT should be closed immediately after /dos/, but just give it a tiny wait to be super safe.
    ok(canread($out_fh, 0.2), t." $prog: MID: STDOUT finished: $!");
    $line = <$out_fh>;
    ok(!$line, t." $prog: back3 eof out: $! ".($line || "(eof)"));
    ok(!$!, t." $prog: clean eof STDOUT: $!");
    ok(close($out_fh), t." $prog: close STDOUT: $!");
    ok(!$!, t." $prog: clean close STDOUT: $!");
    $! = 0;

    # Since STDOUT is closed (#LineH), STDIN should definitely be closed by now (#LineG is the line above).
    # Tickle its STDIN to make sure it slaps back with a SIGPIPE.
    alarm 5;
    ok(canread($in_fh),  t." $prog: STDIN is woked: $!");
    # Haven't touched the woke STDIN yet, so not PIPED yet.
    ok(!$!, t." $prog: MID: STDIN Still No EPIPE: $!");
    ok(!$got_piped, t." $prog: STDIN Still Not PIPED: $got_piped");
    # The PIPE must be broken now that can_read, so writing should fail:
    ok(!(print $in_fh "PIPE CRASH!\n"), t." $prog: line3 tickle: $!");
    is(0+$!, EPIPE, t." $prog: MID: STDIN Got EPIPE: $!");
    ok($got_piped,  t." $prog: Got PIPED: $got_piped");
    $got_piped = 0;
    $! = 0;
    ok(!close($in_fh),  t." $prog: explicit close STDIN should fail after broken write: $!");
    SKIP: {
        skip t." $prog: END: crusty kernel pipe stream broken close detection not supported yet", 1 if !$!;
        is(0+$!, EPIPE, t." $prog: END: close STDIN with broken buffer got EPIPE: $!");
    }
    $! = 0;

    # Test #LineI: p;THREE;close STDERR
    # STDERR should remain empty for about 1 seconds ...
    alarm 5;
    ok(!canread($err_fh), t." $prog: END: STDERR last handle sleeping: $!");
    alarm 5;
    ok(canread($err_fh,1.2),t." $prog: END: STDERR ready: $!");
    alarm 5;
    chomp($line = <$err_fh>);
    ok($line, t." $prog: back4 err: $line");
    like($line, qr/dos/, t." $prog: MID: STDERR perfect read after fork");
    alarm 5;
    SKIP: {
        # STDERR should be closed IMMEDIATELY after saying "dos" since there's no pause, so give plenty of time
        my $detect_stderr_closed = canread($err_fh,0.3);
        skip t." $prog: END: STDERR close detection: $!: FLAW in 'strace' prevents close()ing its STDERR even when its process does!", 1 if $prog eq "strace" and !$detect_stderr_closed;
        ok($detect_stderr_closed,t." $prog: END: STDERR close detection: $!");
    }
    alarm 5;
    $line = <$err_fh>;
    ok(!$line, t." $prog: back5 eof err: $! ".($line || "(eof)"));
    ok(!$!, t." $prog: clean eof STDERR: $!");
    ok(close($err_fh), t." $prog: close STDERR: $!");
    ok(!$!, t." $prog: clean close STDERR: $!");
    $! = 0;

    # Test #LineJ: p;exit
    # $grandchild process should end in about 1 second...
    # Even though the Middle Daddy $pid died way back on #LineF
    alarm 5;
    SKIP: {
        my $detect_grandkid_running = eval {kill 0 => $grandchild};
        skip t." $prog: END: GrandChild $grandchild still running: $!: FLAW in 'strace' prevents close()ing its STDERR even when its process does!", 1 if $prog eq "strace" and !$detect_grandkid_running;
        ok(eval {kill 0 => $grandchild}, t." $prog: END: GrandChild PID[$grandchild] still running");
    }
    alarm 5;
    select undef,undef,undef, 1.3;
    ok(!eval {kill 0 => $grandchild}, t." $prog: END: GrandChild PID[$grandchild] completed");

    # Make sure to clean up Middle Daddy
    alarm 5;
    $? = $! = 0;
    my $died = waitpid(-1, WNOHANG);
    is($died, $pid, t." $prog: PID[$pid] Already DONE[$died] ERRNO[$!]");
    ok(!$!, t." $prog: PID[$pid] No Errno: $!");
    is($?, 0, t." $prog: normal exit: $?");

    # Should already be reaped, but just to be safe, use Wait-YES-HANG instead of Wait-NO-HANG
    alarm 5;
    $? = $! = 0;
    $died = waitpid($pid, 0);
    is($died, -1, t." $prog: PID[$pid] Already reaped [$died]");
    is($?, -1, t." $prog: already exited: $?");
}
