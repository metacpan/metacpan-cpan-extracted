#!/usr/bin/perl

# $Id: 14-shell_script.t 10901 2008-05-01 20:21:28Z victor $

use strict;
use FindBin qw($Bin);
use File::Basename;
use Log::Log4perl qw(:easy);
use Test::More tests => 4;
use lib ("$Bin/../lib");
use Grid::Request;
use Grid::Request::Test;

Log::Log4perl->init("$Bin/testlogger.conf");
my $project = Grid::Request::Test->get_test_project();

my $base = basename($0);
# Create a simple shell script
my $shell = <<"    _HERE";
#!/bin/bash

echo `date`
echo host:\$HOSTNAME
    _HERE

my $scratch = "/usr/local/scratch";
my $script = "${scratch}/test-${base}.sh";
my $output = $script . '.out';

# Remove files in case they are there from a previous run.
cleanup();

eval {
    open(SHELL, ">", $script);
    print SHELL $shell;
    close(SHELL);
    chmod 0755, $script;
};

ok(-f $script, "Shell script created.");

# Submit a request to the DRM to run the script
my $htc = Grid::Request->new( project => $project );
$htc->command($script);
$htc->output($output);

my @ids = $htc->submit_and_wait();
is(scalar(@ids), 1, "Got an 1 id from submit_and_wait().");

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

sub cleanup {
    eval {
       unlink $script;
       unlink $output;
    };
}
