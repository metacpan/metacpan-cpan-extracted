#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Linux::Event::Loop;
use Linux::Event::HTTP::Server::Connection;
use Linux::Event::HTTP::Server;

my $port = $ENV{BENCH_PORT} // die "BENCH_PORT is required\n";
my $response_bytes = $ENV{BENCH_RESPONSE_BYTES} // 32;
my $mode = $ENV{BENCH_LINUXEVENT_MODE} // 'natural';
our $READ_BUDGET_BYTES = 0 + ($ENV{BENCH_READ_BUDGET_BYTES} // 0);
my $payload = 'x' x $response_bytes;

{
    package Linux::Event::HTTP::Bench::NaturalCompareConnection;
    use parent 'Linux::Event::HTTP::Server::Connection';

    sub stream_tuning ($class) {
        return read_budget_bytes => $main::READ_BUDGET_BYTES;
    }

    sub on_request ($self, $request, $response) {
        $response->body($self->data->{payload});
        return;
    }
}

{
    package Linux::Event::HTTP::Bench::RequestEndCompareConnection;
    use parent 'Linux::Event::HTTP::Server::Connection';

    sub stream_tuning ($class) {
        return read_budget_bytes => $main::READ_BUDGET_BYTES;
    }

    sub on_request ($self, $request, $response) {
        return;
    }

    sub on_request_end ($self, $request, $response) {
        $response->body($self->data->{payload});
        return;
    }
}

my $connection_class = $mode eq 'natural'
    ? 'Linux::Event::HTTP::Bench::NaturalCompareConnection'
    : $mode eq 'request-end'
        ? 'Linux::Event::HTTP::Bench::RequestEndCompareConnection'
        : die "unknown BENCH_LINUXEVENT_MODE: $mode\n";

my $loop = Linux::Event::Loop->new;
my $server = Linux::Event::HTTP::Server->new(
    loop             => $loop,
    host             => '127.0.0.1',
    port             => 0 + $port,
    data             => { payload => $payload },
    connection_class => $connection_class,
);

$loop->run;
