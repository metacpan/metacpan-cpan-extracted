#!/usr/bin/env perl
use strict;
use warnings;
use EV::Memcached;

$| = 1;

# Rate limiter using INCR with auto-create and expiry.
# Pattern: key = "rl:<client_id>:<window>", expiry = window size
# Each request increments the counter; if it exceeds the limit, reject.

my $mc = EV::Memcached->new(
    host     => $ENV{MC_HOST} // '127.0.0.1',
    port     => $ENV{MC_PORT} // 11211,
    on_error => sub { warn "error: @_\n" },
);

my $limit  = 5;       # max requests per window
my $window = 10;      # window size in seconds

sub check_rate {
    my ($client_id, $on_result) = @_;

    my $key = "rl:$client_id:" . int(time() / $window);

    # INCR with initial=1, expiry=$window
    # If key doesn't exist, creates it with value 1 and TTL
    # If key exists, increments and returns new count
    $mc->incr($key, 1, 1, $window, sub {
        my ($count, $err) = @_;
        if ($err) {
            # Shouldn't happen with auto-create
            warn "rate check failed: $err\n";
            $on_result->(1); # fail open
            return;
        }
        $on_result->($count <= $limit, $count);
    });
}

# Simulate 8 requests from the same client
my $remaining = 8;
for my $i (1..8) {
    check_rate("client_42", sub {
        my ($allowed, $count) = @_;
        printf "Request %d: %s (count=%d, limit=%d)\n",
            $i,
            $allowed ? "ALLOWED" : "REJECTED",
            $count, $limit;

        if (--$remaining == 0) {
            $mc->disconnect;
        }
    });
}

EV::run;
