#!/usr/bin/perl

# Test script to test email notification.

# $Id: 16-email_notification.t 10901 2008-05-01 20:21:28Z victor $

# TODO: Perhaps there is some way to detect that an email is actually
# sent short of using a real email address and logging in...

use strict;
use FindBin qw($Bin);
use lib ("$Bin/../lib");
use File::Which;
use Test::More tests => 3;
use Grid::Request;
use Grid::Request::Test;

use Log::Log4perl qw(:easy);
Log::Log4perl->init("$Bin/testlogger.conf");

my $email = 'test@example.com';

my $req = Grid::Request::Test->get_test_request();
$req->command(which("echo"));
$req->email($email);
is($req->email(), $email, "Email getter returns same value set.");

my @ids;
eval {
    @ids = $req->submit();
};
ok(! $@, "No exception when job submitted.") or
    Grid::Request::Test->diagnose();

is(scalar(@ids), 1, "Got a single id from submit().");
