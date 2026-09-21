use v5.36;
use strict;
use warnings;

use Test::More;
use Digest::SHA qw(sha1);
use MIME::Base64 qw(encode_base64);

use Linux::Event::IO::Sock::Listener;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;
use Linux::Event::WebSocket::Client;
use Linux::Event::WebSocket::_Frame;
use Linux::Event::WebSocket::_Parser;
use Linux::Event::WebSocket::Server;

{
    package T::UpgradeTailClient;
    use v5.36;
    use parent 'Linux::Event::IO::Sock::Stream';

    sub on_ready ($self) {
        my $state = $self->data;
        my $request = join "\r\n",
            'GET /chat HTTP/1.1',
            'Host: 127.0.0.1:' . $state->{port},
            'Upgrade: websocket',
            'Connection: Upgrade',
            'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==',
            'Sec-WebSocket-Version: 13',
            '', '';
        my $frame = Linux::Event::WebSocket::_Frame->encode(
            text     => 'hello',
            masked   => 1,
            mask_key => "\x01\x02\x03\x04",
        );

        $self->write($request . $frame);
        return;
    }

    sub on_data ($self, $bytes) {
        my $state = $self->data;
        if (!$state->{response_complete}) {
            $state->{response_bytes} .= $bytes;
            my $marker = index($state->{response_bytes}, "\r\n\r\n");
            return if $marker < 0;

            my $end = $marker + 4;
            $state->{response_head} = substr($state->{response_bytes}, 0, $end);
            $bytes = substr($state->{response_bytes}, $end);
            $state->{response_complete} = 1;
            delete $state->{response_bytes};
        }

        $state->{parser}->feed($bytes) if length $bytes;
        while (my $frame = $state->{parser}->next_frame) {
            next if $frame->{opcode} != 1;
            $state->{client_message} = $frame->{payload};
            $state->{guard}->cancel;
            $state->{loop}->stop;
            last;
        }
        return;
    }

    sub on_error ($self, $error) {
        my $state = $self->data;
        push @{$state->{errors}}, "client: $error";
        $state->{guard}->cancel;
        $state->{loop}->stop;
        return;
    }
}

my $loop = Linux::Event::Loop->new;
my $state = {
    loop           => $loop,
    errors         => [],
    server_message => undef,
    client_message => undef,
    server_sequence => [],
    parser         => Linux::Event::WebSocket::_Parser->new(
        endpoint_type  => 'client',
        max_frame_size => 1024,
    ),
};

my $server = Linux::Event::WebSocket::Server->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,

    on_open => sub ($ws) {
        push @{$state->{server_sequence}}, 'open';
    },

    on_message => sub ($ws, $payload, $type) {
        push @{$state->{server_sequence}}, 'message';
        $state->{server_message} = [ $type, $payload ];
        $ws->send_text("echo:$payload");
    },

    on_error => sub ($connection, $error) {
        push @{$state->{errors}}, "server: $error";
        $state->{guard}->cancel;
        $loop->stop;
    },
);
$state->{port} = $server->port;

$state->{guard} = Linux::Event::Kernel::Timer->new(
    loop  => $loop,
    after => 3,
    on_timer => sub ($timer) {
        push @{$state->{errors}}, 'same-read Upgrade test timed out';
        $loop->stop;
    },
);

my $client = T::UpgradeTailClient->connect(
    loop    => $loop,
    host    => '127.0.0.1',
    port    => $server->port,
    timeout => 2,
    data    => $state,
);

$loop->run;

is_deeply($state->{errors}, [], 'same-read Upgrade reports no errors');
like($state->{response_head} // '',
    qr/\AHTTP\/1\.1 101 Switching Protocols\r\n/,
    'server returns a 101 response');
is_deeply($state->{server_message}, [ text => 'hello' ],
    'first frame in the HTTP request read survives the protocol transition');
is_deeply(
    $state->{server_sequence},
    [qw(open message)],
    'server opens before delivering the same-read frame',
);
is($state->{client_message}, 'echo:hello',
    'transitioned server writes a WebSocket response');

$client->close if !$client->is_closed;
$server->close;

{
    my $client_loop = Linux::Event::Loop->new;
    my $client_state = {
        errors   => [],
        sequence => [],
    };
    my $sent = 0;
    my $request_bytes = '';
    my $listener = Linux::Event::IO::Sock::Listener->new(
        loop => $client_loop,
        host => '127.0.0.1',
        port => 0,
        stream => {
            on_data => sub ($stream, $bytes) {
                return if $sent;
                $request_bytes .= $bytes;
                return if index($request_bytes, "\r\n\r\n") < 0;
                $sent = 1;

                my ($key) =
                    $request_bytes =~ /^Sec-WebSocket-Key:[ \t]*(\S+)/mi;
                if (!defined $key) {
                    push @{$client_state->{errors}},
                        'raw server did not receive a WebSocket key';
                    $client_loop->stop;
                    return;
                }
                my $accept = encode_base64(
                    sha1($key . '258EAFA5-E914-47DA-95CA-C5AB0DC85B11'),
                    '',
                );
                my $response = join "\r\n",
                    'HTTP/1.1 101 Switching Protocols',
                    'Upgrade: websocket',
                    'Connection: Upgrade',
                    "Sec-WebSocket-Accept: $accept",
                    '', '';
                my $frame = Linux::Event::WebSocket::_Frame->encode(
                    text => 'welcome',
                );

                $stream->write($response . $frame);
                return;
            },
        },
    );

    my $client_guard = Linux::Event::Kernel::Timer->new(
        loop  => $client_loop,
        after => 3,
        on_timer => sub ($timer) {
            push @{$client_state->{errors}},
                'same-read client Upgrade test timed out';
            $client_loop->stop;
        },
    );

    my $websocket_client = Linux::Event::WebSocket::Client->new(
        loop => $client_loop,

        on_open => sub ($ws) {
            push @{$client_state->{sequence}}, 'open';
        },

        on_message => sub ($ws, $payload, $type) {
            push @{$client_state->{sequence}}, 'message';
            $client_state->{message} = [ $type, $payload ];
            $client_state->{status} = $ws->handshake_response->status;
            $client_guard->cancel;
            $ws->abort;
            $listener->close;
            $client_loop->stop;
        },

        on_error => sub ($connection, $error) {
            push @{$client_state->{errors}}, "client: $error";
            $client_guard->cancel;
            $listener->close;
            $client_loop->stop;
        },
    );

    $websocket_client->connect(
        'ws://127.0.0.1:' . $listener->port . '/socket'
    );
    $client_loop->run;

    is_deeply($client_state->{errors}, [],
        'same-read client Upgrade reports no errors');
    is_deeply($client_state->{sequence}, [qw(open message)],
        'client opens before delivering the same-read frame');
    is_deeply($client_state->{message}, [ text => 'welcome' ],
        'first frame in the HTTP response read survives the protocol transition');
    is($client_state->{status}, 101,
        'client retains the combined Upgrade response');
    ok(
        !$websocket_client->connection->can('on_data'),
        'established client uses native raw input instead of Perl on_data',
    );
}

done_testing;
