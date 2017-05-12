use strict;
use warnings;

use lib 't/lib';

use Fey::Test 0.05;
use Test::More 0.88;

use Fey::Schema;

{
    my $s = Fey::Schema->new( name => 'Test' );

    is( $s->name(), 'Test', 'schema name is Test' );

    $s->set_name('NewTest');

    is( $s->name(), 'NewTest', 'schema name is now NewTest' );
}

{
    my $s = Fey::Schema->new( name => 'Test' );
    my $t = Fey::Table->new( name => 'Test' );

    ok( !$t->schema(), 'table has no schema when created' );

    $s->add_table($t);
    is(
        $t->schema(), $s,
        'table has a schema after calling add_table()'
    );
    is(
        $s->table( $t->name() ), $t,
        'table is in schema'
    );

    $s->remove_table($t);
    ok(
        !$t->schema(),
        'table has no schema after calling remove_table()'
    );
    ok( !$s->table( $t->name() ), 'table is not in schema' );

    $s->add_table($t);
    $s->remove_table( $t->name() );
    ok(
        !$t->schema(),
        'table has no schema after calling remove_table()'
    );

    $s->add_table($t);
    eval { $s->add_table($t); };
    like(
        $@, qr/already contains a table named Test/,
        'error when adding the same table twice'
    );
}

{
    require Fey::FK;

    my $s = Fey::Test->mock_test_schema();

    my $fk = Fey::FK->new(
        source_columns => $s->table('User')->column('user_id'),
        target_columns => $s->table('UserGroup')->column('user_id'),
    );

    $s->add_foreign_key($fk);

    {
        my @fk = $s->foreign_keys_for_table('User');
        is( scalar @fk, 1, 'one fk for User table - passed as name' );
    }

    my @fk = $s->foreign_keys_for_table( $s->table('User') );
    is( scalar @fk, 1, 'one fk for User table - passed as object' );
    is(
        $fk[0]->source_table()->name(), 'User',
        'source table is user'
    );
    is(
        $fk[0]->source_columns()->[0]->name(), 'user_id',
        'source column is user_id'
    );

    $s->add_foreign_key($fk);
    @fk = $s->foreign_keys_for_table('User');
    is( scalar @fk, 1, 'one fk for User table - dupes are ignored' );

    @fk = $s->foreign_keys_for_table('UserGroup');
    is( scalar @fk, 1, 'one fk for UserGroup table' );
    is(
        $fk[0]->id(), $fk->id(),
        'foreign key for UserGroup is same as original fk'
    );

    @fk = $s->foreign_keys_between_tables( 'User', 'UserGroup' );
    is( scalar @fk, 1, 'one fk for UserGroup table' );
    is(
        $fk[0]->id(), $fk->id(),
        'one foreign key between User and UserGroup is same as original'
    );

    my $alias = $s->table('User')->alias( alias_name => 'UserA' );
    @fk = $s->foreign_keys_between_tables( $alias, 'UserGroup' );
    is(
        scalar @fk, 1,
        'one fk between alias of User table and UserGroup table'
    );
    is(
        $fk[0]->source_columns()->[0]->table(), $alias,
        'source column points to alias'
    );

    @fk = $s->foreign_keys_between_tables( 'UserGroup', 'User' );
    is( scalar @fk, 1, 'one fk for UserGroup table' );
    is(
        $fk[0]->id(), $fk->id(),
        'one foreign key between UserGroup and User'
    );

    @fk = $s->foreign_keys_between_tables(
        $s->table('User'),
        $s->table('UserGroup')
    );
    is( scalar @fk, 1, 'one fk for UserGroup table - passed as objects' );

    @fk = $s->foreign_keys_between_tables( 'User', 'Group' );
    is( scalar @fk, 0, 'no fks between User and Group' );

    $s->remove_foreign_key($fk);
    @fk = $s->foreign_keys_for_table('User');
    is( scalar @fk, 0, 'no fks for User table' );

    $s->add_foreign_key($fk);
    my $user_t = $s->table('User');
    $s->remove_table('User');
    @fk = $s->foreign_keys_for_table('UserGroup');
    is(
        scalar @fk, 0,
        'no fks for UserGroup table after User table is removed'
    );

    $s->add_table($user_t);
    $fk = Fey::FK->new(
        source_columns => $s->table('User')->column('user_id'),
        target_columns => $s->table('UserGroup')->column('user_id'),
    );
    $s->add_foreign_key($fk);

    $user_t->remove_column('user_id');
    @fk = $s->foreign_keys_for_table('UserGroup');
    is(
        scalar @fk, 0,
        'no fks for UserGroup table after User.user_id column is removed'
    );

    @fk = $s->foreign_keys_between_tables(
        $s->table('User'),
        $s->table('UserGroup')
    );
    is(
        scalar @fk, 0,
        'no fks between User and UserGroup after User.user_id columns is removed'
    );

    @fk = $s->foreign_keys_between_tables(
        $s->table('UserGroup'),
        $s->table('User')
    );
    is(
        scalar @fk, 0,
        'no fks between UserGroup and User after User.user_id columns is removed'
    );

    @fk = $s->foreign_keys_between_tables(
        $s->table('Message'),
        $s->table('Message')
    );
    is(
        scalar @fk, 0,
        'no fks between Message and Message'
    );
}

{
    my $s = Fey::Test->mock_test_schema();

    my $fk = Fey::FK->new(
        source_columns => $s->table('Message')->column('parent_message_id'),
        target_columns => $s->table('Message')->column('message_id'),
    );

    $s->add_foreign_key($fk);

    my @fks = $s->foreign_keys_for_table('Message');
    is(
        @fks, 1,
        'foreign_keys_for_table() returns just one fk in the case of a self-referential fk'
    );
    is_deeply(
        [ map { $_->name() } @{ $fks[0]->source_columns() } ],
        ['parent_message_id'],
        'source_columns() returns Message.parent_message_id'
    );

    @fks = $s->foreign_keys_between_tables( 'Message', 'Message' );
    is(
        @fks, 1,
        'foreign_keys_between_tables() returns just one fk in the case of a self-referential fk'
    );
    is_deeply(
        [ map { $_->name() } @{ $fks[0]->source_columns() } ],
        ['parent_message_id'],
        'source_columns() returns Message.parent_message_id'
    );
}

{
    my $s = Fey::Test->mock_test_schema();

    my @tables = sort map { $_->name() } $s->tables();

    is( scalar @tables, 4, 'schema has 4 tables' );
    is_deeply(
        \@tables, [ 'Group', 'Message', 'User', 'UserGroup' ],
        'tables are Group, Message, User, & UserGroup'
    );

    @tables = sort map { $_->name() } $s->tables( 'User', 'Group' );

    is( scalar @tables, 2, 'tables() returns named tables' );
    is_deeply(
        \@tables, [ 'Group', 'User' ],
        'tables are Group & User'
    );

    @tables = sort map { $_->name() } $s->tables('NoSuchTable');
    is( scalar @tables, 0, 'tables() ignores tables which do not exist' );
}

done_testing();
