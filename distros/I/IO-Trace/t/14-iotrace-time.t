# Before 'make install' is performed this script should be runnable with
# 'make test'

#########################

use strict;
use warnings;
our (@filters, $test_points);
use Test::More tests => 1 + (@filters = qw[iotrace strace]) * ($test_points = 9);
use File::Temp ();

my $run = "";
my $line = "";
my $tmp = File::Temp->new( UNLINK => 1, SUFFIX => '.trace' );
ok("$tmp", "tracefile[$tmp]");

SKIP: for my $try (@filters) {
    my $prog = $try =~ /(\w+)$/ && $1;
    skip "no strace", $test_points if $prog eq "strace" and !-x "/usr/bin/strace"; # Skip strace tests if doesn't exist

    # run -t and -tt cases to test timestamps formats

    $run = `$try -o $tmp $^X -e '' 2>&1`;
    ok(!!-s $tmp, "$prog: $tmp: Default time logged ".(-s $tmp)." bytes");
    $tmp->seek(0, 0); # SEEK_SET beginning
    chomp($line = <$tmp>);
    like($line, qr/^[^\d]/, "$prog: Default no timestamp: $line");
    $tmp->seek(0, 0);
    $tmp->truncate(0);
    ok(!-s $tmp, "$prog: Default time log cleared");

    $run = `$try -t -o $tmp $^X -e '' 2>&1`;
    ok(!!-s $tmp, "$prog: $tmp: Baby time logged ".(-s $tmp)." bytes");
    $tmp->seek(0, 0); # SEEK_SET beginning
    chomp($line = <$tmp>);
    like($line, qr/^\d\d:\d\d:\d\d /, "$prog: Baby timestamp: $line");
    $tmp->seek(0, 0);
    $tmp->truncate(0);
    ok(!-s $tmp, "$prog: Baby time log cleared");

    $run = `$try -tt -o $tmp $^X -e '' 2>&1`;
    ok(!!-s $tmp, "$prog: $tmp: HiRes time logged ".(-s $tmp)." bytes");
    $tmp->seek(0, 0); # SEEK_SET beginning
    chomp($line = <$tmp>);
    like($line, qr/^\d\d:\d\d:\d\d\.\d\d\d\d\d\d /, "$prog: HiRes timestamp: $line");
    $tmp->seek(0, 0);
    $tmp->truncate(0);
    ok(!-s $tmp, "$prog: HiRes time log cleared");
}
