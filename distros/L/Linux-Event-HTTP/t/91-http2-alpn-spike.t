use v5.36;
use strict;
use warnings;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);

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

use Linux::Event::IO::Sock::Listener;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;
use Linux::Event::TLS ();

use constant {
    H2_HEADERS    => 1,
    H2_END_STREAM => 0x1,
};

sub flush_session ($stream, $session) {
    while ($session->want_write) {
        my $bytes = $session->mem_send;
        last if !defined($bytes) || $bytes eq '';
        $stream->write($bytes);
    }
    return;
}

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
plan skip_all => 'openssl command is required for HTTP/2 ALPN spike'
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
    server_ready       => 0,
    client_ready       => 0,
    server_h2_input    => 0,
    client_h2_input    => 0,
    server_path        => undef,
    client_status      => undef,
    client_body        => '',
    errors             => [],
};

my %server_session;

my $listener = Linux::Event::IO::Sock::Listener->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    stream => {
        tls => {
            cert_file => $cert,
            key_file  => $key,
            alpn      => [ 'h2', 'http/1.1' ],
        },
        on_ready => sub ($stream) {
            ++$state->{server_ready};
            $state->{server_alpn} = $stream->selected_alpn;

            my $session;
            $session = Net::HTTP2::nghttp2::Session->new_server(
                callbacks => {
                    on_begin_headers => sub ($stream_id, $type, $flags) {
                        return 0;
                    },
                    on_header => sub ($stream_id, $name, $value, $flags) {
                        if ($name eq ':path') {
                            $state->{server_path} = $value;
                        }
                        return 0;
                    },
                    on_frame_recv => sub ($frame) {
                        return 0 if $frame->{type} != H2_HEADERS;
                        return 0 if !($frame->{flags} & H2_END_STREAM);
                        return 0 if !$frame->{stream_id};

                        $session->submit_response(
                            $frame->{stream_id},
                            status => 200,
                            headers => [
                                [ 'content-type', 'text/plain' ],
                            ],
                            body => 'tls-h2',
                        );
                        return 0;
                    },
                    on_stream_close => sub ($stream_id, $error_code) {
                        $state->{server_close_error} = $error_code;
                        return 0;
                    },
                },
            );
            $server_session{$stream->fd} = $session;
            $session->send_connection_preface(
                max_concurrent_streams => 100,
            );
            flush_session($stream, $session);
        },
        on_data => sub ($stream, $bytes) {
            ++$state->{server_h2_input};
            die "server received application bytes before TLS ALPN selection\n"
                if !$state->{server_ready}
                || ($state->{server_alpn} // '') ne 'h2';

            my $session = $server_session{$stream->fd}
                or die "server HTTP/2 ALPN session is not ready\n";
            my $consumed = $session->mem_recv($bytes);
            die "server HTTP/2 ALPN session did not consume complete input\n"
                if !defined($consumed) || $consumed != length($bytes);
            flush_session($stream, $session);
        },
        on_error => sub ($stream, $error) {
            push @{$state->{errors}}, "server: $error";
            $loop->stop;
        },
        on_close => sub ($stream) {
            delete $server_session{$stream->fd};
        },
    },
);

my $guard = Linux::Event::Kernel::Timer->new(
    loop => $loop,
    after => 5,
    on_timer => sub ($timer) {
        die "HTTP/2 ALPN integration spike timed out\n";
    },
);

my $client_session;
my $client = Linux::Event::IO::Sock::Stream->connect(
    loop => $loop,
    host => '127.0.0.1',
    port => $listener->port,
    transport => Linux::Event::TLS->client(
        server_name => 'localhost',
        verify      => 0,
        alpn        => [ 'h2', 'http/1.1' ],
    ),
    on_ready => sub ($stream) {
        ++$state->{client_ready};
        $state->{client_alpn} = $stream->selected_alpn;

        $client_session = Net::HTTP2::nghttp2::Session->new_client(
            callbacks => {
                on_header => sub ($stream_id, $name, $value, $flags) {
                    $state->{client_status} = $value
                        if $name eq ':status';
                    return 0;
                },
                on_data_chunk_recv => sub ($stream_id, $data, $flags) {
                    $state->{client_body} .= $data;
                    return 0;
                },
                on_stream_close => sub ($stream_id, $error_code) {
                    $state->{client_close_error} = $error_code;
                    $guard->cancel;
                    $stream->close if !$stream->is_closed;
                    $listener->close;
                    $loop->stop;
                    return 0;
                },
            },
        );

        $client_session->send_connection_preface(
            max_concurrent_streams => 100,
        );
        $state->{client_stream_id} = $client_session->submit_request(
            method    => 'GET',
            path      => '/alpn-h2',
            scheme    => 'https',
            authority => 'localhost',
        );
        flush_session($stream, $client_session);
    },
    on_data => sub ($stream, $bytes) {
        ++$state->{client_h2_input};
        die "client received application bytes before TLS ALPN selection\n"
            if !$state->{client_ready}
                || ($state->{client_alpn} // '') ne 'h2';

        die "client HTTP/2 ALPN session is not ready\n"
            if !$client_session;
        my $consumed = $client_session->mem_recv($bytes);
        die "client HTTP/2 ALPN session did not consume complete input\n"
            if !defined($consumed) || $consumed != length($bytes);
        flush_session($stream, $client_session);
    },
    on_error => sub ($stream, $error) {
        push @{$state->{errors}}, "client: $error";
        $loop->stop;
    },
);

$loop->run;

is_deeply($state->{errors}, [], 'TLS HTTP/2 spike has no transport errors');
is($state->{server_ready}, 1, 'server becomes application-ready after TLS handshake');
is($state->{client_ready}, 1, 'client becomes application-ready after TLS handshake');
is($state->{server_alpn}, 'h2', 'server selects h2 through ALPN');
is($state->{client_alpn}, 'h2', 'client selects h2 through ALPN');
is($state->{server_path}, '/alpn-h2',
    'server parses HTTP/2 request only after h2 selection');
is($state->{client_status}, '200',
    'client receives HTTP/2 response status over TLS');
is($state->{client_body}, 'tls-h2',
    'client receives HTTP/2 response body over TLS');
is($state->{server_close_error}, 0,
    'server HTTP/2 stream closes without protocol error');
is($state->{client_close_error}, 0,
    'client HTTP/2 stream closes without protocol error');
cmp_ok($state->{server_h2_input}, '>=', 1,
    'server received decrypted HTTP/2 application input');
cmp_ok($state->{client_h2_input}, '>=', 1,
    'client received decrypted HTTP/2 application input');

done_testing;
