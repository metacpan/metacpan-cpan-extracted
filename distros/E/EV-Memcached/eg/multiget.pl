#!/usr/bin/env perl
use strict;
use warnings;
use EV::Memcached;

$| = 1;

# Multi-get: efficiently fetch many keys at once using
# GETKQ (quiet get-with-key) + NOOP fence.
# Only cache hits generate responses, reducing network traffic.

my $mc = EV::Memcached->new(
    host     => $ENV{MC_HOST} // '127.0.0.1',
    port     => $ENV{MC_PORT} // 11211,
    on_error => sub { warn "error: @_\n" },
);

# Populate some keys
my @keys = map { "item:$_" } 1..10;
my $remaining = 5;

for my $i (1, 3, 5, 7, 9) {  # only set odd-numbered keys
    $mc->set("item:$i", "data for item $i", sub {
        if (--$remaining == 0) {
            do_mget();
        }
    });
}

sub do_mget {
    print "Fetching 10 keys (5 exist, 5 missing)...\n\n";

    $mc->mget(\@keys, sub {
        my ($results, $err) = @_;
        die "MGET failed: $err" if $err;

        for my $key (@keys) {
            if (exists $results->{$key}) {
                printf "  %-10s => %s\n", $key, $results->{$key};
            } else {
                printf "  %-10s => (miss)\n", $key;
            }
        }

        printf "\n%d hits, %d misses\n",
            scalar(keys %$results), 10 - scalar(keys %$results);

        $mc->disconnect;
    });
}

EV::run;
