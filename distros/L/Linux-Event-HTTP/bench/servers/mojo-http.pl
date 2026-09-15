#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Mojolicious;
use Mojo::Server::Daemon;

my $port = $ENV{BENCH_PORT} // die "BENCH_PORT is required\n";
my $response_bytes = $ENV{BENCH_RESPONSE_BYTES} // 32;
my $payload = 'x' x $response_bytes;

my $app = Mojolicious->new;
$app->log->level('fatal');
$app->routes->any('/bench')->to(cb => sub ($c) {
    my $body = $c->req->body;
    $c->res->headers->content_length(length $payload);
    $c->render(data => $payload, status => 200);
});

my $daemon = Mojo::Server::Daemon->new(
    app    => $app,
    listen => ["http://127.0.0.1:$port"],
);
$daemon->max_clients(10_000);
$daemon->max_requests(1_000_000);
$daemon->keep_alive_timeout(0);
$daemon->silent(1);
$daemon->run;
