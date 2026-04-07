#!/usr/bin/env perl
use strict;
use warnings;
use EV::Redis;

$| = 1;

# Flow control: limit concurrent commands to avoid overwhelming Redis
# when processing large workloads.
my $redis = EV::Redis->new(
    host            => '127.0.0.1',
    max_pending     => 50,      # max 50 in-flight commands
    waiting_timeout => 10000,   # cancel queued commands after 10s
    on_error        => sub { warn "Error: @_\n" },
);

my $total   = 500;
my $done    = 0;
my $errors  = 0;

for my $i (1..$total) {
    $redis->set("fc:$i", "v$i", sub {
        my ($res, $err) = @_;
        $errors++ if $err;
        if (++$done == $total) {
            printf "Done: %d/%d succeeded (%d errors)\n",
                $total - $errors, $total, $errors;
            printf "pending=%d waiting=%d\n",
                $redis->pending_count, $redis->waiting_count;
            $redis->disconnect;
        }
    });
}

printf "Queued %d commands (pending=%d, waiting=%d)\n",
    $total, $redis->pending_count, $redis->waiting_count;

EV::run;
