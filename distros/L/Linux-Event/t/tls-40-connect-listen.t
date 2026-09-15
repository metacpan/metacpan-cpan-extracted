use v5.36;
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use Scalar::Util qw(refaddr);
use Socket qw(AF_INET SOCK_STREAM inet_aton pack_sockaddr_in);

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Listener;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::TLS;

our ($LOOP, $STATE, $CLIENT_ID);

{
    package T::IntegratedTLSServer;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_ready ($stream) {
        push @{ $stream->data->{server_order} }, 'ready';
        $stream->data->{server_ready}++;
        $stream->data->{server_ready_transport} = $stream->is_transport_ready;
    }

    sub on_data ($stream, $bytes) {
        $stream->data->{server_input} .= $bytes;
        $stream->write('pong') if $stream->data->{server_input} eq 'ping';
    }

    sub on_error ($stream, $error) {
        $stream->data->{error} = "$error";
        $stream->loop->stop;
    }

}

{
    package T::IntegratedTLSListener;
    use parent 'Linux::Event::IO::Sock::Listener';

    sub on_error ($listener, $error) {
        $main::STATE->{error} = "$error";
        $listener->loop->stop;
    }

    sub on_accept ($listener, $stream) {
        push @{ $main::STATE->{server_order} }, 'accept';
        $main::STATE->{accepted_transport_ready}
            = $stream->is_transport_ready;
        return;
    }
}

{
    package T::IntegratedTLSClient;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::TLS
        ca_file => "$FindBin::Bin/tls-certs/server-cert.pem",
        alpn    => ['les-integrated/1'];

    sub on_ready ($stream) {
        die 'TLS connecting Stream identity changed'
            if Scalar::Util::refaddr($stream) != $main::CLIENT_ID;
        $stream->data->{client_ready}++;
        $stream->data->{client_ready_transport} = $stream->is_transport_ready;
    }

    sub on_data ($stream, $bytes) {
        $stream->data->{client_input} .= $bytes;
        $stream->loop->stop if $stream->data->{client_input} eq 'pong';
    }

    sub on_error ($stream, $error) {
        $stream->data->{error} = "$error";
        $stream->loop->stop;
    }
}

$STATE = {
    server_ready => 0,
    client_ready => 0,
    server_input => '',
    client_input => '',
    error => '',
    server_order => [],
};
$LOOP = Linux::Event::Loop->new;

my $plain_loop = Linux::Event::Loop->new;
my $plain_transport;
my $plain_listener = Linux::Event::IO::Sock::Listener->new(
    loop => $plain_loop,
    host => '127.0.0.1',
    port => 0,
    stream => {
        class => 'T::IntegratedTLSServer',
        data  => $STATE,
    },
    on_accept => sub ($listener, $stream) {
        $plain_transport = $stream->transport;
        $stream->close;
        $plain_loop->stop;
    },
);
socket(my $plain_client, AF_INET, SOCK_STREAM, 0) or die "socket: $!";
connect($plain_client,
    pack_sockaddr_in($plain_listener->port, inet_aton('127.0.0.1')))
    or die "connect: $!";
$plain_loop->run;
ok(!defined($plain_transport),
    'the same Stream class remains plain when Listener tls is omitted');
close $plain_client;
$plain_listener->close;

my $listener = $LOOP->add(T::IntegratedTLSListener->new(
    host => '127.0.0.1', port => 0,
    stream => {
        class => 'T::IntegratedTLSServer',
        data  => $STATE,
        tls => {
            cert_file => "$FindBin::Bin/tls-certs/server-cert.pem",
            key_file  => "$FindBin::Bin/tls-certs/server-key.pem",
            alpn      => ['les-integrated/1'],
        },
    },
));
my $client = T::IntegratedTLSClient->connect(
    host => 'localhost', port => $listener->port, timeout => 5,
    data => $STATE,
);
$CLIENT_ID = refaddr($client);
ok($client->write('ping'),
    'TLS pre-connect write below high watermark permits more output');
$LOOP->add($client);
$LOOP->run_for(5);

is($STATE->{error}, '', 'integrated TLS client/server path has no error');
is($STATE->{client_ready}, 1, 'client on_ready follows verified TLS handshake');
is($STATE->{server_ready}, 1, 'accepted server on_ready follows TLS handshake');
is_deeply($STATE->{server_order}, [qw(accept ready)],
    'Listener on_accept precedes TLS Stream on_ready');
ok(!$STATE->{accepted_transport_ready},
    'Listener on_accept observes TLS Stream before handshake readiness');
ok($STATE->{client_ready_transport}, 'client transport is ready inside on_ready');
ok($STATE->{server_ready_transport}, 'server transport is ready inside on_ready');
is($client->selected_alpn, 'les-integrated/1',
    'Stream exposes negotiated ALPN without provider access');
like($client->tls_protocol, qr/^TLSv1\.[23]$/,
    'Stream exposes the negotiated TLS protocol');
ok(defined $client->tls_cipher, 'Stream exposes the negotiated TLS cipher');
ok(ref($client->tls_stats) eq 'HASH', 'Stream exposes native TLS statistics');
is($STATE->{server_input}, 'ping', 'server receives queued client plaintext');
is($STATE->{client_input}, 'pong', 'client receives server plaintext');
is(refaddr($client), $CLIENT_ID, 'TLS Stream identity remains stable');

$client->close;
$listener->close;
done_testing;
