use strict;
use warnings;

use Fey::Test;
use Fey::Test::Loader;
use Fey::Test::SQLite;

use Test::More;

use Fey::Loader;

{
    my $loader = Fey::Loader->new( dbh => Fey::Test::SQLite->dbh() );

    my $schema1 = $loader->make_schema( name => 'Test' );
    my $schema2 = Fey::Test->mock_test_schema_with_fks();

    Fey::Test::Loader->compare_schemas(
        $schema1, $schema2, {
            'Message.quality' => { type => 'real' },
            'Message.message_date' =>
                { default => Fey::Literal::Term->new('CURRENT_DATE') },
            skip_foreign_keys => 1,
        },
    );
}

{
    my $def = Fey::Loader::SQLite->_default('NULL');
    isa_ok( $def, 'Fey::Literal::Null' );

    is(
        Fey::Loader::DBI->_default(q{'foo'})->string(), 'foo',
        q{'foo' as default becomes string foo}
    );

    is(
        Fey::Loader::DBI->_default(42)->number(), 42,
        '42 as default becomes 42'
    );

    is(
        Fey::Loader::DBI->_default(42.42)->number(), 42.42,
        '42.42 as default becomes 42.42'
    );

    $def = Fey::Loader::SQLite->_default('CURRENT_TIME');
    isa_ok( $def, 'Fey::Literal::Term' );
    is(
        $def->sql, 'CURRENT_TIME',
        'unquoted CURRENT_TIME as default becomes CURRENT_TIME as term'
    );
}

done_testing();
