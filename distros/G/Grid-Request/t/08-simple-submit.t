#!/usr/bin/perl

# $Id: 08-simple-submit.t 10901 2008-05-01 20:21:28Z victor $

use strict;
use FindBin qw($Bin);
use lib ("$Bin/../lib");
use Log::Log4perl qw(:easy);
use Test::More tests => 1;
use Grid::Request;
use Grid::Request::Test;

my $project = Grid::Request::Test->get_test_project();


Log::Log4perl->init("$Bin/testlogger.conf");

my $htc = Grid::Request->new( project => $project );
$htc->command("/bin/echo");

my @ids = $htc->submit();
is(scalar(@ids), 1, "Got an 1 id from submit().");
