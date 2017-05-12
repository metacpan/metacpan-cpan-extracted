
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

use Fey::Test;
use Fey::Test::Loader;
use Fey::Test::Pg;

use Test::More;

use Fey::Loader;

{
    my $loader = Fey::Loader->new( dbh => Fey::Test::Pg->dbh() );

    my $schema1 = $loader->make_schema( name => 'Test' );
    my $schema2 = Fey::Test->mock_test_schema_with_fks();

    Fey::Test::Loader->compare_schemas(
        $schema1, $schema2, {
            'Message.message_date' => {
                default => Fey::Literal::Function->new('now'),
            },
            'Message.quality' => {
                type => 'numeric',
            },
            'Message.message' => {
                type   => 'character varying',
                length => 255,
            },
        },
    );

    is(
        $loader->_build_dbh_name(), 'test_fey',
        'database name is test_fey'
    );
}

{
    my $def = Fey::Loader::Pg->_default('NULL');
    isa_ok( $def, 'Fey::Literal::Null' );
}

done_testing();
