#!/usr/bin/env perl
use strict;
use warnings;
use EV::Memcached;

$| = 1;

# Distributed lock using ADD (atomic: succeeds only if key doesn't exist).
# Lock has a TTL to prevent deadlocks if the holder crashes.

my $mc = EV::Memcached->new(
    host     => $ENV{MC_HOST} // '127.0.0.1',
    port     => $ENV{MC_PORT} // 11211,
    on_error => sub { warn "error: @_\n" },
);

my $lock_ttl = 10; # seconds

sub acquire_lock {
    my ($name, $cb) = @_;
    my $key = "lock:$name";

    # ADD fails if key exists — atomic lock acquire
    $mc->add($key, $$, $lock_ttl, sub {
        my ($res, $err) = @_;
        $cb->(!$err);
    });
}

sub release_lock {
    my ($name, $cb) = @_;
    $mc->delete("lock:$name", sub {
        my ($res, $err) = @_;
        $cb->(!$err);
    });
}

# Demo: two attempts to acquire the same lock
acquire_lock("deploy", sub {
    my ($acquired) = @_;
    printf "Attempt 1: %s\n", $acquired ? "LOCKED" : "FAILED";

    # Second attempt should fail (lock held)
    acquire_lock("deploy", sub {
        my ($acquired) = @_;
        printf "Attempt 2: %s (expected fail)\n",
            $acquired ? "LOCKED" : "FAILED";

        # Release and try again
        release_lock("deploy", sub {
            my ($ok) = @_;
            printf "Release: %s\n", $ok ? "OK" : "FAILED";

            acquire_lock("deploy", sub {
                my ($acquired) = @_;
                printf "Attempt 3: %s (expected success)\n",
                    $acquired ? "LOCKED" : "FAILED";

                release_lock("deploy", sub {
                    $mc->disconnect;
                });
            });
        });
    });
});

EV::run;
