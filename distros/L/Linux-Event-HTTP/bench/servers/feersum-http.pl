#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Feersum::Runner;

my $port = $ENV{BENCH_PORT} // die "BENCH_PORT is required\n";
my $response_bytes = $ENV{BENCH_RESPONSE_BYTES} // 32;
my $payload = 'x' x $response_bytes;

my $runner = Feersum::Runner->new(
    listen              => ["127.0.0.1:$port"],
    pre_fork            => 0,
    keepalive           => 1,
    max_connection_reqs => 0,
    quiet               => 1,
);

$runner->run(sub ($request) {
    $request->send_response(
        200,
        ['Content-Type' => 'application/octet-stream'],
        \$payload,
    );
    return;
});
