#!/usr/bin/perl

# $Id: 12-runtime.t 10901 2008-05-01 20:21:28Z victor $

# Test if the API supports setting the runtime of a command

use strict;
use FindBin qw($Bin);
use lib ("$Bin/../lib");
use Log::Log4perl qw(:easy);
use Test::More tests => 3;
use Grid::Request;
use Grid::Request::Test;

my $project = Grid::Request::Test->get_test_project();

Log::Log4perl->init("$Bin/testlogger.conf");

my $runtime = 1; # In minutes
# Sleep for 10 times longer than what the runtime should allow
my $sleeptime = $runtime*10*60; # In seconds

my $htc = Grid::Request->new( project => $project );
$htc->command("/bin/sleep");
$htc->runtime($runtime);
$htc->add_param($sleeptime);

my @ids = $htc->submit_and_wait();
is(scalar(@ids), 1, "Got an 1 id from submit_and_wait().");

my $id = $ids[0];

# TODO: From here down, the logic to determine if setting the
# runtime really worked, is DRM dependent, specifically SGE dependent.
# It would be better to recode this to avoid making a call to SGE
# programs to determine if the test really worked, because if you
# switch to another DRM, like condor or LSF, the test will fail.

# It appears we need some time before the job becomes available to qacct
sleep 20;

my $qstat = `qacct -j $id`;

my @q_output = split(/\n/, $qstat);
my @runtime = grep { m/wall/ } @q_output;
ok(scalar(@runtime) == 1, "Got only one line with job wall clock time.");
my $qstat_runtime_line = $runtime[0];
chomp($qstat_runtime_line);
my @out = split(/\s/, $qstat_runtime_line);
my $out_runtime = $out[-1];
ok( (($out_runtime>$runtime*60-10) && ($out_runtime < $sleeptime)), "Setting runtime had the correct effect.");
