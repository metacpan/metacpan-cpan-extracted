use strict;
use warnings;
use lib qw(t/lib);
use MyModel;
use Test::Most;
use DateTime;

my $model   = MyModel->testing;
my $twitter = $model->index('twitter')->type('user');
$twitter->delete;
ok(
    $twitter->put(
        {
            nickname => $_,
            name     => 'mo',
        }
    ),
    'Put mo ok'
) for ( 1 .. 10 );

ok(
    $twitter->put(
        {
            name     => 'plu',
            nickname => $_,
        }
    ),
    'Put plu ok'
) for ( 11 .. 15 );

$twitter->index->refresh;

is( $twitter->count, 15, '15 created' );

ok( $twitter->filter( { term => { name => 'mo' } } )->delete, 'run delete' );
sleep 5;    # wait for delete action to finish

is( $twitter->filter( { term => { name => 'mo' } } )->count,
    0, 'none remain' );

is( $twitter->count, 5, '5 remain' );

done_testing;
