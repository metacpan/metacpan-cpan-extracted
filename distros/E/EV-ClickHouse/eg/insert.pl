#!/usr/bin/env perl
# HTTP insert with session (DDL + insert + select in same session)
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $ch = EV::ClickHouse->new(
    host       => $ENV{CLICKHOUSE_HOST} // $ENV{TEST_CLICKHOUSE_HOST} // '127.0.0.1',
    port       => $ENV{CLICKHOUSE_PORT} // $ENV{TEST_CLICKHOUSE_PORT} // 8123,
    session_id => "example_$$",
    on_connect => sub {
        print "Connected (session example_$$)\n";
    },
    on_error => sub { warn "Connection error: $_[0]\n"; EV::break },
);

# Create a temporary table
$ch->query("create temporary table eg_users (id UInt32, name String)", sub {
    my (undef, $err) = @_;
    die "DDL failed: $err" if $err;
    print "Table created\n";

    # Insert rows (TabSeparated: columns separated by \t, rows by \n)
    my $data = join "\n",
        "1\tAlice",
        "2\tBob",
        "3\tCharlie",
        "";  # trailing newline

    $ch->insert("eg_users", $data, sub {
        my (undef, $err) = @_;
        die "Insert failed: $err" if $err;
        print "Inserted 3 rows\n";

        # Read them back
        $ch->query("select id, name from eg_users order by id format TabSeparated", sub {
            my ($rows, $err) = @_;
            die "Select failed: $err" if $err;
            printf "  %s: %s\n", $_->[0], $_->[1] for @$rows;
            EV::break;
        });
    });
});

EV::run;
