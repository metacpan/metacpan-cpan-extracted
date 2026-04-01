use strict;
use warnings;
use Test::More;
use EV;
use EV::Websockets;
use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;
use MIME::Base64;
use Digest::SHA;

EV::Websockets::_set_debug(1) if $ENV{EV_WS_DEBUG};

my $port = 14345 + int(rand(1000));

my $headers_ok = 0;
my $raw_server_cv = AnyEvent->condvar;

my $raw_port = $port;
my $server_handle;
my $raw_server = tcp_server undef, $raw_port, sub {
    my ($fh) = @_;
    $server_handle = AnyEvent::Handle->new(fh => $fh, on_read => sub {
        my ($h) = @_;
        my $data = $h->{rbuf};
        if ($data =~ /X-Custom-Header: MyValue/ && $data =~ /Sec-WebSocket-Key: (\S+)/i) {
            my $key = $1;
            $headers_ok = 1;
            my $accept = MIME::Base64::encode_base64(Digest::SHA::sha1($key . '258EAFA5-E914-47DA-95CA-C5AB0DC85B11'), '');
            # Send minimal handshake response
            $h->push_write("HTTP/1.1 101 Switching Protocols\015\012" .
                           "Upgrade: websocket\015\012" .
                           "Connection: Upgrade\015\012" .
                           "Sec-WebSocket-Accept: $accept\015\012\015\012");
            $raw_server_cv->send;
        }
    }, on_error => sub { warn "Server error: $_[1]" });
};

my $ctx = EV::Websockets::Context->new();
my $conn = $ctx->connect(
    url => "ws://127.0.0.1:$raw_port",
    headers => { 'X-Custom-Header' => 'MyValue' },
    on_error => sub {
        my ($c, $err) = @_;
        diag "Client error: $err";
        $raw_server_cv->send;
    }
);

# Timeout
my $t = EV::timer(2, 0, sub { $raw_server_cv->send; });

$raw_server_cv->recv;

ok($headers_ok, 'Custom header was sent');

done_testing;
