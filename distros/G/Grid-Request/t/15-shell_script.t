#!/usr/bin/perl

# Test script to verify the submission and execution of a shell script.

# $Id: 14-shell_script.t 10901 2008-05-01 20:21:28Z victor $

use strict;
use FindBin qw($Bin);
use File::Basename;
use Log::Log4perl qw(:easy);
use Test::More;
use lib ("$Bin/../lib");
use Grid::Request;
use Grid::Request::Test;

Log::Log4perl->init("$Bin/testlogger.conf");

my $req = Grid::Request::Test->get_test_request();

# Get the configured temporary directory
my $tempdir = $req->_config()->val($Grid::Request::HTC::config_section, "tempdir");

if (! defined $tempdir || ! -d $tempdir) {
    plan skip_all => 'tempdir not configured or not a directory.';
} else {
    plan tests => 5;
}

# Create the shell script we will submit and formulate the name of the output file
my $base = basename($0);
my $script = "$tempdir/test-${base}.sh";
my $output = $script . '.out';

# Remove files in case they are there from a previous run.
cleanup();

create_shell_script($script);

ok(-f $script, "Shell script created.");

# Submit a request to the DRM to run the script
$req->command($script);
$req->output($output);

my @ids;
eval {
    @ids = $req->submit_and_wait();
};
ok(! $@, "No exception when job submitted via submit_and_wait().") or
    Grid::Request::Test->diagnose();

is(scalar(@ids), 1, "Got an 1 id from submit_and_wait().");

if (scalar(@ids)) {
    # Test if the output file was created
    ok(-f $output, "Output file created.");

    # Further check if the script really executed by examining the output
    my @lines;
    eval {
        open(OUT, "<", $output);
        $/ = undef;
        @lines = <OUT>;
        close(OUT);
        @lines = grep { $_ =~ m/host/ } @lines;
    };

    is(scalar(@lines), 1, "Output file had valid output. Script ran.");
} else {
    # We should 'fail' the tests that would have run above.
    fail("No output file created. Job didn't run.");
    fail("Can't check output validity. Job didn't run.");
}

###########################################################################

sub cleanup {
    eval {
       unlink $script;
       unlink $output;
    };
}

sub create_shell_script {
    my $script = shift;

    # Create a simple shell script
    my $shell = <<"    _HERE";
    #!/bin/bash

    echo `date`
    echo host:\$HOSTNAME
    _HERE

    eval {
        open(SHELL, ">", $script) or die "Unable to open $script for writing: $!";
        print SHELL $shell;
        close(SHELL) or die "Unable to close filehandle: $!";
        chmod 0755, $script;
    };
}
