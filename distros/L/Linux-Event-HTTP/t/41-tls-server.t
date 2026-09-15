use v5.36;
use strict;
use warnings;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);

use Linux::Event::Loop;
use Linux::Event::Kernel::Timer;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::TLS ();
use Linux::Event::HTTP::Server::Connection;
use Linux::Event::HTTP::Server;

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
plan skip_all => 'openssl command is required for TLS integration test'
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

{
    package T::SecureHTTP;
    use parent 'Linux::Event::HTTP::Server::Connection';

    sub tls_defaults ($class) {
        return alpn => ['http/1.1'];
    }

    sub on_request ($self, $req, $res) {
        my $state = $self->data;
        $state->{request_class} = ref($req);
        $state->{connection_class} = ref($self);
        $state->{server_alpn} = $self->selected_alpn;
        $state->{server_tls_protocol} = $self->tls_protocol;
        $state->{server_tls_cipher} = $self->tls_cipher;
        $res->header('Content-Type', 'text/plain');
        $res->body("secure\n");
    }
}

my $loop = Linux::Event::Loop->new;
my $state = {
    wire => '',
    server_ready => 0,
    client_ready => 0,
};

my $server = Linux::Event::HTTP::Server->new(
    loop             => $loop,
    host             => '127.0.0.1',
    port             => 0,
    data             => $state,
    connection_class => 'T::SecureHTTP',
    tls => {
        cert_file => $cert,
        key_file  => $key,
    },
    on_ready => sub ($conn) {
        $state->{server_ready}++;
        $state->{ready_class} = ref($conn);
        $state->{ready_alpn} = $conn->selected_alpn;
        $state->{ready_tls_protocol} = $conn->tls_protocol;
    },
);

my $guard = Linux::Event::Kernel::Timer->new(
    loop  => $loop,
    after => 3,
    on_timer => sub ($timer) {
        die "HTTP TLS Server integration test timed out\n";
    },
);

Linux::Event::IO::Sock::Stream->connect(
    loop => $loop,
    host => '127.0.0.1',
    port => $server->port,
    transport => Linux::Event::TLS->client(
        server_name => 'localhost',
        verify      => 0,
        alpn        => ['http/1.1'],
    ),
    on_ready => sub ($stream) {
        $state->{client_ready}++;
        $state->{client_alpn} = $stream->selected_alpn;
        $state->{client_tls_protocol} = $stream->tls_protocol;
        $state->{client_tls_cipher} = $stream->tls_cipher;
        $stream->write(
            "GET /secure HTTP/1.1\r\n" .
            "Host: localhost\r\n" .
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
        $server->close;
        $loop->stop;
    },
    on_error => sub ($stream, $error) {
        die "HTTP TLS client failed: $error\n";
    },
);

$loop->run;

is($state->{server_ready}, 1,
    'accepted HTTP Connection becomes ready after TLS handshake');
is($state->{client_ready}, 1,
    'TLS client becomes ready after handshake');
is($state->{ready_class}, 'T::SecureHTTP',
    'Server readiness callback receives configured HTTP Connection subclass');
is($state->{connection_class}, 'T::SecureHTTP',
    'HTTP request runs on configured TLS Connection subclass');
is($state->{request_class}, 'Linux::Event::HTTP::Request',
    'decrypted request bytes reach ordinary HTTP Request parser');
is($state->{ready_alpn}, 'http/1.1',
    'server readiness exposes negotiated HTTP/1.1 ALPN');
is($state->{server_alpn}, 'http/1.1',
    'HTTP callback sees negotiated HTTP/1.1 ALPN');
is($state->{client_alpn}, 'http/1.1',
    'client sees negotiated HTTP/1.1 ALPN');
ok(defined($state->{ready_tls_protocol}) && length($state->{ready_tls_protocol}),
    'TLS protocol is available before HTTP readiness callback');
ok(defined($state->{server_tls_protocol}) && length($state->{server_tls_protocol}),
    'HTTP callback can inspect negotiated TLS protocol');
ok(defined($state->{server_tls_cipher}) && length($state->{server_tls_cipher}),
    'HTTP callback can inspect negotiated TLS cipher');
ok(defined($state->{client_tls_cipher}) && length($state->{client_tls_cipher}),
    'client exposes negotiated TLS cipher');
like(
    $state->{wire},
    qr/\AHTTP\/1\.1 200 OK\r\nContent-Type: text\/plain\r\nContent-Length: 7\r\nConnection: close\r\n\r\nsecure\n\z/s,
    'HTTP response is delivered through TLS transport',
);

{
    package T::InvalidSecureHTTP;
    use parent 'Linux::Event::HTTP::Server::Connection';

    sub tls_defaults ($class) {
        return alpn => ['http/1.1'];
    }

    sub on_request ($self, $req, $res) {
        $res->body("unreachable\n");
    }
}

my $ok = eval {
    Linux::Event::HTTP::Server->new(
        loop             => Linux::Event::Loop->new,
        host             => '127.0.0.1',
        port             => 0,
        connection_class => 'T::InvalidSecureHTTP',
        tls              => {},
    );
    1;
};
ok(!$ok, 'Server rejects TLS Connection without server certificate policy');
like($@, qr/cert_file and key_file/,
    'invalid TLS server policy fails at Server construction');

done_testing;
