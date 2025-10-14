# Before 'make install' is performed this script should be runnable with
# 'make test'

#########################

use strict;
use warnings;
our (@filters, $test_points);
use Test::More tests => 1 + (@filters = qw[hooks/iotrace strace]) * ($test_points = 13);
use File::Temp ();

my $run = "";
my $line = "";
my $tmp = File::Temp->new( UNLINK => 1, SUFFIX => '.trace' );
ok("$tmp", "tracefile[$tmp]");

SKIP: for my $try (@filters) {
    my $prog = $try =~ /(\w+)$/ && $1;
    skip "no strace", $test_points if $prog eq "strace" and !-x "/usr/bin/strace"; # Skip strace tests if doesn't exist

    # run simple cases and test option: -o <output_log>

    ($run = `$try 2>&1`) =~ s/\n+/ /g;
    ok (!!$?, "$prog: Args required: $run");

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
