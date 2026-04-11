#!/usr/bin/env perl
# Demonstrate high concurrency: resolve many names simultaneously
# Usage: perl eg/parallel.pl [count]
use strict;
use warnings;
use EV;
use EV::cares qw(:status);
use Time::HiRes ();

my $count = shift || 100;

# generate synthetic hostnames to resolve
my @domains = map { "host-$_.example.com" } 1 .. $count;

# also add some real ones at the end to see actual results
push @domains, qw(
    google.com amazon.com facebook.com twitter.com github.com
    stackoverflow.com wikipedia.org reddit.com netflix.com apple.com
);

my $r = EV::cares->new(
    timeout => 3,
    tries   => 1,
);

my $pending = 0;
my ($ok, $fail) = (0, 0);
my $t0 = Time::HiRes::time();

for my $name (@domains) {
    $pending++;
    $r->resolve($name, sub {
        my ($status, @addrs) = @_;
        if ($status == ARES_SUCCESS) {
            $ok++;
            printf "%s => %s\n", $name, $addrs[0] if @addrs;
        } else {
            $fail++;
        }
        EV::break unless --$pending;
    });
}

printf "fired %d queries...\n", $pending;
EV::run;

my $elapsed = Time::HiRes::time() - $t0;
printf "--- %d ok, %d failed, %.3fs (%.0f queries/s)\n",
    $ok, $fail, $elapsed, ($ok + $fail) / ($elapsed || 1);
