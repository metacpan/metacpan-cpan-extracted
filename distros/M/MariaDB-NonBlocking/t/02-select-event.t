#!perl
use v5.10.1;
use strict;
use warnings;
no warnings 'once';

use Test::More;
use AnyEvent;
use MariaDB::NonBlocking::Event;
use Data::Dumper;
AnyEvent::detect();

use lib 't', '.';
require 'lib.pl';

my $connect_args = {
    user     => $::test_user,
    host     => '127.0.0.1',
    password => $::test_password || '',
};

my $conn = MariaDB::NonBlocking::Event->new;
my $cv   = AnyEvent->condvar;
$conn->connect(
    $connect_args,
    sub {
        my ($conn) = @_;
        my $socket_fd = $conn->mysql_socket_fd;
        cmp_ok($socket_fd, '>=', 1, "Got a socket FD after connecting");

        $conn->run_query("SELECT 1", {}, undef,
            sub {
                $cv->send;
                is_deeply($_[0], [[1]], "SELECT 1 worked");
            },
            sub {
                fail($_[0]);
                $cv->send;
            },
        );
    },
    sub {
        fail($_[0]);
        $cv->send;
    },
);
$cv->recv;

$cv = AnyEvent->condvar;
$conn->run_query("SELECT ?", undef, [2],
    sub {
        $cv->send;
        my ($res) = @_;
        is_deeply($res, [[2]], "SELECT ? bind 2 worked");
    },
    sub {
        fail("SELECT ? bind 2 failed: $_[0]");
        $cv->send;
    },
);
$cv->recv;

$cv = AnyEvent->condvar;
$cv->begin;
$cv->begin;
$conn->run_query(
    "SELECT 3, SLEEP(1)",
    undef,
    undef,
    sub {
        is_deeply($_[0], [[3, 0]], "query that was in flight finished successfully");
        $cv->end;
    },
    sub {
        fail("Query in flight failed");
        diag($_[0]);
        $cv->end;
    },
);
$conn->run_query(
    "SELECT 4, SLEEP(3)",
    {},
    undef,
    sub {
        fail("Should never allow two queries in flight at once");
        $cv->end;
    },
    sub {
        like($_[0], qr/Attempted to /, "query started when another is in flight failed");
        $cv->end;
    },
);
$cv->recv;

my $conn2 = MariaDB::NonBlocking::Event->new;
$conn2->run_query(
    "select 1",
    {},
    undef,
    sub {},
    sub {
        my $e = $_[0];
        like($e, qr/\ACannot start query; not connected/, "->new->connect fails");
    },
);

$cv = AnyEvent->condvar;
$conn2->connect($connect_args,
    sub {
        my ($conn2) = @_;

        $cv->begin;
        $cv->begin;

        my $success_cb = sub { pass("Async query finished"); $cv->end };
        my $failure_cb = sub {
            fail("Query failed unexpectedly: $_[0]");
            $cv->end;
        };
        $conn->run_query("SHOW PROCESSLIST", {}, undef, $success_cb, $failure_cb);
        $conn2->run_query("SELECT 1, SLEEP(1)", {}, undef, $success_cb, $failure_cb);

        return;
    },
    sub {
        $cv->send;
    },
);
$cv->recv;

my $start_query = sub {
    my ($conn, $tuples, $cv, $next_query_start) = @_;
    return $cv->send unless @$tuples;

    my $next_tuple = shift @$tuples;
    my ($re, $sql, $bind) = @$next_tuple;

    $conn->run_query($sql, {}, $bind,
        sub {
            $cv->send;
            fail("Broken query should never succeed");
        },
        sub {
            my $error = $_[0];
            like($error, $re, "$sql failed as expected");

            $next_query_start->($conn, $tuples, $cv, $next_query_start);
        },
    );
};

my @broken_queries = (
    [ qr/\AYou have an error in your SQL syntax/, "SEEEELECT 1" ],
    [ qr/\AYou have an error in your SQL syntax/, "SELECT ?" ],
    [ qr/\ANot enough bind params given/, "SELECT ?", [] ],
    [ qr/\AToo many bind params given for query! Got 2, query needed 1/, "SELECT ?", [1, 2] ],
    [ qr/\ANot enough bind params given/, "SELECT ?, ?", [1] ],
);

for my $conn ($conn, $conn2) {
    $cv = AnyEvent->condvar;
    $start_query->($conn, [@broken_queries], $cv, $start_query);
    $cv->recv;
}

done_testing;
