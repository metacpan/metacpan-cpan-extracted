use strict;
use warnings;

use lib 't/lib';

use Fey::Test 0.05;
use Test::More 0.88;

use Fey::SQL;

my $s   = Fey::Test->mock_test_schema();
my $dbh = Fey::Test->mock_dbh();

{
    my $select = Fey::SQL->new_select();

    $select->select( $s->table('User') );

    isa_ok( $select, 'Fey::SQL::Select' );

    my $sql = q{SELECT "User"."email", "User"."user_id", "User"."username"};
    is(
        $select->select_clause($dbh), $sql,
        'select_clause with one table'
    );

    is_deeply(
        [ map { $_->name() } $select->select_clause_elements() ],
        [qw( email user_id username )],
        'select_clause_elements with one table'
    );
}

{
    my $select = Fey::SQL->new_select();

    $select->select( $s->table('User') );

    my $user_alias = $s->table('User')->alias( alias_name => 'UserA' );
    $select->select($user_alias);

    my $sql = q{SELECT "User"."email", "User"."user_id", "User"."username"};
    $sql .= q{, "UserA"."email", "UserA"."user_id", "UserA"."username"};

    is(
        $select->select_clause($dbh), $sql,
        'select_clause with table alias'
    );
}

{
    my $select = Fey::SQL->new_select();

    $select->select( $s->table('User')->column('user_id') );
    $select->select( $s->table('User') );

    my $sql
        = q{SELECT "User"."user_id", "User"."email", "User"."user_id", "User"."username"};
    is(
        $select->select_clause($dbh), $sql,
        'select_clause when first adding column and then table for that column'
    );
}

{
    my $select = Fey::SQL->new_select();

    $select->select( $s->table('User')->column('user_id') );
    $select->select( $s->table('User')->column('user_id')
            ->alias( alias_name => 'new_user_id' ) );

    my $sql = q{SELECT "User"."user_id", "User"."user_id" AS "new_user_id"};
    is(
        $select->select_clause($dbh), $sql,
        'select_clause with column and alias for that column'
    );

    is_deeply(
        [
            map { $_->can('alias_name') ? $_->alias_name() : $_->name() }
                $select->select_clause_elements()
        ],
        [qw( user_id new_user_id )],
        'select_clause_elements with column and alias for that column'
    );
}

{
    my $select = Fey::SQL->new_select();

    $select->select( $s->table('User')->columns( 'user_id', 'email' ) );

    my $sql = q{SELECT "User"."user_id", "User"."email"};
    is(
        $select->select_clause($dbh), $sql,
        'select_clause preserves order passed to select()'
    );
}

{
    my $select = Fey::SQL->new_select();
    $select->select( $s->table('User')->column('user_id') )->distinct();

    my $sql = q{SELECT DISTINCT "User"."user_id"};
    is( $select->select_clause($dbh), $sql, 'select_clause with distinct' );
}

{
    my $select = Fey::SQL->new_select();

    $select->select('some literal thing');
    my $sql = q{SELECT 'some literal thing'};
    is(
        $select->select_clause($dbh), $sql,
        'select_clause after passing string to select()'
    );
}

{
    my $select = Fey::SQL->new_select();

    $select->select(235.12);
    my $sql = q{SELECT 235.12};
    is(
        $select->select_clause($dbh), $sql,
        'select_clause after passing number to select()'
    );
}

{
    my $select = Fey::SQL->new_select();

    my $concat = Fey::Literal::Function->new(
        'CONCAT',
        $s->table('User')->column('user_id'),
        Fey::Literal::String->new(' '),
        $s->table('User')->column('username'),
    );
    $select->select($concat);

    my $lit_with_alias
        = q{CONCAT("User"."user_id", ' ', "User"."username") AS "FUNCTION0"};
    my $sql = 'SELECT ' . $lit_with_alias;
    is(
        $select->select_clause($dbh), $sql,
        'select_clause after passing function to select()'
    );
}

{
    my $select = Fey::SQL->new_select();

    my $subselect = Fey::SQL->new_select();
    $subselect->select( $s->table('User')->column('email') )
        ->from( $s->table('User') );

    $select->select( $s->table('User')->column('user_id'), $subselect );

    my $sql
        = q{SELECT "User"."user_id", ( SELECT "User"."email" FROM "User" ) AS "SUBSELECT0"};
    is(
        $select->select_clause($dbh), $sql,
        'select_clause with subselect in SELECT clause'
    );
    is(
        $subselect->alias_name, 'SUBSELECT0',
        'subselect alias_name is available'
    );
}

done_testing();
