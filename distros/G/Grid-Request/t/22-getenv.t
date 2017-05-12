#!/usr/bin/perl

# $Id: 22-getenv.t 10901 2008-05-01 20:21:28Z victor $

# Test if the API supports setting the command to replicate the environment
# with getenv() or not.

use strict;
use FindBin qw($Bin);
use File::Basename;
use lib ("$Bin/../lib");
use Log::Log4perl qw(:easy);
use Test::More tests => 7;
use Grid::Request;
use Grid::Request::Test;

Log::Log4perl->init("$Bin/testlogger.conf");
my $project = Grid::Request::Test->get_test_project();

my $name = basename($0);
my $output = "/usr/local/scratch/${name}.out";

cleanup();

# Set an environment variable that we will test for
$ENV{HTC_TEST_ENV_VAR} = "somevalue";
my $htc = Grid::Request->new( project => $project );
$htc->command("/usr/bin/env");
$htc->output($output);

ok(! $htc->getenv(), "Getenv returned false before getenv set.");
$htc->getenv(1);
ok($htc->getenv(), "Getenv returned true after getenv set.");

my @ids = $htc->submit_and_wait();
is(scalar(@ids), 1, "Got an 1 id from submit_and_wait().");

my $id = $ids[0];

wait_for_out($output);

ok(-f $output, "Output file produced.") or
    diag("Might not be visible due to NFS caching issues.");

my @lines = ();
eval {
    open (FILE, "<", $output) or die "Could not open output file $output";
    @lines = <FILE>;
    close FILE;
};

ok(scalar(@lines) > 0, "Output file had data in it.");
my @env = grep { /HTC_TEST_ENV_VAR/ } @lines;
is(scalar(@env), 1, "Output had correct environment variable set."); 
like($env[0], qr/somevalue/, "Environment variable had correct value.");

cleanup();

#############################################################################

sub cleanup {
    eval {
        unlink $output;
    };
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
