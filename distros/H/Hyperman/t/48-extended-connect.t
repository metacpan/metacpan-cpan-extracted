#!perl
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use HMTest qw(free_ports quiet_child server_reap);
use IO::Socket::INET;
use IO::Select;
use Time::HiRes ();
use Hyperman;

# Extended CONNECT (RFC 8441 on HTTP/2, RFC 9220 on HTTP/3): the handshake a
# WebSocket uses on a multiplexed transport, where there is no 101, no
# Upgrade header, and Connection is forbidden.
#
# What is tested here is the SERVER half of that handshake, which is all
# Hyperman owns: advertise the setting, understand the :protocol
# pseudo-header, dispatch a stream that will never end, and carry bytes in
# BOTH directions over it. The RFC 6455 framing that then runs over the
# stream is Punk's and is untouched by any of this.
#
# The client is written out by hand. Nothing on this machine speaks Extended
# CONNECT - curl's WebSocket support is HTTP/1.1 only and h2load has no
# WebSocket at all - which is one of the reasons this phase was deferred.
# HPACK literals without indexing need no dynamic table, so the frames are
# only tedious, not hard.

plan skip_all => 'nghttp2 support not built' unless Hyperman->has_http2;

my ($port) = free_ports(1);
plan skip_all => 'no free loopback port' unless $port;

my $pid = fork;
die "fork: $!" unless defined $pid;
if ($pid == 0) {
    quiet_child();
    require Hyperman;
    Hyperman->run(
        app => sub {
            my $env = shift;

            # An Extended CONNECT arrives as a normal dispatch carrying
            # psgix.connect_protocol. Everything else about it is ordinary.
            if (($env->{'psgix.connect_protocol'} || '') eq 'websocket') {
                return sub {
                    # Accept with a 200 - not a 101, which does not exist
                    # here - and keep the stream open by answering through
                    # the stream seam rather than returning a body.
                    Hyperman::_abi_stream_open($env, 200,
                        [ 'sec-websocket-protocol' => 'echo' ]) or return;
                    Hyperman::_abi_stream_read();
                    Hyperman::_abi_stream_write("up:$env->{PATH_INFO};");
                };
            }

            if ($env->{PATH_INFO} eq '/rx') {
                my ($n, $len, $bytes) = Hyperman::_abi_stream_rx();
                return [ 200, [ 'Content-Type' => 'text/plain' ],
                         ["n=$n len=$len bytes=$bytes"] ];
            }

            # An ordinary request must be unaffected by any of the above.
            return [ 200, [ 'Content-Type' => 'text/plain' ],
                     [ "plain:$env->{PATH_INFO}:"
                     . (defined $env->{'psgix.connect_protocol'} ? 'set' : 'unset') ] ];
        },
        host    => '127.0.0.1',
        port    => $port,
        workers => 1,
        http2   => 1,
    );
    exit 0;
}

# ---- a minimal HTTP/2 client ---------------------------------------------

sub frame {
    my ($type, $flags, $sid, $pay) = @_;
    my $l = length $pay;
    return pack('CCCCCN', ($l >> 16) & 0xff, ($l >> 8) & 0xff, $l & 0xff,
                $type, $flags, $sid) . $pay;
}

# Literal header field without indexing, new name: no dynamic table, no
# Huffman, so nothing here has to track connection state.
sub lit { my ($n, $v) = @_; "\x00" . chr(length $n) . $n . chr(length $v) . $v }

sub read_frame {
    my ($s, $timeout) = @_;
    my $sel = IO::Select->new($s);
    my $hdr = '';
    while (length($hdr) < 9) {
        return unless $sel->can_read($timeout || 5);
        my $n = sysread($s, my $b, 9 - length $hdr);
        return unless $n;
        $hdr .= $b;
    }
    my ($a, $b2, $c, $type, $flags, $sid) = unpack('CCCCCN', $hdr);
    my $len = ($a << 16) | ($b2 << 8) | $c;
    my $pay = '';
    while (length($pay) < $len) {
        return unless $sel->can_read($timeout || 5);
        my $n = sysread($s, my $x, $len - length $pay);
        return unless $n;
        $pay .= $x;
    }
    return ($type, $flags, $sid & 0x7fffffff, $pay);
}

sub connect_h2 {
    my $s;
    for (1 .. 100) {
        $s = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $port,
                                   Proto => 'tcp');
        last if $s;
        Time::HiRes::sleep(0.05);
    }
    return unless $s;
    syswrite $s, "PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n";
    syswrite $s, frame(0x4, 0, 0, '');          # empty SETTINGS
    return $s;
}

# Plain HTTP/1.1, to read the counters back without disturbing the h2 session.
sub get_h1 {
    my ($path) = @_;
    my $s = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $port,
                                  Proto => 'tcp') or return '';
    syswrite $s, "GET $path HTTP/1.1\r\nHost: 127.0.0.1\r\n"
               . "Connection: close\r\n\r\n";
    my $r = '';
    while (1) { my $n = sysread $s, my $b, 65536; last if !$n; $r .= $b }
    close $s;
    my (undef, $body) = split /\r\n\r\n/, $r, 2;
    return defined $body ? $body : '';
}

# ---- the setting is advertised -------------------------------------------

my $sock = connect_h2();
ok($sock, 'connected and sent the HTTP/2 preface') or do {
    kill 'TERM', $pid; server_reap($pid); done_testing(); exit;
};

my $enable_connect;
for (1 .. 10) {
    my ($type, $flags, $sid, $pay) = read_frame($sock);
    last unless defined $type;
    next unless $type == 0x4 && !($flags & 0x1);     # SETTINGS, not the ACK
    # Each entry is a 2-byte id and a 4-byte value.
    while (length $pay >= 6) {
        my ($id, $val) = unpack('nN', substr($pay, 0, 6, ''));
        $enable_connect = $val if $id == 0x8;        # ENABLE_CONNECT_PROTOCOL
    }
    last;
}
is($enable_connect, 1,
   'the server advertises SETTINGS_ENABLE_CONNECT_PROTOCOL, without which no '
 . 'client will ever attempt a WebSocket over HTTP/2');
syswrite $sock, frame(0x4, 0x1, 0, '');              # our SETTINGS ack

# ---- an Extended CONNECT stream ------------------------------------------

# :method CONNECT with :protocol, and - unlike an ordinary CONNECT - both
# :scheme and :path. No END_STREAM: the stream stays open, which is the
# whole point and the reason it cannot be dispatched on end of stream.
my $hb = lit(':method', 'CONNECT') . lit(':protocol', 'websocket')
       . lit(':scheme', 'http')    . lit(':path', '/chat')
       . lit(':authority', "127.0.0.1:$port");
syswrite $sock, frame(0x1, 0x4, 1, $hb);             # END_HEADERS only

my ($got_status, $got_data);
for (1 .. 20) {
    my ($type, $flags, $sid, $pay) = read_frame($sock);
    last unless defined $type;
    $got_status = 1 if $type == 0x1 && $sid == 1;    # HEADERS: the response
    if ($type == 0x0 && $sid == 1) { $got_data = $pay; last }
}

ok($got_status, 'the server answered the CONNECT stream with HEADERS');
is($got_data, 'up:/chat;',
   'the application was dispatched at end of HEADERS and wrote to the stream '
 . '- a stream with no end would never be dispatched otherwise');

# ---- the read half: bytes flow back up the same stream --------------------

syswrite $sock, frame(0x0, 0, 1, 'ping-from-client');
Time::HiRes::sleep(0.2);

my %rx = get_h1('/rx') =~ /(\w+)=([^\s]*)/g;
cmp_ok($rx{n} || 0, '>', 0,
       'DATA on the CONNECT stream reached the read callback');
is($rx{bytes}, 'ping-from-client',
   '...with the bytes intact, delivered rather than buffered into psgi.input');

# ---- and nothing else changed --------------------------------------------

like(get_h1('/plain'), qr/^plain:\/plain:unset$/,
     'an ordinary request is untouched: no psgix.connect_protocol, and it '
   . 'still dispatches on end of stream');

close $sock;
kill 'TERM', $pid;
server_reap($pid);
done_testing();
