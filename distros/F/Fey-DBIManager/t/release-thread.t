
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

use Test::Exception;
use Test::More;

BEGIN {
    plan skip_all => 'Cannot run these tests with a non-threaded Perl'
        unless eval { require threads };
}

use Fey::DBIManager::Source;

{
    my $dbh = DBI->connect(
        'dbi:Pg:dbname=template1', undef, undef,
        { RaiseError => 1 }
    );

    $dbh->do('SET CLIENT_MIN_MESSAGES = ERROR');

    $dbh->do('DROP DATABASE IF EXISTS fey_dbimanager_testing');

    $dbh->do('CREATE DATABASE fey_dbimanager_testing');

    $dbh->disconnect();

    $dbh = DBI->connect(
        'dbi:Pg:dbname=fey_dbimanager_testing', undef, undef,
        { RaiseError => 1 }
    );

    $dbh->do('SET CLIENT_MIN_MESSAGES = ERROR');

    $dbh->do('CREATE TABLE test ( test_id SERIAL8 PRIMARY KEY )');
}

my $source = Fey::DBIManager::Source->new(
    dsn => 'dbi:Pg:dbname=fey_dbimanager_testing' );

lives_ok { $source->dbh()->selectcol_arrayref('SELECT * FROM test') }
'Can select from test table';

my $thread = threads->create(
    sub {
        eval { $source->dbh()->selectcol_arrayref('SELECT * FROM test') };
        return $@;
    }
);

lives_ok { $source->dbh()->selectcol_arrayref('SELECT * FROM test') }
'Can select from test table in original thread';

my $error = $thread->join();
is( $error, q{}, 'Can select in new thread' );

lives_ok { $source->dbh()->selectcol_arrayref('SELECT * FROM test') }
'Can select from test table in original thread after new thread exits';

done_testing();
