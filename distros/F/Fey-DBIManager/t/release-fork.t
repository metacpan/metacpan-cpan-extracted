
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

my $source = Fey::DBIManager::Source->new( dsn => 'dbi:Pg:dbname=fey_dbimanager_testing' );

lives_ok { $source->dbh()->selectcol_arrayref('SELECT * FROM test') }
'Can select from test table';

my $pid;
if ( $pid = fork ) {
    lives_ok { $source->dbh()->selectcol_arrayref('SELECT * FROM test') }
    'Can select from test table in parent';
}
else {
    eval { $source->dbh()->selectcol_arrayref('SELECT * FROM test') };
    if ( my $e = $@ ) {
        diag("Error in child:\n$e");
        exit 1;
    }
    else {
        exit 0;
    }
}

waitpid( $pid, 0 );

ok( !$?, 'child exited cleanly' );

lives_ok { $source->dbh()->selectcol_arrayref('SELECT * FROM test') }
'Can select from test table in parent after child exits';

done_testing();
