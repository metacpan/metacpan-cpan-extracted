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
use constant DROP_TABLE_SQL      => 'DROP TABLE IF EXISTS mariadb_update_test';
use constant SHOW_CREATE_TABLE   => 'SHOW CREATE TABLE mariadb_update_test';
use constant CREATE_TABLE_SQL => <<'EOSQL';
CREATE TABLE mariadb_update_test (
    id int auto_increment,
    foo varchar(255) not null,
    primary key(id)
)
EOSQL
use constant INSERT_SQL       => 'INSERT INTO mariadb_update_test (`foo`) VALUES (?)';
use constant UPDATE_SQL       => 'UPDATE mariadb_update_test SET foo=?';
use constant UPDATE_WHERE_SQL => UPDATE_SQL . ' WHERE id = ?';

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
->then(sub {
    my @values_to_insert = ( ['abc'], ['123'], ['%$!'], );

    my $weak_coderef;
    my $after_insert = sub {
        return unless @values_to_insert;
        my $insert = shift @values_to_insert;
        return $conn->run_query(INSERT_SQL, $insert)->then($weak_coderef);
    };

    $weak_coderef = $after_insert;
    weaken($weak_coderef);

    return $weak_coderef->();
})->then(sub {
    # Now, do some updatin'
    $conn->run_query(UPDATE_WHERE_SQL, ["test$$", 1])->then(sub {
        is_deeply($_[0], [1], "updated 1 row");
    });
})->then(sub {
    $conn->run_query(UPDATE_SQL, ["test" . int(rand($$))])->then(sub {
        is_deeply($_[0], [3], "updated 3 rows");
    });
})->then(sub {
    $conn->run_query(UPDATE_WHERE_SQL, ["test", 4])->then(sub {
        is_deeply($_[0], [], "updated no rows");
    });
})->finally(sub {
    # cleanup
    $conn->run_query(DROP_TABLE_SQL)
})->catch(sub {
    my $error = $_[0];
    like($error, qr/\AException test/, "thrown exceptions work as expected");
});

wait_for_promise $p;



done_testing;
