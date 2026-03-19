#!/usr/bin/env perl
# Per-query and connection-level settings example
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $ch = EV::ClickHouse->new(
    host     => $ENV{CLICKHOUSE_HOST} // '127.0.0.1',
    port     => $ENV{CLICKHOUSE_PORT} // 8123,
    settings => { max_threads => 2 },   # connection-level defaults
    on_connect => sub {
        print "Connected (connection default: max_threads=2)\n";
    },
    on_error => sub { warn "Error: $_[0]\n"; EV::break },
);

# 1) Show connection-level setting
$ch->query("SELECT name, value FROM system.settings WHERE name='max_threads' FORMAT TabSeparated", sub {
    my ($rows, $err) = @_;
    die "query error: $err\n" if $err;
    printf "  connection default: %s = %s\n", $rows->[0][0], $rows->[0][1];

    # 2) Override per-query
    $ch->query(
        "SELECT name, value FROM system.settings WHERE name='max_threads' FORMAT TabSeparated",
        { max_threads => 3 },
        sub {
            my ($rows2, $err2) = @_;
            die "query error: $err2\n" if $err2;
            printf "  per-query override: %s = %s\n", $rows2->[0][0], $rows2->[0][1];

            # 3) query_id example
            $ch->query(
                "SELECT 42 AS answer FORMAT TabSeparated",
                { query_id => 'my-custom-query-id-001' },
                sub {
                    my ($rows3, $err3) = @_;
                    die "query error: $err3\n" if $err3;
                    printf "  query with custom query_id: answer = %s\n", $rows3->[0][0];
                    EV::break;
                },
            );
        },
    );
});

EV::run;
