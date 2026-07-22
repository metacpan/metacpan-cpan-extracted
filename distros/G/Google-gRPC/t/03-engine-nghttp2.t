use strict;
use warnings;
use Test::More;
use Google::gRPC::Engine::NGHTTP2;

BEGIN {
    eval {
        defined &Google::gRPC::Engine::NGHTTP2::_xs_new or die 'not built';
        1;
    } or plan skip_all => 'nghttp2 C/XS module not built or available';
}

plan tests => 2;

subtest 'C/XS Engine initialization and is_xs' => sub {
    my $engine = Google::gRPC::Engine::NGHTTP2->new;
    ok($engine, 'instantiated NGHTTP2 XS engine');
    is($engine->is_xs, 1, 'is_xs returns 1 for XS engine');
};

subtest 'C/XS Engine request submission and output generation' => sub {
    my $engine = Google::gRPC::Engine::NGHTTP2->new;
    my $stream_id = $engine->submit_request({
        headers => [
            ':method'      => 'POST',
            ':path'        => '/test.Service/TestMethod',
            ':scheme'      => 'https',
            ':authority'   => 'localhost:8000',
            'content-type' => 'application/grpc',
        ],
        data => 'xs request payload',
        end_stream => 1,
    });

    ok($stream_id > 0, 'received positive stream_id from XS engine');
    my $out = $engine->get_output;
    ok(length($out) > 0, 'generated HTTP/2 output frames from XS engine');
};
