use strict;
use warnings;
use Test::More tests => 2;
use Google::gRPC::Client;

subtest 'Client channel instantiation and streaming RPC setup' => sub {
    my $client = Google::gRPC::Client->new(
        target     => 'pubsub.googleapis.com:443',
        auth_token => 'mock_token_testtoken',
    );

    ok($client, 'instantiated Client');
    ok($client->channel, 'client lazy loaded channel');

    my $stream = $client->stream(
        service => 'google.pubsub.v1.Subscriber',
        method  => 'StreamingPull',
        type    => 'bidi',
    );

    ok($stream, 'created bidi stream via client');
    is($stream->type, 'bidi', 'stream type is bidi');
};

subtest 'Client integration with Pure-Perl and NGHTTP2 engines' => sub {
    my $client_pp = Google::gRPC::Client->new(
        target      => 'localhost:8000',
        engine_type => 'PP',
    );

    is($client_pp->channel->engine->is_xs, 0, 'client with engine_type PP uses PP engine');

    eval {
        require Google::gRPC::Engine::NGHTTP2;
        Google::gRPC::Engine::NGHTTP2->can('_xs_new') or die 'not built';
        my $client_xs = Google::gRPC::Client->new(
            target      => 'localhost:8000',
            engine_type => 'NGHTTP2',
        );
        is($client_xs->channel->engine->is_xs, 1, 'client with engine_type NGHTTP2 uses XS engine');
    };
};
