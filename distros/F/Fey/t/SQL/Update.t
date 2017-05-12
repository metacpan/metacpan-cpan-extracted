use strict;
use warnings;

use lib 't/lib';

use Fey::Test 0.05;
use Test::More 0.88;

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
    eval { Fey::SQL->new_update()->update() };

    like(
        $@, qr/1 was expected/,
        'update() without any parameters fails'
    );
}

{
    my $update = Fey::SQL->new_update()->update( $s->table('User') );

    is(
        $update->update_clause($dbh), q{UPDATE "User"},
        'update clause for one table'
    );
}

{
    my $update = Fey::SQL->new_update()
        ->update( $s->table('User'), $s->table('UserGroup') );

    is(
        $update->update_clause($dbh), q{UPDATE "User", "UserGroup"},
        'update clause for two tables'
    );
}

{
    my $update = Fey::SQL->new_update( auto_placeholders => 0 );
    $update->update( $s->table('User') );
    $update->set( $s->table('User')->column('username'), 'bubba' );

    is(
        $update->set_clause($dbh), q{SET "username" = 'bubba'},
        'set_clause() for one column'
    );
}

{
    my $update = Fey::SQL->new_update( auto_placeholders => 0 );
    $update->update( $s->table('User') );
    $update->set(
        $s->table('User')->column('username'), 'bubba',
        $s->table('User')->column('email'),    'bubba@bubba.com',
    );

    is(
        $update->set_clause($dbh),
        q{SET "username" = 'bubba', "email" = 'bubba@bubba.com'},
        'set_clause() for two columns'
    );
}

{
    my $update = Fey::SQL->new_update();
    $update->update( $s->table('User') );
    $update->set(
        $s->table('User')->column('username'),
        $s->table('User')->column('email'),
    );

    is(
        $update->set_clause($dbh),
        q{SET "username" = "User"."email"},
        'set_clause() for column = columns'
    );
}

{
    my $update = Fey::SQL->new_update();
    $update->update( $s->table('User') );
    $update->set(
        $s->table('User')->column('size'),
        Fey::Literal->new_from_scalar(undef),
    );

    is(
        $update->set_clause($dbh),
        q{SET "size" = NULL},
        'set_clause() for column = NULL (literal)'
    );
}

{
    my $update = Fey::SQL->new_update();
    $update->update( $s->table('User') );
    $update->set(
        $s->table('User')->column('username'),
        Fey::Literal->new_from_scalar('string'),
    );

    is(
        $update->set_clause($dbh),
        q{SET "username" = 'string'},
        'set_clause() for column = string (literal)'
    );
}

{
    my $update = Fey::SQL->new_update();
    $update->update( $s->table('User') );
    $update->set(
        $s->table('User')->column('username'),
        Fey::Literal->new_from_scalar(42),
    );

    is(
        $update->set_clause($dbh),
        q{SET "username" = 42},
        'set_clause() for column = number (literal)'
    );
}

{
    my $update = Fey::SQL->new_update();
    $update->update( $s->table('User') );
    $update->set(
        $s->table('User')->column('username'),
        Fey::Literal::Function->new('NOW'),
    );

    is(
        $update->set_clause($dbh),
        q{SET "username" = NOW()},
        'set_clause() for column = function (literal)'
    );
}

{
    my $update = Fey::SQL->new_update();
    $update->update( $s->table('User') );
    $update->set(
        $s->table('User')->column('username'),
        Fey::Literal::Term->new('thingy'),
    );

    is(
        $update->set_clause($dbh),
        q{SET "username" = thingy},
        'set_clause() for column = term (literal)'
    );
}

{
    my $update = Fey::SQL->new_update();
    $update->update( $s->table('User') );
    $update->set(
        $s->table('User')->column('username'),
        Fey::Literal::Term->new('thingy'),
    );

    is(
        $update->set_clause($dbh),
        q{SET "username" = thingy},
        'set_clause() for column = term (literal)'
    );
}

{
    my $update = Fey::SQL->new_update( auto_placeholders => 0 );
    $update->update( $s->table('User') );
    $update->set( $s->table('User')->column('username'), 'hello' );
    $update->where( $s->table('User')->column('user_id'), '=', 10 );
    $update->order_by( $s->table('User')->column('user_id') );
    $update->limit(10);

    is(
        $update->sql($dbh),
        q{UPDATE "User" SET "username" = 'hello' WHERE "User"."user_id" = 10 ORDER BY "User"."user_id" LIMIT 10},
        'update sql with where clause, order by, and limit'
    );
}

{
    my $update = Fey::SQL->new_update( auto_placeholders => 0 );
    $update->update( $s->table('User') );
    $update->set( $s->table('User')->column('email'), undef );

    is(
        $update->set_clause($dbh),
        q{SET "email" = NULL},
        'set a column to NULL with placeholders off'
    );
}

{
    my $update = Fey::SQL->new_update();
    $update->update( $s->table('User'), $s->table('Group') );
    $update->set(
        $s->table('User')->column('username'),
        $s->table('Group')->column('name')
    );

    is(
        $update->set_clause($dbh), q{SET "User"."username" = "Group"."name"},
        'set_clause() for multi-table update'
    );
}

{
    my $update = Fey::SQL->new_update();
    $update->update( $s->table('User') );
    eval { $update->set() };

    like(
        $@, qr/list of paired/,
        'set() called with no parameters'
    );
}

{
    my $update = Fey::SQL->new_update();
    $update->update( $s->table('User') );
    eval { $update->set( $s->table('User')->column('username') ) };

    like(
        $@, qr/list of paired/,
        'set() called with one parameter'
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
    my $update = Fey::SQL->new_update( auto_placeholders => 1 );
    $update->update( $s->table('User') );
    $update->set( $s->table('User')->column('user_id'), Num->new(42) );

    is(
        $update->set_clause($dbh), q{SET "user_id" = ?},
        'set_clause() for one column with overloaded object and auto placeholders'
    );
    is_deeply(
        [ $update->bind_params() ], [42],
        'bind params with overloaded object'
    );
}

{
    my $update = Fey::SQL->new_update( auto_placeholders => 0 );
    $update->update( $s->table('User') );
    $update->set( $s->table('User')->column('user_id'), Num->new(42) );

    is(
        $update->set_clause($dbh), q{SET "user_id" = 42},
        'set_clause() for one column with overloaded object, no placeholders'
    );
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
    my $update = Fey::SQL->new_update( auto_placeholders => 1 );
    $update->update( $s->table('User') );
    $update->set( $s->table('User')->column('username'), Str->new('Bubba') );

    is(
        $update->set_clause($dbh), q{SET "username" = ?},
        'set_clause() for one column with overloaded object and auto placeholders'
    );
    is_deeply(
        [ $update->bind_params() ], ['Bubba'],
        'bind params with overloaded object'
    );
}

{
    my $update = Fey::SQL->new_update( auto_placeholders => 0 );
    $update->update( $s->table('User') );
    $update->set( $s->table('User')->column('username'), Str->new('Bubba') );

    is(
        $update->set_clause($dbh), q{SET "username" = 'Bubba'},
        'set_clause() for one column with overloaded object, no placeholders'
    );
}

{
    my $update1 = Fey::SQL->new_update( auto_placeholders => 0 );
    $update1->update( $s->table('User') );
    $update1->set( $s->table('User')->column('username'), 'hello' );

    my $update2 = $update1->clone();

    $update2->where( $s->table('User')->column('user_id'), '=', 10 );
    $update2->order_by( $s->table('User')->column('user_id') );
    $update2->limit(10);

    is(
        $update1->sql($dbh),
        q{UPDATE "User" SET "username" = 'hello'},
        'original update sql does not have where clause, order by, or limit'
    );

    is(
        $update2->sql($dbh),
        q{UPDATE "User" SET "username" = 'hello' WHERE "User"."user_id" = 10 ORDER BY "User"."user_id" LIMIT 10},
        'cloned update sql has where clause, order by, and limit'
    );
}

{
    my $select = Fey::SQL->new_select()->select(1)->from( $s->table('User') );

    #<<<
    my $update =
        Fey::SQL->new_update
                ->update( $s->table('User') )
                ->set( $s->table('User')->column('email')    => 'foo@example.com',
                       $s->table('User')->column('username') => $select,
                     );
    #>>>
    is(
        $update->sql($dbh),
        q{UPDATE "User" SET "email" = ?, "username" = (SELECT 1 FROM "User")},
        'update where one value is a SELECT query'
    );
}

done_testing();
