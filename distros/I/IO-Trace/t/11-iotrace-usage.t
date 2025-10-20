# Before 'make install' is performed this script should be runnable with
# 'make test'

#########################

use strict;
use warnings;
our (@filters, $test_points);
use Test::More tests => 1 + (@filters = qw[iotrace strace]) * ($test_points = 18);
use File::Temp ();
use File::Which qw(which);

my $run = "";
my $line = "";
my $tmp = File::Temp->new( UNLINK => 1, SUFFIX => '.trace' );
ok("$tmp", "tracefile[$tmp]");

SKIP: for my $prog (@filters) {
    my $try = which $prog;
    skip "no strace", $test_points if $prog eq "strace" and !$try; # Skip strace tests if doesn't exist
    ok($try, "$prog: Full path [$try]");

    # run simple cases and test options: -h and -o <output_log>

    ($run = `$try 2>&1`) =~ s/\n+/ /g; # No args spews to STDERR
    $run =~ s/^(.{1,40}).*/$1/;
    ok (!!$?, "$prog: Args required: $run"); # No args is error
    ok (!$!, "$prog: No Errno: $!");

    ($run = `$try -h`) =~ s/\n+/ /g; # view help is not error
    $run =~ s/^(.{1,40}).*/$1/;
    ok ($run, "$prog: Help screen: $run"); # Help screen to STDOUT
    ok (!$?, "$prog: Help no error: $?"); # Help shouldn't error
    ok (!$!, "$prog: Help screen: $!");

    $run = `$try /BoGuS-CommAnd 2>&1`;
    chomp $run;
    ok (!!$?, "$prog: Spawn missing FULL: $run");

    $run = `$try NoSuch-ComMand 2>&1`;
    chomp $run;
    ok (!!$?, "$prog: Spawn missing PATH: $run");

    $run = `$try true 2>&1`;
    ok (!$?, "$prog: Runs true");
    like($run, qr/exited with 0/, "$prog: true case to stderr");

    $run = `$try false 2>&1`;
    ok (!!$?, "$prog: Runs false");
    like($run, qr/exited with [1-9]/, "$prog: false case to stderr");

    # test option: -o <file>
    $run = `$try -o $tmp true 2>&1`;
    ok (!$?, "$prog: Runs true with -o");
    $tmp->seek(0, 0); # SEEK_SET beginning
    chomp ($line = join "", <$tmp>);
    like($line, qr/exited with 0/, "$prog: true case with -o");
    $tmp->seek(0, 0);
    $tmp->truncate(0);
    ok(!-s $tmp, "$prog: true case using -o log cleared");

    $run = `$try -o $tmp false 2>&1`;
    ok (!!$?, "$prog: Runs false with -o");
    chomp ($line = join "", <$tmp>);
    like($line, qr/exited with [1-9]/, "$prog: false case with -o");
    $tmp->seek(0, 0);
    $tmp->truncate(0);
    ok(!-s $tmp, "$prog: false case using -o log cleared");
}
