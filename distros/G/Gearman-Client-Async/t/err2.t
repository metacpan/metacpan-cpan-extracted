#!/usr/bin/perl
#
# connect to one js, submit job, no reply in 'timeout' seconds, fail, job then succeeds right after, ignore it
#

use strict;
use FindBin qw($Bin);
require "$Bin/lib/testlib.pl";

use Test::More;

use constant PORT => 9000;

if (start_server(PORT)) {
    plan tests => 4;
} else {
    plan skip_all => "Can't find server to test with";
    exit 0;
}

# Start 1 worker, telling it we have 2 jobservers when really we only
# have one (it starts at 9000 and works up)
start_worker(PORT, 2);

my $client = Gearman::Client::Async->new;
$client->set_job_servers('127.0.0.1:' . PORT);

my $complete = 0;
my $failed = 0;
my $done   = 0;
my $gotstatus = 0;
my $retried = 0;

Danga::Socket->AddTimer(3.0, sub { $done = 1; });

$client->add_task( Gearman::Task->new( "sleep_for" => \ "2", {
    timeout => 1.0,
    retry_count => 5,
    on_status => sub {
        $gotstatus++;
    },
    on_complete => sub {
        $complete = 1;
    },
    on_fail => sub {
        $failed = 1;
    },
    on_retry => sub {
        $retried = 1;
    },
}));

Danga::Socket->SetPostLoopCallback(sub {
    return !$done;
});

Danga::Socket->EventLoop();

ok($failed, "got a failure");
ok(!$retried, "didn't retry");
ok($gotstatus, "got status");
ok(!$complete, "didn't finish");





