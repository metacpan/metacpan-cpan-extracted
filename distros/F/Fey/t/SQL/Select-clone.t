use strict;
use warnings;

use lib 't/lib';

use Fey::Test 0.05;
use Test::More 0.88;

use Fey::SQL;

my $s   = Fey::Test->mock_test_schema();
my $dbh = Fey::Test->mock_dbh();

{
    my $select1 = Fey::SQL->new_select();

    $select1->select( $s->table('User')->column('user_id') );

    $select1->from( $s->table('User') );

    my $select2 = $select1->clone();

    $select2->where( $s->table('User')->column('username'), '=', 'Bob' );

    is(
        $select1->sql($dbh), q{SELECT "User"."user_id" FROM "User"},
        'original select has no where clause'
    );

    is(
        $select2->sql($dbh),
        q{SELECT "User"."user_id" FROM "User" WHERE "User"."username" = ?},
        'cloned select has a where clause'
    );
}

done_testing();
