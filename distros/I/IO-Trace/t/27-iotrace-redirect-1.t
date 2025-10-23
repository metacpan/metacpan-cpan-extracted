# Before 'make install' is performed this script should be runnable with
# 'make test'

#########################

use strict;
use warnings;
our (@filters, $test_points);
use Test::More tests => 2 + (@filters = qw[none iotrace strace]) * ($test_points = 10);

use File::Which qw(which);
use File::Temp ();
use IO::Handle;

# Test behavior when redirecting STDOUT to a file. (Run 1 seconds)
my $test_prog = q{
    $|=1;                                    #LineA
    while (<STDIN>) {s/o//; print}           #LineB  # (Remove o's)
    sleep 1;exit 0;                          #LineC
};

eval { require Time::HiRes; };
sub t { defined(\&Time::HiRes::time) ? sprintf("%10.6f",Time::HiRes::time()) : time() }

my $pid = 0;
$SIG{ALRM} = sub { require Carp; $pid and Carp::cluck("TIMEOUT ALARM TRIGGERED! Aborting execution PID=[$pid]") and kill TERM => $pid and sleep 1 and kill KILL => $pid; };
alarm 5;
my $line = "";
my $tmp = File::Temp->new( UNLINK => 1, SUFFIX => '.trace' );
ok("$tmp", t." tracefile[$tmp]");
my $redirect_file = File::Temp->new( UNLINK => 1, SUFFIX => '.out' );
ok("$redirect_file", t." redirect_out[$redirect_file]");

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
        open STDERR, ">&", STDOUT;
        open STDOUT, ">", "$redirect_file";
        exec @run or die "exec failure: $!";
    }
    ok($pid, t." $prog: Spawn process PID=[$pid]");

    alarm 5;
    select(undef,undef,undef,0.2);
    ok(!-s $redirect_file, t." $prog: Output file wiped by child: ".-s _);

    # Test #LineB: <STDIN>
    alarm 5;
    $fh->autoflush(1);
    print $fh "one\n";
    print $fh "two\n";

    # Test #LineC: exit
    alarm 5;
    $!=0;
    ok(close($fh), t." $prog: close process handle to clear zombie");
    ok(!$!, t." $prog: no Errno: $!");
    ok(!$?, t." $prog: clean exit: $?");

    alarm 5;
    $redirect_file->seek(0, 0);
    chomp($line = <$redirect_file>);
    is($line, "ne", t." $prog: One: $line");
    alarm 5;
    chomp($line = <$redirect_file>);
    is($line, "tw", t." $prog: Two: $line");
    ok(-s $redirect_file, t." $prog: Output file populated: ".-s _);
}
