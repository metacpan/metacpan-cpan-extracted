#!/usr/bin/env perl
# Error handling — structured error codes and auto-reconnect with backoff
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $ch;
$ch = EV::ClickHouse->new(
    host              => $ENV{CLICKHOUSE_HOST} // '127.0.0.1',
    port              => $ENV{CLICKHOUSE_NATIVE_PORT} // 9000,
    protocol          => 'native',
    auto_reconnect    => 1,
    reconnect_delay   => 0.5,    # start at 500ms
    reconnect_max_delay => 10,   # cap at 10s
    on_connect => sub {
        printf "Connected: %s\n", $ch->server_info;

        # Query a non-existent table
        $ch->query("SELECT * FROM _no_such_table_xyz", sub {
            my ($rows, $err) = @_;
            if ($err) {
                printf "Error: %s\n", $err;
                printf "Error code: %d\n", $ch->last_error_code;

                # Distinguish error types
                my $code = $ch->last_error_code;
                if ($code == 60) {
                    print "  -> UNKNOWN_TABLE (permanent, don't retry)\n";
                } elsif ($code == 202) {
                    print "  -> TOO_MANY_SIMULTANEOUS_QUERIES (retryable)\n";
                }
            }
            EV::break;
        });
    },
    on_error => sub {
        warn "Connection error: $_[0]\n";
        # auto_reconnect will retry with exponential backoff
    },
    on_disconnect => sub {
        print "Disconnected\n";
    },
);

EV::run;
