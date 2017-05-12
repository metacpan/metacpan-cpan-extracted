#!/usr/bin/perl
#
# submit a bunch of jobs to one js, one worker, first sleeps, kill js, get errors, resubmit all to other js
#

use strict;
use FindBin qw($Bin);
require "$Bin/lib/testlib.pl";

use Test::More;

use constant PORT => 9000;

my $s1pid;
if ($s1pid = start_server(PORT)) {
    plan tests => 2;
} else {
    plan skip_all => "Can't find server to test with";
    exit 0;
}

my $s2pid = start_server(PORT+1) or die;
start_worker(PORT, 2);

my $client = Gearman::Client::Async->new;
$client->set_job_servers('127.0.0.1:9000', '127.0.0.1:9001');
$client->t_set_disable_random(1);

my $completed = 0;
my $failed = 0;
my $done   = 0;

my $n_loops = 4;
for (1..$n_loops) {
    $client->add_task( Gearman::Task->new( "sleep_for" => \ "1", {
        retry_count => 1,
        on_complete => sub {
            $completed++;

            # on first success, kill the job server
            if ($completed == 1) {
                kill 9, $s1pid;
            }
            $done = 1 if $completed+$failed == $n_loops;
        },
        on_fail => sub {
            $failed++;
            $done = 1 if $completed+$failed == $n_loops;
        },
    }));
}

Danga::Socket->AddTimer(15.0, sub { $done = 1; });

Danga::Socket->SetPostLoopCallback(sub {
    return !$done;
});

Danga::Socket->EventLoop();

is($completed, $n_loops, "$n_loops completed successfully");
is($failed,    0,        "none failed");





