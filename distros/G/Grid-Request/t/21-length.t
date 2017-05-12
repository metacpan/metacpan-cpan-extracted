#!/usr/bin/perl

# $Id: 21-length.t 10901 2008-05-01 20:21:28Z victor $

# Test if the API supports setting the length of a command

use strict;
use FindBin qw($Bin);
use File::Basename;
use lib ("$Bin/../lib");
use Log::Log4perl qw(:easy);
use Test::More tests => 3;
use Grid::Request;

Log::Log4perl->init("$Bin/testlogger.conf");

my $length = "fast";

my $htc = Grid::Request->new( project => "test" );
$htc->command("/bin/echo");
$htc->length($length);

my @ids = $htc->submit_and_wait();
is(scalar(@ids), 1, "Got an 1 id from submit_and_wait().");

my $id = $ids[0];

# TODO: From here down, the logic to determine if setting the
# length really worked, is DRM dependent, specifically SGE dependent.
# It would be better to recode this to avoid making a call to SGE
# programs to determine if the test really worked, because if you
# switch to another DRM, like condor or LSF, the test will fail.

# It appears we need some time before the job becomes available to qacct
sleep 30;

my $qstat = `qacct -j $id`;
my @q_output = split(/\n/, $qstat);
my @length = grep { m/qname/ } @q_output;
ok(scalar(@length) == 1, "Got only one line with a qname line.");
my $qstat_length_line = $length[0];
chomp($qstat_length_line);
my @out = split(/\s/, $qstat_length_line) if defined($qstat_length_line);
my $out_length = $out[-1] if scalar(@out);
like($out_length, qr/fast/, "Setting length had the correct effect.");
