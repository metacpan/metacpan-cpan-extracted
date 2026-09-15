use v5.36;
use strict;
use warnings;

use Test::More;

use Linux::Event::Loop;
use Linux::Event::Kernel::Timer;
use Linux::Event::IO::Sock::Listener;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::HTTP::Server::Connection;

{
    package T::ChunkedResponseHTTP;
    use parent 'Linux::Event::HTTP::Server::Connection';

    sub on_request ($self, $req, $res) {
        push @{$self->data->{targets}}, $req->target;
        $res->header('Content-Type', 'text/plain');

        if ($req->target eq '/stream') {
            my $body = $self->transaction->response_body;
            push @{$self->data->{write_status}}, $body->write("one\n");
            push @{$self->data->{write_status}}, $body->write('');
            push @{$self->data->{write_status}}, $body->write("two\n");
            $body->complete("three\n");
            return;
        }

        $res->body("done\n");
        return;
    }
}

my $loop = Linux::Event::Loop->new;
my $state = {
    targets      => [],
    write_status => [],
    wire         => '',
};

my $listener = Linux::Event::IO::Sock::Listener->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    stream => {
        class => 'T::ChunkedResponseHTTP',
        data  => $state,
    },
);

my $guard = Linux::Event::Kernel::Timer->new(
    loop  => $loop,
    after => 2,
    on_timer => sub ($timer) {
        die "chunked response integration test timed out\n";
    },
);

my $client = Linux::Event::IO::Sock::Stream->connect(
    loop => $loop,
    host => '127.0.0.1',
    port => $listener->port,
    on_ready => sub ($stream) {
        $stream->write(
            "GET /stream HTTP/1.1\r\n" .
            "Host: example.test\r\n" .
            "\r\n" .
            "GET /done HTTP/1.1\r\n" .
            "Host: example.test\r\n" .
            "Connection: close\r\n" .
            "\r\n"
        );
    },
    on_data => sub ($stream, $bytes) {
        $state->{wire} .= $bytes;
    },
    on_eof => sub ($stream) {
        $guard->cancel;
        $stream->close;
        $listener->close;
        $loop->stop;
    },
    on_error => sub ($stream, $error) {
        die "chunked response client failed: $error\n";
    },
);

$loop->run;

is_deeply(
    $state->{targets},
    [ '/stream', '/done' ],
    'pipelined request after incremental response dispatches in order',
);
ok($state->{write_status}[0], 'first response body write exposes Stream backpressure status');
ok($state->{write_status}[1], 'empty response body write is accepted without completing response');
ok($state->{write_status}[2], 'later response body write exposes Stream backpressure status');

my $wire = $state->{wire};
like(
    $wire,
    qr/\AHTTP\/1\.1 200 OK\r\nContent-Type: text\/plain\r\nTransfer-Encoding: chunked\r\n\r\n4\r\none\n\r\n4\r\ntwo\n\r\n6\r\nthree\n\r\n0\r\n\r\nHTTP\/1\.1 200 OK\r\n/s,
    'HTTP/1.1 incremental body without Content-Length uses chunked transfer coding',
);
unlike(
    $wire,
    qr/0\r\n\r\n0\r\n\r\n/,
    'empty write does not emit a terminating zero chunk',
);
like(
    $wire,
    qr/HTTP\/1\.1 200 OK\r\nContent-Type: text\/plain\r\nContent-Length: 5\r\nConnection: close\r\n\r\ndone\n\z/s,
    'next scalar response follows the completed chunked response',
);

{
    package T::HTTP10Streaming;
    use parent 'Linux::Event::HTTP::Server::Connection';

    sub on_request ($self, $req, $res) {
        $res->header('Content-Type', 'text/plain');
        my $body = $self->transaction->response_body;
        $self->data->{write_status} = $body->write('old ');
        $body->complete("school\n");
        return;
    }
}

$loop = Linux::Event::Loop->new;
my $legacy = {
    wire         => '',
    write_status => 0,
    eof          => 0,
};

$listener = Linux::Event::IO::Sock::Listener->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    stream => {
        class => 'T::HTTP10Streaming',
        data  => $legacy,
    },
);

$guard = Linux::Event::Kernel::Timer->new(
    loop  => $loop,
    after => 2,
    on_timer => sub ($timer) {
        die "HTTP/1.0 response streaming test timed out\n";
    },
);

$client = Linux::Event::IO::Sock::Stream->connect(
    loop => $loop,
    host => '127.0.0.1',
    port => $listener->port,
    on_ready => sub ($stream) {
        $stream->write(
            "GET /legacy HTTP/1.0\r\n" .
            "Connection: keep-alive\r\n" .
            "\r\n"
        );
    },
    on_data => sub ($stream, $bytes) {
        $legacy->{wire} .= $bytes;
    },
    on_eof => sub ($stream) {
        $legacy->{eof} = 1;
        $guard->cancel;
        $stream->close;
        $listener->close;
        $loop->stop;
    },
    on_error => sub ($stream, $error) {
        die "HTTP/1.0 response streaming client failed: $error\n";
    },
);

$loop->run;

ok($legacy->{write_status}, 'HTTP/1.0 response body write exposes backpressure status');
ok($legacy->{eof}, 'HTTP/1.0 unknown-length incremental body closes to delimit the body');
unlike($legacy->{wire}, qr/Transfer-Encoding:/i,
    'HTTP/1.0 incremental body never emits Transfer-Encoding');
unlike($legacy->{wire}, qr/Content-Length:/i,
    'HTTP/1.0 unknown-length incremental body does not invent Content-Length');
unlike($legacy->{wire}, qr/Connection: keep-alive/i,
    'HTTP/1.0 close-delimited response does not advertise persistence');
like(
    $legacy->{wire},
    qr/\AHTTP\/1\.0 200 OK\r\nContent-Type: text\/plain\r\n\r\nold school\n\z/s,
    'HTTP/1.0 incremental body is close-delimited without chunk framing',
);

done_testing;
