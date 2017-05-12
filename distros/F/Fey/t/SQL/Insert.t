use strict;
use warnings;

use lib 't/lib';

use Fey::Test 0.05;
use Test::More 0.88;

use Fey::Placeholder;
use Fey::SQL;

my $s   = Fey::Test->mock_test_schema();
my $dbh = Fey::Test->mock_dbh();

my $size = Fey::Column->new(
    name        => 'size',
    type        => 'text',
    is_nullable => 1,
);
$s->table('User')->add_column($size);

{
    my $insert = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    eval { $insert->into() };
    like(
        $@, qr/1 was expected/,
        'into() without any parameters fails'
    );

}

{
    my $insert = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    $insert->into( $s->table('User')->column('username') );

    is(
        $insert->insert_clause($dbh), q{INSERT INTO "User"},
        'insert_clause() for User table'
    );
    is(
        $insert->columns_clause($dbh), q{("username")},
        'columns_clause with one column'
    );
}

{
    my $insert = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    $insert->into( $s->table('User') );

    is(
        $insert->insert_clause($dbh), q{INSERT INTO "User"},
        'insert_clause() for User table'
    );
    is(
        $insert->columns_clause($dbh),
        q{("user_id", "username", "email", "size")},
        'columns_clause with one table'
    );
}

{
    my $insert = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    $insert->into(
        $s->table('User')->column('user_id'),
        $s->table('User')->column('username')
    );

    is(
        $insert->insert_clause($dbh), q{INSERT INTO "User"},
        'insert_clause() for User table'
    );
    is(
        $insert->columns_clause($dbh), q{("user_id", "username")},
        'columns_clause with two columns'
    );
}

{
    my $insert = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    $insert->into(
        $s->table('User')->column('user_id'),
        $s->table('User')->column('username')
    );

    eval { $insert->values( not_a_column => 1, user_id => 2, ) };
    like(
        $@, qr/not_a_column/,
        'cannot pass key to values() that is not a column name'
    );
}

{
    my $insert = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    $insert->into(
        $s->table('User')->column('user_id'),
        $s->table('User')->column('username')
    );

    eval { $insert->values( username => 'bob' ) };
    like(
        $@, qr/Mandatory parameter 'user_id'/,
        'columns without a default are required when calling values()'
    );
}

{
    my $insert = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    $insert->into(
        $s->table('User')->column('user_id'),
        $s->table('User')->column('username')
    );

    eval { $insert->values( user_id => 1, username => undef ) };
    like(
        $@,
        qr/\QThe 'username' parameter does not pass the type constraint\E.+undef/,
        'cannot pass undef for non-nullable column'
    );
}

{
    my $insert = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    $insert->into( $s->table('User')->column('size') );

    $insert->values( size => 'big' );
    is(
        $insert->values_clause($dbh), q{VALUES ('big')},
        'values_clause() for string as value'
    );
}

{
    my $insert = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    $insert->into( $s->table('User')->column('size') );

    $insert->values( size => undef );
    is(
        $insert->values_clause($dbh), q{VALUES (NULL)},
        'values_clause() for null as value'
    );
}

{
    my $insert = Fey::SQL->new_insert( auto_placeholders => 1 )->insert();

    $insert->into( $s->table('User')->column('size') );

    $insert->values( size => undef );
    is(
        $insert->values_clause($dbh), q{VALUES (NULL)},
        'values_clause() for null as value with auto placeholders'
    );
}

{
    my $insert = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    $insert->into( $s->table('User')->column('size') );

    my $func = Fey::Literal::Function->new('NOW');
    $insert->values( size => $func );
    is(
        $insert->values_clause($dbh), q{VALUES (NOW())},
        'values_clause() for function as value'
    );
}

{
    my $insert = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    $insert->into( $s->table('User')->column('size') );

    my $term = Fey::Literal::Term->new('term test');
    $insert->values( size => $term );
    is(
        $insert->values_clause($dbh), q{VALUES (term test)},
        'values_clause() for term as value'
    );
}

{
    my $insert = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    $insert->into( $s->table('User')->column('size') );

    $insert->values( size => Fey::Placeholder->new() );
    is(
        $insert->values_clause($dbh), q{VALUES (?)},
        'values_clause() for placeholder as value'
    );
}

{
    my $insert = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    $insert->into( $s->table('User')->column('size') );

    $insert->values( size => Fey::Placeholder->new() );
    is(
        $insert->values_clause($dbh), q{VALUES (?)},
        'values_clause() for placeholder as value'
    );
}

{
    my $insert = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    $insert->into( $s->table('User')->column('size') );

    $insert->values( size => 1 );
    $insert->values( size => 2 );
    is(
        $insert->values_clause($dbh), q{VALUES (1),(2)},
        'values_clause() for extended insert (multiple sets of values)'
    );
}

{
    my $insert = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    $insert->into( $s->table('User')->column('size') );

    $insert->values( size => 1 );
    is(
        $insert->sql($dbh), q{INSERT INTO "User" ("size") VALUES (1)},
        'sql() for full insert clause'
    );
}

{
    my $insert1 = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    $insert1->into( $s->table('User')->column('size') );

    my $insert2 = $insert1->clone();

    $insert1->values( size => 1 );

    $insert2->values( size => 42 );

    is(
        $insert1->sql($dbh), q{INSERT INTO "User" ("size") VALUES (1)},
        'sql() for full insert clause is unaffected by cloning'
    );

    is(
        $insert2->sql($dbh), q{INSERT INTO "User" ("size") VALUES (42)},
        'sql() for cloned insert clause has different value'
    );
}

{
    my $insert = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    $insert->into(
        $s->table('User')->columns( 'size', 'email', 'username' ) );

    $insert->values(
        size     => Fey::Placeholder->new(),
        email    => Fey::Placeholder->new(),
        username => Fey::Placeholder->new(),
    );

    is(
        $insert->sql($dbh),
        q{INSERT INTO "User" ("size", "email", "username") VALUES (?, ?, ?)},
        'sql() preserves column order in INTO clause'
    );
}

{
    my $insert = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    $insert->into(
        $s->table('User')->columns( 'email', 'username', 'size' ) );

    $insert->values(
        size     => Fey::Placeholder->new(),
        email    => Fey::Placeholder->new(),
        username => Fey::Placeholder->new(),
    );

    is(
        $insert->sql($dbh),
        q{INSERT INTO "User" ("email", "username", "size") VALUES (?, ?, ?)},
        'sql() preserves column order in INTO clause (different order)'
    );
}

{
    my $select = Fey::SQL->new_select()->select(1)->from( $s->table('User') );

    #<<<
    my $insert =
        Fey::SQL->new_insert
                ->insert()
                ->into( $s->table('User')
                ->columns('email', 'username') )
                ->values( email => 'foo@example.com',
                          username => $select,
                        );
    #>>>
    is(
        $insert->sql($dbh),
        q{INSERT INTO "User" ("email", "username") VALUES (?, (SELECT 1 FROM "User"))},
        'insert where one value is a SELECT query'
    );
}

done_testing();
