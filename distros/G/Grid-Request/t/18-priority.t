#!/usr/bin/perl

# $Id: 18-priority.t 10901 2008-05-01 20:21:28Z victor $

# Test if the API supports specifying the priority of commands 

use strict;
use FindBin qw($Bin);
use lib ("$Bin/../lib");
use Log::Log4perl qw(:easy);
use Test::More tests => 3;
use Grid::Request;
use Grid::Request::Test;

Log::Log4perl->init("$Bin/testlogger.conf");
my $project = Grid::Request::Test->get_test_project();

# Users are NOT able to raise their priority, so we have to lower
# the priority to something less than the default of 0.
my $priority = -18;
my $htc = Grid::Request->new( project => $project );
$htc->command("/bin/echo");
$htc->priority($priority);

my @ids = $htc->submit_and_wait();
is(scalar(@ids), 1, "Got 1 id from submit_and_wait().");

my $id = $ids[0];

# TODO: From here down, the logic to determine if setting the priority really
# worked, is DRM dependent, specifically SGE dependent.  It would be better to
# recode this to avoid making a call to SGE programs to determine if the test
# really worked, because if you switch to another DRM, like condor or LSF, the
# test will fail.

# It appears we need some time before the job becomes available to qacct
sleep 30;

my $qacct = `qacct -j $id 2>/dev/null`;
my @q_output = split(/\n/, $qacct);
my @priority = grep { m/priority/ } @q_output;
ok(scalar(@priority) == 1, "Got only one line with job priority.");
my $qacct_priority_line = $priority[0];
chomp($qacct_priority_line);
my @out = split(/\s/, $qacct_priority_line);
my $out_priority = $out[-1];
is($out_priority, $priority, "Job got the correct priority.");
