use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;

use lib 't/lib';
use Test::IO::Async::Pg qw(skip_without_postgres test_dsn);

# Skip if no PostgreSQL available
my $dsn = skip_without_postgres();
skip_all("Set TEST_PG_DSN to run pool tests") unless $dsn;

use IO::Async::Loop;
use IO::Async::Pg;

my $loop = IO::Async::Loop->new;

subtest 'create pool' => sub {
    my $pg = IO::Async::Pg->new(
        dsn             => test_dsn(),
        min_connections => 1,
        max_connections => 5,
    );

    isa_ok $pg, 'IO::Async::Pg';
    is $pg->min_connections, 1, 'min_connections';
    is $pg->max_connections, 5, 'max_connections';

    $loop->add($pg);
    ok $pg->loop, 'added to loop';

    $loop->remove($pg);
};

subtest 'get connection from pool' => sub {
    my $pg = IO::Async::Pg->new(
        dsn             => test_dsn(),
        min_connections => 1,
        max_connections => 5,
    );
    $loop->add($pg);

    my $conn = $pg->connection->get;
    isa_ok $conn, 'IO::Async::Pg::Connection';

    is $pg->active_count, 1, 'connection is active';

    my $result = $conn->query('SELECT 1 AS one')->get;
    is $result->first->{one}, 1, 'query works';

    $conn->release;
    is $pg->active_count, 0, 'connection released';
    is $pg->idle_count, 1, 'connection returned to idle';

    $loop->remove($pg);
};

subtest 'connection reuse' => sub {
    my $pg = IO::Async::Pg->new(
        dsn             => test_dsn(),
        min_connections => 1,
        max_connections => 5,
    );
    $loop->add($pg);

    my $conn1 = $pg->connection->get;
    my $conn1_dbh = $conn1->dbh;
    $conn1->release;

    my $conn2 = $pg->connection->get;
    is $conn2->dbh, $conn1_dbh, 'same connection reused';

    $conn2->release;
    $loop->remove($pg);
};

subtest 'multiple connections' => sub {
    my $pg = IO::Async::Pg->new(
        dsn             => test_dsn(),
        min_connections => 1,
        max_connections => 3,
    );
    $loop->add($pg);

    my $conn1 = $pg->connection->get;
    my $conn2 = $pg->connection->get;
    my $conn3 = $pg->connection->get;

    is $pg->active_count, 3, '3 active connections';
    is $pg->total_count, 3, '3 total connections';

    $conn1->release;
    $conn2->release;
    $conn3->release;

    is $pg->active_count, 0, 'all released';
    is $pg->idle_count, 3, 'all idle';

    $loop->remove($pg);
};

subtest 'pool stats' => sub {
    my $pg = IO::Async::Pg->new(
        dsn             => test_dsn(),
        min_connections => 0,
        max_connections => 2,
    );
    $loop->add($pg);

    my $conn = $pg->connection->get;
    ok $pg->stats->{created} >= 1, 'created stat incremented';

    $conn->release;
    ok $pg->stats->{released} >= 1, 'released stat incremented';

    $loop->remove($pg);
};

subtest 'on_connect callback' => sub {
    my $connected = 0;

    my $pg = IO::Async::Pg->new(
        dsn             => test_dsn(),
        min_connections => 0,
        max_connections => 2,
        on_connect      => async sub {
            my ($conn) = @_;
            $connected++;
            await $conn->query("SET application_name = 'test_app'");
        },
    );
    $loop->add($pg);

    my $conn = $pg->connection->get;
    is $connected, 1, 'on_connect called';

    my $result = $conn->query("SHOW application_name")->get;
    is $result->first->{application_name}, 'test_app', 'on_connect query executed';

    $conn->release;
    $loop->remove($pg);
};

subtest 'safe_dsn masks password' => sub {
    my $pg = IO::Async::Pg->new(
        dsn             => 'postgresql://user:secret@localhost/db',
        min_connections => 0,
        max_connections => 1,
    );

    is $pg->safe_dsn, 'postgresql://user:***@localhost/db', 'password masked';
};

done_testing;
