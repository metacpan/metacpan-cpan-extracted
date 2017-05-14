#!/usr/bin/perl

# Test if the API supports specifying the priority of commands 

# $Id: 18-priority.t 10901 2008-05-01 20:21:28Z victor $

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

# Get the configured temporary directory
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

# Users are NOT able to raise their priority, so we have to lower
# the priority to something less than the default of 0.
my $priority = -18;
$req->command(which("echo"));
$req->priority($priority);

my @ids;
eval {
    @ids = $req->submit_and_wait();
};
ok(! $@, "No exception when job submitted via submit_and_wait.") or
    Grid::Request::Test->diagnose();

is(scalar(@ids), 1, "Got 1 id from submit_and_wait().");

my $id = $ids[0];

if ($id) {
    analyze_job($id);
} else {
    fail("Unable to verify job priority because no job was run.");
    fail("Unable to check job priority value because no job was run.");
}

###########################################################################

sub analyze_job {
    my $id = shift;

    # TODO: From here down, the logic to determine if setting the priority really
    # worked, is DRM dependent, specifically SGE dependent.  It would be better to
    # recode this to avoid making a call to SGE programs to determine if the test
    # really worked, because if you switch to another DRM, like condor or LSF, the
    # test will fail.

    # It appears we need some time before the job becomes available to qacct
    my $retries = 0;
    my @q_output = ();
    my $exit_value = 1;
    do {
        $retries++;
        sleep 5;
        open QACCT, "qacct -j $id 2>/dev/null |" or die "error running command $!";
        @q_output = <QACCT>;
        close QACCT;
        $exit_value = $? >> 8;
    } while ($exit_value != 0 && $retries <= 3);

    my @priority = grep { m/priority/ } @q_output;
    ok(scalar(@priority) == 1, "Got only one line with job priority.");
    my $qacct_priority_line = $priority[0];
    chomp($qacct_priority_line);
    diag("Priority line: $qacct_priority_line");
    my @out = split(/\s/, $qacct_priority_line);
    my $out_priority = $out[-1];
    is($out_priority, $priority, "Job got the correct priority.");
}
