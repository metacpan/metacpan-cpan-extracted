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
    eval { Fey::SQL->new_delete()->delete()->from() };

    like(
        $@, qr/1 was expected/,
        'from() without any parameters fails'
    );
}

{
    my $delete = Fey::SQL->new_delete()->delete()->from( $s->table('User') );

    is(
        $delete->delete_clause($dbh), q{DELETE FROM "User"},
        'delete clause for one table'
    );
}

{
    my $delete = Fey::SQL->new_delete()->delete()
        ->from( $s->table('User'), $s->table('UserGroup') );

    is(
        $delete->delete_clause($dbh), q{DELETE FROM "User", "UserGroup"},
        'delete clause for two tables'
    );
}

{
    my $delete = Fey::SQL->new_delete( auto_placeholders => 0 );
    $delete->delete()->from( $s->table('User') );
    $delete->where( $s->table('User')->column('user_id'), '=', 10 );
    $delete->order_by( $s->table('User')->column('user_id') );
    $delete->limit(10);

    is(
        $delete->sql($dbh),
        q{DELETE FROM "User" WHERE "User"."user_id" = 10 ORDER BY "User"."user_id" LIMIT 10},
        'delete sql with where clause, order by, and limit'
    );
}

{
    my $delete1 = Fey::SQL->new_delete();
    $delete1->delete()->from( $s->table('User') );

    my $delete2 = $delete1->clone();

    $delete2->where( $s->table('User')->column('user_id'), '=', 10 );
    $delete2->order_by( $s->table('User')->column('user_id') );
    $delete2->limit(10);

    is(
        $delete1->sql($dbh),
        q{DELETE FROM "User"},
        'original delete sql'
    );

    is(
        $delete2->sql($dbh),
        q{DELETE FROM "User" WHERE "User"."user_id" = ? ORDER BY "User"."user_id" LIMIT 10},
        'cloned delete sql adds where clause, order by, and limit'
    );
}

done_testing();
