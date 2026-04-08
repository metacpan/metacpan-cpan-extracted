#!/usr/bin/env perl
use strict;
use warnings;
use EV::Memcached;

$| = 1;

# Flow control: limit concurrent commands to avoid overwhelming
# the server when doing large batch operations.

my $mc = EV::Memcached->new(
    host            => $ENV{MC_HOST} // '127.0.0.1',
    port            => $ENV{MC_PORT} // 11211,
    max_pending     => 50,      # max 50 in-flight commands
    waiting_timeout => 10000,   # cancel queued commands after 10s
    on_error        => sub { warn "Error: @_\n" },
);

my $total   = 500;
my $done    = 0;
my $errors  = 0;
my $max_wait = 0;

for my $i (1..$total) {
    $mc->set("fc:$i", "value-$i", sub {
        my ($res, $err) = @_;
        $errors++ if $err;
        if (++$done == $total) {
            printf "Done: %d/%d succeeded (%d errors)\n",
                $total - $errors, $total, $errors;
            printf "Max waiting queue depth: %d\n", $max_wait;
            $mc->disconnect;
        }
    });

    my $w = $mc->waiting_count;
    $max_wait = $w if $w > $max_wait;
}

printf "Queued %d commands (pending=%d, waiting=%d)\n",
    $total, $mc->pending_count, $mc->waiting_count;

EV::run;
