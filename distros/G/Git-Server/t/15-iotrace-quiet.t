# Before 'make install' is performed this script should be runnable with
# 'make test'

#########################

use strict;
use warnings;
our (@filters, $test_points, $test_option);
use Test::More tests => 1 + (@filters = qw[hooks/iotrace strace]) * ($test_points = 5 * keys %{ $test_option = { none => "", single => "-q", double => "-q -q", bundled => "-qq", triple => "-qqq", "sillyquad" => "-qqqq"} });
use File::Temp ();

my $run = "";
my $line = "";
my $tmp = File::Temp->new( UNLINK => 1, SUFFIX => '.trace' );
ok("$tmp", "tracefile[$tmp]");

SKIP: for my $try (@filters) {
    my $prog = $try =~ /(\w+)$/ && $1;
    skip "no strace", $test_points if $prog eq "strace" and !-x "/usr/bin/strace"; # Skip strace tests if doesn't exist

    # run -q cases to test quiet functionality

    foreach my $label (sort { $test_option->{$a} cmp $test_option->{$b} } keys %$test_option) {
        my $opt = $test_option->{$label};
        $opt = " $opt" if length $opt;
        $run = `$try$opt -s 9000 -o $tmp $^X -e '' 2>&1`;
        is($?, 0, "$prog$opt: Using [$label] quiet flags exited normally: $?");
        ok(!!-s $tmp, "$prog$opt: logged ".(-s $tmp)." bytes to $tmp");
        $tmp->seek(0, 0); # SEEK_SET beginning
        chomp($line = <$tmp>);
        like($line, qr/execve/, "$prog$opt: Launched: $line");
        is($run, "", "$prog$opt: No STDERR spewage");
        $tmp->seek(0, 0);
        $tmp->truncate(0);
        ok(!-s $tmp, "$prog$opt: Log cleared");
    }
}
