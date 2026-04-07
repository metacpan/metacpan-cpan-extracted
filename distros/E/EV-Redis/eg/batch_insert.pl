#!/usr/bin/env perl
use strict;
use warnings;
use EV::Redis;

$| = 1;

# Batch insert with flow control: limit in-flight commands to avoid
# memory buildup when inserting millions of keys.
my $redis = EV::Redis->new(
    host        => '127.0.0.1',
    max_pending => 100,
    on_error    => sub { warn "Error: @_\n" },
);

my $total   = 10_000;
my $done    = 0;
my $errors  = 0;
my $t0      = EV::now;

for my $i (1..$total) {
    $redis->hset("user:$i", 'name', "user_$i", 'score', int(rand 1000), sub {
        my ($res, $err) = @_;
        $errors++ if $err;
        if (++$done == $total) {
            my $elapsed = EV::now - $t0;
            printf "Inserted %d records in %.2fs (%.0f/s), %d errors\n",
                $total, $elapsed, $total / $elapsed, $errors;
            $redis->disconnect;
        }
    });
}

printf "Queued %d inserts (pending=%d waiting=%d)\n",
    $total, $redis->pending_count, $redis->waiting_count;

EV::run;
