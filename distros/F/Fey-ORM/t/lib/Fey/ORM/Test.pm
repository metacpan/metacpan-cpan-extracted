package Fey::ORM::Test;

use strict;
use warnings;

use base 'Exporter';

our @EXPORT_OK = qw( schema );

use Fey::Test 0.05;

sub schema {
    return Fey::Test->mock_test_schema_with_fks();
}

sub require_sqlite {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    unless ( eval 'use Fey::Test::SQLite; 1' ) {
        Test::More::plan skip_all => 'These tests require Fey::Test::SQLite';
    }
}

sub insert_user_data {
    require_sqlite();

    my $dbh = Fey::Test::SQLite->dbh();

    $dbh->do('DELETE FROM User');

    my $insert
        = 'INSERT INTO User ( user_id, username, email ) VALUES ( ?, ?, ? )';
    my $sth = $dbh->prepare($insert);

    $sth->execute( 1,  'autarch', 'autarch@example.com' );
    $sth->execute( 42, 'bubba',   'bubba@example.com' );

    $sth->finish();
}

sub insert_message_data {
    require_sqlite();

    my $dbh = Fey::Test::SQLite->dbh();

    $dbh->do('DELETE FROM Message');

    my $insert
        = 'INSERT INTO Message ( message_id, message, user_id ) VALUES ( ?, ?, ? )';
    my $sth = $dbh->prepare($insert);

    $sth->execute( 1,  'body 1',  1 );
    $sth->execute( 2,  'body 2',  1 );
    $sth->execute( 10, 'body 10', 42 );
    $sth->execute( 99, 'body 99', 42 );

    $sth->finish();
}

sub define_basic_classes {
    my $schema = schema();

    ## no critic (BuiltinFunctions::ProhibitStringyEval, ErrorHandling::RequireCheckingReturnValueOfEval)
    eval <<'EOF';
{
    package Schema;

    use Fey::ORM::Schema;

    has_schema $schema;

    package User;

    use Fey::ORM::Table;

    has_table $schema->table('User');

    package Message;

    use Fey::ORM::Table;

    has_table $schema->table('Message');

    package UserGroup;

    use Fey::ORM::Table;

    has_table $schema->table('UserGroup');
}
EOF

    die $@ if $@;
}

sub define_live_classes {
    define_basic_classes();

    require_sqlite();

    my $dbh = Fey::Test::SQLite->dbh();
    $dbh->{ShowErrorStatement} = 1;

    Schema->DBIManager()
        ->add_source( dbh => $dbh, dsn => Fey::Test::SQLite->dsn() );
}

1;
