# Before 'make install' is performed this script should be runnable with
# 'make test'

#########################

use strict;
use warnings;
our (@filters, @test_exits, $test_points);
use Test::More tests => 1 + (@filters = qw[none hooks/iotrace strace]) * ($test_points = 3 * (@test_exits = (0,1,2,7,22,111,255)));
use File::Temp ();

my $run = "";
my $line = "";
my $tmp = File::Temp->new( UNLINK => 1, SUFFIX => '.trace' );
ok("$tmp", "tracefile[$tmp]");

SKIP: for my $try (@filters) {
    my $prog = $try =~ /(\w+)$/ && $1;
    skip "no strace", $test_points if $prog eq "strace" and !-x "/usr/bin/strace"; # Skip strace tests if doesn't exist

    # test if exit status is preserved through the filter

    for my $exit_val (@test_exits) {
        my $test_prog = qq{
           # Silent test program with conjured exit value
           select undef,undef,undef, 0.2;
           exit $exit_val;
        };
        my @run = ($^X, "-e", $test_prog);
        # Ensure behavior of $test_prog is the same with or without tracing it.
        unshift @run, $try, -e => "execve,clone,openat,close,read,write", -o => "$tmp" if $prog ne "none";

        my $ret = system @run;
        my $real_exit_val = $? >> 8;
        is($exit_val,$real_exit_val, "$prog $exit_val: match exit $real_exit_val");

        SKIP: {
            skip "$prog: no tracer log file", 2 if $prog eq "none";
            $tmp->seek(0, 0); # SEEK_SET beginning
            chomp ($line = join "", <$tmp>);
            $line =~ s/\s+/ /g;
            like($line, qr/\++\s*exited with $exit_val\s*\++\s*$/, "$prog $exit_val: logged correct exit: ");

            $tmp->seek(0, 0);
            $tmp->truncate(0);
            ok(!-s $tmp, "$prog $exit_val: log cleared");
        }
    }
}
