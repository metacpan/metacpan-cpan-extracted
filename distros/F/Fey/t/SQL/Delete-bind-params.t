use strict;
use warnings;

use lib 't/lib';

use Fey::Test 0.05;
use Test::More 0.88;

use Fey::SQL;

my $s   = Fey::Test->mock_test_schema();
my $dbh = Fey::Test->mock_dbh();

{
    my $q = Fey::SQL->new_delete();
    $q->delete()->from( $s->table('User') );
    $q->where( $s->table('User')->column('user_id'), '=', 10 );
    $q->where('OR');
    $q->where( $s->table('User')->column('username'), '=', 'Bob' );

    is(
        $q->where_clause('Fey::FakeDBI'),
        q{WHERE "User"."user_id" = ? OR "User"."username" = ?},
        'where_clause for delete with bind params'
    );
    is_deeply(
        [ $q->bind_params() ], [ 10, 'Bob' ],
        q{bind_params() is [ 10, 'Bob' ]}
    );
}

done_testing();
