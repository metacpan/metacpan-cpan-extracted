#!/usr/bin/perl
#
# tests inserting a job into a dead jobserver.
#

use strict;
use FindBin qw($Bin);
require "$Bin/lib/testlib.pl";

use Test::More;

use constant PORT => 9000;

if (start_server(PORT)) {
    plan tests => 2;
} else {
    plan skip_all => "Can't find server to test with";
    exit 0;
}

## Look for 2 job servers, starting at port number PORT.
start_worker(PORT, 2);
start_worker(PORT, 2);

my $client = Gearman::Client::Async->new;
$client->set_job_servers('127.0.0.1:' . (PORT + 1));

my $counter = 0;
my $failed = 0;
my $done   = 0;

$client->add_task( Gearman::Task->new( "sleep_for" => \ "1", {
    on_complete => sub {
        $counter++;
        $done = 1;
    },
    on_fail => sub {
        $failed = 1;
        $done = 1;
    },
}));

Danga::Socket->SetPostLoopCallback(sub {
    return !$done;
});

Danga::Socket->EventLoop();

ok($failed, "insertion failed");
ok(!$counter, "didn't succeed");




