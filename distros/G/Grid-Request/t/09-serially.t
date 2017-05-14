#!/usr/bin/perl

# Test script to test the submit_serially() method.

# $Id: 06-serially.t 10901 2008-05-01 20:21:28Z victor $

use strict;
use FindBin qw($Bin);
use File::Which;
use lib ("$Bin/../lib");
use Log::Log4perl qw(:easy);
use Test::More tests => 4;
use Grid::Request;
use Grid::Request::Test;

Log::Log4perl->init("$Bin/testlogger.conf");

my $echo = which("echo");
my $req = Grid::Request::Test::get_test_request();
$req->command($echo);

# Submit the job
my @ids;
eval {
    @ids = $req->submit(1);
};
ok(! $@, "1st submission did not trigger an exception.") or
    Grid::Request::Test->diagnose();
is(scalar(@ids), 1, "Got a single id from submit(1).");

my $req2 = Grid::Request::Test::get_test_request();
$req2->command($echo);

eval {
    @ids = $req2->submit_serially();
};

ok(! $@, "2nd submission did not trigger an exception.") or
    Grid::Request::Test->diagnose();

is(scalar(@ids), 1, "Got 1 id from the submit_serially().");
