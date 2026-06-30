use strict;
use warnings;
use Test::More;
use POSIX ();
use IO::Select;
use IO::Socket::INET;
use Digest::SHA qw(sha1);
use MIME::Base64 qw(encode_base64);
use EV;
use EV::Websockets;

use if -d 'blib', lib => 'blib/lib', 'blib/arch';

EV::Websockets::_set_debug(1) if $ENV{EV_WS_DEBUG};

# Regression: a permessage-deflate message whose INFLATED size exceeds lws's
# inflate buffer is delivered to lws's receive callback in several chunks, each
# reporting lws_is_final_fragment() == 1. The binding must reassemble these into
# a single on_message, not emit each chunk as its own (which silently corrupts
# any per-message parser -- the original bug seen against compressed feeds).
#
# We stand up a minimal raw-socket server that negotiates permessage-deflate and
# sends ONE compressed text frame carrying a >1KB payload, then connect with the
# module's client (which offers permessage-deflate) and require exactly one
# on_message equal to the original payload.

eval { require Compress::Raw::Zlib; Compress::Raw::Zlib->import(qw(Z_SYNC_FLUSH)); 1 }
    or plan skip_all => "Compress::Raw::Zlib unavailable";

# A compressible, verifiable payload far larger than any plausible inflate
# buffer, so lws is guaranteed to inflate it in multiple chunks (the condition
# that triggers the bug) regardless of lws's rx_buf_size.
my $payload = join('', map { sprintf("item-%06d;", $_) } 1 .. 6000); # ~78 KB

pipe(my $r, my $w) or plan skip_all => "pipe: $!";
my $pid = fork;
plan skip_all => "fork unavailable: $!" unless defined $pid;

if (!$pid) {
    # ---- child: raw permessage-deflate WebSocket server ----
    close $r;
    my $srv = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 1, ReuseAddr => 1,
    ) or POSIX::_exit(1);
    syswrite($w, $srv->sockport . "\n");
    close $w;

    my $cli = $srv->accept or POSIX::_exit(1);

    # Read the HTTP upgrade request and complete the handshake, accepting pmd.
    my $req = '';
    while ($req !~ /\r\n\r\n/) { sysread($cli, my $b, 4096) or POSIX::_exit(1); $req .= $b; }
    my ($key) = $req =~ /Sec-WebSocket-Key:\s*(\S+)/i;
    my $accept = encode_base64(sha1(($key // '') . '258EAFA5-E914-47DA-95CA-C5AB0DC85B11'), '');
    syswrite($cli,
        "HTTP/1.1 101 Switching Protocols\r\n"
      . "Upgrade: websocket\r\nConnection: Upgrade\r\n"
      . "Sec-WebSocket-Accept: $accept\r\n"
      . "Sec-WebSocket-Extensions: permessage-deflate\r\n\r\n");

    # Raw-deflate the payload, then drop the trailing empty-block marker
    # (00 00 FF FF) as RFC 7692 requires for a compressed message.
    my ($d) = Compress::Raw::Zlib::Deflate->new(WindowBits => -15, AppendOutput => 1);
    my $comp = '';
    $d->deflate($payload, $comp);
    $d->flush($comp, Z_SYNC_FLUSH());
    $comp =~ s/\x00\x00\xff\xff\z//;

    # One server->client frame: FIN=1, RSV1=1 (compressed), opcode=text(0x1); unmasked.
    my $len = length $comp;
    my $frame = chr(0xC1);
    if    ($len < 126)   { $frame .= chr($len) }
    elsif ($len < 65536) { $frame .= chr(126) . pack('n', $len) }
    else                 { $frame .= chr(127) . pack('Q>', $len) }
    $frame .= $comp;
    syswrite($cli, $frame);

    # Stay up briefly so the client can read+inflate before we close.
    select undef, undef, undef, 2;
    POSIX::_exit(0);
}

# ---- parent: the module's client ----
close $w;
my $port;
{
    my $line = '';
    IO::Select->new($r)->can_read(5) and sysread($r, $line, 64);
    ($port) = $line =~ /(\d+)/;
}
close $r;
unless ($port) { kill 'KILL', $pid; waitpid $pid, 0; plan skip_all => "server did not start" }

my $ctx = EV::Websockets::Context->new();
my @msgs;
my $err;
my $conn = $ctx->connect(
    url              => "ws://127.0.0.1:$port",
    max_message_size => 1_048_576,
    on_message       => sub { push @msgs, $_[1]; EV::break },
    on_error         => sub { $err = $_[1]; EV::break },
);
my $watchdog = EV::timer(8, 0, sub { EV::break });
EV::run;

kill 'KILL', $pid;
waitpid $pid, 0;

SKIP: {
    skip "connection/handshake failed: $err", 3 if defined $err;
    is(scalar(@msgs), 1, "compressed message delivered as exactly one on_message")
        or diag "got " . scalar(@msgs) . " callbacks (lengths: "
              . join(',', map length, @msgs) . ") -- pre-fix this fragmented";
    is(length($msgs[0] // ''), length($payload), "reassembled length matches original")
        if @msgs;
    is($msgs[0] // '', $payload, "reassembled content matches original")
        if @msgs;
}

done_testing;

POSIX::_exit(Test::More->builder->is_passing ? 0 : 1);
