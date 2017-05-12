#!/usr/bin/perl
#
# connect to one js, it's down immediately, try another, no retry count
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

start_worker(PORT, 1);

my $client = Gearman::Client::Async->new;
$client->set_job_servers('127.0.0.1:9001', '127.0.0.1:9000');
$client->t_set_disable_random(1);

my $completed = 0;
my $failed = 0;
my $done   = 0;

my $n_loops = 3;
for (1..$n_loops) {
    $client->add_task( Gearman::Task->new( "sleep_for" => \ "0.5", {
        on_complete => sub {
            $completed++;
            $done = 1 if $completed == $n_loops;
        },
        on_fail => sub {
            $failed = 1;
        },
    }));
}

Danga::Socket->AddTimer(3.0, sub { $done = 1; });

Danga::Socket->SetPostLoopCallback(sub {
    return !$done;
});

Danga::Socket->EventLoop();

ok(!$failed, "insertion didn't fail");
is($completed, $n_loops, "completed $n_loops times");




