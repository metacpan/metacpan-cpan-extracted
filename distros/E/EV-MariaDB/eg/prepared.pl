#!/usr/bin/env perl
use strict;
use warnings;
use EV;
use EV::MariaDB;

my $m = EV::MariaDB->new(
    host     => $ENV{TEST_MARIADB_HOST} // '127.0.0.1',
    port     => $ENV{TEST_MARIADB_PORT} // 3306,
    user     => $ENV{TEST_MARIADB_USER} // 'root',
    password => $ENV{TEST_MARIADB_PASS} // '',
    database => $ENV{TEST_MARIADB_DB}   // 'test',
    ($ENV{TEST_MARIADB_SOCKET} ? (unix_socket => $ENV{TEST_MARIADB_SOCKET}) : ()),
    on_connect => sub { print "connected\n" },
    on_error   => sub { die "connection error: $_[0]\n" },
);

$m->query("CREATE TEMPORARY TABLE eg_prep (id INT PRIMARY KEY, val VARCHAR(50))", sub {
    die "create: $_[1]\n" if $_[1];

    $m->prepare("INSERT INTO eg_prep (id, val) VALUES (?, ?)", sub {
        my ($ins, $err) = @_;
        die "prepare insert: $err\n" if $err;

        # chain executes sequentially (prepared stmts don't pipeline)
        my @data = ([1, 'hello'], [2, 'world'], [3, undef]);
        my $next;
        $next = sub {
            my $params = shift @data;
            unless ($params) {
                # all inserts done — now query with a prepared SELECT
                $m->prepare("SELECT * FROM eg_prep WHERE id >= ?", sub {
                    my ($sel, $err) = @_;
                    die "prepare select: $err\n" if $err;

                    $m->execute($sel, [2], sub {
                        my ($rows, $err) = @_;
                        die "execute select: $err\n" if $err;
                        for my $row (@$rows) {
                            printf "%d\t%s\n", $row->[0], $row->[1] // 'NULL';
                        }
                        $m->close_stmt($sel, sub {
                            $m->close_stmt($ins, sub { EV::break });
                        });
                    });
                });
                return;
            }
            $m->execute($ins, $params, sub {
                die "execute insert: $_[1]\n" if $_[1];
                $next->();
            });
        };
        $next->();
    });
});

EV::run;
