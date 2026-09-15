use v5.36;
use strict;
use warnings;

use Test::More;

use Linux::Event::IO::Sock::Stream;
use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;
use Linux::Event::HTTP::Server::Connection;
use Linux::Event::HTTP::Server;

{
    package T::FinalResponse;
    use parent 'Linux::Event::HTTP::Server::Connection';

    sub on_request ($self, $request, $response) {
        my $state = $self->data;
        ++$state->{request_hits};
        die "request boom\n" if $state->{request_die};

        if (($state->{mode} // '') eq 'invalid-body') {
            $response->body([]);
        } elsif (($state->{mode} // '') ne 'body') {
            $response->body($state->{response_body});
        }
        return;
    }

    sub on_body ($self, $request, $response, $bytes) {
        ++$self->data->{body_hits};
        $self->data->{body} .= $bytes;
        return;
    }

    sub on_request_end ($self, $request, $response) {
        my $state = $self->data;
        ++$state->{request_end_hits};
        if (($state->{mode} // '') eq 'body') {
            $response->body('post:' . $state->{body} . "\n");
        }
        return;
    }
}

sub new_state (%extra) {
    return {
        wire => '',
        request_hits => 0,
        body_hits => 0,
        request_end_hits => 0,
        body => '',
        response_body => "fast\n",
        %extra,
    };
}

sub run_exchange ($request_wire, $state, $expected_wire_body = undef) {
    my $loop = Linux::Event::Loop->new;
    my $server = Linux::Event::HTTP::Server->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 0,
        data => $state,
        connection_class => 'T::FinalResponse',
    );

    my $guard = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 2,
        on_timer => sub ($timer) {
            die "final-response integration test timed out\n";
        },
    );

    my $done = 0;
    my $finish = sub ($stream) {
        return if $done;
        my $head_end = index($state->{wire}, "\r\n\r\n");
        return if $head_end < 0;
        my $head_len = $head_end + 4;
        my $head = substr($state->{wire}, 0, $head_len);
        return if $head !~ /\r\nContent-Length:\s*(\d+)\r\n/i;
        my $body_len = defined($expected_wire_body) ? $expected_wire_body : 0 + $1;
        return if length($state->{wire}) < $head_len + $body_len;

        $done = 1;
        $guard->cancel;
        $stream->close;
        $server->close;
        $loop->stop;
    };

    Linux::Event::IO::Sock::Stream->connect(
        loop => $loop,
        host => '127.0.0.1',
        port => $server->port,
        on_ready => sub ($stream) {
            $stream->write($request_wire);
        },
        on_data => sub ($stream, $bytes) {
            $state->{wire} .= $bytes;
            $finish->($stream);
        },
        on_eof => sub ($stream) {
            $finish->($stream);
            die "server closed before complete final response\n" if !$done;
        },
        on_error => sub ($stream, $error) {
            die "final-response client failed: $error\n";
        },
    );

    $loop->run;
    ok($done, 'exchange completed');
    return $state->{wire};
}

my $state = new_state(response_body => "fast\n");
my $wire = run_exchange(
    "GET /fast HTTP/1.1\r\nHost: example.test\r\n\r\n",
    $state,
);
like(
    $wire,
    qr/\AHTTP\/1\.1 200 OK\r\nContent-Length: 5\r\n\r\nfast\n\z/s,
    'ordinary on_request plus Response->body completes eligible scalar response',
);
is($state->{request_hits}, 1, 'ordinary request callback runs once');

$state = new_state(response_body => 'head-body');
$wire = run_exchange(
    "HEAD /head HTTP/1.1\r\nHost: example.test\r\n\r\n",
    $state,
    0,
);
like(
    $wire,
    qr/\AHTTP\/1\.1 200 OK\r\nContent-Length: 9\r\n\r\n\z/s,
    'HEAD keeps representation length while suppressing response body bytes',
);
is($state->{request_hits}, 1, 'HEAD uses the same ordinary request callback');

$state = new_state(response_body => "old\n");
$wire = run_exchange(
    "GET /old HTTP/1.0\r\n\r\n",
    $state,
);
like(
    $wire,
    qr/\AHTTP\/1\.0 200 OK\r\nContent-Length: 4\r\n\r\nold\n\z/s,
    'HTTP/1.0 uses ordinary Response serialization',
);
is($state->{request_hits}, 1, 'HTTP/1.0 uses the same ordinary request callback');

$state = new_state(mode => 'body');
$wire = run_exchange(
    "POST /body HTTP/1.1\r\n" .
        "Host: example.test\r\n" .
        "Content-Length: 4\r\n\r\n" .
        "data",
    $state,
);
like($wire, qr/\r\n\r\npost:data\n\z/s, 'body-bearing request stays on streaming request path');
is($state->{request_hits}, 1, 'body-bearing request invokes ordinary on_request');
is($state->{body}, 'data', 'request body bytes are delivered');
is($state->{request_end_hits}, 1, 'request-end callback completes body response');

$state = new_state(request_die => 1);
$wire = run_exchange(
    "GET /boom HTTP/1.1\r\nHost: example.test\r\n\r\n",
    $state,
);
like(
    $wire,
    qr/\AHTTP\/1\.1 500 [^\r\n]+\r\nContent-Length: 0\r\nConnection: close\r\n\r\n\z/s,
    'ordinary request callback exception becomes protocol-safe 500',
);
is($state->{request_hits}, 1, 'failing ordinary request callback runs once');

$state = new_state(mode => 'invalid-body');
$wire = run_exchange(
    "GET /invalid-body HTTP/1.1\r\nHost: example.test\r\n\r\n",
    $state,
);
like(
    $wire,
    qr/\AHTTP\/1\.1 500 [^\r\n]+\r\nContent-Length: 0\r\nConnection: close\r\n\r\n\z/s,
    'invalid Response->body value becomes protocol-safe 500',
);
is($state->{request_hits}, 1, 'invalid body is handled inside ordinary request callback');

$state = new_state(response_body => "ignored\n");
$wire = run_exchange(
    "GET /expect HTTP/1.1\r\n" .
        "Host: example.test\r\n" .
        "Expect: nonsense\r\n\r\n",
    $state,
);
like(
    $wire,
    qr/\AHTTP\/1\.1 417 [^\r\n]+\r\nContent-Length: 0\r\nConnection: close\r\n\r\n\z/s,
    'unsupported Expect is rejected before application dispatch',
);
is($state->{request_hits}, 0, 'invalid Expect never reaches on_request');

done_testing;
