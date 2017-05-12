use strict;
use warnings;

use lib 't/lib';

use Fey::Test 0.05;
use Test::More 0.88;

use Fey::SQL;

my $s   = Fey::Test->mock_test_schema_with_fks();
my $dbh = Fey::Test->mock_dbh();

{
    my $where1 = Fey::SQL->new_where( auto_placeholders => 0 );
    $where1->where( $s->table('User')->column('user_id'), '=', 2 );

    my $where2 = $where1->clone();
    $where2->where( $s->table('User')->column('username'), '=', 'Bob' );

    is(
        $where1->where_clause($dbh), q{WHERE "User"."user_id" = 2},
        'original where clause has one condition'
    );

    is(
        $where2->where_clause($dbh),
        q{WHERE "User"."user_id" = 2 AND "User"."username" = 'Bob'},
        'original where clause has two conditions'
    );
}

done_testing();
