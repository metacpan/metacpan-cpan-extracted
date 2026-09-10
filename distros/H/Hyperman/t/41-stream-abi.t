#!perl
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use HMTest qw(free_ports quiet_child server_reap);
use IO::Socket::INET;
use Socket qw(PF_INET SOCK_STREAM SOL_SOCKET SO_RCVBUF
              inet_aton pack_sockaddr_in);
use Time::HiRes ();
use Errno ();
use Hyperman;

# ABI v6 stream handles (include/hyperman/hm_abi.h, include/hyperman/hm_stream.h).
#
# The claim being tested is that ONE C seam writes a streaming body over
# HTTP/1.1 and over HTTP/2 without the caller naming the transport. So the
# application below never branches on the protocol: every path calls the same
# four table entries, and the test drives it once over each.
#
# Everything C-side goes through Hyperman::_abi_stream_* (xs/abi.xs), which
# resolves the function-pointer table and calls through it. A Perl test cannot
# register a C callback, so the abort and drain callbacks report into counters
# that a LATER request reads back out - the same shape t/33-worker-start.t
# uses for on_worker_start.

my ($port) = free_ports(1);
plan skip_all => "no free loopback port" unless $port;

my $h2 = Hyperman->has_http2 ? 1 : 0;

my $pid = fork;
die "fork: $!" unless defined $pid;
if ($pid == 0) {
    quiet_child();
    require Hyperman;
    Hyperman->run(
        app => sub {
            my $env = shift;
            my $p   = $env->{PATH_INFO};

            # The C seam, from a deferred response. The responder handed in
            # here is deliberately ignored: the point is that the body is
            # produced by the ABI and not by psgi.streaming.
            if ($p eq '/c-stream') {
                return sub {
                    Hyperman::_abi_stream_open($env, 200,
                        [ 'Content-Type' => 'text/plain' ]) or return;
                    Hyperman::_abi_stream_write("chunk$_;") for 1 .. 3;
                    Hyperman::_abi_stream_close();
                };
            }

            # Open, write once, and leave it open. Whatever kills the stream
            # next - the client hanging up, an h2 RST_STREAM - is what the
            # abort callback is there to catch.
            if ($p eq '/c-stream-hold') {
                return sub {
                    Hyperman::_abi_stream_open($env, 200,
                        [ 'Content-Type' => 'text/plain' ]) or return;
                    Hyperman::_abi_stream_write("hold;");
                };
            }

            # A producer that fails part way. The body it managed is not a
            # whole response, and a clean close would present it as one - so
            # this ends the other way, and the point of the test is that the
            # client can tell the difference.
            if ($p eq '/c-stream-abort') {
                return sub {
                    Hyperman::_abi_stream_open($env, 200,
                        [ 'Content-Type' => 'text/plain' ]) or return;
                    Hyperman::_abi_stream_write("partial;");
                    Hyperman::_abi_stream_abort();
                };
            }

            # 2048 chunks of 4KiB. Far more than the high-water mark, so the
            # producer is told to stop and has to resume from on_drain - and
            # more than a Linux send buffer autotunes to, so the kernel cannot
            # take the whole body and leave nothing to pause on.
            if ($p eq '/c-stream-big') {
                return sub {
                    Hyperman::_abi_stream_open($env, 200,
                        [ 'Content-Type' => 'text/plain' ]) or return;
                    Hyperman::_abi_stream_produce(2048);
                };
            }

            # The Perl door onto the same registry.
            if ($p eq '/perl-stream') {
                return sub {
                    my $w = Hyperman::stream($env, 200,
                                [ 'Content-Type' => 'text/plain' ]);
                    $w->write("perl1;");
                    $w->write("perl2");
                    $w->close;
                };
            }

            # Calling the Perl door from a synchronous handler is refused,
            # because the handler's return value is still coming and would be
            # written on top of the body.
            if ($p eq '/perl-stream-sync') {
                my $err = '';
                eval { Hyperman::stream($env, 200, []); 1 } or $err = "$@";
                $err =~ s/\s+\z//;
                return [ 200, [ 'Content-Type' => 'text/plain' ], [$err] ];
            }

            # Write and close a handle whose stream died: an error return,
            # not a crash.
            if ($p eq '/late') {
                my $w = Hyperman::_abi_stream_write("late");
                my $c = Hyperman::_abi_stream_close();
                return [ 200, [ 'Content-Type' => 'text/plain' ],
                         ["write=$w close=$c"] ];
            }

            if ($p eq '/state') {
                my @s = Hyperman::_abi_stream_state();
                return [ 200, [ 'Content-Type' => 'text/plain' ],
                         [ "open=$s[0] aborts=$s[1] drains=$s[2] "
                         . "writes=$s[3] fulls=$s[4]" ] ];
            }

            return [ 200, [ 'Content-Type' => 'text/plain' ], ["ok:$p"] ];
        },
        host    => '127.0.0.1',
        port    => $port,
        workers => 1,
        ($h2 ? (http2 => 1) : ()),
    );
    exit 0;
}

# ---- HTTP/1.1 helpers -----------------------------------------------------

sub connect_h1 {
    my $s;
    for (1 .. 100) {
        $s = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $port,
                                   Proto => 'tcp');
        last if $s;
        Time::HiRes::sleep(0.05);
    }
    return $s;
}

# Send one request and read to EOF. The streamed responses here are
# EOF-delimited (Connection: close), which is what hm_start_stream does.
sub get_h1 {
    my ($path) = @_;
    my $s = connect_h1() or return;
    syswrite $s, "GET $path HTTP/1.1\r\nHost: 127.0.0.1\r\n"
               . "Connection: close\r\n\r\n";
    my $resp = '';
    while (1) {
        my $n = sysread $s, my $buf, 65536;
        last if !defined $n || $n == 0;
        $resp .= $buf;
    }
    close $s;
    my ($head, $body) = split /\r\n\r\n/, $resp, 2;
    return ($head, defined $body ? $body : '');
}

sub body_h1 { my (undef, $b) = get_h1(@_); return $b }

# A client whose receive buffer is set SMALL, before connect so the window
# scale is negotiated from it. Returns the socket and the buffer size the
# kernel settled on. See the backpressure block below for why the size of the
# client's window is what decides whether that test tests anything.
sub connect_h1_window {
    my ($want) = @_;
    my $addr = pack_sockaddr_in($port, inet_aton('127.0.0.1'));
    for (1 .. 100) {
        socket(my $s, PF_INET, SOCK_STREAM, 0) or return;
        setsockopt($s, SOL_SOCKET, SO_RCVBUF, pack('i', $want));
        my $got = getsockopt($s, SOL_SOCKET, SO_RCVBUF);
        $got = defined $got ? unpack('i', $got) : $want;
        return ($s, $got) if connect($s, $addr);
        close $s;
        Time::HiRes::sleep(0.05);
    }
    return;
}

# ---- HTTP/1.1: the same seam, one transport -------------------------------

my ($head, $body) = get_h1('/c-stream');
like($head || '', qr{^HTTP/1\.1 200 }, 'HTTP/1.1: the C seam sent a 200');
like($head || '', qr{Content-Type: text/plain}i,
     'HTTP/1.1: the headers it was given went out');
is($body, 'chunk1;chunk2;chunk3;',
   'HTTP/1.1: three stream_write calls, in order, then stream_close');

is(body_h1('/perl-stream'), 'perl1;perl2',
   'HTTP/1.1: the Perl door writes the same body through the same registry');

like(body_h1('/perl-stream-sync'), qr/has not deferred/,
     'a synchronous handler is refused rather than corrupting its response');

my %st;
sub state_now {
    my $b = body_h1('/state') || '';
    %st = $b =~ /(\w+)=(-?\d+)/g;
    return \%st;
}

state_now();
is($st{open},   0, 'no handle is left open after a clean close');
is($st{aborts}, 0, 'a clean close does not report an abort');

# ---- abort on HTTP/1.1: a reset, because a clean close cannot say it ------
#
# The body is EOF-delimited, so the graceful close IS the success signal and
# there is nothing else in the protocol left to say. A TCP reset is the only
# thing a client can tell apart from it, which is why stream_abort sends one.
{
    my $s = connect_h1();
    SKIP: {
        skip 'no connection', 2 unless $s;
        syswrite $s, "GET /c-stream-abort HTTP/1.1\r\nHost: 127.0.0.1\r\n"
                   . "Connection: close\r\n\r\n";
        my ($resp, $reset) = ('', 0);
        while (1) {
            my $n = sysread $s, my $buf, 4096;
            if (!defined $n) {
                $reset = 1 if $!{ECONNRESET};
                last;
            }
            last if $n == 0;
            $resp .= $buf;
        }
        close $s;
        ok($reset, 'HTTP/1.1: an aborted body ends in a reset, not a clean EOF')
            or diag("ended cleanly with " . length($resp) . " bytes");

        state_now();
        is($st{open}, 0, '...and the handle is released, as close releases it');
    }
}

# ---- backpressure: the producer is stopped and resumed --------------------
#
# The pause is reached when the server is holding more than
# HM_ABI_STREAM_HIWAT (256KiB) that the kernel would not take, so the body has
# to outrun every buffer between the two processes - and not reading is not
# enough on its own. Linux autotunes a loopback send buffer up to
# tcp_wmem[2], 4MiB by default, which swallows this 2MiB body whole: every
# write succeeds, the producer runs straight through and `fulls` reads 0
# forever (CPAN Testers, Hyperman 0.44, perl 5.32.1 on Debian). macOS caps
# sendspace at 128KiB and does not autotune, which is why the same test always
# paused here.
#
# Guessing a body size big enough for any tuning is the wrong end of it: the
# client instead shrinks its OWN receive buffer before connecting, which caps
# the window the server's send buffer can autotune against and puts the pause
# a few tens of KiB into the body on every platform.
{
    my ($s, $rcvbuf) = connect_h1_window(8192);
    SKIP: {
        skip 'no connection', 3 unless $s;
        syswrite $s, "GET /c-stream-big HTTP/1.1\r\nHost: 127.0.0.1\r\n"
                   . "Connection: close\r\n\r\n";
        # Do not read yet - a client that drains as fast as the server writes
        # never fills anything. Waiting for the server to say it is full,
        # rather than sleeping for a guessed interval, is what makes this hold
        # on a loaded smoker too.
        for (1 .. 250) {
            state_now();
            last if $st{fulls} > 0;
            Time::HiRes::sleep(0.02);
        }
        # Nothing was refused. On a kernel that ignored SO_RCVBUF the body can
        # still fit in the buffers, and there is then no backpressure here to
        # observe - report that, rather than failing the server for it.
        if ($st{fulls} == 0 && $rcvbuf > 2048 * 4096) {
            close $s;
            skip "the whole body fits in the socket buffers "
               . "(SO_RCVBUF=$rcvbuf)", 3;
        }

        cmp_ok($st{fulls}, '>', 0,
               'stream_write reported the connection full at least once');

        my $resp = '';
        while (1) {
            my $n = sysread $s, my $buf, 8192;
            last if !defined $n || $n == 0;
            $resp .= $buf;
        }
        close $s;
        my (undef, $b) = split /\r\n\r\n/, $resp, 2;
        is(length($b || ''), 2048 * 4096,
           'the whole body arrived across the pause and resume');

        state_now();
        cmp_ok($st{drains}, '>', 0,
               'and stream_on_drain fired to restart the producer');
    }
}

# ---- abort on HTTP/1.1: the client hangs up mid-body ----------------------

{
    my $s = connect_h1();
    SKIP: {
        skip 'no connection', 3 unless $s;
        syswrite $s, "GET /c-stream-hold HTTP/1.1\r\nHost: 127.0.0.1\r\n"
                   . "Connection: close\r\n\r\n";
        my $got = '';
        for (1 .. 200) {
            my $n = sysread $s, my $buf, 4096;
            last if !defined $n || $n == 0;
            $got .= $buf;
            last if $got =~ /hold;/;
        }
        like($got, qr/hold;/, 'the held stream sent its first chunk');
        close $s;                      # the peer goes away mid-body

        my $aborts = $st{aborts};
        for (1 .. 100) {
            state_now();
            last if $st{aborts} > $aborts;
            Time::HiRes::sleep(0.02);
        }
        is($st{aborts}, $aborts + 1,
           'stream_on_abort fired when the connection died under the stream');
        is($st{open}, 1,
           'the handle itself survives the abort - only stream_close frees it');

        is(body_h1('/late'), 'write=-2 close=-2',
           'a write to a dead stream is an error return, and close still '
         . 'releases the handle');
    }
}

# ---- HTTP/2: the same application code, a multiplexed transport -----------

SKIP: {
    skip 'nghttp2 support not built', 3 unless $h2;

    my $curl = `which curl 2>/dev/null`;
    chomp $curl;
    SKIP: {
        skip 'no HTTP/2-capable curl', 1
            unless $curl && `curl --version 2>/dev/null` =~ /\bHTTP2\b/;
        my $out = `$curl -s --http2-prior-knowledge http://127.0.0.1:$port/c-stream 2>/dev/null`;
        is($out, 'chunk1;chunk2;chunk3;',
           'HTTP/2: the same seam, the same body, no branch in the app');
    }

    # An h2 peer can reset ONE stream out of many, which HTTP/1.1 has no
    # analogue for and is the reason stream_on_abort exists. Nothing on this
    # machine sends a RST_STREAM on demand, so the frames are written by
    # hand: HPACK literals without indexing need no dynamic table, and the
    # response only has to be recognised as DATA, not decoded.
    my $frame = sub {
        my ($type, $flags, $sid, $pay) = @_;
        my $l = length $pay;
        return pack('CCCCCN', ($l >> 16) & 0xff, ($l >> 8) & 0xff, $l & 0xff,
                    $type, $flags, $sid) . $pay;
    };
    my $lit = sub {
        my ($n, $v) = @_;
        return "\x00" . chr(length $n) . $n . chr(length $v) . $v;
    };
    my $read_frame = sub {
        my ($s) = @_;
        my $hdr = '';
        while (length($hdr) < 9) {
            my $n = sysread($s, my $b, 9 - length $hdr);
            return unless $n;
            $hdr .= $b;
        }
        my ($a, $b2, $c, $type, $flags, $sid) = unpack('CCCCCN', $hdr);
        my $len = ($a << 16) | ($b2 << 8) | $c;
        my $pay = '';
        while (length($pay) < $len) {
            my $n = sysread($s, my $x, $len - length $pay);
            return unless $n;
            $pay .= $x;
        }
        return ($type, $flags, $sid & 0x7fffffff, $pay);
    };

    my $s = connect_h1();
    SKIP: {
        skip 'no connection', 2 unless $s;
        state_now();
        my $aborts = $st{aborts};

        syswrite $s, "PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n";
        syswrite $s, $frame->(0x4, 0, 0, '');            # empty SETTINGS
        my $hb = $lit->(':method', 'GET') . $lit->(':scheme', 'http')
               . $lit->(':path', '/c-stream-hold')
               . $lit->(':authority', "127.0.0.1:$port");
        syswrite $s, $frame->(0x1, 0x5, 1, $hb);         # END_STREAM|END_HEADERS

        my $data = '';
        my $ok = eval {
            local $SIG{ALRM} = sub { die "timeout\n" };
            alarm 10;
            while (1) {
                my ($type, undef, $sid, $pay) = $read_frame->($s);
                last unless defined $type;
                if ($type == 0x4 && $pay eq '') {        # SETTINGS: ack it
                    syswrite $s, $frame->(0x4, 0x1, 0, '');
                }
                if ($type == 0x0 && $sid == 1) { $data .= $pay; last if length $data }
            }
            alarm 0;
            1;
        };
        alarm 0;

        is($data, 'hold;',
           'HTTP/2: the held stream sent its chunk as a DATA frame')
            or diag($ok ? "read stopped early" : "raw h2 client: $@");

        # RST_STREAM(CANCEL) on stream 1 only - the connection stays up.
        syswrite $s, $frame->(0x3, 0, 1, pack('N', 8));

        for (1 .. 100) {
            state_now();
            last if $st{aborts} > $aborts;
            Time::HiRes::sleep(0.02);
        }
        is($st{aborts}, $aborts + 1,
           'stream_on_abort fired on an h2 RST_STREAM, with the connection '
         . 'still open');
        close $s;

        is(body_h1('/late'), 'write=-2 close=-2',
           'HTTP/2: a write to the reset stream is an error return');
    }

    # ---- the abort, the other way round --------------------------------
    #
    # Above, the peer reset the stream and the server heard it. Here the
    # SERVER aborts, and the peer has to hear that - which on a multiplexed
    # transport it cannot infer, because the connection is still carrying
    # other streams and never closes. RST_STREAM is the whole point of the
    # entry: it says "this response is not to be trusted" about one stream
    # and leaves the rest alone.
    my $s2 = connect_h1();
    SKIP: {
        skip 'no connection', 2 unless $s2;
        syswrite $s2, "PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n";
        syswrite $s2, $frame->(0x4, 0, 0, '');
        my $hb = $lit->(':method', 'GET') . $lit->(':scheme', 'http')
               . $lit->(':path', '/c-stream-abort')
               . $lit->(':authority', "127.0.0.1:$port");
        syswrite $s2, $frame->(0x1, 0x5, 1, $hb);

        my ($data, $rst, $end) = ('', undef, 0);
        eval {
            local $SIG{ALRM} = sub { die "timeout\n" };
            alarm 10;
            while (1) {
                my ($type, $flags, $sid, $pay) = $read_frame->($s2);
                last unless defined $type;
                if ($type == 0x4 && $pay eq '') {
                    syswrite $s2, $frame->(0x4, 0x1, 0, '');
                }
                if ($type == 0x0 && $sid == 1) {
                    $data .= $pay;
                    $end = 1 if $flags & 0x1;      # END_STREAM: a clean end
                }
                if ($type == 0x3 && $sid == 1) {   # RST_STREAM
                    $rst = unpack 'N', $pay;
                    last;
                }
            }
            alarm 0;
            1;
        };
        alarm 0;
        close $s2;

        ok(defined $rst,
           'HTTP/2: an aborted stream is reset, so the client knows the body '
         . 'is incomplete')
            or diag("no RST_STREAM; got " . length($data) . " body bytes"
                  . ($end ? " and a clean END_STREAM" : ""));
        ok(!$end, '...and never sees the END_STREAM that would call it whole');
    }
}

kill 'TERM', $pid;
server_reap($pid);
done_testing();
