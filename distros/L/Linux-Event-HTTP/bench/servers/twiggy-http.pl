#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use AnyEvent;
use Twiggy::Server;

my $port = $ENV{BENCH_PORT} // die "BENCH_PORT is required\n";
my $response_bytes = $ENV{BENCH_RESPONSE_BYTES} // 32;
my $payload = 'x' x $response_bytes;

my $app = sub ($env) {
    if (($env->{CONTENT_LENGTH} // 0) > 0) {
        my $remaining = 0 + $env->{CONTENT_LENGTH};
        my $input = $env->{'psgi.input'};
        while ($remaining > 0) {
            my $buf = '';
            my $n = $input->read($buf, $remaining);
            last if !defined($n) || $n <= 0;
            $remaining -= $n;
        }
    }

    return [
        200,
        [
            'Content-Type'   => 'application/octet-stream',
            'Content-Length' => length($payload),
        ],
        [$payload],
    ];
};

my $server = Twiggy::Server->new(
    host => '127.0.0.1',
    port => 0 + $port,
);
$server->register_service($app);
AE::cv->recv;
