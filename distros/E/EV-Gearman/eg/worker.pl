#!/usr/bin/perl
# Run a worker that registers `reverse` and `upper` and serves forever.
# Usage: worker.pl [host:port]
use strict;
use warnings;
use EV;
use EV::Gearman;

my $addr = shift // '127.0.0.1:4730';
my ($host, $port) = split /:/, $addr;
$port //= 4730;

my $g = EV::Gearman->new(
    host       => $host,
    port       => $port,
    client_id  => "worker-$$",
    reconnect  => 1,
    on_error   => sub { warn "[worker $$] @_\n" },
    on_connect => sub { warn "[worker $$] connected\n" },
);

$g->register_function(reverse => sub {
    my $job = shift;
    return scalar reverse $job->workload;
});

$g->register_function(upper => sub {
    my $job = shift;
    return uc $job->workload;
});

$g->work(sub { warn "[worker $$] idle\n" });
EV::run;
