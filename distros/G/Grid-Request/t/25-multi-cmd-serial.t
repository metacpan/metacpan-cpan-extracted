#!/usr/bin/perl

# Test the behavior of multiple commands when submitted serially.

# $Id: 24-multi-cmd-serial.t 10901 2008-05-01 20:21:28Z victor $

use strict;
use File::Basename;
use File::Which;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Log::Log4perl qw(:easy);
use Test::More;
use Grid::Request;
use Grid::Request::Test;

Log::Log4perl->init("$Bin/testlogger.conf");

my $req = Grid::Request::Test->get_test_request();
my $tempdir = $req->_config()->val($Grid::Request::HTC::config_section, "tempdir");

if (! defined $tempdir || ! -d $tempdir) {
    plan skip_all => 'tempdir not configured or not a directory.';
} else {
    plan tests => 8;
}

my $base = basename($0);

my $outdir = $tempdir;
my $output1 = $outdir . "/${base}.1.out";
my $output2 = $outdir . "/${base}.2.out";

cleanup();
ok(! -e $output1, "Output file 1 does not exist.");
ok(! -e $output2, "Output file 2 does not exist.");

my $echo = which("echo");

$req->command($echo);
$req->add_param("command1");
$req->output($output1);

$req->new_command();

$req->command($echo);
$req->add_param("command2");
$req->output($output2);

my @ids;
eval {
    @ids = $req->submit_and_wait();
};
ok(! $@, "No exception when submitting job via submit_and_wait().") or
    Grid::Request::Test->diagnose();

is(scalar(@ids), 2, "Correct number of ids from submit().");

if (scalar(@ids) == 2) {
    wait_for_out($output1);
    ok(-e $output1, "Output file 1 created.") or
       diag("Might not be visible due to NFS caching issues.");

    wait_for_out($output2);
    ok(-e $output2, "Output file 2 created.") or
       diag("Might not be visible due to NFS caching issues.");

    my $line1 = read_first_line($output1);
    is($line1, "command1", "1st command had the correct output.");
    my $line2 = read_first_line($output2);
    is($line2, "command2", "2nd command had the correct output.");
} else {
    # We have to 'fail' the tests that would have run above.
    fail("Can't check output of 1st command. No job run.");
    fail("Can't check output of 2nd command. No job run.");
}

cleanup();

#############################################################################

sub cleanup {
    eval {
        unlink $output1;
        unlink $output2;
    };
}

sub read_first_line {
    my $file = shift;
    my $line;
    eval {
        open (FILE, "<", $file) or die "Couldn't open $file for reading.";
        $line = <FILE>;
        close FILE;
    };
    chomp($line) if defined($line);
    return $line;
}

sub wait_for_out {
    my $output = shift;
    my $n=1;
    while (($n < 10 ) && (! -e $output)) {
        last if (-e $output);
        sleep $n*6;
        $n++;
    }
}
