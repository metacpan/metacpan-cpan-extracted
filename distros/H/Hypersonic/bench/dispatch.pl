#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use lib '../XS-JIT/blib/lib';
use lib '../XS-JIT/blib/arch';

use Hypersonic;
use Time::HiRes qw(time);

# Create server with some routes
my $server = Hypersonic->new(cache_dir => '_bench_cache');

$server->get('/api/hello' => sub { '{"message":"Hello, World!"}' });
$server->get('/health' => sub { 'OK' });
$server->get('/api/users' => sub { '[{"id":1,"name":"Alice"},{"id":2,"name":"Bob"}]' });
$server->post('/api/data' => sub { '{"status":"created"}' });

print "Compiling routes...\n";
$server->compile();
print "Done.\n\n";

# Pre-create request arrays (simulating parsed HTTP requests)
my @requests = (
    ['GET', '/api/hello', '', 1, 0],
    ['GET', '/health', '', 1, 0],
    ['GET', '/api/users', '', 1, 0],
    ['POST', '/api/data', '{}', 1, 0],
    ['GET', '/not-found', '', 1, 0],  # 404 case
);

# Warm up
for (1..1000) {
    for my $req (@requests) {
        $server->dispatch($req);
    }
}

# Benchmark
my $iterations = 1_000_000;
print "Benchmarking $iterations dispatch calls...\n\n";

for my $req (@requests) {
    my $method = $req->[0];
    my $path = $req->[1];

    my $start = time();
    for (1..$iterations) {
        $server->dispatch($req);
    }
    my $elapsed = time() - $start;

    my $rate = $iterations / $elapsed;
    printf "%-6s %-15s  %10.0f req/sec  (%.3f sec)\n",
           $method, $path, $rate, $elapsed;
}

print "\n";

# Mixed workload benchmark
print "Mixed workload (all routes)...\n";
my $total_reqs = $iterations * scalar(@requests);
my $start = time();
for (1..$iterations) {
    for my $req (@requests) {
        $server->dispatch($req);
    }
}
my $elapsed = time() - $start;
my $rate = $total_reqs / $elapsed;
printf "Total: %d requests in %.3f sec = %.0f req/sec\n", $total_reqs, $elapsed, $rate;
