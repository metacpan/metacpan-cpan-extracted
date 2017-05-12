#!/usr/bin/perl

# $Id: 20-class.t 10901 2008-05-01 20:21:28Z victor $

# Test if the API supports the class method.

use strict;
use FindBin qw($Bin);
use File::Basename;
use lib ("$Bin/../lib");
use Log::Log4perl qw(:easy);
use Test::More tests => 4;
use Grid::Request;
use Grid::Request::Test;

Log::Log4perl->init("$Bin/testlogger.conf");
my $project = Grid::Request::Test->get_test_project();

my $class = "myclass";

my $htc = Grid::Request->new( project => $project );
$htc->command("/bin/echo");
$htc->class("Assembly");

is($htc->class(), "Assembly", "Getter got the set value.");

my @ids = $htc->submit_and_wait();
is(scalar(@ids), 1, "Got an 1 id from submit_and_wait().");

my $id = $ids[0];

# TODO: From here down, the logic to determine if setting the
# name really worked, is DRM dependent, specifically SGE dependent.
# It would be better to recode this to avoid making a call to SGE
# programs to determine if the test really worked, because if you
# switch to another DRM, like condor or LSF, the test will fail.

# It appears we need some time before the job becomes available to qacct
sleep 30;

my $qstat = `qacct -j $id`;
my @q_output = split(/\n/, $qstat);
my @class = grep { m/qname/ } @q_output;
ok(scalar(@class) == 1, "Got only one line with qname.");
my $qstat_class_line = $class[0] if scalar(@class);
chomp($qstat_class_line) if defined $qstat_class_line;
my @out = split(/\s/, $qstat_class_line) if defined $qstat_class_line;
my $out_class = $out[-1] if scalar(@out);
like($out_class, qr/msc/, "Class had the correct effect on queue.");
