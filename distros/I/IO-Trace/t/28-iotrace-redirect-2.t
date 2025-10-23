# Before 'make install' is performed this script should be runnable with
# 'make test'

#########################

use strict;
use warnings;
our (@filters, $test_points);
use Test::More tests => 3 + (@filters = qw[none iotrace strace]) * ($test_points = 13);

use File::Which qw(which);
use File::Temp ();
use IO::Handle;

# Test behavior when redirecting STDOUT to a file. (Run 2 seconds)
my $test_prog = q{
    $|=1;                                    #LineA
    while (<STDIN>) {s/o//; print}           #LineB  # (Remove o's)
    close STDOUT;warn "Done\n";              #LineC
    sleep 1;close STDERR;                    #LineD
    sleep 1;exit 0;                          #LineE
};

eval { require Time::HiRes; };
sub t { defined(\&Time::HiRes::time) ? sprintf("%10.6f",Time::HiRes::time()) : time() }

my $pid = 0;
$SIG{ALRM} = sub { require Carp; $pid and Carp::cluck("TIMEOUT ALARM TRIGGERED! Aborting execution PID=[$pid]") and kill TERM => $pid and sleep 1 and kill KILL => $pid; };
alarm 5;
my $line = "";
my $tmp = File::Temp->new( UNLINK => 1, SUFFIX => '.trace' );
ok("$tmp", t." tracefile[$tmp]");
my $redirect_out = File::Temp->new( UNLINK => 1, SUFFIX => '.out' );
ok("$redirect_out", t." redirect_out[$redirect_out]");
my $redirect_err = File::Temp->new( UNLINK => 1, SUFFIX => '.err' );
ok("$redirect_err", t." redirect_err[$redirect_err]");

SKIP: for my $prog (@filters) {
    my $try = $prog ne "none" ? which $prog : "n/a";
    skip "no strace", $test_points if $prog eq "strace" and !$try; # Skip strace tests if doesn't exist
    ok($try, t." $prog: Full path [$try]");

    # run case where STDOUT is redirected to a file

    my @run = ($^X, "-e", $test_prog);
    # Ensure behavior of $test_prog is the same with or without tracing it.
    unshift @run, $try, -tt => -s9000 => -o => "$tmp" if $prog ne "none";

    ok((my $fh = IO::Handle->new), t." $prog: Input handle");
    $pid = open $fh, "|-";
    if (!$pid) {
        # Child process runs the test
        open STDOUT, ">", "$redirect_out";
        open STDERR, ">", "$redirect_err";
        exec @run or die "exec failure: $!";
    }
    ok($pid, t." $prog: Spawn process PID=[$pid]");

    alarm 5;
    select(undef,undef,undef,0.2);
    ok(!-s $redirect_out, t." $prog: Out file wiped by child: ".-s _);
    ok(!-s $redirect_err, t." $prog: Err file wiped by child: ".-s _);

    # Test #LineB: <STDIN>
    alarm 5;
    $fh->autoflush(1);
    print $fh "one\n";
    print $fh "two\n";
    alarm 5;
    select undef,undef,undef, 2.2;

    # Test #LineC: close OUT
    # Test #LineD: close ERR
    # Test #LineE: p;exit
    alarm 5;
    $!=0;
    ok(close($fh), t." $prog: close process handle to clear zombie");
    ok(!$!, t." $prog: no Errno: $!");
    ok(!$?, t." $prog: clean exit: $?");

    alarm 5;
    $redirect_out->seek(0, 0);
    chomp($line = <$redirect_out>);
    is($line, "ne", t." $prog: One: $line");
    alarm 5;
    chomp($line = <$redirect_out>);
    is($line, "tw", t." $prog: Two: $line");
    ok(-s $redirect_out, t." $prog: Out file populated: ".-s _);

    alarm 5;
    $redirect_err->seek(0, 0);
    chomp($line = <$redirect_err>);
    like($line, qr/one/, t." $prog: Three: $line");
    ok(-s $redirect_err, t." $prog: Err file populated: ".-s _);
}
