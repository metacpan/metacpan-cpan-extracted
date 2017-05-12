# -*- mode: Perl; -*-
package PgSqlConnectionTest;

use parent qw(Eve::Test);

use strict;
use warnings;

no warnings qw(redefine);

use Test::More;

use Eve::DbiStub;

use Eve::PgSqlConnection;

sub test_connect : Test(5) {
    my $self = shift;

    my $pgsql_connection = Eve::PgSqlConnection->new();

    isa_ok($pgsql_connection->dbh, 'DBI');

    ok($pgsql_connection->dbh->call_pos(-1), 'connect');
    is_deeply(
        [$pgsql_connection->dbh->call_args(-1)],
        [$pgsql_connection->dbh, 'DBI', 'dbi:Pg:dbname=;host=;port=',
         undef, undef,
         {
             RaiseError => 1, ShowErrorStatement => 1, AutoCommit => 1,
             pg_server_prepare => 1, pg_enable_utf8 => 1
         }]);

    $pgsql_connection = Eve::PgSqlConnection->new(
        host => 'myhost', port => '1234', database => 'mydb',
        user => 'me', password => 'mykey');

    ok($pgsql_connection->dbh->call_pos(-1), 'connect');
    is_deeply(
        [$pgsql_connection->dbh->call_args(-1)],
        [$pgsql_connection->dbh, 'DBI',
         'dbi:Pg:dbname=mydb;host=myhost;port=1234',
         'me', 'mykey',
         {
             RaiseError => 1, ShowErrorStatement => 1, AutoCommit => 1,
             pg_server_prepare => 1, pg_enable_utf8 => 1
         }]);
}

1;
