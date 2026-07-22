use strict;
use warnings;
use Test::More tests => 2;
use Google::gRPC::Engine::PP;

subtest 'Pure-Perl Engine initialization and is_xs' => sub {
    my $engine = Google::gRPC::Engine::PP->new;
    ok($engine, 'instantiated PP engine');
    is($engine->is_xs, 0, 'is_xs returns 0 for Pure-Perl engine');
};

subtest 'Pure-Perl request submission and output generation' => sub {
    my $engine = Google::gRPC::Engine::PP->new;
    my $stream_id = $engine->submit_request({
        headers => [
            ':method'      => 'POST',
            ':path'        => '/test.Service/TestMethod',
            ':scheme'      => 'https',
            ':authority'   => 'localhost:8000',
            'content-type' => 'application/grpc',
        ],
        data => 'request payload',
        end_stream => 1,
    });

    ok($stream_id, 'received stream_id from PP engine');
    my $out = $engine->get_output;
    ok(length($out) > 0, 'generated HTTP/2 output frames');
};
