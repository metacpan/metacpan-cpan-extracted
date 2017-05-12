use strict;
use warnings;

use lib 't/lib';

use Fey::Test 0.05;
use Test::More 0.88;

use Fey::SQL;

my $s   = Fey::Test->mock_test_schema_with_fks();
my $dbh = Fey::Test->mock_dbh();

{
    my $q = Fey::SQL->new_select();

    $q->where( $s->table('User')->column('user_id'), '=', 5 );

    is(
        $q->where_clause($dbh), q{WHERE "User"."user_id" = ?},
        'simple comparison with placeholders - col = literal'
    );
    is_deeply(
        [ $q->bind_params() ], [5],
        'bind_params is [ 5 ]'
    );
}

{
    my $q = Fey::SQL->new_select();

    $q->where( $s->table('User')->column('username'), '=', 'bob' );

    is(
        $q->where_clause($dbh), q{WHERE "User"."username" = ?},
        'simple comparison with placeholders - col = overloaded object'
    );
    is_deeply(
        [ $q->bind_params() ], ['bob'],
        q{bind_params is [ 'bob' ]}
    );
}

{
    my $q = Fey::SQL->new_select();

    $q->where( $s->table('User')->column('user_id'), '=', 5 );
    $q->where('or');
    $q->where( $s->table('User')->column('user_id'), '=', 7 );

    is(
        $q->where_clause($dbh),
        q{WHERE "User"."user_id" = ? OR "User"."user_id" = ?},
        'multi-clause comparison with placeholders'
    );
    is_deeply(
        [ $q->bind_params() ], [ 5, 7 ],
        'bind_params is [ 5, 7 ]'
    );
}

{
    my $q = Fey::SQL->new_select();

    my $subselect = Fey::SQL->new_select();
    $subselect->select( $s->table('User')->column('user_id') );
    $subselect->from( $s->table('User') );
    $subselect->where(
        $s->table('User')->column('user_id'), 'IN', 5, 6, 7,
        9
    );

    $q->from($subselect);

    is(
        $q->from_clause($dbh),
        q{FROM ( SELECT "User"."user_id" FROM "User" WHERE "User"."user_id" IN (?, ?, ?, ?) ) AS "SUBSELECT0"},
        'subselect in FROM with placeholders'
    );
    is_deeply(
        [ $q->bind_params() ], [ 5, 6, 7, 9 ],
        'bind_params is [ 5, 6, 7, 9 ]'
    );
}

{
    my $q = Fey::SQL->new_select();

    my $subselect = Fey::SQL->new_select();
    $subselect->select( $s->table('User')->column('user_id') );
    $subselect->from( $s->table('User') );
    $subselect->where(
        $s->table('User')->column('user_id'), 'IN', 5, 6, 7,
        9
    );

    $q->where( $s->table('User')->column('user_id'), 'IN', $subselect );

    is(
        $q->where_clause($dbh),
        q{WHERE "User"."user_id" IN (SELECT "User"."user_id" FROM "User" WHERE "User"."user_id" IN (?, ?, ?, ?))},
        'subselect in WHERE with placeholders'
    );
    is_deeply(
        [ $q->bind_params() ], [ 5, 6, 7, 9 ],
        'bind_params is [ 5, 6, 7, 9 ]'
    );
}

{
    my $q = Fey::SQL->new_select();

    $q->having( $s->table('User')->column('user_id'), '=', 5 );

    is(
        $q->having_clause($dbh), q{HAVING "User"."user_id" = ?},
        'HAVING with placeholders - col = literal'
    );
    is_deeply(
        [ $q->bind_params() ], [5],
        'bind_params is [ 5 ]'
    );
}

{
    my $q = Fey::SQL->new_select();

    my $subselect = Fey::SQL->new_select();
    $subselect->select( $s->table('User')->column('user_id') );
    $subselect->from( $s->table('User') );
    $subselect->where(
        $s->table('User')->column('user_id'), 'IN',
        5, 6, 7, 9
    );

    $q->having( $s->table('User')->column('user_id'), 'IN', $subselect );

    is(
        $q->having_clause($dbh),
        q{HAVING "User"."user_id" IN (SELECT "User"."user_id" FROM "User" WHERE "User"."user_id" IN (?, ?, ?, ?))},
        'subselect in HAVING with placeholders'
    );
    is_deeply(
        [ $q->bind_params() ], [ 5, 6, 7, 9 ],
        'bind_params is [ 5, 6, 7, 9 ] (got bind params from subselect in HAVING clause)'
    );
}

{
    my $q = Fey::SQL->new_select();

    my $subselect = Fey::SQL->new_select();
    $subselect->select( $s->table('User')->column('user_id') );
    $subselect->from( $s->table('User') );
    $subselect->where( $s->table('User')->column('user_id'), 'IN', 5, 9 );

    $q->from($subselect);
    $q->where( $s->table('User')->column('user_id'), '=',  29 );
    $q->where( $s->table('User')->column('user_id'), 'IN', $subselect );
    $q->having( $s->table('User')->column('user_id'), '=', 23 );

    is_deeply(
        [ $q->bind_params() ], [ 5, 9, 29, 5, 9, 23 ],
        'bind_params is [ 5, 9, 29, 5, 9, 23 ] (got bind params from subselect in WHERE clause)'
    );
}

{
    my $q = Fey::SQL->new_select();

    my $q2 = Fey::SQL->new_where();
    $q2->where( $s->table('User')->column('user_id'), '=', 2 );

    $q->from( $s->table('User'), 'left', $s->table('UserGroup'), $q2 );
    $q->where( $s->table('User')->column('user_id'), '=', 3 );

    my $sql = q{FROM "User" LEFT OUTER JOIN "UserGroup"};
    $sql .= q{ ON ("UserGroup"."user_id" = "User"."user_id"};
    $sql .= q{ AND "User"."user_id" = ?)};

    is(
        $q->from_clause($dbh), $sql,
        'from_clause() SQL uses placeholders'
    );

    is_deeply(
        [ $q->bind_params() ], [ 2, 3 ],
        'bind_params is [ 2, 3 ] (got bind params from condition in FROM clause)'
    );
}

{
    my $q = Fey::SQL->new_select();

    my $subselect = Fey::SQL->new_select();
    #<<<
    $subselect
        ->select( $s->table('User') )
        ->from  ( $s->table('User') )
        ->where( $s->table('User')->column('user_id'), '=', 2 );

    $q
        ->select( $s->table('User'), $subselect )
        ->from  ( $s->table('User') )
        ->where( $s->table('User')->column('user_id'), '=', 3 );
    #>>

    is_deeply(
        [ $q->bind_params() ], [ 2, 3 ],
        'bind_params is [ 2, 3 ] (got bind params from subselect in SELECT clause)'
    );
}

done_testing();
