# Before 'make install' is performed this script should be runnable with
# 'make test'

#########################

use strict;
use warnings;
our (@filters, $test_points);
use Test::More tests => 2 + (@filters = qw[iotrace strace]) * ($test_points = 14);
use File::Which qw(which);
use File::Temp ();

my $run = "";
my $line = "";
my $tmp = File::Temp->new( UNLINK => 1, SUFFIX => '.trace' );
ok("$tmp", "tracefile[$tmp]");

my $found_tracer = {};
for my $prog (@filters) { SKIP: {
    # make sure prog is available
    my $tracer = which($prog) or skip "no $prog found", $test_points;
    ok($found_tracer->{$prog} = $tracer, "$prog found: $tracer");

    # run simple cases and test option: -o <output_log>

    ($run = `$tracer 2>&1`) =~ s/\n+/ /g;
    ok(!!$?, "$prog: Args required: $run"); # No args is error
    ok(!$!, "$prog: No Errno: $!");

    $run = `$tracer -h`; # view help is not error
    $run =~ s/\s+/ /g;
    $run =~ s/^(.{1,40}).*/$1/;
    ok(!$?, "$prog: Help screen: $run");

    $run = `$tracer true 2>&1`;
    ok(!$?, "$prog: Runs true");
    like($run, qr/exited with 0/, "$prog: true case to stderr");

    $run = `$tracer false 2>&1`;
    ok(!!$?, "$prog: Runs false");
    like($run, qr/exited with [1-9]/, "$prog: false case to stderr");

    # test option: -o <file>
    $run = `$tracer -o $tmp true 2>&1`;
    ok(!$?, "$prog: Runs true with -o");
    $tmp->seek(0, 0); # SEEK_SET beginning
    chomp ($line = join "", <$tmp>);
    like($line, qr/exited with 0/, "$prog: true case with -o");
    $tmp->seek(0, 0);
    $tmp->truncate(0);
    ok(!-s $tmp, "$prog: true case using -o log cleared");

    $run = `$tracer -o $tmp false 2>&1`;
    ok (!!$?, "$prog: Runs false with -o");
    chomp ($line = join "", <$tmp>);
    like($line, qr/exited with [1-9]/, "$prog: false case with -o");
    $tmp->seek(0, 0);
    $tmp->truncate(0);
    ok(!-s $tmp, "$prog: false case using -o log cleared");
}}
my $many = keys %$found_tracer;
ok($many, "Found $many tracer(s): (".join("), (", map {"$_=>$found_tracer->{$_}"} sort keys %$found_tracer).")");
