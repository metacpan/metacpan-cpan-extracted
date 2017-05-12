package MyModel::User;

use Moose;
use ElasticSearchX::Model::Document;

package MyModel::Tweet;

use Moose;
use ElasticSearchX::Model::Document;

has text => ( is => 'ro' );

package MyModel;

use Moose;
use ElasticSearchX::Model;

__PACKAGE__->meta->make_immutable;

package main;

use strict;
use warnings;

use Test::Most;
use Test::MockObject::Extends;

my $es = Test::MockObject::Extends->new( Search::Elasticsearch->new );
my $i  = 0;
$es->mock( bulk => sub { $i++; return {} } );

ok( my $model = MyModel->new( es => $es ), 'Created object' );

my $stash;
{
    ok( my $bulk = $model->bulk, 'bulk object' );
    $stash = $bulk->stash->_buffer;

    $bulk->put( $model->index('default')->type('tweet')
            ->new_document( { text => 'foo' } ) );

    is( $bulk->stash_size, 1, 'stash size is 1' );
    ok( !$i, "bulk not yet called" );
}

ok( $i, "bulk was called" );

is_deeply( $stash, [], 'stash has been commited' );

done_testing;
