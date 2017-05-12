
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
use Fey::Test::mysql;

use Test::More;

use Fey::Literal;
use Fey::Loader;

{
    my $loader = Fey::Loader->new( dbh => Fey::Test::mysql->dbh() );

    my $schema1 = $loader->make_schema( name => 'Test' );
    my $schema2 = Fey::Test->mock_test_schema_with_fks();

    Fey::Test::Loader->compare_schemas(
        $schema1, $schema2, {
            'Message.message_id' => {
                type   => 'INT',
                length => 11,
            },
            'Message.message' => {
                type   => 'VARCHAR',
                length => 255,
            },
            'Message.quality' => {
                type    => 'DECIMAL',
                default => Fey::Literal::Term->new('2.30'),
            },
            'Message.message_date' => {
                type         => 'TIMESTAMP',
                length       => 14,
                precision    => 0,             # gah, mysql is so weird
                generic_type => 'datetime',
                default => Fey::Literal::Term->new('CURRENT_TIMESTAMP'),
            },
            'Message.parent_message_id' => {
                type   => 'INT',
                length => 11,
            },
            'Message.user_id' => {
                type   => 'INT',
                length => 11,
            },
            'User.user_id' => {
                type   => 'INT',
                length => 11,
            },
            'User.username' => {
                type   => 'VARCHAR',
                length => 255,
            },
            'User.email' => {
                type => 'TEXT',
            },
            'UserGroup.group_id' => {
                type   => 'INT',
                length => 11,
            },
            'UserGroup.user_id' => {
                type   => 'INT',
                length => 11,
            },
            'Group.group_id' => {
                type   => 'INT',
                length => 11,
            },
            'Group.name' => {
                type   => 'VARCHAR',
                length => 255,
            },
        },
    );

    is(
        $loader->_build_dbh_name(), 'test_Fey',
        'database name is test_fey'
    );
}

{
    my $def = Fey::Loader::mysql->_default('NULL');
    isa_ok( $def, 'Fey::Literal::Null' );
}

done_testing();
