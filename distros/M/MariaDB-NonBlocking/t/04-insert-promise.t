#!perl
use v5.10.1;
use strict;
use warnings;
no warnings 'once';

use Test::More;
use AnyEvent;
use Scalar::Util qw/weaken/;
use Promises qw/collect/;
use MariaDB::NonBlocking::Promises;
use Data::Dumper;

use lib 't', '.';
require 'lib.pl';

sub wait_for_promise ($) {
    my $p = shift;
    my $cv = AnyEvent->condvar;
    $p->then(
        sub { $cv->send; },
        sub { $cv->send; },
    );
    $cv->recv;
}

use constant CREATE_DATABASE_FMT => 'CREATE DATABASE IF NOT EXISTS %s';
use constant DROP_TABLE_SQL      => 'DROP TABLE IF EXISTS mariadb_insert_test';
use constant SHOW_CREATE_TABLE   => 'SHOW CREATE TABLE mariadb_insert_test';
use constant CREATE_TABLE_SQL => <<'EOSQL';
CREATE TABLE mariadb_insert_test (
    id int auto_increment,
    foo varchar(255) not null,
    primary key(id)
)
EOSQL
use constant INSERT_SQL => 'INSERT INTO mariadb_insert_test (`foo`) VALUES (?)';

my $connect_args = {
    user     => $::test_user,
    password => $::test_password || '',
    ( $::testdb ? (database => $::testdb) : () ),
    host     => '127.0.0.1',
};
my $test_database = $::testdb || 'mariadb_perl_test';

my $conn = MariaDB::NonBlocking::Promises->init;
my $create_database_sql = sprintf(CREATE_DATABASE_FMT, $test_database);
my $p = $conn->connect($connect_args)
->then(sub { $conn->run_query($create_database_sql) })
->then(sub { $conn->run_query("use $test_database") })
->then(sub { $conn->run_query(DROP_TABLE_SQL)       })
->then(sub { $conn->run_query(CREATE_TABLE_SQL)     })
# TODO
#->then(sub { is_deeply($_[0], [[1]], "created the table") })
->then(sub {
    my @values_to_insert = (
        ['abc'], ['123'], ['%$!'],
    );

    my @expect = map +[$_+1, @{$values_to_insert[$_]}], 0..$#values_to_insert;

    my $expected_id = 1;

    my $weak_coderef;
    my $after_insert = sub {
        my ($ret) = @_;

        if ( $ret ) {
            is_deeply($ret, [1], "insert returns the number of inserted rows");
            my $last_insert_id = $conn->insert_id;
            is($last_insert_id, $expected_id++, "INSERTed the right ID");
        }

        return $conn->run_query(INSERT_SQL, shift @values_to_insert)->then($weak_coderef) if @values_to_insert;

        return $conn->run_query("SELECT * FROM mariadb_insert_test")->then(sub {
            is_deeply($_[0], \@expect, "chained inserts work as expected!")
                or diag(Dumper($_[0]));
            die "Exception test";
        })
    };

    $weak_coderef = $after_insert;
    weaken($weak_coderef);

    return $weak_coderef->();
})->finally(sub {
    # cleanup
    $conn->run_query(DROP_TABLE_SQL)
})->catch(sub {
    my $error = $_[0];
    like($error, qr/\AException test/, "thrown exceptions work as expected");
});

wait_for_promise $p;



done_testing;
