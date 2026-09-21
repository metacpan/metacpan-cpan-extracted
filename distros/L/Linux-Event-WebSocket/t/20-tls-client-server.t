use v5.36;
use strict;
use warnings;

use Test::More;
use FindBin qw($Bin);

use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;
use Linux::Event::WebSocket::Client;
use Linux::Event::WebSocket::Server;

my $cert = "$Bin/tls-certs/server-cert.pem";
my $key  = "$Bin/tls-certs/server-key.pem";

my $loop = Linux::Event::Loop->new;
my $state = {
    errors => [],
};

my $server = Linux::Event::WebSocket::Server->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    tls => {
        cert_file => $cert,
        key_file  => $key,
    },

    on_open => sub ($ws) {
        $state->{server_open}++;
        $state->{server_secure} = $ws->secure;
        $state->{server_transport} = $ws->transport_name;
    },

    on_message => sub ($ws, $payload, $type) {
        $state->{server_message} = [ $type, $payload ];
        $ws->send_text("tls:$payload");
    },

    on_error => sub ($connection, $error) {
        push @{$state->{errors}}, "server: $error";
    },
);

my $guard = Linux::Event::Kernel::Timer->new(
    loop => $loop,
    after => 5,
    on_timer => sub ($timer) {
        die "wss integration test timed out\n";
    },
);

my $client = Linux::Event::WebSocket::Client->new(
    loop => $loop,
    tls => {
        ca_file => $cert,
    },

    on_open => sub ($ws) {
        $state->{client_open}++;
        $state->{client_secure} = $ws->secure;
        $state->{client_transport} = $ws->transport_name;
        $ws->send_text('hello');
    },

    on_message => sub ($ws, $payload, $type) {
        $state->{client_message} = [ $type, $payload ];
        $ws->close(code => 1000, reason => 'tls done');
    },

    on_close => sub ($ws, $code, $reason) {
        $state->{client_close}++;
        $state->{client_close_code} = $code;
        $state->{client_close_reason} = $reason;
        $guard->cancel;
        $server->close;
        $loop->stop;
    },

    on_error => sub ($connection, $error) {
        push @{$state->{errors}}, "client: $error";
        $guard->cancel;
        $server->close;
        $loop->stop;
    },
);

$client->connect('wss://localhost:' . $server->port . '/secure');
$loop->run;

is_deeply($state->{errors}, [], 'wss exchange reports no errors');
is($state->{server_open}, 1, 'server opens TLS WebSocket connection');
is($state->{client_open}, 1, 'client opens TLS WebSocket connection');
ok($state->{server_secure}, 'server WebSocket reports secure transport');
ok($state->{client_secure}, 'client WebSocket reports secure transport');
is($state->{server_transport}, 'tls', 'server keeps TLS transport after Upgrade');
is($state->{client_transport}, 'tls', 'client keeps TLS transport after Upgrade');
is_deeply($state->{server_message}, [ text => 'hello' ],
    'server receives text over wss');
is_deeply($state->{client_message}, [ text => 'tls:hello' ],
    'client receives text over wss');
is($state->{client_close}, 1, 'client observes clean wss close');
is($state->{client_close_code}, 1000, 'wss close code is preserved');
is($state->{client_close_reason}, 'tls done', 'wss close reason is preserved');

done_testing;
