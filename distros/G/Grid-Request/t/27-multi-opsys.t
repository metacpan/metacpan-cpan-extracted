#!/usr/bin/perl

# Test to verify that specifying multiple opersting systems for
# commands is supported.

# $Id: 26-multi-opsys.t 10901 2008-05-01 20:21:28Z victor $

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

# Get the configured temporary directory
my $tempdir = $req->_config()->val($Grid::Request::HTC::config_section, "tempdir");

if (! defined $tempdir || ! -d $tempdir) {
    plan skip_all => 'tempdir not configured or not a directory';
} else {
    plan tests => 7;
}

my $base = basename($0);
my $output = "$tempdir/${base}.out";
my $opsys = "Linux,Solaris";

cleanup();
ok(! -e $output, "Output file does not exist.");

$req->command(which("uname"));
$req->output($output);
$req->opsys($opsys);

is($req->output(), $output, "output() got same value that was set.");
is($req->opsys(), $opsys, "opsys() got same value that was set.");

# Submit the job
my @ids;
eval {
    @ids = $req->submit_serially();
};
ok(! $@, "No exception when submitting job via submit_serially.") or
    Grid::Request::Test->diagnose();

is(scalar(@ids), 1, "Got a single id from submit_serially().");

if (scalar(@ids)) {
    wait_for_out($output);

    ok(-f $output, "Output file was created.");

    my $result = "";
    eval {
        open(FILE, "<", $output) or die "Could not open the output file $output.";
        $result = <FILE>;
        close FILE;
        chomp($result);
    };

    ok($result =~ m/^(SunOS|Linux)$/, "Job ran on a correct operating system.");
} else {
    fail("Output file not created because job not run.");
    fail("Unable to verify operating system of job because no job run.");
}

cleanup();

#############################################################################

sub cleanup {
    eval { unlink $output; };
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
