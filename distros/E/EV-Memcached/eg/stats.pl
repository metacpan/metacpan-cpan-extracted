#!/usr/bin/env perl
use strict;
use warnings;
use EV::Memcached;

$| = 1;

# Fetch and display server statistics.

my $mc = EV::Memcached->new(
    host     => $ENV{MC_HOST} // '127.0.0.1',
    port     => $ENV{MC_PORT} // 11211,
    on_error => sub { die "error: @_\n" },
);

# General stats
$mc->stats(sub {
    my ($stats, $err) = @_;
    die "STATS failed: $err" if $err;

    print "=== General Stats ===\n";
    my @interesting = qw(
        pid version uptime curr_connections total_connections
        cmd_get cmd_set get_hits get_misses
        bytes curr_items total_items evictions
        bytes_read bytes_written
    );
    for my $key (@interesting) {
        printf "  %-25s %s\n", $key, $stats->{$key} // 'N/A';
    }

    # Calculate hit rate
    my $hits = $stats->{get_hits} // 0;
    my $misses = $stats->{get_misses} // 0;
    my $total = $hits + $misses;
    if ($total > 0) {
        printf "\n  Hit rate: %.1f%% (%d/%d)\n",
            100 * $hits / $total, $hits, $total;
    }

    print "\n";
    $mc->disconnect;
});

EV::run;
