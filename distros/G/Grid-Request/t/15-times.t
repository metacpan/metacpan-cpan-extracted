#!/usr/bin/perl

# $Id: 15-times.t 10901 2008-05-01 20:21:28Z victor $

# This script tests the functionality of the times() method

use strict;
use File::Basename;
use FindBin qw($Bin);
use lib ("$Bin/../lib");
use Log::Log4perl qw(:easy);
use Test::More tests => 4;
use Grid::Request;
use Grid::Request::Test;

Log::Log4perl->init("$Bin/testlogger.conf");
my $project = Grid::Request::Test->get_test_project();

my $name = basename($0);

# Create a simple shell script
my $scratch = "/usr/local/scratch";
my $script = "${scratch}/times_count.sh";
my $output = $script . '.tasks';
my $times = 15;
my $shell = <<"    _HERE";
#!/bin/bash

echo id:\$SGE_TASK_ID >> $output
    _HERE


# Remove these files in case they are there from a previous run.
eval {
    unlink $script;
    unlink $output;
};
open(SHELL, ">", $script);
print SHELL $shell;
close(SHELL);
chmod 0755, $script;

ok(-f $script && -x $script, "Shell script created.");

# Submit a request to the DRM to run the script
my $htc = Grid::Request->new( project => $project );
$htc->command($script);
$htc->times($times);

my @ids = $htc->submit_and_wait();
is(scalar(@ids), $times, "Got $times ids from submit_and_wait().");

# Test if the output file was created
ok(-f $output, "Output file created.");

# Further check if the script really executed by examining the output
open(OUT, "<", $output);
my @lines = <OUT>;
close(OUT);
@lines = grep { $_ =~ m/id/ } @lines;
is(scalar(@lines), $times, "Output file had output from each task.");
