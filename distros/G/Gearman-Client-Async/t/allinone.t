#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use Test::More;

$ENV{PERL5LIB} .= ":$Bin/../../Gearman/lib";
use lib "$Bin/../../Gearman/lib";
use lib "$Bin/../../../../server/lib";

use Gearman::Server;
use Gearman::Client::Async;

my $server = Gearman::Server->new();
$server->start_worker('t/worker.pl');

my $client = Gearman::Client::Async->new(job_servers => [ $server ]);

my $good = 0;
my $status;

plan tests => 2;

Danga::Socket->AddTimer(0, sub {
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
});

Danga::Socket->AddTimer(4.0, sub {
     die "Timeout, test fails";
});

Danga::Socket->SetPostLoopCallback(sub {
    if ($good >= 2) {
        pass("Got both responses");
        return 0;
    }
    return 1;
});

Danga::Socket->EventLoop();

is(length $status, 14, "12 status messages");

# vim: filetype=perl
