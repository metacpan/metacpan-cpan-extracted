use v5.36;
use strict;
use warnings;

use Test::More;

use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;
use Linux::Event::WebSocket::Client;
use Linux::Event::WebSocket::Server;

my $loop = Linux::Event::Loop->new;
my $state = {
    errors => [],
    server_messages => [],
    client_messages => [],
};

my $text = 'wide-' . chr(0x263a);
my $binary = pack('C*', 0, 255, 128, 1, 2, 3);

my $server = Linux::Event::WebSocket::Server->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,

    on_message => sub ($ws, $payload, $type) {
        push @{$state->{server_messages}}, [ $type, $payload ];
        if ($type eq 'text') {
            $ws->send_text($payload);
        } else {
            $ws->send_binary($payload);
        }
    },

    on_error => sub ($connection, $error) {
        push @{$state->{errors}}, "server: $error";
    },
);

my $guard = Linux::Event::Kernel::Timer->new(
    loop => $loop,
    after => 3,
    on_timer => sub ($timer) {
        die "message type integration test timed out\n";
    },
);

my $client = Linux::Event::WebSocket::Client->new(
    loop => $loop,

    on_open => sub ($ws) {
        $ws->ping('probe');
        $ws->send_text($text);
    },

    on_message => sub ($ws, $payload, $type) {
        push @{$state->{client_messages}}, [ $type, $payload ];
        if (@{$state->{client_messages}} == 1) {
            $ws->send_binary($binary);
        } else {
            $ws->close(code => 1000, reason => 'types done');
        }
    },

    on_close => sub ($ws, $code, $reason) {
        $state->{close} = [ $code, $reason ];
        $guard->cancel;
        $server->close;
        $loop->stop;
    },

    on_error => sub ($connection, $error) {
        push @{$state->{errors}}, "client: $error";
    },
);

$client->connect('ws://127.0.0.1:' . $server->port . '/types');
$loop->run;

is_deeply($state->{errors}, [], 'text/binary/ping exchange reports no errors');
is(scalar @{$state->{server_messages}}, 2, 'server receives two data messages');
is($state->{server_messages}[0][0], 'text', 'first server message is text');
is($state->{server_messages}[0][1], $text, 'server receives decoded Unicode text');
is($state->{server_messages}[1][0], 'binary', 'second server message is binary');
is($state->{server_messages}[1][1], $binary, 'server receives binary bytes unchanged');
is(scalar @{$state->{client_messages}}, 2, 'client receives two echoed messages');
is($state->{client_messages}[0][0], 'text', 'first client message is text');
is($state->{client_messages}[0][1], $text, 'client receives decoded Unicode text');
is($state->{client_messages}[1][0], 'binary', 'second client message is binary');
is($state->{client_messages}[1][1], $binary, 'client receives binary bytes unchanged');
is_deeply($state->{close}, [ 1000, 'types done' ], 'close follows successful exchange');

done_testing;
