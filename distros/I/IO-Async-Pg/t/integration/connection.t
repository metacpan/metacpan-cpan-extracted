use strict;
use warnings;
use Test2::V0;

use lib 't/lib';
use Test::IO::Async::Pg qw(skip_without_postgres test_dsn);

# Skip if no PostgreSQL available
my $dsn = skip_without_postgres();
skip_all("Set TEST_PG_DSN to run integration tests") unless $dsn;

use IO::Async::Loop;
use IO::Async::Pg::Connection;
use IO::Async::Pg::Util qw(parse_dsn);
use DBI;
use DBD::Pg;

my $loop = IO::Async::Loop->new;

# Helper to create a connection
sub make_connection {
    my $parsed = parse_dsn(test_dsn());

    my $dbh = DBI->connect(
        $parsed->{dbi_dsn},
        $parsed->{user},
        $parsed->{password},
        {
            AutoCommit     => 1,
            RaiseError     => 1,
            PrintError     => 0,
            pg_enable_utf8 => 1,
        }
    ) or die "Cannot connect: " . DBI->errstr;

    my $conn = IO::Async::Pg::Connection->new(
        dbh => $dbh,
    );

    $loop->add($conn);
    return $conn;
}

subtest 'simple query' => sub {
    my $conn = make_connection();

    my $result = $conn->query('SELECT 1 + 1 AS sum')->get;

    is $result->first->{sum}, 2, 'query returns correct result';
    is $result->count, 1, 'one row';

    $loop->remove($conn);
    $conn->_close_dbh;
};

subtest 'query with positional placeholders' => sub {
    my $conn = make_connection();

    my $result = $conn->query('SELECT $1::int + $2::int AS sum', 3, 4)->get;

    is $result->first->{sum}, 7, 'positional placeholders work';

    $loop->remove($conn);
    $conn->_close_dbh;
};

subtest 'query with named placeholders' => sub {
    my $conn = make_connection();

    my $result = $conn->query(
        'SELECT :a::int + :b::int AS sum',
        { a => 10, b => 20 }
    )->get;

    is $result->first->{sum}, 30, 'named placeholders work';

    $loop->remove($conn);
    $conn->_close_dbh;
};

subtest 'multiple rows' => sub {
    my $conn = make_connection();

    my $result = $conn->query('SELECT generate_series(1, 5) AS n')->get;

    is $result->count, 5, 'five rows returned';
    is [ map { $_->{n} } @{$result->rows} ], [1, 2, 3, 4, 5], 'correct values';

    $loop->remove($conn);
    $conn->_close_dbh;
};

subtest 'query error' => sub {
    my $conn = make_connection();

    my $err;
    eval {
        $conn->query('SELECT * FROM nonexistent_table_xyz')->get;
    };
    $err = $@;

    ok $err, 'error thrown';
    isa_ok $err, 'IO::Async::Pg::Error::Query';
    like $err->message, qr/nonexistent_table|does not exist/i, 'error mentions table';

    $loop->remove($conn);
    $conn->_close_dbh;
};

subtest 'query count increments' => sub {
    my $conn = make_connection();

    is $conn->query_count, 0, 'starts at 0';

    $conn->query('SELECT 1')->get;
    is $conn->query_count, 1, 'incremented after first query';

    $conn->query('SELECT 2')->get;
    is $conn->query_count, 2, 'incremented after second query';

    $loop->remove($conn);
    $conn->_close_dbh;
};

subtest 'scalar method' => sub {
    my $conn = make_connection();

    my $result = $conn->query('SELECT COUNT(*) FROM pg_tables')->get;

    ok $result->scalar > 0, 'scalar returns count value';

    $loop->remove($conn);
    $conn->_close_dbh;
};

done_testing;
