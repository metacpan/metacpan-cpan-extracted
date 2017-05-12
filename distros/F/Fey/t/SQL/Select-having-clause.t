use strict;
use warnings;

use lib 't/lib';

use Fey::Test 0.05;
use Test::More 0.88;

use Fey::Placeholder;
use Fey::SQL;

my $s   = Fey::Test->mock_test_schema_with_fks();
my $dbh = Fey::Test->mock_dbh();

{
    my $q = Fey::SQL->new_select();

    eval { $q->having() };
    like(
        $@, qr/does not pass the type constraint/,
        'having() without any parameters is an error'
    );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 );

    $q->having( $s->table('User')->column('user_id'), '=', 1 );

    is(
        $q->having_clause($dbh), q{HAVING "User"."user_id" = 1},
        'simple comparison - col = literal'
    );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 );

    $q->having(
        $s->table('User')->column('user_id')->alias( alias_name => 'alias' ),
        '=', 1
    );

    is(
        $q->having_clause($dbh), q{HAVING "alias" = 1},
        'simple comparison - col alias = literal'
    );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 );

    $q->having(
        $s->table('User')->column('username'), 'LIKE',
        '%foo%'
    );

    is(
        $q->having_clause($dbh), q{HAVING "User"."username" LIKE '%foo%'},
        'simple comparison - col LIKE literal'
    );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 );

    $q->having( 1, '=', $s->table('User')->column('user_id') );

    is(
        $q->having_clause($dbh), q{HAVING 1 = "User"."user_id"},
        'simple comparison - literal = col'
    );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 );

    $q->having(
        $s->table('User')->column('user_id'), '=',
        $s->table('User')->column('user_id')
    );

    is(
        $q->having_clause($dbh),
        q{HAVING "User"."user_id" = "User"."user_id"},
        'simple comparison - col = col'
    );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 );

    $q->having( $s->table('User')->column('user_id'), 'IN', 1, 2, 3 );

    is(
        $q->having_clause($dbh), q{HAVING "User"."user_id" IN (1, 2, 3)},
        'simple comparison - IN'
    );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 );

    $q->having( $s->table('User')->column('user_id'), 'NOT IN', 1, 2, 3 );

    is(
        $q->having_clause($dbh), q{HAVING "User"."user_id" NOT IN (1, 2, 3)},
        'simple comparison - IN'
    );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 );

    $q->having(
        $s->table('User')->column('user_id'), '=',
        Fey::Placeholder->new()
    );

    is(
        $q->having_clause($dbh), q{HAVING "User"."user_id" = ?},
        'simple comparison - col = placeholder'
    );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 );

    my $sub = Fey::SQL->new_select( auto_placeholders => 0 );
    $sub->select( $s->table('User')->column('user_id') );
    $sub->from( $s->table('User') );

    $q->having( $s->table('User')->column('user_id'), 'IN', $sub );

    is(
        $q->having_clause($dbh),
        q{HAVING "User"."user_id" IN (SELECT "User"."user_id" FROM "User")},
        'comparison with subselect'
    );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 );

    $q->having( $s->table('User')->column('user_id'), '=', undef );

    is(
        $q->having_clause($dbh), q{HAVING "User"."user_id" IS NULL},
        'undef in comparison (=)'
    );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 );

    $q->having( $s->table('User')->column('user_id'), '!=', undef );

    is(
        $q->having_clause($dbh), q{HAVING "User"."user_id" IS NOT NULL},
        'undef in comparison (!=)'
    );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 );

    $q->having( $s->table('User')->column('user_id'), 'BETWEEN', 1, 5 );

    is(
        $q->having_clause($dbh), q{HAVING "User"."user_id" BETWEEN 1 AND 5},
        'simple comparison - BETWEEN'
    );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 );

    $q->having( $s->table('User')->column('user_id'), '=', 1 );
    $q->having( $s->table('User')->column('user_id'), '=', 2 );

    is(
        $q->having_clause($dbh),
        q{HAVING "User"."user_id" = 1 AND "User"."user_id" = 2},
        'multiple clauses with implicit AN'
    );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 );

    $q->having( $s->table('User')->column('user_id'), '=', 1 );
    $q->having('or');
    $q->having( $s->table('User')->column('user_id'), '=', 2 );

    is(
        $q->having_clause($dbh),
        q{HAVING "User"."user_id" = 1 OR "User"."user_id" = 2},
        'multiple clauses with OR'
    );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 );

    $q->having('(');
    $q->having( $s->table('User')->column('user_id'), '=', 2 );
    $q->having(')');

    is(
        $q->having_clause($dbh), q{HAVING ( "User"."user_id" = 2 )},
        'subgroup in having clause'
    );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 );

    eval { $q->having( $s->table('User')->column('user_id'), '=', 1, 2 ) };
    like(
        $@, qr/more than one right-hand side/,
        'error when passing more than one RHS with ='
    );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 );

    my $sub = Fey::SQL->new_select( auto_placeholders => 0 );
    $sub->select( $s->table('User')->column('user_id') );
    $sub->from( $s->table('User') );

    eval { $q->having( $s->table('User')->column('user_id'), 'LIKE', $sub ) };
    like(
        $@, qr/use a subselect on the right-hand side/,
        'error when passing subselect with LIKE'
    );
}

{
    my $q = Fey::SQL->new_select( auto_placeholders => 0 );

    eval { $q->having( $s->table('User')->column('user_id'), 'BETWEEN', 1 ) };
    like(
        $@, qr/requires two arguments/,
        'error when passing one RHS with BETWEEN'
    );
}

done_testing();
