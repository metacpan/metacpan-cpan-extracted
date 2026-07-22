use strict;
use warnings;
use Test::More tests => 3;
use Google::gRPC::Channel;
use Google::gRPC::Framing;

subtest 'Channel initialization and stream creation' => sub {
    my $channel = Google::gRPC::Channel->new(
        target     => 'localhost:8000',
        auth_token => 'test-bearer-token',
        engine_type => 'PP',
    );

    ok($channel, 'created channel');
    my $stream = $channel->create_stream(
        service => 'google.pubsub.v1.Subscriber',
        method  => 'Pull',
        request => 'dummy request payload',
        type    => 'unary',
    );

    ok($stream, 'created stream');
    is($stream->type, 'unary', 'stream type is unary');
    is($stream->channel, $channel, 'stream holds parent channel');

    my $output = $channel->get_output;
    ok(length($output) > 0, 'channel output buffer generated frames');
};

subtest 'Stream message push and unpack' => sub {
    my $channel = Google::gRPC::Channel->new(
        target => 'localhost:8000',
        engine_type => 'PP',
    );

    my $received_msg;
    my $stream = $channel->create_stream(
        service    => 'test.Service',
        method     => 'StreamMethod',
        type       => 'server_stream',
        on_message => sub {
            my ($s, $msg) = @_;
            $received_msg = $msg;
        },
    );

    my $payload = 'response item payload';
    my $framed = Google::gRPC::Framing::pack_frame($payload);

    $stream->push_incoming_data($framed);

    is($received_msg, 'response item payload', 'received message callback fired with correct payload');
    my $msg_from_queue = $stream->recv_message();
    is($msg_from_queue, 'response item payload', 'recv_message popped item from queue');
};

subtest 'Stream trailers and completion' => sub {
    my $channel = Google::gRPC::Channel->new(
        target => 'localhost:8000',
        engine_type => 'PP',
    );

    my $status_received;
    my $stream = $channel->create_stream(
        service => 'test.Service',
        method  => 'TestMethod',
        type    => 'unary',
        on_trailers => sub {
            my ($s, $info) = @_;
            $status_received = $info->{status};
        },
    );

    $stream->handle_trailers({
        'content-type' => 'application/grpc',
        'grpc-status'  => '0',
        'grpc-message' => 'OK',
    });

    is($status_received, 0, 'trailers status 0 received');
    is($stream->status, 0, 'stream status is set to 0');
};
