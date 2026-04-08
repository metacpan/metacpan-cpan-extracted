#!/usr/bin/env perl
use strict;
use warnings;
use EV::Memcached;

$| = 1;

# Pipeline: send many commands without waiting for replies.
# The binary protocol and EV IO handle batching automatically.

my $mc = EV::Memcached->new(
    host     => $ENV{MC_HOST} // '127.0.0.1',
    port     => $ENV{MC_PORT} // 11211,
    on_error => sub { warn "error: @_\n" },
);

my $total = 1000;
my $done  = 0;
my $t0    = EV::now;

for my $i (1..$total) {
    $mc->set("pipeline:$i", "value-$i", sub {
        my ($res, $err) = @_;
        warn "SET pipeline:$i failed: $err\n" if $err;
        if (++$done == $total) {
            my $elapsed = EV::now - $t0;
            printf "Pipelined %d SETs in %.3fs (%.0f ops/s)\n",
                $total, $elapsed, $total / $elapsed;

            # Verify a few
            $mc->get("pipeline:1", sub {
                my ($val) = @_;
                print "pipeline:1 = $val\n";

                $mc->get("pipeline:$total", sub {
                    my ($val) = @_;
                    print "pipeline:$total = $val\n";
                    $mc->disconnect;
                });
            });
        }
    });
}

EV::run;
