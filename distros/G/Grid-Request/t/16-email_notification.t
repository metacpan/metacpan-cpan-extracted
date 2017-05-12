#!/usr/bin/perl

# $Id: 16-email_notification.t 10901 2008-05-01 20:21:28Z victor $

use strict;
use FindBin qw($Bin);
use lib ("$Bin/../lib");
use Test::More tests => 2;
use Grid::Request;
use Grid::Request::Test;


use Log::Log4perl qw(:easy);
Log::Log4perl->init("$Bin/testlogger.conf");

my $project = Grid::Request::Test->get_test_project();

my $domain = `hostname --fqdn`;
chomp($domain) if defined($domain);
my @d = split(/\./, $domain);
$domain = $d[-2] . '.' . $d[-1];
my $email = getpwuid($>) . $domain;

my $htc = Grid::Request->new( project => $project );
$htc->command("/bin/echo");
$htc->email($email);
is($htc->email(), $email, "Email getter returns same value set.");

my @ids = $htc->submit();
is(scalar(@ids), 1, "Got an 1 id from submit().");
