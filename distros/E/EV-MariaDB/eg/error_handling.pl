#!/usr/bin/env perl
use strict;
use warnings;
use EV;
use EV::MariaDB;

my $errors_seen = 0;

my $m = EV::MariaDB->new(
    host            => $ENV{TEST_MARIADB_HOST} // '127.0.0.1',
    port            => $ENV{TEST_MARIADB_PORT} // 3306,
    user            => $ENV{TEST_MARIADB_USER} // 'root',
    password        => $ENV{TEST_MARIADB_PASS} // '',
    database        => $ENV{TEST_MARIADB_DB}   // 'test',
    connect_timeout => 5,
    read_timeout    => 10,
    ($ENV{TEST_MARIADB_SOCKET} ? (unix_socket => $ENV{TEST_MARIADB_SOCKET}) : ()),

    on_connect => sub { print "connected\n" },
    on_error   => sub {
        # connection-level errors arrive here
        warn "on_error: $_[0]\n";
        $errors_seen++;
    },
);

# 1. query-level error (bad SQL) — delivered via callback
$m->query("SELECT * FROM nonexistent_table_xyzzy", sub {
    my ($res, $err) = @_;
    if ($err) {
        print "query error (expected): $err\n";
        print "  errno: ", $m->error_number, "\n";
        print "  sqlstate: ", $m->sqlstate, "\n";
    }

    # 2. valid query still works after an error
    $m->query("SELECT 1 AS ok", sub {
        my ($rows, $err) = @_;
        die "recovery query failed: $err\n" if $err;
        print "recovery query: ok=", $rows->[0][0], "\n";

        # 3. reset_connection clears session state
        $m->reset_connection(sub {
            my ($ok, $err) = @_;
            die "reset_connection: $err\n" if $err;
            print "reset_connection: success\n";
            EV::break;
        });
    });
});

EV::run;
