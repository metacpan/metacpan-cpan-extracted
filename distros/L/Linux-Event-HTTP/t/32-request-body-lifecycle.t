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
    package T::EarlyResponseHTTP;
    use parent 'Linux::Event::HTTP::Server::Connection';

    sub on_request ($self, $request, $response) {
        my $target = $request->target;
        push @{$self->data->{requests}}, $target;
        $self->data->{bodies}{$target} = '';
        $response->body($target eq '/early' ? "early\n" : "next\n");
    }

    sub on_body ($self, $request, $response, $bytes) {
        $self->data->{bodies}{$request->target} .= $bytes;
    }

    sub on_request_end ($self, $request, $response) {
        push @{$self->data->{ends}}, $request->target;
    }
}

my $loop = Linux::Event::Loop->new;
my $state = {
    requests => [],
    ends     => [],
    bodies   => {},
    response => '',
};

my $listener = Linux::Event::IO::Sock::Listener->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    stream => {
        class => 'T::EarlyResponseHTTP',
        data  => $state,
    },
);

my $guard = Linux::Event::Kernel::Timer->new(
    loop  => $loop,
    after => 2,
    on_timer => sub ($timer) {
        die "response-first body lifecycle test timed out\n";
    },
);

my $client = Linux::Event::IO::Sock::Stream->connect(
    loop => $loop,
    host => '127.0.0.1',
    port => $listener->port,
    on_ready => sub ($stream) {
        $stream->write(
            "POST /early HTTP/1.1\r\n" .
            "Host: example.test\r\n" .
            "Content-Length: 4\r\n" .
            "\r\n" .
            "data" .
            "GET /next HTTP/1.1\r\n" .
            "Host: example.test\r\n" .
            "Connection: close\r\n" .
            "\r\n"
        );
    },
    on_data => sub ($stream, $bytes) {
        $state->{response} .= $bytes;
    },
    on_eof => sub ($stream) {
        $guard->cancel;
        $stream->close;
        $listener->close;
        $loop->stop;
    },
    on_error => sub ($stream, $error) {
        die "response-first test client failed: $error\n";
    },
);

$loop->run;

is_deeply($state->{requests}, [ '/early', '/next' ],
    'next request waits until response-first transaction consumes its body');
is($state->{bodies}{'/early'}, 'data',
    'request body continues streaming after its response is complete');
is_deeply($state->{ends}, [ '/early', '/next' ],
    'on_request_end runs even when responses complete first, including close response');
like($state->{response}, qr/early\n.*?next\n\z/s,
    'response-first transaction preserves response ordering');

{
    package T::MalformedChunkHTTP;
    use parent 'Linux::Event::HTTP::Server::Connection';

    sub on_request ($self, $request, $response) {
        $self->data->{requests}++;
    }

    sub on_request_end ($self, $request, $response) {
        $self->data->{ends}++;
    }
}

$loop = Linux::Event::Loop->new;
my $bad = {
    requests => 0,
    ends     => 0,
    response => '',
};

$listener = Linux::Event::IO::Sock::Listener->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    stream => {
        class => 'T::MalformedChunkHTTP',
        data  => $bad,
    },
);

$guard = Linux::Event::Kernel::Timer->new(
    loop  => $loop,
    after => 2,
    on_timer => sub ($timer) {
        die "malformed chunk integration test timed out\n";
    },
);

$client = Linux::Event::IO::Sock::Stream->connect(
    loop => $loop,
    host => '127.0.0.1',
    port => $listener->port,
    on_ready => sub ($stream) {
        $stream->write(
            "POST /bad HTTP/1.1\r\n" .
            "Host: example.test\r\n" .
            "Transfer-Encoding: chunked\r\n" .
            "\r\n" .
            "Z\r\n"
        );
    },
    on_data => sub ($stream, $bytes) {
        $bad->{response} .= $bytes;
    },
    on_eof => sub ($stream) {
        $guard->cancel;
        $stream->close;
        $listener->close;
        $loop->stop;
    },
    on_error => sub ($stream, $error) {
        die "malformed chunk test client failed: $error\n";
    },
);

$loop->run;

is($bad->{requests}, 1, 'request head is dispatched before malformed body is encountered');
is($bad->{ends}, 0, 'malformed chunked body never reaches on_request_end');
like($bad->{response}, qr/\AHTTP\/1\.1 400 Bad Request\r\n/,
    'malformed chunk framing receives 400 when response has not started');

done_testing;
