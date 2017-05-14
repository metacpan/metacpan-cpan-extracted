#!/usr/bin/perl

# Test script to test rudimentary submissions.

# $Id: 08-simple-submit.t 10901 2008-05-01 20:21:28Z victor $

use strict;
use FindBin qw($Bin);
use File::Which;
use lib ("$Bin/../lib");
use Log::Log4perl qw(:easy);
use Test::More tests => 2;
use Grid::Request;
use Grid::Request::Test;

use Grid::Request::Exceptions;

Log::Log4perl->init("$Bin/testlogger.conf");

my $req = Grid::Request::Test::get_test_request();
$req->command(which("echo"));

# Submit the job
my @ids;
eval {
    @ids = $req->submit();
};

ok(! $@, "Submission did not trigger an exception.") or
    Grid::Request::Test->diagnose();

is(scalar(@ids), 1, "Got a single id from submit.");
