#!perl
use 5.008003;
use strict;
use warnings;
use IO::Socket::INET;
use Test::More;
use Fetch;

# The same WebSocket client, but talking to a real Hyperman server: the PSGI
# app hijacks the connection via psgix.io (a dup of the client socket), answers
# the 101 handshake and echoes frames. Nice client/server symmetry across the
# Semantic stack. Skips unless Hyperman and the core digest modules are present.

plan skip_all => 'Hyperman not installed'
    unless eval { require Hyperman; 1 };
plan skip_all => 'Digest::SHA needed'   unless eval { require Digest::SHA; 1 };
plan skip_all => 'MIME::Base64 needed'  unless eval { require MIME::Base64; 1 };
Digest::SHA->import('sha1');
MIME::Base64->import('encode_base64');

my $probe = IO::Socket::INET->new(LocalHost => '127.0.0.1', LocalPort => 0,
    Listen => 1, ReuseAddr => 1) or plan skip_all => "cannot pick a port: $!";
my $port = $probe->sockport;
close $probe;

my $pid = fork;
plan skip_all => "cannot fork: $!" unless defined $pid;
if (!$pid) {
    open STDERR, '>', '/dev/null';
    Hyperman->run(
        host => '127.0.0.1', port => $port, workers => 1,
        app => sub {
            my $env = shift;
            my $key = $env->{HTTP_SEC_WEBSOCKET_KEY};
            return [ 400, [ 'Content-Type' => 'text/plain' ], [ 'not ws' ] ]
                unless $key;
            my $io = $env->{'psgix.io'};
            $io->blocking(1);   # dup shares Hyperman's non-blocking flag; the
                                # hijacked session reads/writes blocking
            my $accept = encode_base64(
                sha1($key . '258EAFA5-E914-47DA-95CA-C5AB0DC85B11'), '');
            syswrite($io, "HTTP/1.1 101 Switching Protocols\r\n"
                        . "Upgrade: websocket\r\nConnection: Upgrade\r\n"
                        . "Sec-WebSocket-Accept: $accept\r\n\r\n");

            my $read_n = sub {
                my ($n) = @_;
                my $buf = '';
                while (length($buf) < $n) {
                    my $r = sysread($io, my $b, $n - length($buf));
                    return undef unless $r;
                    $buf .= $b;
                }
                return $buf;
            };
            my $send = sub {
                my ($op, $pay) = @_;
                my $len = length $pay;
                my $hdr = pack('C', 0x80 | $op);
                if    ($len < 126)   { $hdr .= pack('C', $len) }
                elsif ($len < 65536) { $hdr .= pack('Cn', 126, $len) }
                else { $hdr .= pack('C', 127) . pack('NN', $len >> 32, $len & 0xffffffff) }
                syswrite($io, $hdr . $pay);
            };

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
                last if $op == 0x8;
                if ($op == 0x9) { $send->(0xA, $pay); next }
                $send->($op, $pay);
            }
            close $io;
            return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'done' ] ];
        },
    );
    exit 0;
}

# wait for the listener
my $up;
for (1 .. 50) {
    select(undef, undef, undef, 0.1);
    my $s = IO::Socket::INET->new(PeerHost => '127.0.0.1', PeerPort => $port);
    if ($s) { close $s; $up = 1; last }
}
unless ($up) { kill 'TERM', $pid; waitpid $pid, 0;
    plan skip_all => 'Hyperman server did not start' }

plan tests => 4;

my $ua = Fetch->new;
my $ws = $ua->websocket("ws://127.0.0.1:$port/echo")->get;
isa_ok($ws, 'Fetch::WebSocket', 'handshake against Hyperman resolves');

$ws->send('hello hyperman');
is($ws->next_message->get, 'hello hyperman', 'text echoed by Hyperman app');

my $big = 'z' x 2000;
$ws->send($big);
is($ws->next_message->get, $big, 'large message echoed');

$ws->send_binary("\x00\xff\x10");
is($ws->next_message->get, "\x00\xff\x10", 'binary echoed');

$ws->close;

END { local $?; if ($pid) { kill 'TERM', $pid; waitpid $pid, 0 } }
