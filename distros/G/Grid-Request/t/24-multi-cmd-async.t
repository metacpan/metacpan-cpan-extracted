#!/usr/bin/perl

# Test the behavior of multiple commands when submitted asynchronously.

# $Id: 23-multi-cmd-async.t 10901 2008-05-01 20:21:28Z victor $

use strict;
use File::Basename;
use File::Which;
use FindBin qw($Bin);
use Log::Log4perl qw(:easy);
use lib "$Bin/../lib";
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
my $echo = which("echo");

eval {
    unlink $output1;
    unlink $output2;
};
ok(! -e $output1, "Output file 1 does not exist.");
ok(! -e $output2, "Output file 2 does not exist.");

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
ok(! $@, "No exceptions when job submitted via submit_and_wait().") or
    Grid::Request::Test->diagnose();

is(scalar(@ids), 2, "Correct number of ids from submit().");

if (scalar(@ids) == 2) {
    wait_for_out($output1);
    ok(-f $output1, "Output file from 1st command created.") or
        diag("Might not be visible due to NFS caching issues.");

    wait_for_out($output2);
    ok(-f $output2, "Output file from 2nd command created.") or
        diag("Might not be visible due to NFS caching issues.");

    my $result1 = read_first_line($output1);
    my $result2 = read_first_line($output2);
    is($result1, "command1", "1st command had the correct output.");
    is($result2, "command2", "2nd command had the correct output.");
} else {
    # We have to 'fail' the tests above.
    fail("No job submitted. Can't check output of 1st command.");
    fail("No job submitted. Can't check output of 2nd command.");
    fail("Can't verify 1st command had correct output.");
    fail("Can't verify 2nd command had correct output.");
}

###########################################################################

sub read_first_line {
    my $file = shift;
    my $line;
    eval {
        open (FILE, "<", $file) or die "Could not open $file for reading.";
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
