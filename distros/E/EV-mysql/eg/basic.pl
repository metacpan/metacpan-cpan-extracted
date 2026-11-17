#!/usr/bin/env perl
use strict;
use warnings;
use EV;
use EV::mysql;

my $m;
$m = EV::mysql->new(
    host     => $ENV{TEST_MYSQL_HOST} // '127.0.0.1',
    port     => $ENV{TEST_MYSQL_PORT} // 3306,
    user     => $ENV{TEST_MYSQL_USER} // 'root',
    password => $ENV{TEST_MYSQL_PASS} // '',
    database => $ENV{TEST_MYSQL_DB}   // 'test',
    utf8     => 1,
    ($ENV{TEST_MYSQL_SOCKET} ? (unix_socket => $ENV{TEST_MYSQL_SOCKET}) : ()),

    on_connect => sub {
        print "connected to ", $m->host_info, "\n";
        print "server: ", $m->server_info, "\n";
    },
    on_error => sub { die "connection error: $_[0]\n" },
);

$m->query("create temporary table eg_basic (id int auto_increment primary key, name varchar(50))", sub {
    my ($res, $err) = @_;
    die "create: $err\n" if $err;

    $m->query("insert into eg_basic (name) values ('alice'), ('bob'), (null)", sub {
        my ($affected, $err) = @_;
        die "insert: $err\n" if $err;
        print "inserted $affected rows, last_id=", $m->insert_id, "\n";

        $m->query("select id, name from eg_basic order by id", sub {
            my ($rows, $err, $fields) = @_;
            die "select: $err\n" if $err;
            print join("\t", @$fields), "\n";
            for my $row (@$rows) {
                print join("\t", map { $_ // 'NULL' } @$row), "\n";
            }
            $m->close_async(sub { EV::break });
        });
    });
});

EV::run;
