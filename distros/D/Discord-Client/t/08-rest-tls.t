use v5.26;
use warnings;
use Test2::V1;
use lib 't/lib';
use TestDiscordTLS qw(certificate_directory);
use IO::Async::Loop;
use IO::Async::Listener;
use IO::Async::SSL;
use Net::Async::HTTP;
use Discord::Client::REST;

sub tls_server {
    my ($certificate_ip) = @_;

    # Trust this private CA only when the test explicitly supplies it to the client.
    my $directory = certificate_directory($certificate_ip);

    # Record only HTTP requests that made it through the local TLS handshake.
    my $loop = IO::Async::Loop->new;
    my ( @streams, @requests, @handshake_errors );
    my $listener = IO::Async::Listener->new(
        on_stream => sub {
            my ( undef, $stream ) = @_;
            push @streams, $stream;
            $stream->configure(
                on_read => sub {
                    my ( $stream, $buffer ) = @_;
                    return 0 unless $$buffer =~ /\r\n\r\n/;
                    push @requests, $$buffer;
                    $$buffer = '';
                    my $body = '{"tls":true}';
                    $stream->write( "HTTP/1.1 200 OK\r\nContent-Length: "
                            . length($body)
                            . "\r\nConnection: close\r\n\r\n$body" );
                    $stream->close_when_empty;
                    return 0;
                }
            );
            $loop->add($stream);
        }
    );
    $loop->add($listener);
    $listener->listen(
        addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 },
        extensions => ['SSL'],
        SSL_cert_file => "$directory/cert.pem",
        SSL_key_file => "$directory/key.pem",
        on_ssl_error => sub { push @handshake_errors, $_[0] },
    )->get;
    return {
        loop => $loop,
        listener => $listener,
        directory => $directory,
        requests => \@requests,
        streams => \@streams,
        base_url => 'https://127.0.0.1:' . $listener->read_handle->sockport . '/api/v10',
    };
}

sub close_server {
    my ($fixture) = @_;

    # Close accepted connections before stopping the listener and releasing its loop resources.
    for my $stream ( @{ $fixture->{streams} } ) {
        $stream->close;
        $fixture->{loop}->remove($stream) if $stream->loop;
    }
    $fixture->{listener}->close;
}

T2->subtest(
    'trusted CA and matching hostname allow a real HTTPS request',
    sub {
        my $fixture = tls_server('127.0.0.1');
        my $http = Net::Async::HTTP->new(
            fail_on_error => 0,
            SSL_ca_file => "$fixture->{directory}/ca.pem",
            SSL_verify_mode => 1,
            SSL_verifycn_scheme => 'http',
        );
        $fixture->{loop}->add($http);
        my $rest = Discord::Client::REST->new(
            token => 'FAKE_TEST_TOKEN',
            loop => $fixture->{loop},
            http => $http,
            timeout => 2,
            base_url => $fixture->{base_url},
        );

        # A trusted matching certificate must allow credentials to reach the test server.
        my $request = $rest->get_current_user;
        $fixture->{loop}->await($request);
        T2->is( scalar( $request->get ), { tls => 1 }, 'HTTPS response is decoded' );
        T2->is( scalar( @{ $fixture->{requests} } ), 1, 'one authenticated request reaches the server' );
        T2->like(
            $fixture->{requests}[0],
            qr/^Authorization: Bot FAKE_TEST_TOKEN\r$/m,
            'authorization is sent only after TLS succeeds'
        );

        # Close SDK work first, then release the injected transport and server.
        $rest->close->get;
        T2->ref_is( $http->loop, $fixture->{loop}, 'injected TLS transport remains caller-owned' );
        $fixture->{loop}->remove($http);
        close_server($fixture);
    }
);

T2->subtest(
    'the default HTTPS transport rejects an untrusted server before sending credentials',
    sub {
        my $fixture = tls_server('127.0.0.1');
        my $rest = Discord::Client::REST->new(
            token => 'FAKE_TEST_TOKEN',
            loop => $fixture->{loop},
            timeout => 2,
            base_url => $fixture->{base_url},
        );

        # Success tests alone cannot detect disabled certificate verification.
        my $request = $rest->get_current_user;
        $fixture->{loop}->await($request);
        T2->ok( $request->is_failed, 'untrusted certificate fails the request' );
        T2->is( scalar( @{ $fixture->{requests} } ), 0, 'no HTTP headers reach the untrusted server' );
        T2->is( $rest->stats->{http_started}, 1, 'the TLS failure is not retried' );
        $rest->close->get;
        close_server($fixture);
    }
);

T2->subtest(
    'a trusted CA cannot authorize the wrong server hostname',
    sub {
        # Trust the issuer but give the server a different IP in its certificate.
        my $fixture = tls_server('127.0.0.2');
        my $http = Net::Async::HTTP->new(
            fail_on_error => 0,
            SSL_ca_file => "$fixture->{directory}/ca.pem",
            SSL_verify_mode => 1,
            SSL_verifycn_scheme => 'http',
        );
        $fixture->{loop}->add($http);
        my $rest = Discord::Client::REST->new(
            token => 'FAKE_TEST_TOKEN',
            loop => $fixture->{loop},
            http => $http,
            timeout => 2,
            base_url => $fixture->{base_url},
        );

        # Hostname validation must reject the connection before any HTTP headers are sent.
        my $request = $rest->get_current_user;
        $fixture->{loop}->await($request);
        T2->ok( $request->is_failed, 'hostname mismatch fails the request' );
        T2->is( scalar( @{ $fixture->{requests} } ), 0, 'credentials are withheld on hostname mismatch' );
        $rest->close->get;
        $fixture->{loop}->remove($http);
        close_server($fixture);
    }
);

T2->done_testing;
