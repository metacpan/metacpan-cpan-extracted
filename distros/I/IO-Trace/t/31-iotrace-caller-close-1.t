# Before 'make install' is performed this script should be runnable with
# 'make test'

#########################

use strict;
use warnings;
our (@filters, $test_points);
use Test::More tests => 1 + (@filters = qw[none iotrace strace]) * ($test_points = 31);
use Errno qw(EPIPE);
use File::Temp ();
use POSIX qw(WNOHANG);
use IO::Handle;
use IPC::Open3 qw(open3);

# Test caller close STDOUT (fd 1) behavior (Run 6 seconds)
my $test_prog = q{
    $|=1;$SIG{PIPE}=sub{warn"PIPED!$!\n"};   #LineA
    sub p{sleep 1;$!=0}                      #LineB
    sub r{$_=<STDIN>//"(undef)";chomp;$_}    #LineC
    r;                                       #LineD
    p;print "OUT-ONE:$_\n";                  #LineE
    p;print "OUT-TWO:$_\n";   $a=0+$!;$!=0;  #LineF
    p;print "OUT-THREE:$_\n"; $b=0+$!;$!=0;  #LineG
    p;close STDOUT;        my $c=0+$!;$!=0;  #LineH
    p;warn  "ERR-FOUR:$_ <$a><$b><$c>\n";    #LineI
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
$SIG{ALRM} = sub { require Carp; $pid and Carp::cluck("TIMEOUT ALARM TRIGGERED! Aborting execution PID=[$pid]") and kill TERM => $pid and sleep 1 and kill KILL => $pid; };
alarm 5;
my $tmp = File::Temp->new( UNLINK => 1, SUFFIX => '.trace' );
ok("$tmp", t." tracefile[$tmp]");

SKIP: for my $try (@filters) {
    my $prog = $try =~ /(\w+)$/ && $1;
    skip "no strace", $test_points if $prog eq "strace" and !-x "/usr/bin/strace"; # Skip strace tests if doesn't exist

    # run cases where STDOUT is closed by the caller first

    my @run = ($^X, "-e", $test_prog);
    # Ensure behavior of $test_prog is the same with or without tracing it.
    unshift @run, $try, -e => "execve,clone,openat,close,read,write", -o => "$tmp" if $prog ne "none";

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
    ok(!canread($err_fh), t." $prog: TOP: STDERR is empty so far: $!");

    # Test #LineD: <STDIN>
    alarm 5;
    ok((print $in_fh "uno!\n"),t." $prog: line1");

    # Test #LineE: p (PAUSE for a second); ONE
    # STDOUT should be empty for about a second waiting for the target to spawn up and read and sleep and echo back
    alarm 5;
    ok(!canread($out_fh),    t." $prog: PRE: STDOUT is still empty: $!");
    ok(canread($out_fh,2.7), t." $prog: PRE: STDOUT ready: $!");
    alarm 5;
    chomp($line = <$out_fh>);
    ok($line, t." $prog: back1: $line");

    # Test #LineF: p (PAUSE); TWO
    alarm 5;
    # Message should be ignored and lost:
    ok((print $in_fh "dos!\n"),t." $prog: line2: $!");
    ok(!canread($out_fh),      t." $prog: MID: STDOUT is empty: $!");
    ok(canread($out_fh,1.3),   t." $prog: MID: STDOUT woke: $!");

    # STDOUT knocked on the door, trying to shove "TWO" to me, but slam the door closed without taking it.
    ok(close($out_fh), t." $prog: explicitly close STDOUT: $!");

    # Test #LineG: p; THREE
    # Hopefully gets PIPE slapped for attempting THREE to my close()'d STDOUT.
    # If so, it should crash a message to its STDERR.
    alarm 5;
    ok(!canread($err_fh),    t." $prog: MID: STDERR is still empty: $!");
    ok(canread($err_fh,1.3), t." $prog: MID: STDERR woke: $!");
    chomp($line = <$err_fh>);
    ok($line, t." $prog: back3: $line");
    like($line, qr/PIPE/,    t." $prog: MID: STDOUT pipe slapped: $! $line");
    unlike($line, qr/dos/,   t." $prog: MID: STDIN no leaky pipe");

    # Test #LineH: p; close STDOUT
    # Test #LineI: p; FOUR
    alarm 5;
    ok(!canread($err_fh),    t." $prog: Waiting for Errno reports: $!");
    ok(canread($err_fh,2.8), t." $prog: END: STDERR woke: $!");
    chomp($line = <$err_fh>);
    ok($line, t." $prog: back4: $line");

    ok($line=~s/<(\d+)>//, t." $prog: TWO: [$line] Errno=$1");
    $!=$1;
    ok(!$!,                t." $prog: TWO: No error: $!");

    ok($line=~s/<(\d+)>//, t." $prog: THREE: [$line] Errno=$1");
    $!=$1;
    is(0+$!, EPIPE,        t." $prog: THREE: Got EPIPE: $!");

    ok($line=~s/<(\d+)>//, t." $prog: close: [$line] Errno=$1");
    $!=$1;
    SKIP: {
        skip t." $prog: END: crusty kernel pipe stream broken close detection not supported yet", 1 if !$!;
        is(0+$!, EPIPE,    t." $prog: close with broken buffer got EPIPE: $!");
    }

    # Test #LineJ: p;
    # Prog should exit in under 1 seconds...
    alarm 5;
    $? = $! = 0;
    my $died = waitpid(-1, WNOHANG);
    is($died, 0, t." $prog: PID[$pid] still running: $died $!");
    is($?, -1, t." $prog: did not exit: $?");
    ok(canread($err_fh,1.3), t." $prog: END: implicit close STDERR: $!");
    # Give plenty of time to complete exit
    select undef,undef,undef, 0.1;

    # Test #LineJ: exit 0
    alarm 5;
    $? = $! = 0;
    $died = waitpid(-1, WNOHANG);
    is($died, $pid, t." $prog: PID[$pid] DONE[$died]");
    is($?, 0, t." $prog: normal exit: $?");
}
