#!/usr/bin/perl

# Test if the API supports the class method. In SGE, setting "class" doesn't do
# anything and is essentially a no-op. Therefore, we just check that it doesn't
# break anything and that can we can submit a job even though we've set
# 'class'.

# $Id: 20-class.t 10901 2008-05-01 20:21:28Z victor $

use strict;
use FindBin qw($Bin);
use File::Basename;
use File::Which;
use lib ("$Bin/../lib");
use Log::Log4perl qw(:easy);
use Test::More tests => 3;
use Grid::Request;
use Grid::Request::Test;

Log::Log4perl->init("$Bin/testlogger.conf");

my $req = Grid::Request::Test->get_test_request();

my $class = "myclass";

$req->command(which("echo"));
$req->class($class);

is($req->class(), $class, "Getter got the set value.");

my @ids;
eval {
    @ids = $req->submit_and_wait();
};
ok(! $@, "No exceptions when job submitted via submit_and_wait().") or
    Grid::Request::Test->diagnose();

is(scalar(@ids), 1, "Got an 1 id from submit_and_wait().");
