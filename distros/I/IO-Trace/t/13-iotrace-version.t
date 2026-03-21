# Before 'make install' is performed this script should be runnable with
# 'make test'

#########################

use strict;
use warnings;
our (@filters, @test_exits, $test_points);
use Test::More tests => 1 + (@filters = qw[iotrace strace]) * ($test_points = 4);
use File::Temp ();

my $run = "";
my $tmp = File::Temp->new( UNLINK => 1, SUFFIX => '.err' );
ok("$tmp", "tracefile[$tmp]");

SKIP: for my $try (@filters) {
    my $prog = $try =~ /(\w+)$/ && $1;
    skip "no strace", $test_points if $prog eq "strace" and !-x "/usr/bin/strace"; # Skip strace tests if doesn't exist

    # test if version shows

    ($run = `$try -V 2>$tmp`) =~ s/\n+/ /g; # -V means Show version to STDOUT
    ok (!-s $tmp, "prog: No STDERR: $tmp");
    like($run, qr/ version \d/, "$prog: Good Version Format: $run");
    ok (!$?, "$prog: Version clean exit: $?");
    ok (!$!, "$prog: No Errno: $!");
}
