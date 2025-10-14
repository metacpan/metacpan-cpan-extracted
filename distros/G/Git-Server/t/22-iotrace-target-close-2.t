# Before 'make install' is performed this script should be runnable with
# 'make test'

#########################

use strict;
use warnings;
our (@filters, $test_points);
use Test::More tests => 1 + (@filters = qw[none hooks/iotrace strace]) * ($test_points = 23);
use File::Temp ();
use POSIX qw(WNOHANG);
use IO::Handle;
use IPC::Open3 qw(open3);

# Test target close STDERR (fd 2) behavior (Run 6 seconds)
my $test_prog = q{
    $|=1;                                    #LineA
    sub p{sleep 1}                           #LineB
    sub r{$_=<STDIN>//"(undef)";chomp;$_}    #LineC
    p;r;                                     #LineD
    p;warn "ERR-ONE:$_\n";                   #LineE
    p;close STDERR;                          #LineF
    p;print "OUT-TWO:$_\n";                  #LineG
    p;warn "ERR-THREE:$_\n";                 #LineH
    p;exit 0;                                #LineI
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

    # run cases where STDERR is closed by the target first

    my @run = ($^X, "-e", $test_prog);
    # Ensure behavior of $test_prog is the same with or without tracing it.
    unshift @run, $try, -qqqq => -tt => -e => "execve,clone,openat,close,read,write", -o => "$tmp" if $prog ne "none";

    alarm 5;
    my $line;
    # open3 needs real handles, at least for STDERR
    my $in_fh  = IO::Handle->new;
    my $out_fh = IO::Handle->new;
    my $err_fh = IO::Handle->new;
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
    # STDERR should still be empty
    alarm 5;
    ok(!canread($err_fh), t." $prog: PRE: STDERR is still empty: $!");

    # Test #LineE: ONE
    alarm 5;
    ok(canread($err_fh,2.8), t." $prog: PRE: STDERR ready: $!");
    alarm 5;
    chomp($line = <$err_fh>);
    ok($line, t." $prog: back1: $line");
    like($line, qr/uno/, t." $prog: MID: STDIN perfect read");

    # Test #LineF: p (PAUSE); close STDERR
    # STDERR should still be empty
    alarm 5;
    ok(!canread($err_fh), t." $prog: MID: STDERR is still empty: $!");
    # STDERR should remain empty for about 1 seconds ...
    alarm 5;
    SKIP: {
        my $detect_stderr_closed = canread($err_fh,1.2);
        skip t." $prog: FLAW in 'strace' prevents close()ing its STDERR even when its process does! This behavior is not necessary with '-qqq' and '-o <file>' since nothing can ever spew out of its STDERR, but 'strace' is probably lazy to bother handling this case and/or would rather keep STDERR open to prepare in case an unknown exception might occur in the future.", 1 if $prog eq "strace" and !$detect_stderr_closed;
        ok($detect_stderr_closed,t." $prog: MID: STDERR ready: $!");
    }

    # Test #LineG: p;TWO
    alarm 5;
    ok(!canread($out_fh), t." $prog: MID: STDOUT is still empty: $!");
    alarm 5;
    ok(canread($out_fh,1.2),t." $prog: MID: STDOUT ready: $!");
    alarm 5;
    chomp($line = <$out_fh>);
    ok($line, t." $prog: back2: $line");
    like($line, qr{TWO.*uno}, t." $prog: END: STDOUT done");
    # STDOUT buffer should be clean by now
    alarm 5;
    ok(!canread($out_fh), t." $prog: END: STDOUT is empty: $!");

    # Test #LineH: p; warn THREE
    # Test #LineI: p; exit 0
    alarm 5;
    my $died = waitpid(-1, WNOHANG);
    ok($died<=0, t." $prog: PID[$pid] still running: $died");
    # STDOUT should implicitly close in under 2 seconds when prog exits
    ok(canread($out_fh,2.2), t." $prog: END: STDOUT woke: $!");
    # Printing to the closed handle hopefully will NOT actually send anything
    chomp($line = <$err_fh> // "(eof)");
    like($line, qr/eof/, t." $prog: back2 STDERR done: $! $line");
    unlike($line, qr/THREE/, t." $prog: back2 no leaks for STDERR");
    # Give plenty of time to complete exit
    select undef,undef,undef, 0.1;

    alarm 5;
    $died = waitpid(-1, WNOHANG);
    is($died, $pid, t." $prog: PID[$pid] DONE[$died]");
    is($?, 0, t." $prog: normal exit: $?");

    $tmp->seek(0,0);
    my $explicit_close = "";
    while (<$tmp>) {
        $explicit_close .= " [$1]" if /(.*\bclose\(1\).*)/;
    }
    ok(!$explicit_close, t." $prog: END: STDOUT implicitly closed:$explicit_close");
}
