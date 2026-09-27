use v5.36;
use strict;
use warnings;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use Scalar::Util qw(refaddr);

BEGIN {
    eval {
        require Net::HTTP2::nghttp2;
        Net::HTTP2::nghttp2->VERSION('0.011');
        require Net::HTTP2::nghttp2::Session;
        1;
    } or plan skip_all => 'Net::HTTP2::nghttp2 is not installed';

    Net::HTTP2::nghttp2->available
        or plan skip_all => 'nghttp2 library is not available';
}

use Linux::Event::HTTP::Client::Connection;
use Linux::Event::HTTP::Request;
use Linux::Event::HTTP::Server;
use Linux::Event::HTTP::_HTTP2::Client;
use Linux::Event::HTTP::_HTTP2::ClientConnection;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;
use Linux::Event::TLS ();

my $openssl = -x '/usr/bin/openssl' ? '/usr/bin/openssl' : undef;
if (!defined $openssl) {
    for my $dir (File::Spec->path) {
        my $candidate = File::Spec->catfile($dir, 'openssl');
        if (-x $candidate) {
            $openssl = $candidate;
            last;
        }
    }
}
plan skip_all => 'openssl command is required for HTTP/2 selector test'
    if !defined $openssl;

my $temp = tempdir(CLEANUP => 1);
my $cert = File::Spec->catfile($temp, 'server-cert.pem');
my $key = File::Spec->catfile($temp, 'server-key.pem');

my $generated;
{
    local $ENV{OPENSSL_CONF};
    delete $ENV{OPENSSL_CONF};
    $generated = system(
        $openssl, 'req', '-x509', '-newkey', 'rsa:2048', '-nodes',
        '-keyout', $key,
        '-out', $cert,
        '-subj', '/CN=localhost',
        '-addext', 'subjectAltName=DNS:localhost',
        '-days', '1',
    );
}
plan skip_all => 'openssl could not generate temporary TLS certificate'
    if $generated != 0 || !-s $cert || !-s $key;

my $loop = Linux::Event::Loop->new;
my $state = {
    server_ready       => [],
    server_request     => [],
    h2_client_response => '',
    h1_client_response => '',
    errors             => [],
};

my $server = Linux::Event::HTTP::Server->new(
    loop  => $loop,
    host  => '127.0.0.1',
    port  => 0,
    http2 => 1,
    tls   => {
        cert_file => $cert,
        key_file  => $key,
    },
    on_ready => sub ($conn) {
        push @{$state->{server_ready}}, {
            class     => ref($conn),
            id        => refaddr($conn),
            fd        => $conn->fd,
            alpn      => $conn->selected_alpn,
            transport => $conn->transport_name,
        };
    },
    on_request => sub ($conn, $req, $res) {
        my $tx = $conn->transaction;
        push @{$state->{server_request}}, {
            class     => ref($conn),
            alpn      => $conn->selected_alpn,
            version   => $req->version,
            target    => $req->target,
            authority => $req->authority,
            tx_match  => defined($tx)
                && refaddr($tx->request) == refaddr($req) ? 1 : 0,
        };

        if ($req->version eq '2') {
            $res->header('x-protocol', 'h2');
            $res->body("h2\n");
        } else {
            $res->header('x-protocol', 'http/1.1');
            $res->body("h1\n");
        }
    },
    on_error => sub ($conn, $error) {
        push @{$state->{errors}}, "server: $error";
        $loop->stop;
    },
);

ok($server->http2, 'high-level Server reports HTTP/2 enabled');

my $guard = Linux::Event::Kernel::Timer->new(
    loop  => $loop,
    after => 10,
    on_timer => sub ($timer) {
        die "high-level HTTP/2 Server selector test timed out\n";
    },
);

my $start_h1;
$start_h1 = sub {
    my $wire = '';
    Linux::Event::IO::Sock::Stream->connect(
        loop => $loop,
        host => '127.0.0.1',
        port => $server->port,
        transport => Linux::Event::TLS->client(
            server_name => 'localhost',
            verify      => 0,
            alpn        => [ 'http/1.1' ],
        ),
        on_ready => sub ($stream) {
            $state->{h1_client_alpn} = $stream->selected_alpn;
            $stream->write(
                "GET /fallback HTTP/1.1\r\n" .
                "Host: localhost\r\n" .
                "Connection: close\r\n" .
                "\r\n"
            );
        },
        on_data => sub ($stream, $bytes) {
            $wire .= $bytes;
        },
        on_eof => sub ($stream) {
            $state->{h1_client_response} = $wire;
            $state->{h1_client_complete} = 1;
            $guard->cancel;
            $stream->close if !$stream->is_closed;
            $server->close;
            $loop->stop;
        },
        on_error => sub ($stream, $error) {
            push @{$state->{errors}}, "h1 client: $error";
            $loop->stop;
        },
    );
};

my $h2_executor;
my $h2_client = Linux::Event::HTTP::Client::Connection->connect(
    loop => $loop,
    host => '127.0.0.1',
    port => $server->port,
    transport => Linux::Event::TLS->client(
        server_name => 'localhost',
        verify      => 0,
        alpn        => [ 'h2', 'http/1.1' ],
    ),
    on_ready => sub ($conn) {
        $state->{h2_client_before_class} = ref($conn);
        $state->{h2_client_before_id} = refaddr($conn);
        $state->{h2_client_fd} = $conn->fd;
        $state->{h2_client_alpn} = $conn->selected_alpn;

        $conn->pause_read;
        $conn->loop->defer(sub {
            $h2_executor = Linux::Event::HTTP::_HTTP2::Client->new(
                stream    => $conn,
                autostart => 0,
            );
            $conn->{_http2_executor} = $h2_executor;
            $conn->transition_to(
                'Linux::Event::HTTP::_HTTP2::ClientConnection',
            );

            $state->{h2_client_after_class} = ref($conn);
            $state->{h2_client_after_id} = refaddr($conn);
            $state->{h2_client_transport} = $conn->transport_name;

            $h2_executor->start;

            my $request = Linux::Event::HTTP::Request->new(
                method    => 'GET',
                target    => '/selected',
                version   => '2',
                scheme    => 'https',
                authority => 'localhost',
            );

            $conn->request(
                $request,
                on_response => sub ($tx, $res) {
                    $state->{h2_status} = $res->status;
                    $state->{h2_protocol_header} =
                        $res->header('x-protocol');
                },
                on_body => sub ($tx, $res, $bytes) {
                    $state->{h2_client_response} .= $bytes;
                },
                on_complete => sub ($tx) {
                    $state->{h2_client_complete} = 1;
                    $state->{h2_tx_complete_in_callback} =
                        $tx->is_complete ? 1 : 0;
                    $start_h1->();
                },
                on_error => sub ($tx, $error) {
                    push @{$state->{errors}}, "h2 client: $error";
                    $loop->stop;
                },
            );
            $conn->resume_read if $conn->is_read_paused;
        });
    },
);

$loop->run;

$h2_client->close if !$h2_client->is_closed;

is_deeply($state->{errors}, [],
    'high-level Server selector has no transport/protocol errors');

is($state->{h2_client_alpn}, 'h2', 'client TLS selects h2');
is($state->{h2_client_before_class},
    'Linux::Event::HTTP::Client::Connection',
    'test client begins as native HTTP/1 connection');
is($state->{h2_client_after_class},
    'Linux::Event::HTTP::_HTTP2::ClientConnection',
    'test client transitions to private H2 connection');
is($state->{h2_client_before_id}, $state->{h2_client_after_id},
    'test client transition preserves object identity');
is($state->{h2_client_transport}, 'tls',
    'test client transition preserves TLS transport');
is($state->{h2_status}, 200, 'H2 client receives status 200');
is($state->{h2_protocol_header}, 'h2',
    'H2 response came through high-level Server HTTP/2 path');
is($state->{h2_client_response}, "h2\n",
    'H2 client receives response body');
ok($state->{h2_client_complete}, 'H2 Transaction completes');
ok($state->{h2_tx_complete_in_callback},
    'H2 on_complete observes terminal Transaction');

is($state->{h1_client_alpn}, 'http/1.1',
    'second TLS client negotiates HTTP/1.1 fallback');
like($state->{h1_client_response}, qr{\AHTTP/1\.1 200 OK\r\n}s,
    'HTTP/1.1 fallback uses existing serializer');
like($state->{h1_client_response}, qr{x-protocol: http/1\.1}i,
    'HTTP/1.1 fallback reaches same Server callback');
like($state->{h1_client_response}, qr{\r\n\r\nh1\n\z}s,
    'HTTP/1.1 fallback receives correct body');
ok($state->{h1_client_complete}, 'HTTP/1.1 fallback completes');

is(scalar(@{$state->{server_ready}}), 2,
    'Server readiness runs once for H2 and once for HTTP/1.1');
my ($h2_ready) = grep { ($_->{alpn} // '') eq 'h2' }
    @{$state->{server_ready}};
my ($h1_ready) = grep { ($_->{alpn} // '') eq 'http/1.1' }
    @{$state->{server_ready}};

is($h2_ready->{class}, 'Linux::Event::HTTP::_HTTP2::ServerConnection',
    'high-level Server on_ready sees transitioned H2 connection');
is($h2_ready->{transport}, 'tls',
    'H2 Server connection retains TLS transport');
is($h1_ready->{class}, 'Linux::Event::HTTP::Server::Connection',
    'HTTP/1.1 fallback stays on existing Server::Connection');
is($h1_ready->{transport}, 'tls',
    'HTTP/1.1 fallback retains TLS transport');

is(scalar(@{$state->{server_request}}), 2,
    'same high-level on_request receives H2 and HTTP/1.1');
my ($h2_request) = grep { $_->{version} eq '2' }
    @{$state->{server_request}};
my ($h1_request) = grep { $_->{version} eq '1.1' }
    @{$state->{server_request}};

is($h2_request->{class}, 'Linux::Event::HTTP::_HTTP2::ServerConnection',
    'H2 callback receives transitioned connection object');
is($h2_request->{alpn}, 'h2', 'H2 callback sees h2 ALPN');
is($h2_request->{target}, '/selected',
    'H2 callback sees mapped Request target');
is($h2_request->{authority}, 'localhost',
    'H2 callback sees mapped Request authority');
ok($h2_request->{tx_match},
    'H2 conn->transaction is scoped to current stream');

is($h1_request->{class}, 'Linux::Event::HTTP::Server::Connection',
    'HTTP/1.1 callback receives existing connection class');
is($h1_request->{alpn}, 'http/1.1',
    'HTTP/1.1 callback sees fallback ALPN');
is($h1_request->{target}, '/fallback',
    'HTTP/1.1 callback sees ordinary Request target');
is($h1_request->{authority}, 'localhost',
    'HTTP/1.1 Request derives authority from Host');
ok($h1_request->{tx_match},
    'HTTP/1.1 conn->transaction retains ordinary semantics');

{
    my $ok = eval {
        Linux::Event::HTTP::Server->new(
            loop  => Linux::Event::Loop->new,
            host  => '127.0.0.1',
            port  => 0,
            http2 => 1,
            on_request => sub {},
        );
        1;
    };
    ok(!$ok, 'http2 Server requires TLS');
    like($@, qr/http2 requires tls/,
        'missing TLS error is explicit');
}

{
    package T::CustomHTTP2Connection;
    use parent 'Linux::Event::HTTP::Server::Connection';
    sub on_request ($self, $req, $res) { $res->body('unused') }
}

{
    my $ok = eval {
        Linux::Event::HTTP::Server->new(
            loop  => Linux::Event::Loop->new,
            host  => '127.0.0.1',
            port  => 0,
            http2 => 1,
            connection_class => 'T::CustomHTTP2Connection',
            tls => {
                cert_file => $cert,
                key_file  => $key,
            },
        );
        1;
    };
    ok(!$ok, 'http2 rejects custom connection_class for now');
    like($@, qr/http2 currently requires the default connection_class/,
        'custom connection_class limitation is explicit');
}

{
    my $ok = eval {
        Linux::Event::HTTP::Server->new(
            loop  => Linux::Event::Loop->new,
            host  => '127.0.0.1',
            port  => 0,
            http2 => 1,
            tls => {
                cert_file => $cert,
                key_file  => $key,
                alpn      => [ 'h2' ],
            },
            on_request => sub {},
        );
        1;
    };
    ok(!$ok, 'http2 Server owns ALPN policy');
    like($@, qr/http2 owns TLS ALPN selection/,
        'custom ALPN conflict is explicit');
}


{
    my $user_close_count = 0;
    my $transitioned = bless {
        _http_user_on_close => sub { ++$user_close_count },
    }, 'Linux::Event::HTTP::_HTTP2::ServerConnection';

    my $ok = eval {
        Linux::Event::HTTP::Server::Connection::_http_transport_close(
            $transitioned,
        );
        1;
    };
    ok($ok,
        'retained server close callback survives H2 class transition');
    is($user_close_count, 1,
        'retained server close callback still dispatches user on_close');
}

done_testing;
