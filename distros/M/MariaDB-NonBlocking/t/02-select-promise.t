#!perl
use v5.10.1;
use strict;
use warnings;
no warnings 'once';

use Test::More;
use AnyEvent;
use AnyEvent::XSPromises qw/collect/;
use MariaDB::NonBlocking::Promises;
use Data::Dumper;
AnyEvent::detect();

use lib 't', '.';
require 'lib.pl';

sub wait_for_promise ($) {
    my $p = shift;
    my $cv = AnyEvent->condvar;
    $p->then(
        sub { $cv->send($_[0]); },
        sub { $cv->croak($_[0]); },
    );
    $cv->recv;
}

my $connect_args = {
    user     => $::test_user,
    host     => '127.0.0.1',
    password => $::test_password || '',
};

my $conn = MariaDB::NonBlocking::Promises->new;
my $connect_and_query = $conn->connect($connect_args)->then(sub {
    my ($conn) = @_;
    my $socket_fd = $conn->mysql_socket_fd;
    cmp_ok($socket_fd, '>=', 1, "Got a socket FD after connecting");

    return $conn->run_query("SELECT 1")->then(sub {
        is_deeply($_[0], [[1]], "SELECT 1 worked");
    }, sub {
        fail($_[0]);
    });
});
wait_for_promise $connect_and_query;

my $select_with_bind = $conn->run_query("SELECT ?", [2])->then(
    sub {
        is_deeply($_[0], [[2]], "SELECT ? bind 2 worked");
    },
    sub {
        fail("SELECT ? bind 2 failed: $_[0]");
    },
);
wait_for_promise $select_with_bind;

my $select_sleep = $conn->run_query("SELECT 3, SLEEP(1)")->then(
    sub {
        is_deeply($_[0], [[3, 0]], "query that was in flight finished successfully");
    },
    sub {
        fail("Query in flight failed");
        diag($_[0]);
    },
);
my $select_sleep_2 = $conn->run_query("SELECT 4, SLEEP(3)")->then(
    sub {
        fail("Should never allow two queries in flight at once");
    },
    sub {
        like($_[0], qr/Attempted to /, "query started when another is in flight failed");
    },
);

wait_for_promise $select_sleep;
wait_for_promise $select_sleep_2;

my $conn2 = MariaDB::NonBlocking::Promises->new;
my $query_without_connecting = $conn2->run_query("select 1")->then(
    sub { fail("Should never reach here"); }
)->catch(sub {
    my $e = $_[0];
    like($e, qr/\ACannot start query; not connected/, "->new->connect fails");
});

wait_for_promise $query_without_connecting;

my $connect_and_run_multiple_queries = $conn2->connect($connect_args)->then(
    sub {
        my ($conn2) = @_;

        my $p1 = $conn->run_query("SHOW PROCESSLIST");
        my $p2 = $conn2->run_query("SELECT 1, SLEEP(1)");

        return collect($p1, $p2)->then(sub {
            pass("Async queries finished correctly");
        }, sub {
            fail("Async queries failed unexpectedly: $_[0]");
        });
    },
    sub {
        fail("Failed to connect to a second handle");
    },
);
wait_for_promise $connect_and_run_multiple_queries;

my $start_query = sub {
    my ($conn, $tuples, $next_query_start) = @_;
    return unless @$tuples;

    my $next_tuple = shift @$tuples;
    my ($re, $sql, $bind) = @$next_tuple;

    return $conn->run_query($sql, $bind)->then(sub {
        fail("$sql: Broken query should never succeed");
    }, sub {
        my $error = $_[0];
        like($error, $re, ($sql // '<undef>') . " failed as expected");
        $next_query_start->($conn, $tuples, $next_query_start);
    });
};

my @broken_queries = (
    [ qr/\AYou have an error in your SQL syntax/, "SEEEELECT 1" ],
    [ qr/\AYou have an error in your SQL syntax/, "SELECT ?" ],
    [ qr/\ANot enough bind params given/, "SELECT ?", [] ],
    [ qr/\AToo many bind params given for query! Got 2, query needed 1/, "SELECT ?", [1, 2] ],
    [ qr/\ANot enough bind params given/, "SELECT ?, ?", [1] ],
    [ qr/Query was empty/, undef, [] ],
    [ qr/Query was empty/, undef ],
    [ qr/Query was empty/, '', [] ],
    [ qr/Query was empty/, '' ],
    [ qr/Query was empty/, '   ' ],
);

my @promises;
for my $conn ($conn, $conn2) {
    push @promises, $start_query->($conn, [@broken_queries], $start_query);
}
wait_for_promise(collect(@promises));

done_testing;
