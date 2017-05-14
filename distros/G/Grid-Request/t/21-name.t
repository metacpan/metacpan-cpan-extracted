#!/usr/bin/perl

# Test the ability of naming of commands.

# $Id: 19-name.t 10901 2008-05-01 20:21:28Z victor $

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

# Skip the tests if we are not using SGE.
# Get the configured DRM type 
my $drm = $req->_config()->val($Grid::Request::HTC::config_section, "drm");

if ($drm ne "SGE") {
   plan skip_all => "Test written for SGE. The 'drm' is set to another grid type: $drm.";
}  else {
    my $qacct = which("qacct");
    if (! defined $qacct) {
       plan skip_all => "Couldn't find qacct in the PATH.";
    } else {
        plan tests => 4;
    }
}

my $name = "drmaaname";

$req->command(which("echo"));
$req->name($name);

my @ids;
eval {
    @ids = $req->submit_and_wait();
};

ok(! $@, "No exceptions when job is submitted via submit_and_wait().") or
    Grid::Request::Test->diagnose();

is(scalar(@ids), 1, "Got a single id from submit_and_wait().");

my $id = $ids[0];
if ($id) {
    analyze_job($id);
} else {
    fail("Unable to determine job name because no job was submitted.");
    fail("Unable to check that the job name had the correct value.");
}

###########################################################################

sub analyze_job {
    my $id = shift;

    # TODO: From here down, the logic to determine if setting the
    # name really worked, is DRM dependent, specifically SGE dependent.
    # Skip the tests if we are not using SGE.

    # SGE exhibits a lag between the time the job finishes (per drmaa)
    # and the time the data about the job is available to qacct. We
    # therefore poll and wait for the results to be available.
    my $ready = wait_for_qacct($id);

    if ($ready) {
        my $qacct = `qacct -j $id`;
        my @q_output = split(/\n/, $qacct);
        my @name = grep { m/jobname/ } @q_output;
        ok(scalar(@name) == 1, "Got only one line with job name.");
        my $qacct_name_line = $name[0];
        chomp($qacct_name_line);
        my @out = split(/\s/, $qacct_name_line);
        my $out_name = $out[-1];
        is($out_name, $name, "Job got the correct name.");
    } else {
        print STDERR "Unable to query results of job using qacct.\n";
    }
}

sub wait_for_qacct {
    my $id = shift;
    sleep 1;
    my $ready = 0;
    for my $attempt qw(1 2 3 4) {
        sleep $attempt;
        system("qacct -j $id 1>/dev/null 2>/dev/null");

        my $exit_value = $? >> 8;
        if ($exit_value == 0) {
            $ready = 1;
            last;
        }
    }
    return $ready;
}
