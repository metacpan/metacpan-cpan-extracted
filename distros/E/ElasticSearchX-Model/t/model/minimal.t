package MyModel::User;
use Moose;
use ElasticSearchX::Model::Document;

package MyModel::Tweet;
use Moose;
use ElasticSearchX::Model::Document;

package MyModel;
use Moose;
use ElasticSearchX::Model;

__PACKAGE__->meta->make_immutable;

package main;
use Test::Most;
use strict;
use warnings;

ok( my $model = MyModel->new(), 'Created object ok' );
my $meta = $model->meta;

is_deeply( [ $meta->get_index_list ], ['default'], 'Has index default' );

ok( my $idx = $model->index('default'), 'Get default index' );

is_deeply(
    $idx->types,
    {
        user  => MyModel::User->meta,
        tweet => MyModel::Tweet->meta
    },
    'Types loaded ok'
);

done_testing;
