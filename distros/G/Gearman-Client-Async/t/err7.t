#!/usr/bin/perl
#
# memory leaks on timeouts
#

use strict;
use FindBin qw($Bin);
require "$Bin/lib/testlib.pl";

use Test::More;

use constant PORT => 9000;

if (start_server(PORT)) {
    plan tests => 3;
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

use Scalar::Util qw(weaken);
my $taskptr;
{
    my $task = Gearman::Task->new( "sleep_for" => \ "2", {
        timeout => 1.0,
        retry_count => 5,
        on_complete => sub {
            $complete = 1;
        },
        on_fail => sub {
            $failed = 1;
            $done = 1;
        },
    });
    $client->add_task($task);
    $taskptr = $task;
    weaken($taskptr);
}

Danga::Socket->SetPostLoopCallback(sub {
    return !$done;
});

Danga::Socket->EventLoop();

ok(!$taskptr, "Gearman::Task object went out of scope");
ok($failed, "got a failure");
ok(!$complete, "didn't finish");





