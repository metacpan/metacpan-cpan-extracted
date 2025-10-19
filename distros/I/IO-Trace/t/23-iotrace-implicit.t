# Before 'make install' is performed this script should be runnable with
# 'make test'

#########################

use strict;
use warnings;
our (@filters, $test_points);
use Test::More tests => 1 + (@filters = qw[none iotrace strace]) * ($test_points = 28);
use File::Temp ();
use POSIX qw(WNOHANG);
use IO::Handle;
use IPC::Open3 qw(open3);

# Test implicit close of STDOUT and STDERR upon exit (Run 3 seconds)
my $test_prog = q{
    $|=1;                                    #LineA
    sub p{sleep 1}                           #LineB
    sub r{$_=<STDIN>//"(undef)";chomp;$_}    #LineC
    r;                                       #LineD
    p;print "OUT-ONE:$_\n";                  #LineE
    p;r;warn "ERR-TWO:$_\n";                 #LineF
    p;exit 0;                                #LineG
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

    # run case where STDOUT and STDERR are implicitly closed when the target exits.

    my @run = ($^X, "-e", $test_prog);
    # Ensure behavior of $test_prog is the same with or without tracing it.
    unshift @run, $try, -tt => -e => "execve,clone,openat,close,read,write", -o => "$tmp" if $prog ne "none";

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
    $in_fh->autoflush(1);
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
    like($line, qr/uno/, t." $prog: PRE: STDOUT perfect read");

    # Test #LineF: p;<STDIN>;TWO
    alarm 5;
    ok((print $in_fh "dos!\n"),t." $prog: line2");
    # STDERR should still be empty for about a second
    ok(!canread($err_fh), t." $prog: MID: STDERR is still empty: $!");
    alarm 5;
    ok(canread($err_fh,1.8), t." $prog: MID: STDERR woke: $!");
    alarm 5;
    chomp($line = <$err_fh>);
    ok($line, t." $prog: back2: $line");
    like($line, qr/dos/, t." $prog: MID: STDERR perfect read");
    $! = 0;
    ok(close($in_fh),  t." $prog: ENDL explicit close STDIN: $!");
    ok(!$!, t." $prog: END: close STDIN No Errno: $!");

    # Test #LineG: p;exit
    # STDOUT and STDERR should still be empty for about a second waiting for prog to exit
    alarm 5;
    my $died = waitpid(-1, WNOHANG);
    ok($died<=0, t." $prog: PID[$pid] still running: $died");
    ok(!canread($out_fh), t." $prog: END: STDOUT is still empty: $!");
    ok(!canread($err_fh), t." $prog: END: STDERR is still empty: $!");

    # All prog handles should have been implicitly closed upon exit once $out_fh awakens
    alarm 5;
    ok(canread($out_fh,1.8), t." $prog: END: STDOUT done: $!");
    alarm 5;
    $line = <$out_fh>;
    ok(!$line, t." $prog: END: eof out: $! ".($line || "(eof)"));
    # prog should not be able to detect caller explicitly closing STDOUT:
    ok(close($out_fh),  t." $prog: END: close STDOUT fine: $!");

    alarm 5;
    ok(canread($err_fh,0.3), t." $prog: END: STDERR done: $!");
    alarm 5;
    $line = <$err_fh>;
    ok(!$line, t." $prog: END: eof err: $! ".($line || "(eof)"));
    # prog should not be able to detect caller explicitly closing STDOUT:
    ok(close($err_fh),  t." $prog: END: close STDERR fine: $!");

    # Should be exited by now
    alarm 5;
    $died = waitpid($pid, 0);
    is($died, $pid, t." $prog: PID[$pid] DONE[$died]");
    is($?, 0, t." $prog: normal exit: $?");

    $tmp->seek(0,0);
    my $explicit_close = "";
    while (<$tmp>) {
        $explicit_close .= " [$1]" if /(.*\bclose\([12]\).*)/;
    }
    ok(!$explicit_close, t." $prog: END: STDOUT and STDERR implicitly closed:$explicit_close");
}
