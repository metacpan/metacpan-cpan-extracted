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
    package T::BodyHTTP;
    use parent 'Linux::Event::HTTP::Server::Connection';

    sub stream_tuning ($class) {
        return read_size => 8;
    }

    sub on_request ($self, $request, $response) {
        my $target = $request->target;
        push @{$self->data->{events}}, "request:$target";
        $self->data->{bodies}{$target} = '';
        $response->header('Content-Type', 'text/plain');
    }

    sub on_body ($self, $request, $response, $bytes) {
        my $target = $request->target;
        $self->data->{bodies}{$target} .= $bytes;
        push @{$self->data->{events}}, "body:$target";
    }

    sub on_request_end ($self, $request, $response) {
        my $target = $request->target;
        push @{$self->data->{events}}, "end:$target";
        $response->body("$target\n");
    }
}

my $loop = Linux::Event::Loop->new;
my $state = {
    events   => [],
    bodies   => {},
    response => '',
};

my $listener = Linux::Event::IO::Sock::Listener->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    stream => {
        class => 'T::BodyHTTP',
        data  => $state,
    },
);

my $guard = Linux::Event::Kernel::Timer->new(
    loop  => $loop,
    after => 2,
    on_timer => sub ($timer) {
        die "request body integration test timed out\n";
    },
);

my $client = Linux::Event::IO::Sock::Stream->connect(
    loop => $loop,
    host => '127.0.0.1',
    port => $listener->port,
    on_ready => sub ($stream) {
        $stream->write(
            "POST /fixed HTTP/1.1\r\n" .
            "Host: example.test\r\n" .
            "Content-Length: 11\r\n" .
            "\r\n" .
            "hello world" .
            "POST /chunk HTTP/1.1\r\n" .
            "Host: example.test\r\n" .
            "Transfer-Encoding: chunked\r\n" .
            "\r\n" .
            "4;demo=yes\r\nWiki\r\n" .
            "5\r\npedia\r\n" .
            "0\r\nX-Trailer: ignored-for-now\r\n\r\n" .
            "GET /done HTTP/1.1\r\n" .
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
        die "request body test client failed: $error\n";
    },
);

$loop->run;

is($state->{bodies}{'/fixed'}, 'hello world',
    'Content-Length body is delivered without accumulation by Connection');
is($state->{bodies}{'/chunk'}, 'Wikipedia',
    'chunked request body is decoded before application delivery');
is($state->{bodies}{'/done'}, '',
    'bodyless request reaches the same transaction lifecycle');

my @requests = grep { /\Arequest:/ } @{$state->{events}};
my @ends = grep { /\Aend:/ } @{$state->{events}};
is_deeply(
    \@requests,
    [ 'request:/fixed', 'request:/chunk', 'request:/done' ],
    'pipelined requests dispatch in order across body boundaries',
);
is_deeply(
    \@ends,
    [ 'end:/fixed', 'end:/chunk', 'end:/done' ],
    'on_request_end runs once for fixed, chunked, and bodyless requests',
);

my @status = $state->{response} =~ /HTTP\/1\.1 200 OK\r\n/g;
is(scalar @status, 3, 'all three pipelined transactions receive responses');
like($state->{response}, qr{/fixed\n.*?/chunk\n.*?/done\n\z}s,
    'responses remain ordered with their request transactions');

{
    package T::ExpectHTTP;
    use parent 'Linux::Event::HTTP::Server::Connection';

    sub on_request ($self, $request, $response) {
        $self->data->{requests}++;
    }

    sub on_body ($self, $request, $response, $bytes) {
        $self->data->{body} .= $bytes;
    }

    sub on_request_end ($self, $request, $response) {
        $response->body("ok\n");
    }
}

$loop = Linux::Event::Loop->new;
my $expect = {
    requests => 0,
    body     => '',
    response => '',
    sent     => 0,
};

$listener = Linux::Event::IO::Sock::Listener->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    stream => {
        class => 'T::ExpectHTTP',
        data  => $expect,
    },
);

$guard = Linux::Event::Kernel::Timer->new(
    loop  => $loop,
    after => 2,
    on_timer => sub ($timer) {
        die "100-continue integration test timed out\n";
    },
);

$client = Linux::Event::IO::Sock::Stream->connect(
    loop => $loop,
    host => '127.0.0.1',
    port => $listener->port,
    on_ready => sub ($stream) {
        $stream->write(
            "POST /expect HTTP/1.1\r\n" .
            "Host: example.test\r\n" .
            "Content-Length: 4\r\n" .
            "Expect: 100-continue\r\n" .
            "Connection: close\r\n" .
            "\r\n"
        );
    },
    on_data => sub ($stream, $bytes) {
        $expect->{response} .= $bytes;
        if (!$expect->{sent}
            && $expect->{response} =~ /HTTP\/1\.1 100 Continue\r\n\r\n/) {
            $expect->{sent} = 1;
            $stream->write('data');
        }
    },
    on_eof => sub ($stream) {
        $guard->cancel;
        $stream->close;
        $listener->close;
        $loop->stop;
    },
    on_error => sub ($stream, $error) {
        die "100-continue test client failed: $error\n";
    },
);

$loop->run;

ok($expect->{sent}, 'client receives 100 Continue before sending request body');
is($expect->{requests}, 1, '100-continue request is dispatched once');
is($expect->{body}, 'data', 'body arriving after 100 Continue is streamed');
like(
    $expect->{response},
    qr/\AHTTP\/1\.1 100 Continue\r\n\r\nHTTP\/1\.1 200 OK\r\n.*?\r\n\r\nok\n\z/s,
    'interim response is followed by final response',
);

$loop = Linux::Event::Loop->new;
my $unsupported = {
    requests => 0,
    response => '',
};

$listener = Linux::Event::IO::Sock::Listener->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    stream => {
        class => 'T::ExpectHTTP',
        data  => $unsupported,
    },
);

$guard = Linux::Event::Kernel::Timer->new(
    loop  => $loop,
    after => 2,
    on_timer => sub ($timer) {
        die "unsupported Expect integration test timed out\n";
    },
);

$client = Linux::Event::IO::Sock::Stream->connect(
    loop => $loop,
    host => '127.0.0.1',
    port => $listener->port,
    on_ready => sub ($stream) {
        $stream->write(
            "POST /expect HTTP/1.1\r\n" .
            "Host: example.test\r\n" .
            "Content-Length: 4\r\n" .
            "Expect: something-else\r\n" .
            "Connection: close\r\n" .
            "\r\n"
        );
    },
    on_data => sub ($stream, $bytes) {
        $unsupported->{response} .= $bytes;
    },
    on_eof => sub ($stream) {
        $guard->cancel;
        $stream->close;
        $listener->close;
        $loop->stop;
    },
    on_error => sub ($stream, $error) {
        die "unsupported Expect test client failed: $error\n";
    },
);

$loop->run;

is($unsupported->{requests}, 0,
    'unsupported expectation is rejected before application dispatch');
like($unsupported->{response}, qr/\AHTTP\/1\.1 417 Expectation Failed\r\n/,
    'unsupported expectation receives 417');

done_testing;
