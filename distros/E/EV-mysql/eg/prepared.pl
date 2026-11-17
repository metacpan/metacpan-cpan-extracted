#!/usr/bin/env perl
use strict;
use warnings;
use EV;
use EV::mysql;

my $m = EV::mysql->new(
    host     => $ENV{TEST_MYSQL_HOST} // '127.0.0.1',
    port     => $ENV{TEST_MYSQL_PORT} // 3306,
    user     => $ENV{TEST_MYSQL_USER} // 'root',
    password => $ENV{TEST_MYSQL_PASS} // '',
    database => $ENV{TEST_MYSQL_DB}   // 'test',
    ($ENV{TEST_MYSQL_SOCKET} ? (unix_socket => $ENV{TEST_MYSQL_SOCKET}) : ()),
    on_connect => sub { print "connected\n" },
    on_error   => sub { die "connection error: $_[0]\n" },
);

$m->query("create temporary table eg_prep (id int primary key, val varchar(50))", sub {
    die "create: $_[1]\n" if $_[1];

    $m->prepare("insert into eg_prep (id, val) values (?, ?)", sub {
        my ($ins, $err) = @_;
        die "prepare insert: $err\n" if $err;

        # queue executions in FIFO order (parameters are snapshotted per execute)
        for my $params ([1, 'hello'], [2, 'world'], [3, undef]) {
            $m->execute($ins, $params, sub {
                die "execute insert: $_[1]\n" if $_[1];
            });
        }

        $m->prepare("select id, val from eg_prep where id >= ? order by id", sub {
            my ($sel, $err) = @_;
            die "prepare select: $err\n" if $err;

            $m->execute($sel, [2], sub {
                my ($rows, $err) = @_;
                die "execute select: $err\n" if $err;
                for my $row (@$rows) {
                    printf "%d\t%s\n", $row->[0], $row->[1] // 'NULL';
                }
                $m->close_stmt($sel, sub {});
                $m->close_stmt($ins, sub {});
                $m->close_async(sub { EV::break });
            });
        });
    });
});

EV::run;
