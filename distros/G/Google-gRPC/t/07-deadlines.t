use strict;
use warnings;
use Test::More tests => 3;
use Google::gRPC::Deadline;
use Google::gRPC::Channel;
use Google::gRPC::Stream;

subtest 'Deadline parsing and header formatting' => sub {
    is(Google::gRPC::Deadline::parse_timeout('500m'), 0.5, 'parsed 500m to 0.5 sec');
    is(Google::gRPC::Deadline::parse_timeout('10S'), 10, 'parsed 10S to 10 sec');
    is(Google::gRPC::Deadline::parse_timeout('1H'), 3600, 'parsed 1H to 3600 sec');
    is(Google::gRPC::Deadline::parse_timeout(2.5), 2.5, 'parsed float sec directly');

    is(Google::gRPC::Deadline::format_grpc_timeout(0.5), '500m', 'formatted 0.5 sec to 500m');
    is(Google::gRPC::Deadline::format_grpc_timeout(10), '10S', 'formatted 10 sec to 10S');
    is(Google::gRPC::Deadline::format_grpc_timeout(3600), '1H', 'formatted 3600 sec to 1H');
};

subtest 'Channel timeout header injection' => sub {
    my $channel = Google::gRPC::Channel->new(
        target      => 'localhost:8000',
        engine_type => 'PP',
        timeout     => '500m',
    );

    my $stream = $channel->create_stream(
        service => 'test.Service',
        method  => 'TestMethod',
        type    => 'unary',
    );

    ok($stream, 'created stream with channel timeout');
    ok(defined $stream->deadline, 'stream has deadline timestamp set');
};

subtest 'Stream timeout triggers DEADLINE_EXCEEDED' => sub {
    my $channel = Google::gRPC::Channel->new(
        target      => 'localhost:8000',
        engine_type => 'PP',
    );

    my $trailers_received;
    my $stream = $channel->create_stream(
        service     => 'test.Service',
        method      => 'LongRunningMethod',
        timeout     => 0.01,
        type        => 'unary',
        on_trailers => sub {
            my ($s, $info) = @_;
            $trailers_received = $info;
        },
    );

    # Sleep slightly to let deadline expire
    select(undef, undef, undef, 0.05);

    $stream->check_deadline();

    is($stream->status, 4, 'stream status updated to 4 DEADLINE_EXCEEDED');
    is($stream->status_message, 'Deadline Exceeded', 'status message set');
    ok($trailers_received, 'on_trailers callback triggered');
    is($trailers_received->{status}, 4, 'trailers status code is 4');
};
