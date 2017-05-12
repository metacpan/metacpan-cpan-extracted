use strict;
use warnings;

use lib 't/lib';

use Fey::Test 0.05;
use Test::More 0.88;

use Fey::SQL;

my $s   = Fey::Test->mock_test_schema();
my $dbh = Fey::Test->mock_dbh();

{
    my $q = Fey::SQL->new_update();
    $q->update( $s->table('User') );
    $q->set( $s->table('User')->column('username'), 'bubba' );

    is(
        $q->set_clause($dbh), q{SET "username" = ?},
        'set_clause() for one column'
    );
    is_deeply(
        [ $q->bind_params() ], ['bubba'],
        q{bind_params() is [ 'bubba' ]}
    );
}

{
    my $q = Fey::SQL->new_update();
    $q->update( $s->table('User') );
    $q->set(
        $s->table('User')->column('username'), 'bubba',
        $s->table('User')->column('email'),    'bubba@bubba.com',
    );

    is(
        $q->set_clause($dbh),
        q{SET "username" = ?, "email" = ?},
        'set_clause() for two columns'
    );

    is_deeply(
        [ $q->bind_params() ], [ 'bubba', 'bubba@bubba.com' ],
        q{bind_params() is [ 'bubba', 'bubba@bubba.com' ]}
    );
}

{
    my $q = Fey::SQL->new_update();
    $q->update( $s->table('User') );
    $q->set(
        $s->table('User')->column('username'), 'bubba',
        $s->table('User')->column('email'),    'bubba@bubba.com',
    );

    $q->where( $s->table('User')->column('user_id'), 'BETWEEN', 1, 5 );

    is_deeply(
        [ $q->bind_params() ], [ 'bubba', 'bubba@bubba.com', 1, 5 ],
        q{bind_params() is [ 'bubba', 'bubba@bubba.com', 1, 5 ]}
    );
}

done_testing();
