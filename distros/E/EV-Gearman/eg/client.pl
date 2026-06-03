#!/usr/bin/perl
# Submit one foreground job and print the result.
# Usage: client.pl [host:port] [func] [workload]
use strict;
use warnings;
use EV;
use EV::Gearman;

my $addr = shift // '127.0.0.1:4730';
my $func = shift // 'reverse';
my $load = shift // "Hello, world";
my ($host, $port) = split /:/, $addr;
$port //= 4730;

my $g = EV::Gearman->new(host => $host, port => $port);

$g->submit_job($func, $load, sub {
    my ($result, $err) = @_;
    if ($err) { warn "job failed: $err\n" }
    else      { print "result: $result\n" }
    EV::break;
});

EV::run;
