#!/usr/bin/env perl
use strict;
use warnings;
use EV::Memcached;

$| = 1;

# Atomic counters using INCR/DECR.
# These operate on raw uint64 values stored as decimal strings.

my $mc = EV::Memcached->new(
    host     => $ENV{MC_HOST} // '127.0.0.1',
    port     => $ENV{MC_PORT} // 11211,
    on_error => sub { warn "error: @_\n" },
);

# Set initial value as a string representation of a number
$mc->set('hits', '100', sub {
    my ($res, $err) = @_;
    die "SET failed: $err" if $err;
    print "Set hits = 100\n";

    # Increment by 1 (default delta)
    $mc->incr('hits', 1, sub {
        my ($val, $err) = @_;
        die "INCR failed: $err" if $err;
        print "After incr(1): hits = $val\n";

        # Increment by 10
        $mc->incr('hits', 10, sub {
            my ($val, $err) = @_;
            print "After incr(10): hits = $val\n";

            # Decrement by 5
            $mc->decr('hits', 5, sub {
                my ($val, $err) = @_;
                print "After decr(5): hits = $val\n";

                # Decrement below zero (memcached clamps to 0)
                $mc->decr('hits', 999, sub {
                    my ($val, $err) = @_;
                    print "After decr(999): hits = $val (clamped to 0)\n";

                    # INCR with auto-create: if key doesn't exist, create
                    # with the given initial value. Pass expiry=0xFFFFFFFF
                    # (the default when expiry is omitted) to disable
                    # auto-create — the call then errors with NOT_FOUND.
                    $mc->delete('new_counter', sub {
                        $mc->incr('new_counter', 1, 1000, 300, sub {
                            my ($val, $err) = @_;
                            if ($err) {
                                print "INCR new_counter: $err\n";
                            } else {
                                print "INCR auto-create: new_counter = $val\n";
                            }
                            $mc->disconnect;
                        });
                    });
                });
            });
        });
    });
});

EV::run;
