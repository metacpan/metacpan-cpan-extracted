#!/usr/bin/perl
#
# uniq merging
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

my $w1pid = start_worker(PORT, 1) or die;
my $client = Gearman::Client::Async->new;
$client->set_job_servers('127.0.0.1:9000');

my $completed = 0;
my $failed = 0;
my $done   = 0;

my $n_loops = 4;
for (1..$n_loops) {
    $client->add_task( Gearman::Task->new( "sleep_for" => \ "1", {
        uniq => "foo",
        retry_count => 1,
        on_complete => sub {
            $completed++;

            # on first success, kill the worker, so it can't do more.
            if ($completed == 1) {
                kill 9, $w1pid;
            }
            $done = 1 if $completed+$failed == $n_loops;
        },
        on_fail => sub {
            $failed++;
            $done = 1 if $completed+$failed == $n_loops;
        },
    }));
}

Danga::Socket->AddTimer(5.0, sub { $done = 1; });

Danga::Socket->SetPostLoopCallback(sub {
    return !$done;
});

Danga::Socket->EventLoop();

is($completed, $n_loops, "$n_loops tasks done");
is($failed,    0,        "none failed");





