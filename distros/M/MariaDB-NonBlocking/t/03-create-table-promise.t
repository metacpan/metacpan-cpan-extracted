#!perl
use v5.10.1;
use strict;
use warnings;
no warnings 'once';

use Test::More;
use AnyEvent;
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

use constant DROP_TABLE_SQL   => 'DROP TABLE IF EXISTS mariadb_create_test';
use constant SHOW_CREATE_TABLE => 'SHOW CREATE TABLE mariadb_create_test';
use constant CREATE_TABLE_SQL => <<'EOSQL';
CREATE TABLE mariadb_create_test (
    id int primary key,
    foo varchar(255) not null
)
EOSQL

my $connect_args = {
    user     => $::test_user,
    password => $::test_password || '',
    ( $::testdb ? (database => $::testdb) : () ),
    host     => '127.0.0.1',
};
my $test_database = $::testdb || 'mariadb_perl_test';

my $conn = MariaDB::NonBlocking::Promises->init;
my $create_database_sql = sprintf(CREATE_DATABASE_FMT, $test_database);
my $p = $conn->connect($connect_args)->then(sub {
    my ($conn) = @_;
    $conn->run_query($create_database_sql)->catch(sub {
        fail("Could not run the CREATE DATABASE IF NOT EXISTS");
        diag($_[0]);
    })->then(sub {
        is_deeply($_[0], [1], "CREATE TABLE IF NOT EXISTS worked");
        return $conn->run_query("use $test_database")->then(sub {
            is_deeply($_[0], [], "USE DATABASE worked");
            return;
        });
    });
}, sub { fail('Failed to connect: ' . $_[0]) })->then(sub {
    return $conn->run_query(DROP_TABLE_SQL)->then(sub {
        is_deeply($_[0], [], "DROP TABLE IF EXISTS worked");
    });
})->then(sub {
    return $conn->run_query(CREATE_TABLE_SQL)->then(sub {
        my ($ret) = @_;
        is_deeply($ret, [], "CREATE TABLE worked");
        return $conn->run_query(SHOW_CREATE_TABLE)->then(sub {
            my ($res) = @_;
            my $table_name = $res->[0][0];
            is($table_name, 'mariadb_create_test', 'show create table worked');
            return;
        })->then(sub {
            return $conn->run_query(SHOW_CREATE_TABLE, undef, {want_hashrefs => 1})->then(sub {
                my ($res) = @_;
                my $table_name = $res->[0]{Table};
                is($table_name, 'mariadb_create_test', 'show create table worked');
                return;
            });
        })->then(sub {
            return $conn->run_query(CREATE_TABLE_SQL)->then(sub {
                fail("Should never get here");
            }, sub {
                my $error = $_[0];
                like($error, qr/already exists/, "double-create error reported correctly");
            });
        });
    }, sub { fail('Create table failed: ' . $_[0]) })
})->then(sub {
    return $conn->run_query("SELECT * FROM mariadb_create_test")->then(sub {
        is_deeply($_[0], [], "select on an empty table works");
    })
})->finally(sub {
    # cleanup
    $conn->run_query(DROP_TABLE_SQL)
});

wait_for_promise $p;



done_testing;
