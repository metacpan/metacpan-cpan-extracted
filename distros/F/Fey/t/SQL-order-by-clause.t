use strict;
use warnings;

use lib 't/lib';

use Fey::Test 0.05;
use Test::More 0.88;

use Fey::Literal;
use Fey::SQL;

my $s   = Fey::Test->mock_test_schema_with_fks();
my $dbh = Fey::Test->mock_dbh();

{
    my $q = Fey::SQL->new_select()->select( $s->table('User') );

    eval { $q->order_by() };
    like(
        $@, qr/0 parameters/,
        'at least one parameter is required for order_by()'
    );
}

{
    my $q = Fey::SQL->new_select()->select( $s->table('User') );

    $q->order_by( $s->table('User')->column('user_id') );
    is(
        $q->order_by_clause($dbh), q{ORDER BY "User"."user_id"},
        'order_by() one column'
    );
}

{
    my $q = Fey::SQL->new_select()->select( $s->table('User') );

    $q->order_by( $s->table('User')->column('user_id'), 'ASC' );
    is(
        $q->order_by_clause($dbh), q{ORDER BY "User"."user_id" ASC},
        'order_by() one column explicit ASC'
    );
}

{
    my $q = Fey::SQL->new_select()->select( $s->table('User') );

    $q->order_by( $s->table('User')->column('user_id'), 'DESC' );
    is(
        $q->order_by_clause($dbh), q{ORDER BY "User"."user_id" DESC},
        'order_by() one column explicit DESC'
    );
}

{
    my $q = Fey::SQL->new_select()->select( $s->table('User') );

    $q->order_by( $s->table('User')->column('user_id'), 'DESC NULLS FIRST' );
    is(
        $q->order_by_clause($dbh),
        q{ORDER BY "User"."user_id" DESC NULLS FIRST},
        'order_by() one column nulls first'
    );
}

{
    my $q = Fey::SQL->new_select()->select( $s->table('User') );

    $q->order_by( $s->table('User')->column('user_id'), 'DESC NULLS LAST' );
    is(
        $q->order_by_clause($dbh),
        q{ORDER BY "User"."user_id" DESC NULLS LAST},
        'order_by() one column nulls last'
    );
}

{
    my $q = Fey::SQL->new_select()->select( $s->table('User') );

    $q->order_by(
        $s->table('User')->column('user_id'),
        $s->table('User')->column('username'), 'ASC'
    );
    is(
        $q->order_by_clause($dbh),
        q{ORDER BY "User"."user_id", "User"."username" ASC},
        'order_by() two columns'
    );
}

{
    my $q = Fey::SQL->new_select()->select( $s->table('User') );

    $q->order_by(
        $s->table('User')->column('user_id'),  'DESC',
        $s->table('User')->column('username'), 'ASC'
    );
    is(
        $q->order_by_clause($dbh),
        q{ORDER BY "User"."user_id" DESC, "User"."username" ASC},
        'order_by() two columns'
    );
}

{
    my $q = Fey::SQL->new_select()->select( $s->table('User') );

    $q->order_by( $s->table('User')->column('user_id')
            ->alias( alias_name => 'alias_test' ) );

    is(
        $q->order_by_clause($dbh), q{ORDER BY "alias_test"},
        'order_by() column alias'
    );
}

{
    my $q = Fey::SQL->new_select()->select( $s->table('User') );

    my $now = Fey::Literal::Function->new('NOW');
    $now->_make_alias();

    $q->order_by($now);

    like(
        $q->order_by_clause($dbh), qr/ORDER BY "FUNCTION\d+"/,
        'order_by() function'
    );
}

{
    my $q = Fey::SQL->new_select()->select( $s->table('User') );

    my $now = Fey::Literal::Function->new('NOW');
    $q->order_by($now);

    like(
        $q->order_by_clause($dbh), qr/ORDER BY NOW()/,
        'order_by() function without an alias'
    );
}

{
    my $q = Fey::SQL->new_select()->select( $s->table('User') );

    my $term = Fey::Literal::Term->new(q{"Foo"::text});
    $q->order_by($term);

    is(
        $q->order_by_clause($dbh), q{ORDER BY "Foo"::text},
        'order_by() term'
    );
}

done_testing();
