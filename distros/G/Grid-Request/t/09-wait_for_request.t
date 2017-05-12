#!/usr/bin/perl

# $Id: 09-wait_for_request.t 10901 2008-05-01 20:21:28Z victor $

use strict;
use File::Basename;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Log::Log4perl qw(:easy);
use Grid::Request;
use Grid::Request::Test;
use Test::More tests => 3;

my $project = Grid::Request::Test->get_test_project();

Log::Log4perl->init("$Bin/testlogger.conf");

my $name = basename($0);
my $output = "/usr/local/scratch/${name}.out";

cleanup();
ok(! -e $output, "Output file does not exist.");

# Formulate and submit the request
my $htc = Grid::Request->new( project => $project );
$htc->command("/bin/echo");
$htc->output($output);

my @ids = $htc->submit_and_wait();
is(scalar(@ids), 1, "Got 1 id from submit_and_wait().");

wait_for_out($output);

ok(-f $output, "Output file was created.") or
    diag("Might not be visible due to NFS caching issues.");
cleanup();

sub cleanup {
    eval { unlink $output; };
}

sub wait_for_out {
    my $output = shift;
    my $n=1;
    while (($n < 10 ) && (! -e $output)) {
        last if (-e $output);
        sleep $n*6;
        $n++;
    }
}
