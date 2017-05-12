use strict;
use warnings;

use Test::More;

use Fey::Test::SQLite;
use Fey::DBIManager::Source;

my $source = Fey::DBIManager::Source->new(
    dsn => Fey::Test::SQLite->dsn(),
    dbh => Fey::Test::SQLite->dbh(),
);

ok(
    !$source->allows_nested_transactions(),
    'source allows nested transactions is false with SQLite'
);

SKIP:
{
    skip 'These tests require Test::Output', 1
        unless eval "use Test::Output; 1";

    stderr_is(
        sub {
            Fey::DBIManager::Source->new(
                dsn => Fey::Test::SQLite->dsn(),
                dbh => Fey::Test::SQLite->dbh(),
            )->_build_allows_nested_transactions();
        },
        '',
        'no warnings checking for nested transaction support with DBD::SQLite'
    );
}

done_testing();
