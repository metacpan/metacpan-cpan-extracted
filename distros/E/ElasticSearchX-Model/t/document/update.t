use strict;
use warnings;

use lib qw(t/lib);

use MyModel;
use Test::Most;

my $model   = MyModel->testing;
my $twitter = $model->index('twitter')->type('user');

ok( $twitter->put( { nickname => 1, }, { refresh => 1 } ), 'Put mo ok' );

ok( my $tweet = $twitter->fields( [qw(nickname)] )->first,
    'get partial tweet' );

ok( $tweet->update, 'updating a partial document succeeds' );

ok( $tweet->put, 'put succeeds' );

ok( $tweet->update( { refresh => 1 } ), 'update succeeds after put' );

ok( $tweet = $twitter->first, 'get partial tweet' );

ok( $tweet->update, 'update succeeds after put' );

done_testing;
