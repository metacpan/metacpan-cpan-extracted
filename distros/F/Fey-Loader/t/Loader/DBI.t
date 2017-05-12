use strict;
use warnings;

use Fey::Test;
use Fey::Test::Loader;

use Test::More;

use Fey::Loader;

sub new_loader {
    local $SIG{__WARN__} = sub {
        my @w = grep { !/driver-specific/ } @_;
        warn @w if @w;
    };

    return Fey::Loader->new( dbh => Fey::Test->mock_dbh(), @_ );
}

{
    my $loader = new_loader();

    my $schema1 = $loader->make_schema();
    my $schema2 = Fey::Test->mock_test_schema_with_fks();

    Fey::Test::Loader->compare_schemas(
        $schema1, $schema2, {
            'Group.group_id'     => { is_auto_increment => 0 },
            'Message.message_id' => { is_auto_increment => 0 },
            'User.user_id'       => { is_auto_increment => 0 },
        },
    );
}

{
    my $def = Fey::Loader::DBI->_default('NULL');
    isa_ok( $def, 'Fey::Literal::Null' );

    is(
        Fey::Loader::DBI->_default(q{'foo'})->string(), 'foo',
        q{'foo' as default becomes string foo}
    );

    is(
        Fey::Loader::DBI->_default(q{"foo"})->string(), 'foo',
        q{"foo" as default becomes string foo}
    );

    is(
        Fey::Loader::DBI->_default(42)->number(), 42,
        '42 as default becomes 42'
    );

    is(
        Fey::Loader::DBI->_default(42.42)->number(), 42.42,
        '42.42 as default becomes 42.42'
    );

    $def = Fey::Loader::DBI->_default('NOW');
    isa_ok( $def, 'Fey::Literal::Term' );
    is(
        $def->sql, 'NOW',
        'unquoted NOW as default becomes NOW as term'
    );
}

{
    {

        package Test::Schema;
        use Moose;
        extends 'Fey::Schema';
    }

    {

        package Test::Table;
        use Moose;
        extends 'Fey::Table';
    }

    {

        package Test::Column;
        use Moose;
        extends 'Fey::Column';
    }

    {

        package Test::FK;
        use Moose;
        extends 'Fey::FK';
    }

    my $loader = new_loader(
        schema_class => 'Test::Schema',
        table_class  => 'Test::Table',
        column_class => 'Test::Column',
        fk_class     => 'Test::FK',
    );

    my $schema = $loader->make_schema();

    isa_ok( $schema, 'Test::Schema' );

    for my $table ( $schema->tables() ) {
        isa_ok( $table, 'Test::Table' );

        for my $column ( $table->columns() ) {
            isa_ok( $column, 'Test::Column' );
        }

        for my $fk ( $schema->foreign_keys_for_table($table) ) {
            isa_ok( $fk, 'Test::FK' );
        }
    }
}

{
    my $dbh = Fey::Test->mock_dbh();

    $dbh->{Name} = 'database=FooBar;port=1234';

    my $loader = Fey::Loader::DBI->new( dbh => $dbh );

    is(
        $loader->_dbh_name(), 'FooBar',
        'parsed database name from DSN'
    );

    $dbh->{Name} = 'database=FooBar2';

    $loader = Fey::Loader::DBI->new( dbh => $dbh );

    is(
        $loader->_dbh_name(), 'FooBar2',
        'parsed database name from DSN'
    );

    $dbh->{Name} = 'dbname=FooBar3';

    $loader = Fey::Loader::DBI->new( dbh => $dbh );

    is(
        $loader->_dbh_name(), 'FooBar3',
        'parsed database name from DSN'
    );
}

done_testing();
