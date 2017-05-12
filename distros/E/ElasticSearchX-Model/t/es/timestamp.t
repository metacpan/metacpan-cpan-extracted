use strict;
use warnings;
use lib qw(t/lib);
use MyModel;
use Test::Most;
use DateTime;

my $model   = MyModel->testing;
my $twitter = $model->index('twitter')->type('user');
ok(
    $twitter->refresh->put(
        {
            nickname => 'mo',
            name     => 'Moritz Onken',
        }
    ),
    'Put mo ok'
);

ok( my $user = $twitter->fields( [qw(_timestamp _source)] )->first,
    'get user' );

is( $user->name, 'Moritz Onken', 'got field ok' );
ok( $user->timestamp, 'get timestamp field' );
is( $user->nickname, 'mo', 'nickname ok' );
ok( $user->update, 'update' );
is( $user->nickname, 'mo', 'nickname still ok' );
done_testing;
