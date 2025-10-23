# Before 'make install' is performed this script should be runnable with
# 'make test'

#########################

use strict;
use warnings;
our (@filters, @sigs, $test_points);
# Special signals sent directly by the kernel do not need to be manually forwarded to the target process: SEGV CHLD XCPU
use Test::More tests => 2 + (@filters = qw[none iotrace strace]) * (1 + (@sigs = qw[TERM INT IO USR1 USR2 HUP INFO ALRM FPE WINCH PWR]) * ($test_points = 17));

use File::Which qw(which);
use File::Temp ();
use POSIX qw(WNOHANG);
use IO::Handle;
use IPC::Open3 qw(open3);
use Config qw(%Config);

# Test behavior when target receives signals (Run 3 seconds).
my $test_prog = q{
    $|=1;                                    #LineA
    sub p{sleep 1}                           #LineB
    sub r{$_=<STDIN>//"(undef)";chomp;$_}    #LineC
    my $s=r;                                 #LineD
    print "NotReady[SIG$s]<$$>\n";           #LineE
    p;$SIG{$s}=sub{print"GOT[SIG$s]\n"};     #LineF
    print "NowReady[SIG$s]\n";               #LineG
    p;p;                                     #LineH
    exit 0;                                  #LineI
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

my $system_sig = do {
    my @all_sigs = split / /, $Config{sig_name};
    my %sig_hash = ();
    foreach (my $i = 0; $i < @all_sigs; $i++) {
        $sig_hash{$all_sigs[$i]} = $i;
    };
    \%sig_hash;
};
ok(keys(%$system_sig), t." Found (".keys(%$system_sig).") valid system signals");

# Log which SIG cause the script to exit when no explicit handler is defined.
my $fatal_sig = {};

SKIP: for my $prog (@filters) {
    my $try = $prog ne "none" ? which $prog : "n/a";
    skip "no strace", 1 + (@sigs * $test_points) if $prog eq "strace" and !$try; # Skip strace tests if doesn't exist
    ok($try, t." $prog: Full path [$try]");

    my @run = ($^X, "-e", $test_prog);
    # Ensure behavior of $test_prog is the same with or without tracing it.
    unshift @run, $try, -e => "execve,clone,openat,close,read,write", -o => "$tmp" if $prog ne "none";

    # Detect fatal signals
    foreach my $sig (@sigs) { SKIP: {
        skip t." $prog: SIG$sig not valid on system", $test_points if !exists $system_sig->{$sig};
        ok(exists $system_sig->{$sig}, t." $prog: SIG$sig: system signal num $system_sig->{$sig}");

        alarm 5;
        my $line;
        # open3 needs real handles, at least for STDERR
        my $in_fh  = IO::Handle->new;
        my $out_fh = IO::Handle->new;
        my $err_fh = IO::Handle->new;
        $! = 0; # Reset errno
        $pid = open3($in_fh, $out_fh, $err_fh, @run) or die "open3: FAILED! $!\n";
        ok($pid, t." $prog: SIG$sig: spawned [pid=$pid] $!");

        # If @run started properly, then its I/O should be writeable but not readable yet
        alarm 5;
        # Test #LineD: <STDIN>
        ok(canwrite($in_fh),  t." $prog: SIG$sig: TOP: STDIN is writeable: $!");
        ok(!canread($out_fh), t." $prog: SIG$sig: TOP: STDOUT is empty so far: $!");
        ok(!canread($err_fh), t." $prog: SIG$sig: TOP: STDERR is empty so far: $!");
        alarm 5;
        ok((print $in_fh "$sig\n"),t." $prog: SIG$sig: line1");
        ok(close($in_fh),  t." $prog: SIG$sig: TOP: close STDIN: $!");

        # Test #LineE: NotReady
        alarm 5;
        chomp($line = <$out_fh>);
        ok($line, t." $prog: SIG$sig: back1: $line");
        ok($line =~ /NotReady.*<(\d+)>/, t." $prog: SIG$sig: TOP: Received signal prediction: $line");
        my $grandkid = $1 || $pid;
        like($line, qr/NotReady/, t." $prog: SIG$sig: TOP: Waiting to enable handler PID=[$grandkid]");

        # Test #LineF: p (PAUSE for a second); %SIG catcher
        # Test if this is its default SIG handler is fatal by quickly sending it before its Signal Handler Catcher is installed (in about one second from now).
        ok(kill($sig => $pid), t." $prog: SIG$sig: TOP: Fatal Tester Signal Sent");

        # Test #LineG: NowReady
        alarm 5;
        ok(canread($out_fh, 3.9), t." $prog: SIG$sig: PRE: STDOUT ready: $!");
        alarm 5;
        # Only flag $prog "none" SIG fatal behavior
        defined($line = <$out_fh>) or $prog ne "none" or $fatal_sig->{$sig} = $system_sig->{$sig};
        ok(($line || $fatal_sig->{$sig}), t." $prog: SIG$sig: MID: Detected DEFAULT signal behavior: ".($fatal_sig->{$sig} ? "Fatal" : "Proceed"));

        # Test #LineH: p;p
        # Test #LineI: exit
        alarm 5;
        my $died = waitpid($pid, 0);
        is($died, $pid, t." $prog: SIG$sig: END: PID[$pid] DONE[$died] STATUS[$?]");
        my $exited = $? >> 8;
        ok(!$exited, t." $prog: SIG$sig: END: Clean exit status[$exited]");
        my $signal = $? & 0xff;
        is($signal, ($fatal_sig->{$sig} || 0), t." $prog: SIG$sig: END: Exit with expected signal result[$signal]");

        alarm 5;
        # Make sure grandkid is dead too
        ok((!kill(0 => $grandkid) or !sleep 1 or
            !kill(0 => $grandkid) or !sleep 1 or
            !kill(0 => $grandkid) or !sleep 1 or
            !kill(0 => $grandkid) or !sleep 1 or
            !kill(0 => $grandkid)), t." $prog: SIG$sig: END: GrandKid[$grandkid] DONE too");
        alarm 5;
    } }
}
