#!/usr/bin/env perl
# Native TCP protocol with typed data and progress tracking
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $ch = EV::ClickHouse->new(
    host     => $ENV{CLICKHOUSE_HOST} // '127.0.0.1',
    port     => $ENV{CLICKHOUSE_NATIVE_PORT} // 9000,
    protocol => 'native',
    on_connect => sub {
        print "Connected via native protocol\n";
    },
    on_progress => sub {
        my ($rows, $bytes, $total_rows, $written_rows, $written_bytes) = @_;
        printf "  progress: %d rows, %d bytes, %d total\n",
            $rows, $bytes, $total_rows if $rows;
    },
    on_error => sub { warn "Connection error: $_[0]\n"; EV::break },
);

# Native protocol returns typed data (not strings like HTTP/TabSeparated)
$ch->query("SELECT toUInt32(42) AS answer, 'hello' AS greeting, toFloat64(3.14) AS pi", sub {
    my ($rows, $err) = @_;
    if ($err) {
        warn "Query error: $err\n";
    } else {
        for my $row (@$rows) {
            printf "answer=%s greeting=%s pi=%s\n", @$row;
        }
    }
    EV::break;
});

EV::run;
