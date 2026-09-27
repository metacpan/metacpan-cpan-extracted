use v5.36;
use strict;
use warnings;

use Test::More;

use Linux::Event::HTTP::Client::Connection;
use Linux::Event::HTTP::Request;
use Linux::Event::IO::Sock::Listener;
use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;

{
    package T::NativeHTTPClientConnection;
    use parent 'Linux::Event::HTTP::Client::Connection';

    sub _http_client_native_response ($self, $response) {
        ++$self->data->{native_response_hits};
        return $self->SUPER::_http_client_native_response($response);
    }

    sub _http_client_native_fallback_input ($self, $bytes) {
        ++$self->data->{fallback_hits};
        $self->data->{fallback_bytes} .= $bytes;
        return $self->SUPER::_http_client_native_fallback_input($bytes);
    }
}

{
    package T::InvalidNativeHTTPClientConnection;
    use parent 'Linux::Event::HTTP::Client::Connection';

    sub on_data ($self, $bytes) {
        return;
    }
}

sub request_for () {
    return Linux::Event::HTTP::Request->new(
        method  => 'GET',
        target  => '/',
        headers => [ [ Host => 'example.test' ] ],
    );
}

subtest 'fragmented response head stays native and only body reaches fallback' => sub {
    my $loop = Linux::Event::Loop->new;
    my $sent = 0;
    my $finish_write;

    my $listener = Linux::Event::IO::Sock::Listener->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 0,
        stream => {
            on_data => sub ($stream, $bytes) {
                return if $sent++;
                $stream->write("HTTP/1.1 200 O");
                $finish_write = Linux::Event::Kernel::Timer->new(
                    loop => $loop,
                    after => 0.01,
                    on_timer => sub ($timer) {
                        $stream->write(
                            "K\r\n" .
                            "X-Native: yes\r\n" .
                            "Content-Length: 4\r\n\r\n" .
                            "DATA"
                        );
                    },
                );
            },
        },
    );

    my $guard = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 2,
        on_timer => sub ($timer) {
            die "native fragmented response test timed out\n";
        },
    );

    my $state = {
        native_response_hits => 0,
        fallback_hits        => 0,
        fallback_bytes       => '',
        body                 => '',
    };

    my $client = T::NativeHTTPClientConnection->connect(
        loop => $loop,
        host => '127.0.0.1',
        port => $listener->port,
        data => $state,
    );

    my $tx = $client->request(
        request_for(),
        on_response => sub ($transaction, $response) {
            $state->{status} = $response->status;
            $state->{header} = $response->header('X-Native');
        },
        on_body => sub ($transaction, $response, $bytes) {
            $state->{body} .= $bytes;
        },
        on_complete => sub ($transaction) {
            $guard->cancel;
            $finish_write->cancel if $finish_write;
            $client->close if !$client->is_closed;
            $listener->close;
            $loop->stop;
        },
        on_error => sub ($transaction, $error) {
            die "native fragmented response failed: $error\n";
        },
    );

    $loop->run;

    is($state->{native_response_hits}, 1,
        'fragmented response head is delivered once by the native provider');
    is($state->{status}, 200, 'native response status is available');
    is($state->{header}, 'yes', 'native response headers preserve values');
    is($state->{body}, 'DATA', 'body lifecycle receives exact body bytes');
    is($state->{fallback_bytes}, 'DATA',
        'response-head bytes never enter the Perl body fallback');
    cmp_ok($state->{fallback_hits}, '>=', 1,
        'body bytes enter the existing fallback body state machine');
    ok($tx->is_complete, 'fragmented native response Transaction completes');
};

subtest 'informational and final heads in one read both parse natively' => sub {
    my $loop = Linux::Event::Loop->new;
    my $sent = 0;

    my $listener = Linux::Event::IO::Sock::Listener->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 0,
        stream => {
            on_data => sub ($stream, $bytes) {
                return if $sent++;
                $stream->write(
                    "HTTP/1.1 100 Continue\r\n\r\n" .
                    "HTTP/1.1 200 OK\r\n" .
                    "Content-Length: 2\r\n\r\n" .
                    "ok"
                );
            },
        },
    );

    my $guard = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 2,
        on_timer => sub ($timer) {
            die "native informational response test timed out\n";
        },
    );

    my $state = {
        native_response_hits => 0,
        fallback_hits        => 0,
        fallback_bytes       => '',
        informational        => 0,
        body                 => '',
    };

    my $client = T::NativeHTTPClientConnection->connect(
        loop => $loop,
        host => '127.0.0.1',
        port => $listener->port,
        data => $state,
    );

    my $tx = $client->request(
        request_for(),
        on_informational => sub ($transaction, $response) {
            ++$state->{informational};
            $state->{informational_status} = $response->status;
        },
        on_response => sub ($transaction, $response) {
            $state->{final_status} = $response->status;
        },
        on_body => sub ($transaction, $response, $bytes) {
            $state->{body} .= $bytes;
        },
        on_complete => sub ($transaction) {
            $guard->cancel;
            $client->close if !$client->is_closed;
            $listener->close;
            $loop->stop;
        },
        on_error => sub ($transaction, $error) {
            die "native informational response failed: $error\n";
        },
    );

    $loop->run;

    is($state->{native_response_hits}, 2,
        'informational and final response heads both use native parsing');
    is($state->{informational}, 1, 'one informational callback runs');
    is($state->{informational_status}, 100, 'informational status is preserved');
    is($state->{final_status}, 200, 'final response follows informational head');
    is($state->{body}, 'ok', 'final body is delivered normally');
    is($state->{fallback_bytes}, 'ok',
        'only final body bytes enter Perl fallback');
    ok($tx->is_complete, 'informational plus final Transaction completes');
};

subtest 'native HTTP client subclasses cannot replace protocol input with on_data' => sub {
    my $loop = Linux::Event::Loop->new;
    my $listener = Linux::Event::IO::Sock::Listener->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 0,
        stream => {
            on_data => sub ($stream, $bytes) { return; },
        },
    );

    my $client;
    my $ok = eval {
        $client = T::InvalidNativeHTTPClientConnection->connect(
            loop => $loop,
            host => '127.0.0.1',
            port => $listener->port,
        );
        1;
    };

    ok(!$ok, 'on_data override is rejected for native HTTP client input');
    like($@, qr/native consumer cannot be combined with on_data/i,
        'native input ownership error is explicit');

    $client->close if $client && !$client->is_closed;
    $listener->close;
};

subtest 'reentrant close from on_response is safe under native input' => sub {
    my $loop = Linux::Event::Loop->new;
    my $sent = 0;

    my $listener = Linux::Event::IO::Sock::Listener->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 0,
        stream => {
            on_data => sub ($stream, $bytes) {
                return if $sent++;
                $stream->write(
                    "HTTP/1.1 200 OK\r\n" .
                    "Content-Length: 4\r\n\r\n" .
                    "DATA"
                );
            },
        },
    );

    my $guard = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 2,
        on_timer => sub ($timer) {
            die "native client reentrant close test timed out\n";
        },
    );

    my $state = {
        native_response_hits => 0,
        fallback_hits        => 0,
        fallback_bytes       => '',
        response_hits        => 0,
    };

    my $client = T::NativeHTTPClientConnection->connect(
        loop => $loop,
        host => '127.0.0.1',
        port => $listener->port,
        data => $state,
    );

    my $tx = $client->request(
        request_for(),
        on_response => sub ($transaction, $response) {
            ++$state->{response_hits};
            $client->close;
            $guard->cancel;
            $listener->close;
            $loop->stop;
        },
        on_error => sub ($transaction, $error) {
            $state->{error} = "$error";
        },
    );

    $loop->run;

    is($state->{native_response_hits}, 1,
        'response entered the native provider before reentrant close');
    is($state->{response_hits}, 1, 'on_response ran exactly once');
    ok($client->is_closed, 'client closed reentrantly without native consume failure');
    ok($tx->is_terminal, 'closing from on_response leaves Transaction terminal');
    unlike($state->{error} // '', qr/internal Stream input consume exceeds buffered bytes/,
        'reentrant close does not trigger native input accounting failure');
};

done_testing;
