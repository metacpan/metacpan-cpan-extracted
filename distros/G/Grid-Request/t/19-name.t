#!/usr/bin/perl

# $Id: 19-name.t 10901 2008-05-01 20:21:28Z victor $

# Test if the API supports the naming of commands.

use strict;
use FindBin qw($Bin);
use File::Basename;
use lib ("$Bin/../lib");
use Log::Log4perl qw(:easy);
use Test::More tests => 3;
use Grid::Request;
use Grid::Request::Test;

Log::Log4perl->init("$Bin/testlogger.conf");
my $project = Grid::Request::Test->get_test_project();

my $name = "drmaaname";

my $htc = Grid::Request->new( project => $project );
$htc->command("/bin/echo");
$htc->name($name);

my @ids = $htc->submit_and_wait();
is(scalar(@ids), 1, "Got an single id from submit_and_wait().");

my $id = $ids[0];

# TODO: From here down, the logic to determine if setting the
# name really worked, is DRM dependent, specifically SGE dependent.
# It would be better to recode this to avoid making a call to SGE
# programs to determine if the test really worked, because if you
# switch to another DRM, like condor or LSF, the test will fail.
my $qstat = `qacct -j $id`;
my @q_output = split(/\n/, $qstat);
my @name = grep { m/jobname/ } @q_output;
ok(scalar(@name) == 1, "Got only one line with job name.");
my $qstat_name_line = $name[0];
chomp($qstat_name_line);
my @out = split(/\s/, $qstat_name_line);
my $out_name = $out[-1];
is($out_name, $name, "Job got the correct name.");
