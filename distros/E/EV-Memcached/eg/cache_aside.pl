#!/usr/bin/env perl
use strict;
use warnings;
use EV::Memcached;

$| = 1;

# Cache-aside pattern: check cache first, on miss compute and store.
# This is the most common caching pattern in web applications.

my $mc = EV::Memcached->new(
    host     => $ENV{MC_HOST} // '127.0.0.1',
    port     => $ENV{MC_PORT} // 11211,
    on_error => sub { warn "error: @_\n" },
);

# Simulated slow data source (database, API, etc.)
sub fetch_from_source {
    my ($key, $cb) = @_;
    # Simulate async work with a timer
    my $w; $w = EV::timer 0.1, 0, sub {
        undef $w;
        $cb->("computed_value_for_$key");
    };
}

sub cached_get {
    my ($key, $ttl, $cb) = @_;

    $mc->get($key, sub {
        my ($val, $err) = @_;

        if (defined $val) {
            # Cache hit
            $cb->($val, 'hit');
            return;
        }

        # Cache miss — fetch from source and populate cache
        fetch_from_source($key, sub {
            my ($data) = @_;

            # Store in cache with TTL, fire-and-forget
            $mc->set($key, $data, $ttl);

            $cb->($data, 'miss');
        });
    });
}

# Demo: first call is a miss, second is a hit
cached_get("user:1001:profile", 300, sub {
    my ($val, $status) = @_;
    printf "1st fetch: %s (%s)\n", $val, $status;

    cached_get("user:1001:profile", 300, sub {
        my ($val, $status) = @_;
        printf "2nd fetch: %s (%s)\n", $val, $status;

        # Different key — another miss
        cached_get("user:1002:profile", 300, sub {
            my ($val, $status) = @_;
            printf "3rd fetch: %s (%s)\n", $val, $status;

            $mc->disconnect;
        });
    });
});

EV::run;
