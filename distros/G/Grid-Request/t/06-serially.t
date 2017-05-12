#!/usr/bin/perl

# $Id: 06-serially.t 10901 2008-05-01 20:21:28Z victor $

use strict;
use FindBin qw($Bin);
use lib ("$Bin/../lib");
use Log::Log4perl qw(:easy);
use Test::More tests => 2;
use Grid::Request;
use Grid::Request::Test;

my $project = Grid::Request::Test->get_test_project();
Log::Log4perl->init("$Bin/testlogger.conf");

eval {
    my $htc = Grid::Request->new( project => $project );
    $htc->command("/bin/echo");

    my @ids = $htc->submit(1);
    is(scalar(@ids), 1, "Got 1 id from submit(1).");

    my $htc2 = Grid::Request->new( project => "test" );
    $htc2->command("/bin/echo");

    @ids = $htc2->submit_serially();
    is(scalar(@ids), 1, "Got 1 id from the submit_serially().");
};

if ( my $e = Exception::Class->caught('Grid::Request::DRMAAException') )
{
     diag( join ' ', $e->drmaa(), $e->diagnosis());
     exit 1;
}
