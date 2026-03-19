#!/usr/bin/env perl
# Queued queries — fire many queries, callbacks arrive in order
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $ch = EV::ClickHouse->new(
    host     => $ENV{CLICKHOUSE_HOST} // '127.0.0.1',
    port     => $ENV{CLICKHOUSE_PORT} // 8123,
    on_error => sub { warn "Connection error: $_[0]\n"; EV::break },
);

my $remaining = 20;

for my $i (1 .. $remaining) {
    $ch->q("SELECT $i AS n, $i * $i AS square FORMAT TabSeparated", sub {
        my ($rows, $err) = @_;
        if ($err) {
            warn "Query $i error: $err\n";
        } else {
            printf "query %2d: n=%-3s square=%s\n", $i, $rows->[0][0], $rows->[0][1];
        }
        EV::break if --$remaining == 0;
    });
}

printf "Queued %d queries (pending_count=%d)\n", 20, $ch->pending_count;
EV::run;
