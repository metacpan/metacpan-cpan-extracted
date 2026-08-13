#!perl
use 5.008003;
use strict;
use warnings;
use IO::Socket::INET;
use Test::More;
use File::Spec ();
use Fetch;

# WebSocket (RFC 6455) client: the handshake, then masked text/binary frames
# out and reassembled messages in, against a small hand-rolled echo server
# (dependency-free: Digest::SHA + MIME::Base64 are core). This exercises
# Fetch's native framing end to end.

BEGIN {
    plan skip_all => 'Digest::SHA needed for the test server'
        unless eval { require Digest::SHA; 1 };
    plan skip_all => 'MIME::Base64 needed for the test server'
        unless eval { require MIME::Base64; 1 };
}
Digest::SHA->import('sha1');
MIME::Base64->import('encode_base64');

my $srv = IO::Socket::INET->new(
    LocalHost => '127.0.0.1', LocalPort => 0, Listen => 8, ReuseAddr => 1,
) or plan skip_all => "cannot listen: $!";
my $port = $srv->sockport;

my $pid = fork;
plan skip_all => "cannot fork: $!" unless defined $pid;
if (!$pid) {
    # Never hold the harness TAP pipe open, and never outlive the run:
    # a leaked server child hangs the whole suite after this test is done.
    open STDOUT, ">", File::Spec->devnull();
    open STDERR, ">", File::Spec->devnull();
    alarm 120;
    $SIG{TERM} = sub { exit 0 };
    my $c = $srv->accept or exit 0;
    $c->blocking(1);

    # ---- handshake ----
    my $hs = '';
    while ($hs !~ /\r\n\r\n/) {
        my $r = sysread($c, my $b, 1);
        last unless $r;
        $hs .= $b;
    }
    my ($key) = $hs =~ /Sec-WebSocket-Key:\s*(\S+)/i;
    my $accept = encode_base64(
        sha1($key . '258EAFA5-E914-47DA-95CA-C5AB0DC85B11'), '');
    syswrite($c, "HTTP/1.1 101 Switching Protocols\r\n"
               . "Upgrade: websocket\r\nConnection: Upgrade\r\n"
               . "Sec-WebSocket-Accept: $accept\r\n\r\n");

    # ---- frame helpers ----
    my $read_n = sub {
        my ($n) = @_;
        my $buf = '';
        while (length($buf) < $n) {
            my $r = sysread($c, my $b, $n - length($buf));
            return undef unless $r;
            $buf .= $b;
        }
        return $buf;
    };
    my $send_frame = sub {
        my ($op, $pay) = @_;
        my $len = length $pay;
        my $hdr = pack('C', 0x80 | $op);
        if    ($len < 126)   { $hdr .= pack('C', $len) }
        elsif ($len < 65536) { $hdr .= pack('Cn', 126, $len) }
        else { $hdr .= pack('C', 127) . pack('NN', $len >> 32, $len & 0xffffffff) }
        syswrite($c, $hdr . $pay);
    };

    # ---- echo loop ----
    while (1) {
        my $h = $read_n->(2);
        last unless defined $h;
        my ($b0, $b1) = unpack('CC', $h);
        my $op     = $b0 & 0x0f;
        my $masked = $b1 & 0x80;
        my $len    = $b1 & 0x7f;
        if    ($len == 126) { $len = unpack('n', $read_n->(2)) }
        elsif ($len == 127) { my ($hi, $lo) = unpack('NN', $read_n->(8)); $len = $hi * 2**32 + $lo }
        my $mask = $masked ? $read_n->(4) : '';
        my $pay  = $len ? $read_n->($len) : '';
        last if $len && !defined $pay;
        if ($masked) {
            my @m = unpack('C4', $mask);
            my @p = unpack('C*', $pay);
            $p[$_] ^= $m[$_ % 4] for 0 .. $#p;
            $pay = pack('C*', @p);
        }
        last if $op == 0x8;                 # close
        if ($op == 0x9) { $send_frame->(0xA, $pay); next }   # ping -> pong
        $send_frame->($op, $pay);           # echo text/binary
    }
    close $c;
    exit 0;
}
select(undef, undef, undef, 0.3);

plan tests => 7;

my $ua = Fetch->new;
my $ws = $ua->websocket("ws://127.0.0.1:$port/echo")->get;
isa_ok($ws, 'Fetch::WebSocket', 'handshake resolves to a Fetch::WebSocket');

$ws->send('hello');
is($ws->next_message->get, 'hello', 'text message echoed back');

$ws->send('a second, longer message here');
is($ws->next_message->get, 'a second, longer message here',
    'a second message on the same socket');

# a payload over 125 bytes exercises the 16-bit length path
my $big = 'x' x 1000;
$ws->send($big);
is($ws->next_message->get, $big, 'large message (extended length) echoed');

# binary
$ws->send_binary("\x00\x01\x02\xfe\xff");
is($ws->next_message->get, "\x00\x01\x02\xfe\xff", 'binary message echoed');

# on_message callback path: the callback resolves a future we then await, so
# ->get pumps the loop until the echo arrives and the callback fires
{
    my $f = Fetch::Future->new;
    $ws->on_message(sub { $f->done($_[0]) });
    $ws->send('via-callback');
    is($f->get, 'via-callback', 'on_message callback receives the message');
}

$ws->close;
ok($ws->is_closed, 'close shuts the socket down');

END { local $?; if ($pid) { kill 'KILL', $pid; waitpid $pid, 0 } }
