package MyModel::Twitter::User;
use Moose;
use ElasticSearchX::Model::Document;

package MyModel::Twitter::Tweet;
use Moose;
use ElasticSearchX::Model::Document;

package MyModel::IRC::User;
use Moose;
BEGIN { extends 'MyModel::Twitter::User'; }

package MyIndexTrait;
use Moose::Role;

package MyModel;
use Moose;
use ElasticSearchX::Model;

analyzer lowercase => ( tokenizer => 'keyword',  filter   => 'lowercase' );
analyzer fulltext  => ( type      => 'snowball', language => 'English' );

index twitter =>
    ( namespace => 'MyModel::Twitter', alias_for => 'twitter_v1' );
index irc => ( namespace => 'MyModel::IRC', traits => [qw(MyIndexTrait)] );

__PACKAGE__->meta->make_immutable;

package main;
use Test::Most;
use strict;
use warnings;

ok( my $model = MyModel->new(), 'Created object ok' );
my $meta = $model->meta;
ok( $model->does('ElasticSearchX::Model::Role'), 'Does role' );

is_deeply(
    [ sort $meta->get_index_list ],
    [ sort 'irc', 'twitter', 'twitter_v1' ],
    'Has index twitter'
);

ok( my $idx = $model->index('twitter'), 'Get index twitter' );
ok( $idx = $model->index('twitter_v1'), 'Get index twitter_v1' );

is_deeply(
    $idx->types,
    {
        user  => MyModel::Twitter::User->meta,
        tweet => MyModel::Twitter::Tweet->meta
    },
    'Types loaded ok'
);

ok( $idx = $idx->model->index('irc'), 'Switch index' );

isa_ok( $idx, 'ElasticSearchX::Model::Index' );

is_deeply(
    $idx->types,
    { user => MyModel::IRC::User->meta },
    'Types loaded ok'
);

ok( $idx->does('MyIndexTrait'), 'Trait has been applied' );

isa_ok( $idx->type('user'), 'ElasticSearchX::Model::Document::Set' );

is_deeply( $idx->type('user')->index, $idx, 'MyModel::IRC::User' );

#$model->deploy;

done_testing;
