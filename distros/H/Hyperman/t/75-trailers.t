#!perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use HMTest qw(free_ports quiet_child server_guard server_status server_reap);
use IO::Socket::INET;
use Time::HiRes ();
use File::Temp ();
use Hyperman;

# Trailer fields: sent after a body by ->close(\@trailers) and by the ABI's
# stream_close_trailers (v10). On HTTP/2 they always go. On HTTP/1.1 they go
# when the body is chunked and the request's TE asked for them.
#
# The customer is gRPC, whose call status is a trailer (grpc-status,
# grpc-message) under an HTTP 200 that says nothing about the outcome. No
# trailers, no gRPC.
#
# Three things are checked, in increasing dependence on the environment:
#
#   1. the list rules, without a server. ->close judges the list before it
#      considers the transport, so every writer shape refuses the same way,
#      and HTTP/3 refuses a usable list outright for want of support
#   2. the frames, with a bare HTTP/2 client written here. What makes a
#      trailer a trailer is framing: the last DATA frame must not carry
#      END_STREAM, and a second HEADERS frame must. That is checked without
#      decoding HPACK
#   3. the field contents, when nghttp(1) is installed. It decodes HPACK,
#      which no test should reimplement, and lists every header it decoded.
#      curl is no use here, since it does not report HTTP/2 trailers

# ---- 1. the list rules, no server -----------------------------------------------
#
# A writer is a blessed arrayref whose shape says which transport it is for.
# One assembled by hand points at no live connection, so a sound list is
# quietly discarded. The test is that an unsound one croaks, names the
# problem, and frees what it built.
{
    my $h2 = sub { bless [ -1, 0, 1, 'h2' ], 'Hyperman::Writer' };
    my @bad = (
        [ 'not-a-ref',              qr/must be an array reference/, 'a plain string' ],
        [ { 'grpc-status' => 0 },   qr/must be an array reference/, 'a hash reference' ],
        [ [ 'grpc-status' ],        qr/odd number of elements/,     'an odd-length list' ],
        [ [ '' => 1 ],              qr/name is empty/,              'an empty name' ],
        [ [ undef, 1 ],             qr/name is empty/,              'an undefined name' ],
        [ [ 'bad name' => 1 ],      qr/'bad name' is not a valid field name/, 'a space in a name' ],
        [ [ ':status' => 200 ],     qr/':status' is not a valid field name/,  'a pseudo-header' ],
        [ [ "x\r\nInjected" => 1 ], qr/not a valid field name/,     'CR LF in a name' ],
        [ [ 'x-a' => undef ],       qr/'x-a' has an undefined value/, 'an undefined value' ],
        [ [ 'x-a' => "a\r\nb: c" ], qr/'x-a' has a control character/, 'CR LF in a value' ],
        [ [ 'x-a' => "a\0b" ],      qr/control character/,          'NUL in a value' ],
        [ [ 'x-a' => "a\x7fb" ],    qr/control character/,          'DEL in a value' ],
        [ [ 'ok' => 1, 'x y' => 2 ], qr/'x y' is not a valid/,      'a bad name after a good one' ],
    );
    for my $case (@bad) {
        my ($t, $re, $what) = @$case;
        my $ok = eval { $h2->()->close($t); 1 };
        my $err = $@;
        ok(!$ok, "refused: $what");
        like($err, qr/^Hyperman::Writer::close: /, '  named as a close refusal');
        like($err, $re, '  and says why');
    }

    ok(eval { $h2->()->close(['x-tab' => "a\tb"]); 1 },
       'a tab inside a value is allowed') or diag $@;
    ok(eval { $h2->()->close(undef); 1 }, 'close(undef) is a plain close');
    ok(eval { $h2->()->close([]); 1 },    'close([]) is a plain close');
    ok(eval { $h2->()->close(['Connection' => 'x', 'TE' => 'trailers']); 1 },
       'a list of only dropped names is a plain close');

    # no live handle behind either of these: the list must still be released
    ok(eval { bless([ 0, 0, 'stream' ], 'Hyperman::Writer')->close(['a' => 1]); 1 },
       'a closed stream-handle writer takes a list quietly');
    ok(eval { bless([ 123456, 9, 'stream' ], 'Hyperman::Writer')->close(['a' => 1]); 1 },
       'so does one naming a handle that is not live');
    ok(eval { bless([ -1, 0, 0, 'h1' ], 'Hyperman::Writer')->close(['a' => 1]); 1 },
       'and an HTTP/1.1 writer with no connection');

    my $ok = eval { bless([ -1, 0, 0, 'h3' ], 'Hyperman::Writer')->close(['grpc-status' => 0]); 1 };
    ok(!$ok, 'an HTTP/3 writer refuses trailers');
    like($@, qr/trailers are not implemented over HTTP\/3/, '  as not implemented');
    ok(eval { bless([ -1, 0, 0, 'h3' ], 'Hyperman::Writer')->close(undef); 1 },
       '  but still closes without them');
    ok(eval { bless([ -1, 0, 0, 'h3' ], 'Hyperman::Writer')->close([ 'Connection' => 'close' ]); 1 },
       '  and a list with nothing left to send after the dropped names is a plain close there too');
}

# ---- the server ----------------------------------------------------------------

SKIP: {
skip 'HTTP/2 support not built', 1 unless Hyperman->has_http2;
skip 'fork is not Windows', 1 if $^O eq 'MSWin32';

my ($pa, $pb) = free_ports(2);
skip 'no free loopback ports', 1 unless $pa && $pb;
my $dir = File::Temp::tempdir(CLEANUP => 1);

# TLS beside cleartext when it can be had: ALPN h2 is the same stream code
# with a different socket underneath, and it is the path a browser takes.
my ($cert, $key) = ("$dir/cert.pem", "$dir/key.pem");
my $tls = 0;
if (Hyperman->has_tls && `which openssl 2>/dev/null` =~ /\S/) {
    system(qq{openssl req -x509 -newkey rsa:2048 -nodes -keyout "$key" }
         . qq{-out "$cert" -days 1 -subj "/CN=localhost" >/dev/null 2>&1});
    $tls = -s $cert && -s $key;
}

my %keep;               # writers whose body finishes after the handler returns
my $big = 'B' x (200 * 1024);    # past the 64KB initial flow-control window

my $app = sub {
    my $env = shift;
    my $p = $env->{PATH_INFO};
    my $loop = $env->{'psgix.loop'};
    my @grpc = ('grpc-status' => 0, 'grpc-message' => 'ok');
    my $ct = [ 'Content-Type' => 'application/grpc' ];

    # the psgi.streaming writer (HTTP/2 form: buffered, submitted at close)
    if ($p eq '/writer') {
        return sub {
            my $w = $_[0]->([ 200, $ct ]);
            $w->write('hello ');
            $w->write('world');
            $w->close([ 'Grpc-Status' => 0, 'grpc-message' => "  all good\t",
                        'Content-Length' => 99, 'Connection' => 'close',
                        'TE' => 'trailers', 'Transfer-Encoding' => 'chunked',
                        'Trailer' => 'x', 'Host' => 'evil', 'Proxy-Connection' => 'close',
                        'X-Tab' => "a\tb" ]);
        };
    }
    if ($p eq '/writer-empty')   { return sub { $_[0]->([ 200, $ct ])->close([@grpc]) } }
    if ($p eq '/writer-big')     { return sub { my $w = $_[0]->([ 200, $ct ]); $w->write($big); $w->close([@grpc]) } }
    if ($p eq '/writer-none')    { return sub { my $w = $_[0]->([ 200, $ct ]); $w->write('plain'); $w->close } }
    if ($p eq '/writer-dropped') { return sub { my $w = $_[0]->([ 200, $ct ]); $w->write('plain'); $w->close([ 'Connection' => 'x' ]) } }
    if ($p eq '/writer-twice') {
        return sub {
            my $w = $_[0]->([ 200, $ct ]);
            $w->write('once');
            $w->close([ 'x-first' => 1 ]);
            $w->close([ 'x-second' => 2 ]);      # a no-op: the body has ended
        };
    }
    if ($p eq '/writer-refused') {
        # a refused list leaves the writer OPEN: the application can still end
        # the body properly, which is the point of refusing before sending
        return sub {
            my $w = $_[0]->([ 200, $ct ]);
            $w->write('recovered');
            my $err = eval { $w->close([ 'bad name' => 1 ]); 'none' } // $@;
            $w->close([ 'x-refused' => ($err =~ /not a valid field name/ ? 'yes' : 'no') ]);
        };
    }
    if ($p eq '/writer-later') {
        return sub {
            my $w = $_[0]->([ 200, $ct ]);
            $w->write('later ');
            $keep{$p} = $w;
            $loop->timer(0.1, sub { $w->write('still'); $w->close([@grpc]); delete $keep{$p} });
        };
    }

    # the transport-neutral stream handle (a live producer on HTTP/2)
    if ($p eq '/stream') {
        return sub {
            my $w = Hyperman::stream($env, 200, $ct);
            $w->write('streamed ');
            $w->write('body');
            $w->close([ 'grpc-status' => 14, 'grpc-message' => 'try later' ]);
        };
    }
    if ($p eq '/stream-empty') { return sub { Hyperman::stream($env, 200, $ct)->close([@grpc]) } }
    if ($p eq '/stream-big') {
        return sub {
            my $w = Hyperman::stream($env, 200, $ct);
            $w->write('s' x 16384) for 1 .. 40;    # 640KB, in pieces
            $w->close([@grpc]);
        };
    }
    if ($p eq '/stream-later') {
        # the provider has run dry and DEFERRED by the time the trailers come:
        # the close has to wake it so it can reach EOF and send them
        return sub {
            my $w = Hyperman::stream($env, 200, $ct);
            $w->write('first ');
            $keep{$p} = $w;
            $loop->timer(0.1, sub { $w->write('second'); $w->close([@grpc]); delete $keep{$p} });
        };
    }
    if ($p eq '/stream-none') { return sub { my $w = Hyperman::stream($env, 200, $ct); $w->write('plain'); $w->close } }

    # the client is gone before the body ends: nothing to send, nothing leaked
    if ($p eq '/gone-writer') {
        return sub {
            my $w = $_[0]->([ 200, $ct ]);
            $keep{$p} = $w;
            $loop->timer(0.6, sub { $w->close([@grpc]); delete $keep{$p} });
        };
    }
    if ($p eq '/gone-stream') {
        return sub {
            my $w = Hyperman::stream($env, 200, $ct);
            $w->write('partial');
            $keep{$p} = $w;
            $loop->timer(0.6, sub { $w->close([@grpc]); delete $keep{$p} });
        };
    }

    if ($p eq '/flag') { return [ 200, [], [ $env->{'psgix.hyperman.trailers'} // 'absent' ] ] }

    # HTTP/1.1 specifics
    if ($p eq '/counted') {
        # a body with its own Content-Length has nowhere to put trailers
        return sub { my $w = $_[0]->([ 200, [ 'Content-Length' => 5 ] ]); $w->write('fixed'); $w->close([@grpc]) };
    }
    if ($p eq '/inject') {
        # the response-splitting attempt: refused, so nothing reaches the wire
        return sub {
            my $w = $_[0]->([ 200, $ct ]);
            $w->write('safe');
            my $err = eval { $w->close([ 'x-a' => "1\r\nInjected: yes" ]); 'none' } // $@;
            $w->close([ 'x-refused' => ($err =~ /control character/ ? 'yes' : 'no') ]);
        };
    }

    # ABI v10 through the table. The refused list leaves the body open, so
    # the producer can write more and then close properly, and it reports
    # the return codes in the trailers it finally sends.
    if ($p eq '/abi') {
        return sub {
            Hyperman::_abi_stream_open($env, 200, $ct);
            Hyperman::_abi_stream_write('abi ');
            my $bad = Hyperman::_abi_stream_close_trailers([ 'bad name' => 1 ]);
            my $w   = Hyperman::_abi_stream_write('body');
            my $ok  = Hyperman::_abi_stream_close_trailers(
                [ 'grpc-status' => 0, 'x-refused' => $bad, 'x-write-after' => $w ]);
            $keep{abi_rc} = $ok;
        };
    }
    if ($p eq '/abi-none') {
        return sub {
            Hyperman::_abi_stream_open($env, 200, $ct);
            Hyperman::_abi_stream_write('plain');
            $keep{abi_none_rc} = Hyperman::_abi_stream_close_trailers(undef);
        };
    }
    if ($p eq '/abi-rc') {
        return [ 200, [], [ join ',', map { $_ // 'u' } @keep{qw(abi_rc abi_none_rc)},
                            Hyperman::_abi_stream_close_trailers([ 'a' => 1 ]) ] ];
    }
    [ 200, [ 'Content-Type' => 'text/plain' ], [ $p ] ];
};

my $pid = server_guard(fork // die "fork: $!");
if (!$pid) {
    quiet_child(stderr => "$dir/stderr");
    # The access log is on for a reason: a response that completes inside
    # its handler frees its stream before dispatch comes to log the status
    # and length, and that used to be a read of freed memory.
    Hyperman->run(app => $app, host => '127.0.0.1', workers => 1, http2 => 1,
        access_log => "$dir/access.log", access_log_format => '%U %>s %b',
        listen => [ { port => $pa },
                    ($tls ? { port => $pb, tls_cert => $cert, tls_key => $key } : ()) ]);
    exit 0;
}

my $up = 0;
for (1 .. 100) {
    my $s = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$pa");
    if ($s) { $up = 1; last }
    last if server_status($pid);
    Time::HiRes::sleep(0.05);
}
ok($up, 'the h2 server is up') or skip 'the server did not start: '
    . (server_status($pid) // 'no answer'), 1;

# ---- 2. the frames, read by a bare client -----------------------------------------
#
# The client sends the preface, a SETTINGS that widens the stream window, a
# connection-level WINDOW_UPDATE, and a GET. It then collects every frame on
# the stream until one ends it.

my $frame = sub { my ($type, $flags, $sid, $payload) = @_;
                  substr(pack('N', length $payload), 1) . pack('CCN', $type, $flags, $sid) . $payload };
my $lit = sub { my ($n, $v) = @_; "\x00" . chr(length $n) . $n . chr(length $v) . $v };
my $opening = "PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n"
            . $frame->(4, 0, 0, pack('nN', 4, 0x7fffffff))      # INITIAL_WINDOW_SIZE
            . $frame->(8, 0, 0, pack('N', 0x3fffffff));         # connection window

# `stingy` keeps the default 64KB windows, so a larger body stalls on flow
# control with its trailers still owed
sub raw_conn {
    my (%o) = @_;
    my $s = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$pa") or return;
    $s->syswrite($o{stingy} ? "PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n" . $frame->(4, 0, 0, '')
                            : $opening);
    return { s => $s, buf => '' };
}
sub raw_get {
    my ($c, $sid, $path) = @_;
    $c->{s}->syswrite($frame->(1, 0x5, $sid, join '',
        $lit->(':method', 'GET'), $lit->(':scheme', 'http'),
        $lit->(':path', $path), $lit->(':authority', 'a')));
}
# Frames on stream $sid until one ends it (END_STREAM or RST_STREAM), or
# until $stop->($frame) says enough. SETTINGS are acknowledged on the way.
sub raw_read {
    my ($c, $sid, $stop) = @_;
    my @got;
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm 5;
        READ: while (1) {
            while (length $c->{buf} >= 9) {
                my ($len, $type, $flags, $id) = unpack 'NCCN', "\0" . substr($c->{buf}, 0, 9);
                last if length $c->{buf} < 9 + $len;
                substr($c->{buf}, 0, 9 + $len, '');
                $id &= 0x7fffffff;
                $c->{s}->syswrite($frame->(4, 1, 0, '')) if $type == 4 && !($flags & 1);
                next unless $id == $sid;
                my $f = { type => $type, flags => $flags, len => $len };
                push @got, $f;
                last READ if $type == 3;                            # RST_STREAM
                last READ if ($type == 0 || $type == 1) && ($flags & 1);
                last READ if $stop && $stop->($f);
            }
            my $n = $c->{s}->sysread(my $chunk, 65536);
            last unless $n;
            $c->{buf} .= $chunk;
        }
        alarm 0;
    };
    return @got;
}
sub raw_frames {
    my ($path) = @_;
    my $c = raw_conn() or return;
    raw_get($c, 1, $path);
    return raw_read($c, 1);
}

# H = HEADERS, D = DATA, R = RST_STREAM; a trailing ! is END_STREAM
sub shape {
    join ' ', map { ($_->{type} == 1 ? 'H' : $_->{type} == 0 ? 'D' : $_->{type} == 3 ? 'R' : "T$_->{type}")
                  . ($_->{flags} & 1 ? '!' : '') } @_;
}
sub body_len { my $n = 0; $n += $_->{len} for grep { $_->{type} == 0 } @_; $n }

for my $case (
    [ '/writer',        11,          'the writer' ],
    [ '/writer-empty',  0,           'the writer, with no body at all' ],
    [ '/writer-big',    length $big, 'the writer, past the flow-control window' ],
    [ '/writer-twice',  4,           'the writer closed twice' ],
    [ '/writer-later',  11,          'the writer, closed from a timer' ],
    [ '/stream',        13,          'a stream handle' ],
    [ '/stream-empty',  0,           'a stream handle, with no body' ],
    [ '/stream-big',    40 * 16384,  'a stream handle, 640KB in pieces' ],
    [ '/stream-later',  12,          'a stream handle whose provider had deferred' ],
) {
    my ($path, $len, $what) = @$case;
    my @f = raw_frames($path);
    my $shape = shape(@f);
    like($shape, qr/^H (?:D )*H!\z/,
         "$what: HEADERS, the body, then a trailing HEADERS that ends the stream")
        or diag "frames: $shape";
    unlike($shape, qr/D!/, '  no DATA frame ends the stream') ;
    is(body_len(@f), $len, "  and the body is whole ($len bytes)");
}

for my $case (
    [ '/writer-none',    'the writer closed without trailers' ],
    [ '/writer-dropped', 'the writer closed with only dropped names' ],
    [ '/stream-none',    'a stream handle closed without trailers' ],
) {
    my ($path, $what) = @$case;
    my $shape = shape(raw_frames($path));
    like($shape, qr/^H (?:D )*D!\z/, "$what: the last DATA ends the stream, as before")
        or diag "frames: $shape";
}

# ---- 3. the contents, from nghttp ------------------------------------------------

my $nghttp;
for my $c (split /\n/, `which -a nghttp 2>/dev/null` || '') {
    next unless $c && -x $c;
    $nghttp = $c;
    last;
}

# nghttp -v prints each header as it is decoded and then the frame it came in,
# so the headers seen since the last frame line belong to the next HEADERS.
sub ng_frames {
    my ($url) = @_;
    my @out = `"$nghttp" -v -t 5 "$url" 2>&1`;
    my (@pending, @f);
    for (@out) {
        if (/recv \(stream_id=\d+\) (:?[^:\s]+): (.*?)\r?$/) { push @pending, [ $1, $2 ]; next }
        if (/recv (HEADERS|DATA) frame <length=(\d+), flags=0x([0-9a-f]+), stream_id=(\d+)>/) {
            next unless $4;     # never stream 0
            push @f, { type => $1, len => $2, flags => hex $3,
                       hdrs => ($1 eq 'HEADERS' ? [ splice @pending ] : []) };
        }
    }
    return @f;
}
sub ng_trailers {
    my @f = ng_frames(@_);
    return undef unless @f >= 2 && $f[-1]{type} eq 'HEADERS' && ($f[-1]{flags} & 1);
    return $f[-1]{hdrs};
}

SKIP: {
    skip 'nghttp(1) not installed: trailer contents unchecked (the frames above still were)', 1
        unless $nghttp;

    my $base = "http://127.0.0.1:$pa";
    my $t = ng_trailers("$base/writer");
    ok($t, 'nghttp reads trailers from the writer') or diag 'frames: '
        . join ' ', map { "$_->{type}/$_->{flags}" } ng_frames("$base/writer");
    $t ||= [];
    is_deeply([ map { $_->[0] } @$t ], [ qw(grpc-status grpc-message x-tab) ],
              '  names lowercased, in order, and the framing/connection names dropped');
    is_deeply($t, [ [ 'grpc-status', '0' ], [ 'grpc-message', 'all good' ], [ 'x-tab', "a\tb" ] ],
              '  values as given, trimmed at the ends but not inside');

    is_deeply(ng_trailers("$base/stream"),
              [ [ 'grpc-status', '14' ], [ 'grpc-message', 'try later' ] ],
              'a stream handle sends its trailers');
    is_deeply(ng_trailers("$base/writer-empty"),
              [ [ 'grpc-status', '0' ], [ 'grpc-message', 'ok' ] ],
              'trailers with no body (what a gRPC error reply after headers looks like)');
    is_deeply(ng_trailers("$base/writer-twice"), [ [ 'x-first', '1' ] ],
              'the first close wins; the second sends nothing');
    is_deeply(ng_trailers("$base/writer-refused"), [ [ 'x-refused', 'yes' ] ],
              'a refused list leaves the writer open for a proper close');
    is_deeply(ng_trailers("$base/stream-later"),
              [ [ 'grpc-status', '0' ], [ 'grpc-message', 'ok' ] ],
              'trailers after the provider had deferred');
    is(ng_trailers("$base/writer-none"), undef, 'no list, no trailers');

    SKIP: {
        skip 'no TLS build or no openssl(1) to make a certificate', 2 unless $tls;
        my $tb = "https://127.0.0.1:$pb";
        is_deeply(ng_trailers("$tb/writer-empty"),
                  [ [ 'grpc-status', '0' ], [ 'grpc-message', 'ok' ] ],
                  'over TLS (ALPN h2), the writer sends its trailers');
        is_deeply(ng_trailers("$tb/stream"),
                  [ [ 'grpc-status', '14' ], [ 'grpc-message', 'try later' ] ],
                  '  and so does a stream handle');
    }
}

# ---- HTTP/1.1: a trailer section for the client that asked ----------------------
#
# Another bare client, because the bytes themselves are the point. Each read
# yields the head, the de-chunked body, and the trailer section exactly as
# sent: whatever sits between the zero-size chunk and the blank line.

sub h1_conn { IO::Socket::INET->new(PeerAddr => "127.0.0.1:$pa") }
sub h1_send {
    my ($s, $path, %o) = @_;
    my $proto  = $o{proto}  || 'HTTP/1.1';
    my $method = $o{method} || 'GET';
    $s->syswrite("$method $path $proto\r\nHost: a\r\n" . join('', map { "$_\r\n" } @{ $o{h} || [] }) . "\r\n");
}
sub h1_read {
    my ($s, %o) = @_;
    my $buf = '';
    my $fill = sub {
        my $n = $s->sysread(my $c, 65536);
        return 0 unless $n;
        $buf .= $c;
        return 1;
    };
    my %r;
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm 5;
        1 until $buf =~ /\r\n\r\n/ or !$fill->();
        my $end = index($buf, "\r\n\r\n");
        die "no head\n" if $end < 0;
        $r{head} = substr($buf, 0, $end + 4, '');
        ($r{status}) = $r{head} =~ m{^HTTP/1\.[01] (\d+)};
        if ($o{head_only}) { }
        elsif ($r{head} =~ /^Transfer-Encoding: chunked\r$/mi) {
            $r{body} = '';
            while (1) {
                1 until $buf =~ /\r\n/ or !$fill->();
                $buf =~ s/\A([0-9a-fA-F]+)\r\n// or die "bad chunk size\n";
                my $n = hex $1;
                if ($n == 0) {
                    # the trailer section: field lines, then an empty line
                    1 until $buf =~ /\A((?:[^\r\n]+\r\n)*)\r\n/ or !$fill->();
                    $buf =~ s/\A((?:[^\r\n]+\r\n)*)\r\n// or die "no end of body\n";
                    $r{trailers} = $1;
                    last;
                }
                1 until length($buf) >= $n + 2 or !$fill->();
                $r{body} .= substr($buf, 0, $n, '');
                $buf =~ s/\A\r\n// or die "no chunk CRLF\n";
            }
        }
        elsif ($r{head} =~ /^Content-Length: (\d+)\r$/mi) {
            my $n = $1;
            1 until length($buf) >= $n or !$fill->();
            $r{body} = substr($buf, 0, $n, '');
        }
        else { 1 while $fill->(); $r{body} = $buf; $buf = '' }
        alarm 0;
    };
    $r{error} = $@ if $@;
    $r{rest} = $buf;
    return \%r;
}
sub h1 { my ($path, %o) = @_; my $s = h1_conn() or return {}; h1_send($s, $path, %o); h1_read($s, %o) }

{
    my $r = h1('/writer', h => [ 'TE: trailers' ]);
    like($r->{head}, qr/^Transfer-Encoding: chunked\r$/mi, 'HTTP/1.1 with TE: trailers: the body is chunked');
    is($r->{body}, 'hello world', '  the body is whole');
    is($r->{trailers}, "grpc-status: 0\r\ngrpc-message: all good\r\nx-tab: a\tb\r\n",
       '  and the trailer section follows the last chunk: lowercased, trimmed, '
     . 'the framing/connection names dropped');

    $r = h1('/writer');
    is($r->{body}, 'hello world', 'without TE the body is the same');
    is($r->{trailers}, '', '  and the trailer section is empty: 0 CRLF CRLF, as before');

    for my $te ('deflate;q=0.5, Trailers', 'trailers;q=1', ' gzip ,trailers ') {
        is(h1('/writer', h => [ "TE: $te" ])->{trailers} =~ /^grpc-status: 0\r$/m ? 1 : 0, 1,
           "TE: '$te' asks for them");
    }
    is(h1('/writer', h => [ 'TE: gzip', 'TE: trailers' ])->{trailers} =~ /grpc-status/ ? 1 : 0, 1,
       'so does a second TE line');
    is(h1('/writer', h => [ 'TE: x-trailers, trailersx' ])->{trailers}, '',
       'a longer token that merely contains "trailers" does not');

    $r = h1('/stream', h => [ 'TE: trailers' ]);
    is($r->{trailers}, "grpc-status: 14\r\ngrpc-message: try later\r\n",
       'a stream handle sends them over HTTP/1.1 too');
    $r = h1('/stream-empty', h => [ 'TE: trailers' ]);
    is_deeply([ $r->{body}, $r->{trailers} ], [ '', "grpc-status: 0\r\ngrpc-message: ok\r\n" ],
              '  with no body at all');

    $r = h1('/writer', proto => 'HTTP/1.0', h => [ 'TE: trailers' ]);
    unlike($r->{head}, qr/chunked/i, 'HTTP/1.0 gets no chunked body');
    is($r->{body}, 'hello world', '  so its body ends at the close');
    unlike($r->{body}, qr/grpc/, '  and carries no trailers');

    $r = h1('/writer', h => [ 'TE: trailers', 'Connection: close' ]);
    unlike($r->{head}, qr/chunked/i, 'a request that closes gets an EOF-delimited body');
    is($r->{body}, 'hello world', '  without trailers in it');

    $r = h1('/writer', method => 'HEAD', head_only => 1, h => [ 'TE: trailers' ]);
    is($r->{status}, 200, 'a HEAD answers');
    is($r->{rest}, '', '  with nothing after the headers - no last chunk, no trailers');

    $r = h1('/counted', h => [ 'TE: trailers' ]);
    is($r->{body}, 'fixed', 'a body with its own Content-Length');
    unlike($r->{head}, qr/chunked/i, '  stays counted');
    is($r->{rest}, '', '  and nothing follows it');

    $r = h1('/inject', h => [ 'TE: trailers' ]);
    is($r->{trailers}, "x-refused: yes\r\n", 'CR LF in a trailer value is refused, not written');
    unlike($r->{head} . ($r->{trailers} // ''), qr/Injected/i, '  so nothing can be split into the response');

    is(h1('/flag', h => [ 'TE: trailers' ])->{body}, '1',
       'psgix.hyperman.trailers is set for a keep-alive HTTP/1.1 request that asked');
    is(h1('/flag')->{body}, 'absent', '  and absent for one that did not');
    is(h1('/flag', h => [ 'TE: trailers', 'Connection: close' ])->{body}, 'absent',
       '  and for one that will close (its body cannot be chunked)');
    is(h1('/flag', proto => 'HTTP/1.0', h => [ 'TE: trailers' ])->{body}, 'absent',
       '  and for HTTP/1.0');

    # keep-alive: the body really is over after the trailer section
    my $s = h1_conn();
    h1_send($s, '/writer', h => [ 'TE: trailers' ]);
    my $one = h1_read($s);
    h1_send($s, '/stream', h => [ 'TE: trailers' ]);
    my $two = h1_read($s);
    h1_send($s, '/plain-after');
    my $three = h1_read($s);
    is($one->{body} . '|' . $two->{body} . '|' . $three->{body}, 'hello world|streamed body|/plain-after',
       'three requests on one keep-alive connection, trailers between them, each in frame');
    is($two->{trailers}, "grpc-status: 14\r\ngrpc-message: try later\r\n", '  the second with its own trailers');
}

# ---- ABI v10: stream_close_trailers, through the table -----------------------------
{
    my $r = h1('/abi', h => [ 'TE: trailers' ]);
    is($r->{body}, 'abi body', 'ABI v10 over HTTP/1.1: a refused list left the body open, and it was finished');
    is($r->{trailers}, "grpc-status: 0\r\nx-refused: -3\r\nx-write-after: 0\r\n",
       '  the refusal was HM_ABI_STREAM_ARG, the write after it was accepted, and the trailers went');
    $r = h1('/abi-none', h => [ 'TE: trailers' ]);
    is_deeply([ $r->{body}, $r->{trailers} ], [ 'plain', '' ], '  undef trailers is a plain close');
    is(h1('/abi-rc')->{body}, '0,0,-1',
       '  both closes returned OK, and with no handle open it is STALE');

    my @f = raw_frames('/abi');
    like(shape(@f), qr/^H (?:D )*H!\z/, 'ABI v10 over HTTP/2: a trailing HEADERS ends the stream')
        or diag 'frames: ' . shape(@f);
    is(body_len(@f), 8, '  after the whole body');
  SKIP: {
        skip 'nghttp(1) not installed', 1 unless $nghttp;
        is_deeply(ng_trailers("http://127.0.0.1:$pa/abi"),
                  [ [ 'grpc-status', '0' ], [ 'x-refused', '-3' ], [ 'x-write-after', '0' ] ],
                  '  carrying the same fields');
    }
}

# ---- the environment says so --------------------------------------------------
{
    my @f = raw_frames('/flag');
    ok(scalar(grep { $_->{type} == 0 && $_->{len} == 1 } @f),
       'psgix.hyperman.trailers is set on an HTTP/2 request');
}

# ---- the client leaves first ---------------------------------------------------------
#
# Trailers promised to a stream that has gone. The close has to find no
# stream, release the list, and leave the worker running. A stream goes two
# ways: with its whole connection, or alone by RST_STREAM while the
# connection carries on, and in the second case its neighbours must notice
# nothing.
{
    my $c = raw_conn();
    raw_get($c, 1, '/gone-writer');
    raw_get($c, 3, '/gone-stream');
    raw_read($c, 3, sub { $_[0]{type} == 0 });   # 'partial' has arrived
    close $c->{s};                                # the connection goes
    Time::HiRes::sleep(0.9);                      # past both closes
    ok(!defined server_status($pid),
       'closing with trailers after the connection dropped is harmless');

    $c = raw_conn();
    raw_get($c, 1, '/gone-writer');
    raw_get($c, 3, '/gone-stream');
    raw_read($c, 3, sub { $_[0]{type} == 0 });
    $c->{s}->syswrite($frame->(3, 0, $_, pack('N', 8))) for 1, 3;   # RST_STREAM CANCEL
    Time::HiRes::sleep(0.9);
    ok(!defined server_status($pid),
       'closing with trailers after the stream was reset is harmless');
    raw_get($c, 5, '/stream');
    my $shape = shape(raw_read($c, 5));
    like($shape, qr/^H (?:D )*H!\z/,
         '  and the same connection still carries trailers on its next stream')
        or diag "frames: $shape";

    # Closed, trailers handed over - and then stuck: the body is bigger than
    # the window and this client never opens it. The reset frees the stream
    # with the trailers still owed, and they must go with it.
    $c = raw_conn(stingy => 1);
    raw_get($c, 1, '/writer-big');
    raw_get($c, 3, '/stream-big');
    my $seen = 0;
    raw_read($c, 3, sub { $_[0]{type} == 0 && ++$seen >= 1 });
    $c->{s}->syswrite($frame->(3, 0, $_, pack('N', 8))) for 1, 3;
    Time::HiRes::sleep(0.3);
    ok(!defined server_status($pid),
       'a stream reset while its body is held by flow control, trailers owed, is harmless');
    # Those two spent the CONNECTION window, which a reset does not give back:
    # the client returns it, as any real one does, or nothing more - not even
    # a zero-length body reaching its EOF - can be sent on this connection.
    $c->{s}->syswrite($frame->(8, 0, 0, pack('N', 0x3fffffff)));
    raw_get($c, 5, '/stream-empty');
    like(shape(raw_read($c, 5)), qr/^H (?:D )*H!\z/, '  and the connection carries on');
}

# ---- the access log, for responses that completed inside their handler -------
{
    my $log = '';
    for (1 .. 20) { $log = HMTest::slurp("$dir/access.log"); last if $log =~ m{^/stream-big }m; Time::HiRes::sleep(0.1) }
    like($log, qr{^/writer 200 11$}m,           'the access log has the writer\'s status and length');
    like($log, qr{^/stream 200 13$}m,           '  and a stream handle\'s');
    like($log, qr{^/writer-big 200 204800$}m,   '  and one that filled several windows');
    like($log, qr{^/stream-big 200 655360$}m,   '  and a stream handle\'s that did');
}

kill 'TERM', $pid;
server_reap($pid);
my $err = HMTest::slurp("$dir/stderr");
unlike($err, qr/panic|Attempt to free|Segmentation|double free|corrupt|AddressSanitizer/i,
       'no memory complaints from the server') or diag $err;
}

done_testing;
