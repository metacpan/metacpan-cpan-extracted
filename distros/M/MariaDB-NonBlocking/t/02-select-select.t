#!perl
use v5.10.1;
use strict;
use warnings;
no warnings 'once';

use Test::More;
use MariaDB::NonBlocking::Select;
use Data::Dumper;

use lib 't', '.';
require 'lib.pl';

my $connect_args = {
    user     => $::test_user,
    host     => '127.0.0.1',
    password => $::test_password || '',
};

my $conn = MariaDB::NonBlocking::Select->new;
eval {
    $conn->connect($connect_args);
    1;
} or do {
    my $e = $@;
    fail($e);
};

my $socket_fd = $conn->mysql_socket_fd;
cmp_ok($socket_fd, '>=', 1, "Got a socket FD after connecting");

eval {
    my $result = $conn->run_query("SELECT 1");
    is_deeply($result, [[1]], "SELECT 1 worked");
    1;
} or do {
    my $e = $@;
    fail($e);
};

eval {
    my $res = $conn->run_query("SELECT ?", undef, [2]);
    is_deeply($res, [[2]], "SELECT ? bind 2 worked");
    1;
} or do {
    my $e = $@;
    fail("SELECT ? bind 2 failed: $e");
};

my $conn2 = MariaDB::NonBlocking::Select->new;
eval {
    $conn2->run_query("select 1");
    fail("Should not get here");
    1;
} or do {
    my $e = $@;
    like($e, qr/\ACannot start query; not connected/, "->new->connect fails");
};

sub run_query_expected_to_fail {
    my ($conn, $re, $sql, $bind) = @_;

    eval {
        $conn->run_query($sql, {}, $bind);
        fail("Broken query should never succeed");
        1;
    } or do {
        my $error = $@;
        like($error, $re, "$sql failed as expected");
    };
}

my @broken_queries = (
    [ qr/\AYou have an error in your SQL syntax/, "SEEEELECT 1" ],
    [ qr/\AYou have an error in your SQL syntax/, "SELECT ?" ],
    [ qr/\ANot enough bind params given/, "SELECT ?", [] ],
    [ qr/\AToo many bind params given for query! Got 2, query needed 1/, "SELECT ?", [1, 2] ],
    [ qr/\ANot enough bind params given/, "SELECT ?, ?", [1] ],
);

for my $tuple ( @broken_queries ) {
    run_query_expected_to_fail($conn, @$tuple);
}

done_testing;
