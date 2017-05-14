#!/usr/bin/perl

# This script tests the functionality of the times() method

# $Id: 15-times.t 10901 2008-05-01 20:21:28Z victor $

use strict;
use File::Basename;
use FindBin qw($Bin);
use lib ("$Bin/../lib");
use Log::Log4perl qw(:easy);
use Test::More;
use Grid::Request;
use Grid::Request::Test;
use File::Temp qw(tempdir);

Log::Log4perl->init("$Bin/testlogger.conf");

my $name = basename($0);

my $req = Grid::Request::Test->get_test_request();

# Get the configured temporary directory
my $tempdir = $req->_config()->val($Grid::Request::HTC::config_section, "tempdir");

if (! defined $tempdir || ! -d $tempdir) {
    plan skip_all => 'tempdir not configured or not a directory.';
} else {
    plan tests => 4;
}

# Create a simple shell script
my $script = "${tempdir}/times_count.sh";
my $job_tempdir = tempdir ( DIR => $tempdir );

# Test if the output file was created
ok(-d $job_tempdir, "Temporary directory created for output.");

my $times = 15;
my $shell = <<"    _HERE";
#!/bin/bash

DIR=\$1
if [ -z \$SGE_TASK_ID ]; then
    env > \$DIR/\$\$
else
    echo id:\$SGE_TASK_ID > \$DIR/\$SGE_TASK_ID
fi
    _HERE


# Remove the script in case it's there from a previous run.
eval {
    unlink $script;
};
open(SHELL, ">", $script);
print SHELL $shell;
close(SHELL);
chmod 0755, $script;

ok(-f $script && -x $script, "Shell script created.");

# Submit a request to the DRM to run the script
$req->command($script);
$req->add_param($job_tempdir);
$req->times($times);

my @ids = $req->submit_and_wait();
is(scalar(@ids), $times, "Got $times ids from submit_and_wait().");

# Further check if the script really executed by examining the output
# directory and checking if the right number of files are present.
opendir(my $dh, $job_tempdir) || die "Cannot open directory $job_tempdir: $!";
my @files = grep { -f "$job_tempdir/$_" } readdir($dh);
closedir $dh;
is(scalar(@files), $times, "Output directory had output from each task.");
