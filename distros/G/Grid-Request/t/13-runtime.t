#!/usr/bin/perl

# Test if the API supports setting the runtime limit of a command.

# $Id$

use strict;
use File::Which;
use FindBin qw($Bin);
use lib ("$Bin/../lib");
use Log::Log4perl qw(:easy);
use Test::More;
use Grid::Request;
use Grid::Request::Test;

Log::Log4perl->init("$Bin/testlogger.conf");

my $req = Grid::Request::Test->get_test_request();

# Get the configured DRM type.
my $drm = lc($req->_config()->val($Grid::Request::HTC::config_section, "drm"));

if ($drm ne "sge" && $drm ne "condor") {
   plan skip_all => "Test written for SGE or Condor. The 'drm' is set to another grid type: $drm.";
}  else {
   plan tests => 6;
}

check_negative_runtime();
check_zero_runtime();
check_valid_runtime();

###########################################################################

sub check_valid_runtime {
    my $req = Grid::Request::Test->get_test_request();

    my $runtime = 1; # In minutes
    # Sleep for 10 times longer than what the runtime should allow
    my $sleeptime = $runtime*10*60; # In seconds

    $req->command(which("sleep"));
    $req->runtime($runtime);
    $req->add_param($sleeptime);

    my @ids;
    eval {
        @ids = $req->submit_and_wait();
    };
    ok(! $@, "Able to submit_and_wait().") or
       Grid::Request::Test->diagnose();

    is(scalar(@ids), 1, "Got a single id from submit_and_wait().");

    if (scalar(@ids)) {
        my $id = $ids[0];
        if ($drm eq "SGE") {
            analyze_sge_job($id, $sleeptime, $runtime);
        } elsif (lc($drm) eq "condor") {
            analyze_condor_job($id, $sleeptime, $runtime);
        } else {
            die "Bad DRM value: $drm.\n";
        }
    } else {
        # Here we have to fail each of the tests that should have been run.
        fail("Unable to examine for wall clock time.");
        fail("Unable to check if runtime was less than sleeptime.");
    }
}

sub check_negative_runtime {
    my $req = Grid::Request::Test->get_test_request();
    undef $@;
    eval {
        $req->runtime(-1);
    };
    ok(defined $@, "Caught error when attempting to set a negative runtime limit.");
}

sub check_zero_runtime {
    my $req = Grid::Request::Test->get_test_request();
    undef $@;
    eval {
        $req->runtime(0);
    };
    ok(defined $@, "Caught error when attempting to set a 0 runtime limit.");
}

sub analyze_sge_job {
    my ($id, $sleeptime, $runtime) = @_;

    my $qacct = which("qacct");
    if (! defined $qacct) {
       die "Couldn't find qacct in the PATH.";
    }

    # TODO: From here down, the logic to determine if setting the
    # runtime really worked, is DRM dependent, specifically SGE dependent.
    # It would be better to recode this to avoid making a call to SGE
    # programs to determine if the test really worked, because if you
    # switch to another DRM, like condor or LSF, the test will fail.

    # It appears we need some time before the job becomes available to qacct
    sleep 20;

    my $qacct = `qacct -j $id`;

    my @q_output = split(/\n/, $qacct);
    my @runtime = grep { m/wall/ } @q_output;
    ok(scalar(@runtime) == 1, "Got only one line with job wall clock time.");
    my $qacct_runtime_line = $runtime[0];
    chomp($qacct_runtime_line);
    my @out = split(/\s/, $qacct_runtime_line);
    my $out_runtime = $out[-1];
    ok( (($out_runtime > $runtime*60-10) && ($out_runtime < $sleeptime)), "Setting runtime had the correct effect.");
}

sub analyze_condor_job {
    my ($id, $sleeptime, $runtime) = @_;

    my $condor_hist = which("condor_history");
    if (! defined $condor_hist) {
       die "Couldn't find condor_history in the PATH.";
    }

    if ($id =~ m/.*\.(\d+\.\d+)$/) {
        $id = $1;
    }

    my $condor_hist_out = `$condor_hist -long $id`;

    my @hist_lines = split(/\n/, $condor_hist_out);
    my @runtime = grep { m/^RemoteWallClockTime/ } @hist_lines;

    ok(scalar(@runtime) == 1, "Got only one line with job wall clock time.");
    my $condor_runtime_line = $runtime[0];
    chomp($condor_runtime_line);
    my @out = split(/=/, $condor_runtime_line);
    my $out_runtime = $out[-1];
    $out_runtime =~ s/\s//g;
    ok( (($out_runtime > $runtime*60-10) && ($out_runtime < $sleeptime)), "Setting runtime had the correct effect.");
}

