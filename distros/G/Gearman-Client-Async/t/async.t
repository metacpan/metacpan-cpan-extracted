#!/usr/bin/perl

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

start_server(PORT + 1);

## Look for 2 job servers, starting at port number PORT.
start_worker(PORT, 2);
start_worker(PORT, 2);

my $client = Gearman::Client::Async->new;
$client->set_job_servers('127.0.0.1:' . (PORT + 1), '127.0.0.1:' . PORT);

my $good = 0;
my $status;

$client->add_task( Gearman::Task->new( "sleep_for" => \ "2", {
    on_complete => sub {
        my $res = shift;
        $good++;
    },
    on_status => sub {
        $status .= '2';
    },
    on_retry => sub {
        print "RETRY: [@_]\n";
    },
    on_fail => sub {
        print "FAIL: [@_]\n";
    },
    retry_count => 5,
} ) );

$client->add_task( Gearman::Task->new( "sleep_for" => \ "1", {
    on_complete => sub {
        my $res = shift;
        $good++;
    },
    on_status => sub {
        $status .= '1';
    },
    on_retry => sub {
        print "RETRY: [@_]\n";
    },
    on_fail => sub {
        fail(join "/", @_);
        print "FAIL: [@_]\n";
    },
    retry_count => 5,
} ) );

Danga::Socket->AddTimer(3.0, sub {
    die "Timeout, test fails";
});

Danga::Socket->SetPostLoopCallback(sub {
    return $good < 2;
});

Danga::Socket->EventLoop();

like($status, qr/1212/, "alternating status");
is(length $status, 14, "12 status messages");




