use v5.36;
use Test::More;
use IO::Socket::INET;
use Linux::Event::Loop;
use Linux::Event::Kernel::Timer;
use Linux::Event::HTTP::Server;

my $ready = eval { require Unblock::WebSocket::Server; 1 };
die "WebSocket required: $@" if !$ready && $ENV{REBUILD_REQUIRE_WEBSOCKET};
plan skip_all => 'optional Unblock::WebSocket is missing' unless $ready;

my $loop = Linux::Event::Loop->new;
my ($opened, $offered, $messages, $normal, @order, @received, @errors);
my $server = Linux::Event::HTTP::Server->new(
    loop => $loop, host => '127.0.0.1', port => 0,
    native_input => ($ENV{REBUILD_NATIVE_INPUT} // 1),
    http1 => { websocket => 1 },
    on_request => sub ($tx, $req) {
        ++$normal;
        $tx->respond(status => 200, body => 'ordinary');
    },
    on_websocket => sub ($tx, $req) {
        ++$offered;
        push @order, 'offer';
        return {
            backend => 'perl',
            on_open => sub {
                ++$opened;
                push @order, 'open';
            },
            on_message => sub ($ws, $body, $type) {
                ++$messages;
                push @order, 'message';
                push @received, [$body, $type];
                $ws->send_text("echo:$body");
                $loop->stop;
            },
            on_error => sub ($ws, $error) { push @errors, "$error" },
        };
    },
);
my $sock = IO::Socket::INET->new(
    PeerAddr => '127.0.0.1', PeerPort => $server->port, Proto => 'tcp',
) or die "connect: $!";
my $head = "GET /ws HTTP/1.1\r\nHost: localhost\r\n"
    . "Upgrade: websocket\r\nConnection: Upgrade\r\n"
    . "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n"
    . "Sec-WebSocket-Version: 13\r\n\r\n";
my $payload = 'hello';
my $mask = pack('C4', 1, 2, 3, 4);
my $masked = join '', map {
    chr(ord(substr($payload, $_, 1)) ^ ord(substr($mask, $_ % 4, 1)))
} 0 .. length($payload) - 1;
my $frame = pack('CC', 0x81, 0x80 | length($payload)) . $mask . $masked;
my $wire = $head . $frame;
is(syswrite($sock, $wire), length($wire),
    'handshake and masked frame sent in one kernel write');
my $guard = Linux::Event::Kernel::Timer->new(
    loop => $loop, after => 4,
    on_timer => sub { push @errors, 'timeout'; $loop->stop },
);
$loop->run;
$guard->cancel;
is($offered, 1, 'one accepted upgrade');
is($opened, 1, 'WebSocket opens once');
is($messages, 1, 'same-read frame delivered once');
is_deeply(\@received, [['hello', 'text']], 'WebSocket frame intact');
is_deeply(\@order, ['offer', 'open', 'message'],
    '101 accepted before native remainder delivered');
is_deeply(\@errors, [], 'no callback errors');

$loop->run_for(0.05);
$sock->blocking(0);
my $reply = '';
for (1..6) {
    my $count = sysread($sock, my $part, 8192);
    $reply .= $part if defined($count) && $count > 0;
    last if index($reply, pack('CC', 0x81, 10) . 'echo:hello') >= 0;
    $loop->run_for(0.03);
}
like($reply, qr{\AHTTP/1\.1 101 Switching Protocols\r\n}i,
    'HTTP1 writes 101 to original socket');
like($reply, qr/\r\n\r\n.*\x81\x0aecho:hello/s,
    'WebSocket output follows HTTP headers in order');

close $sock;
$loop->run_for(0.03);
my $shutdown = 0;
$server->shutdown(grace => 0, on_complete => sub {
    ++$shutdown;
    $loop->stop;
});
if (!$shutdown) {
    my $timeout = Linux::Event::Kernel::Timer->new(
        loop => $loop, after => 3,
        on_timer => sub { push @errors, 'shutdown timeout'; $loop->stop },
    );
    $loop->run;
    $timeout->cancel;
}
is($shutdown, 1, 'shutdown completion called once');
is($server->connection_count, 0, 'upgraded connection removed from Server');
is($loop->count, 0, 'no surviving watchers');
done_testing;
