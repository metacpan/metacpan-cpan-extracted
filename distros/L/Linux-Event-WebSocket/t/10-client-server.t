use v5.36;
use strict;
use warnings;

use Test::More;
use Scalar::Util qw(refaddr);

use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;
use Linux::Event::WebSocket::Client;
use Linux::Event::WebSocket::Server;

my $loop = Linux::Event::Loop->new;
my $state = {
    errors          => [],
    server_open     => 0,
    client_open     => 0,
    server_close    => 0,
    client_close    => 0,
    server_message  => undef,
    client_message  => undef,
    handshake_path  => undef,
};

my $server = Linux::Event::WebSocket::Server->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    data => $state,
    subprotocols => ['chat'],

    on_handshake => sub ($request) {
        $state->{handshake_path} = $request->target;
        return $request->target eq '/chat';
    },

    on_open => sub ($ws) {
        ++$state->{server_open};
        $state->{server_class} = ref $ws;
        $state->{server_protocol} = $ws->subprotocol;
        $state->{server_secure} = $ws->secure;
        $state->{server_request_target} = $ws->handshake_request->target;
    },

    on_message => sub ($ws, $payload, $type) {
        $state->{server_message} = [ $type, $payload ];
        $ws->send_text("echo:$payload");
    },

    on_close => sub ($ws, $code, $reason) {
        ++$state->{server_close};
        $state->{server_close_code} = $code;
        $state->{server_close_reason} = $reason;
    },

    on_error => sub ($connection, $error) {
        push @{$state->{errors}}, "server: $error";
    },
);

my $guard = Linux::Event::Kernel::Timer->new(
    loop => $loop,
    after => 3,
    on_timer => sub ($timer) {
        die "production WebSocket integration test timed out\n";
    },
);

my $client = Linux::Event::WebSocket::Client->new(
    loop => $loop,
    data => $state,
    subprotocols => ['chat'],

    on_open => sub ($ws) {
        ++$state->{client_open};
        $state->{client_class} = ref $ws;
        $state->{client_protocol} = $ws->subprotocol;
        $state->{client_secure} = $ws->secure;
        $state->{client_response_status} = $ws->handshake_response->status;
        $state->{open_ref} = refaddr($ws);
        $ws->send_text('hello');
    },

    on_message => sub ($ws, $payload, $type) {
        $state->{client_message} = [ $type, $payload ];
        $ws->close(code => 1000, reason => 'done');
    },

    on_close => sub ($ws, $code, $reason) {
        ++$state->{client_close};
        $state->{client_close_code} = $code;
        $state->{client_close_reason} = $reason;
        $guard->cancel;
        $server->close;
        $loop->stop;
    },

    on_error => sub ($connection, $error) {
        push @{$state->{errors}}, "client: $error";
    },
);

my $connection = $client->connect(
    'ws://127.0.0.1:' . $server->port . '/chat'
);
$state->{initial_ref} = refaddr($connection);

$loop->run;

is_deeply($state->{errors}, [], 'client and server report no errors');
is($state->{handshake_path}, '/chat', 'server handshake callback sees request target');
is($state->{server_open}, 1, 'server opens one WebSocket connection');
is($state->{client_open}, 1, 'client opens one WebSocket connection');
is($state->{server_class}, 'Linux::Event::WebSocket::Server::Connection',
    'server transitions into production WebSocket connection class');
is($state->{client_class}, 'Linux::Event::WebSocket::Client::Connection',
    'client transitions into production WebSocket connection class');
is($state->{initial_ref}, $state->{open_ref},
    'client keeps object identity across HTTP Upgrade');
is($state->{server_protocol}, 'chat', 'server exposes negotiated subprotocol');
is($state->{client_protocol}, 'chat', 'client exposes negotiated subprotocol');
ok(!$state->{server_secure}, 'plain server connection reports non-TLS transport');
ok(!$state->{client_secure}, 'plain client connection reports non-TLS transport');
is($state->{server_request_target}, '/chat',
    'server connection retains handshake Request');
is($state->{client_response_status}, 101,
    'client connection retains validated handshake Response');
is_deeply($state->{server_message}, [ text => 'hello' ],
    'server receives decoded text message');
is_deeply($state->{client_message}, [ text => 'echo:hello' ],
    'client receives echoed text message');
is($state->{server_close}, 1, 'server observes one WebSocket close');
is($state->{client_close}, 1, 'client observes one WebSocket close');
is($state->{server_close_code}, 1000, 'server sees client close code');
is($state->{server_close_reason}, 'done', 'server sees client close reason');
is($state->{client_close_code}, 1000, 'client sees echoed close code');
is($state->{client_close_reason}, 'done', 'client sees echoed close reason');

done_testing;
