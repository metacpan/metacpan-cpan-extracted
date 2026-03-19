#!/usr/bin/env perl
# Native protocol with LZ4 compression and INSERT
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $ch = EV::ClickHouse->new(
    host     => $ENV{CLICKHOUSE_HOST} // '127.0.0.1',
    port     => $ENV{CLICKHOUSE_NATIVE_PORT} // 9000,
    protocol => 'native',
    compress => 1,
    on_connect => sub {
        print "Connected (native + LZ4)\n";
    },
    on_error => sub { warn "Connection error: $_[0]\n"; EV::break },
);

$ch->query("CREATE TEMPORARY TABLE eg_events (ts DateTime, level String, msg String)", sub {
    my (undef, $err) = @_;
    die "DDL failed: $err" if $err;

    my $data = join "\n",
        "2025-01-15 10:00:00\tINFO\tService started",
        "2025-01-15 10:00:01\tWARN\tHigh memory usage",
        "2025-01-15 10:00:02\tERROR\tConnection refused",
        "";

    $ch->insert("eg_events", $data, sub {
        my (undef, $err) = @_;
        die "Insert failed: $err" if $err;
        print "Inserted 3 events (LZ4 compressed)\n";

        $ch->query("SELECT * FROM eg_events ORDER BY ts", sub {
            my ($rows, $err) = @_;
            die "Select failed: $err" if $err;
            printf "  [%s] %s: %s\n", @$_ for @$rows;
            EV::break;
        });
    });
});

EV::run;
