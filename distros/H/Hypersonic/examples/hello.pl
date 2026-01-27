#!/usr/bin/env perl
use strict;
use warnings;

use lib 'lib';
use lib '../XS-JIT/blib/lib';
use lib '../XS-JIT/blib/arch';

use Hypersonic;

my $server = Hypersonic->new();

# Static routes only - for benchmarking pure C performance
$server->get('/api/hello' => sub { '{"message":"Hello, World!"}' });
$server->get('/health' => sub { 'OK' });

$server->compile();
$server->run(port => 8080, workers => 4);
