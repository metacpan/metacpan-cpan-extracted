#!/usr/bin/perl

# Test if code supports setting the command to replicate the environment
# with getenv() or not.

# $Id: 22-getenv.t 10901 2008-05-01 20:21:28Z victor $

use strict;
use FindBin qw($Bin);
use File::Basename;
use File::Which;
use lib ("$Bin/../lib");
use Log::Log4perl qw(:easy);
use Test::More;
use Grid::Request;
use Grid::Request::Test;

Log::Log4perl->init("$Bin/testlogger.conf");

my $req = Grid::Request::Test->get_test_request();

# Get the configured temporary directory
my $tempdir = $req->_config()->val($Grid::Request::HTC::config_section, "tempdir");

if (! defined $tempdir || ! -d $tempdir) {
    plan skip_all => 'tempdir not configured or not a directory';
} else {
    plan tests => 8;
}

my $name = basename($0);
my $output = "$tempdir/${name}.out";

cleanup();

# Set an environment variable that we will test for
$ENV{HTC_TEST_ENV_VAR} = "somevalue";
$req->command(which("env"));
$req->output($output);

ok(! $req->getenv(), "Getenv returned false before getenv set.");
$req->getenv(1);
ok($req->getenv(), "Getenv returned true after getenv set.");

my @ids;
eval {
    @ids = $req->submit_and_wait();
};
ok(! $@, "No exception when job submitted via submit_and_wait().") or
    Grid::Request::Test->diagnose();

is(scalar(@ids), 1, "Got an 1 id from submit_and_wait().");

if (scalar(@ids)) {
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
} else {
    # We have to 'fail' our tests from above.
    fail("Can't produce output file. No job run.");
    fail("Can't check contents of output file. No job run.");
    fail("Can't check if environment varialbe present in output file. No job run.");
    fail("Can't check that environment variable had the correct value. No job run.");
}

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
