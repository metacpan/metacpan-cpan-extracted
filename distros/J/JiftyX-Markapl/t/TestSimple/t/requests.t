#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use lib 't/TestSimple/lib/TestSimple';
use Test::More;
use Jifty::Test;
use Jifty::Test::WWW::Mechanize;

my $server = Jifty::Test->make_server;
my $server_url = $server->started_ok;

my $mech = Jifty::Test::WWW::Mechanize->new;

$mech->get_ok("${server_url}/hi");
$mech->content_is("<h1>HI</h1>");

done_testing;
