#!/usr/bin/env perl
use strict;
use warnings;
use EV::Redis;

my $redis = EV::Redis->new(
    host     => '127.0.0.1',
    on_error => sub { warn "Redis error: @_\n" },
);

# Pipeline: send many commands without waiting for replies.
# Hiredis batches them over the wire automatically.
my $total = 1000;
my $done  = 0;
my $t0    = EV::now;

for my $i (1..$total) {
    $redis->set("bench:$i", "value-$i", sub {
        my ($res, $err) = @_;
        warn "SET bench:$i failed: $err\n" if $err;
        if (++$done == $total) {
            my $elapsed = EV::now - $t0;
            printf "Pipelined %d SETs in %.3fs (%.0f ops/s)\n",
                $total, $elapsed, $total / $elapsed;
            # cleanup
            $redis->del("bench:$_") for 1..$total;
            my $w; $w = EV::timer 0.1, 0, sub {
                undef $w;
                $redis->disconnect;
            };
        }
    });
}

EV::run;
