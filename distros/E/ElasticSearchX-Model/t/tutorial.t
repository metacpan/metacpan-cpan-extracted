use strict;
use warnings;
use lib qw(t/lib);
use MyModel;
use Test::Most;
use DateTime;
use JSON::MaybeXS;

my $model     = MyModel->testing;
my $twitter   = $model->index('twitter');
my $timestamp = DateTime->now;
ok(
    my $tweet = $twitter->type('tweet')->put(
        {
            user      => 'mo',
            post_date => $timestamp,
            message   => 'Elastic baby!',
        },
        { refresh => 1 }
    ),
    'Put ok'
);

ok( $tweet->_id, 'has id' );
is( $tweet->_version, 1, 'has version 1' );
my $tweets = $twitter->type('tweet');

is( $tweets->count, 1, 'Count ok' );

throws_ok {
    $twitter->type('tweet')->get( { post_date => $timestamp, } );
}
qr/fields/;

ok( $tweets->get( $tweet->id ), 'Get tweet by id' );

ok(
    $tweet = $tweets->get(
        {
            user      => 'mo',
            post_date => $timestamp,
        }
    ),
    'Get tweet by key/values'
);

is( $tweet->_version, 1, 'version still 1 after get' );

isa_ok( $tweet->post_date, 'DateTime' );
my $raw = {
    _id     => $tweet->id,
    _index  => "twitter",
    _source => {
        id        => $tweet->id,
        message   => "Elastic baby!",
        post_date => $timestamp->iso8601,
        user      => "mo"
    },
    _type    => "tweet",
    _version => 1
};
$tweets = $tweets->raw;
is_deeply(
    $tweets->get( $tweet->id ),
    { %$raw, found => JSON::true },
    'Raw response'
);

is_deeply(
    $tweets->all->{hits},
    { hits => [ { %$raw, _score => 1 } ], max_score => 1, total => 1 },
    'Raw all response'
);

is(
    $twitter->type('tweet')->filter( { term => { user => 'mo' } } )->query(
        {
            query_string =>
                { default_field => 'message.analyzed', query => 'baby' }
        }
        )->size(100)->all,
    1,
    'get all tweets that match "hello"'
);

{
    my $iterator = $twitter->type('tweet')->scroll;
    my $i        = 0;
    while ( my $tweet = $iterator->next ) {
        $i++;
        is( $tweet->_version, 1, '_version set on search as well' );
        isa_ok( $tweet, 'MyModel::Tweet' );
    }
    is( $i, 1, 'got one result' );
}
{
    my $iterator = $twitter->type('tweet')->raw->scroll;
    my $i        = 0;
    while ( my $tweet = $iterator->next ) {
        $i++;
        is( ref $tweet, 'HASH', 'isa HashRef' );
    }
    is( $i, 1, 'got one result' );
    ok( $twitter->delete, 'delete twitter index' );
}

{

    package MyModel::Reindex;
    use Moose;
    use ElasticSearchX::Model;

    index twitter => ( namespace => 'MyModel', alias_for => 'twitter_v1' );
    index twitter_v2 => ( namespace => 'MyModel' );
}

{

    package main;
    my $model = MyModel::Reindex->new( es => $ENV{ES} || ':9900' );
    $model->deploy( delete => 1 );
    my $old = $model->index('twitter');
    my $new = $model->index('twitter_v2');

    ok(
        my $tweet = $old->type('tweet')->put(
            {
                user      => 'mo',
                post_date => $timestamp,
                message   => 'Elastic baby!',
            },
            { refresh => 1 }
        ),
        'create document'
    );
    my $iterator = $old->type('tweet')->size(1000)->scroll;
    while ( my $tweet = $iterator->next ) {
        $tweet->message('something else');
        $tweet->index($new);
        $tweet->put;
    }
    ok( $model->meta->remove_index('twitter'), 'remove index twitter' );
    ok(
        $model->meta->add_index(
            'twitter', { namespace => 'MyModel', alias_for => 'twitter_v2' }
        ),
        'add index twitter'
    );
    ok( $model->deploy, 'deploy model to update aliases' );
    ok( my $reindexed = $old->type('tweet')->first, 'get from twitter' );
    is( $reindexed->message, 'something else', 'reindexed' );
}

done_testing;
