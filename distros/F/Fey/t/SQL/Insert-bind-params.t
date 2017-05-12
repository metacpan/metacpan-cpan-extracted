use strict;
use warnings;

use lib 't/lib';

use Fey::Test 0.05;
use Test::More 0.88;

use Fey::SQL;

my $s   = Fey::Test->mock_test_schema_with_fks();
my $dbh = Fey::Test->mock_dbh();

{
    my $q = Fey::SQL->new_insert()->insert();

    $q->into( $s->table('User')->columns( 'user_id', 'username' ) );

    $q->values( user_id => 1, username => 'bob' );

    is(
        $q->values_clause($dbh), q{VALUES (?, ?)},
        'values_clause() for normal insert'
    );
    is_deeply(
        [ $q->bind_params() ], [ 1, 'bob' ],
        q{bind_params() is [ 1, 'bob' ]}
    );
}

{
    my $q = Fey::SQL->new_insert()->insert();

    $q->into( $s->table('User')->columns( 'user_id', 'username' ) );

    $q->values( user_id => 1, username => 'bob' );
    $q->values( user_id => 2, username => 'faye' );

    is(
        $q->values_clause($dbh), q{VALUES (?, ?),(?, ?)},
        'values_clause() for extended insert'
    );
    is_deeply(
        [ $q->bind_params() ], [ 1, 'bob', 2, 'faye' ],
        q{bind_params() is [ 1, 'bob', 2, 'faye' ]}
    );
}

{
    my $q = Fey::SQL->new_insert()->insert();

    $q->into(
        $s->table('User')->column('user_id'),
        $s->table('User')->column('username')
    );

    $q->values( user_id => 42, username => 'Bubba' );

    is(
        $q->columns_clause($dbh), q{("user_id", "username")},
        'insert clause has columns in expected order'
    );
    is(
        $q->values_clause($dbh), q{VALUES (?, ?)},
        'values_clause() for two columns column with auto placeholders'
    );
    is_deeply(
        [ $q->bind_params() ], [ 42, 'Bubba' ],
        'bind params are in the right order'
    );
}

{
    my $q = Fey::SQL->new_insert()->insert();

    $q->into(
        $s->table('User')->column('username'),
        $s->table('User')->column('user_id')
    );

    $q->values( user_id => 42, username => 'Bubba' );

    is(
        $q->columns_clause($dbh), q{("username", "user_id")},
        'columns clause has columns in expected order'
    );
    is_deeply(
        [ $q->bind_params() ], [ 'Bubba', 42 ],
        'bind params are in the right order'
    );
}

my $size = Fey::Column->new(
    name        => 'size',
    type        => 'text',
    is_nullable => 1,
);
$s->table('User')->add_column($size);

{
    my $insert = Fey::SQL->new_insert( auto_placeholders => 1 );

    $insert->into(
        $s->table('User')->columns( 'user_id', 'size', 'username' ) );
    $insert->values(
        size     => 42,
        user_id  => 921,
        username => 'User',
    );

    is(
        $insert->sql($dbh),
        q{INSERT INTO "User" ("user_id", "size", "username") VALUES (?, ?, ?)},
        'sql() for insert with auto-placeholders - column order matches into()'
    );
    is_deeply(
        [ $insert->bind_params() ],
        [ 921, 42, 'User' ],
        'bind_params() returns params in the right order'
    );
}

{

    package Num;

    use overload '0+' => sub { ${ $_[0] } };

    sub new {
        my $num = $_[1];
        return bless \$num, __PACKAGE__;
    }
}

{

    package Str;

    use overload q{""} => sub { ${ $_[0] } };

    sub new {
        my $str = $_[1];
        return bless \$str, __PACKAGE__;
    }
}

{
    my $q = Fey::SQL->new_insert( auto_placeholders => 1 )->insert();

    $q->into(
        $s->table('User')->column('user_id'),
        $s->table('User')->column('username')
    );

    $q->values( user_id => Num->new(42), username => Str->new('Bubba') );

    is(
        $q->values_clause($dbh), q{VALUES (?, ?)},
        'values_clause() for two columns column with overloaded objects and auto placeholders'
    );
    is_deeply(
        [ $q->bind_params() ], [ 42, 'Bubba' ],
        'bind params with overloaded object'
    );
}

{
    my $q = Fey::SQL->new_insert( auto_placeholders => 0 )->insert();

    $q->into(
        $s->table('User')->column('user_id'),
        $s->table('User')->column('username')
    );

    $q->values( user_id => Num->new(42), username => Str->new('Bubba') );

    is(
        $q->values_clause($dbh), q{VALUES (42, 'Bubba')},
        'values_clause() for two columns column with overloaded object, no placeholders'
    );
}

done_testing();
