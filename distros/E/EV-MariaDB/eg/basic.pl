#!/usr/bin/env perl
use strict;
use warnings;
use EV;
use EV::MariaDB;

my $m;
$m = EV::MariaDB->new(
    host     => $ENV{TEST_MARIADB_HOST} // '127.0.0.1',
    port     => $ENV{TEST_MARIADB_PORT} // 3306,
    user     => $ENV{TEST_MARIADB_USER} // 'root',
    password => $ENV{TEST_MARIADB_PASS} // '',
    database => $ENV{TEST_MARIADB_DB}   // 'test',
    ($ENV{TEST_MARIADB_SOCKET} ? (unix_socket => $ENV{TEST_MARIADB_SOCKET}) : ()),

    on_connect => sub {
        print "connected to ", $m->host_info, "\n";
        print "server: ", $m->server_info, "\n";
    },
    on_error => sub { die "connection error: $_[0]\n" },
);

# CREATE TABLE
$m->query("CREATE TEMPORARY TABLE eg_basic (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(50))", sub {
    my ($res, $err) = @_;
    die "create: $err\n" if $err;

    # INSERT
    $m->query("INSERT INTO eg_basic (name) VALUES ('alice'), ('bob'), ('charlie')", sub {
        my ($affected, $err) = @_;
        die "insert: $err\n" if $err;
        print "inserted $affected rows, last_id=", $m->insert_id, "\n";

        # SELECT
        $m->query("SELECT * FROM eg_basic", sub {
            my ($rows, $err) = @_;
            die "select: $err\n" if $err;
            for my $row (@$rows) {
                print join("\t", @$row), "\n";
            }
            EV::break;
        });
    });
});

EV::run;
