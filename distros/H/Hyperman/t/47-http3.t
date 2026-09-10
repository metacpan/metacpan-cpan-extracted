#!perl
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use HMTest qw(free_ports quiet_child server_reap);
use Time::HiRes ();
use Hyperman;

# HTTP/3 end to end: real requests from a real client, over QUIC.
#
# Every response path the other transports have is driven here - sync, a
# parked Future, the psgi.streaming responder and its Writer, a request body,
# and a body large enough to cross several flow-control windows - because the
# claim is that an application does not change when the transport does.
#
# The client is chosen by curl's HTTP3 FEATURE, not by a flag or a version: a
# tool can accept --http3 and have no QUIC in it, which is exactly what
# h2load does. --http3-only, so nothing here can silently pass over TCP.

plan skip_all => 'HTTP/3 support not built' unless Hyperman->has_http3;

my $curl;
for my $c ('/opt/homebrew/opt/curl/bin/curl', '/usr/local/opt/curl/bin/curl',
           split /\n/, `which -a curl 2>/dev/null` || '') {
    next unless $c && -x $c;
    my $v = `$c --version 2>/dev/null` || '';
    next unless $v =~ /^Features:.*\bHTTP3\b/m;
    $curl = $c;
    last;
}
plan skip_all => 'no HTTP/3-capable curl' unless $curl;
note("client: $curl");

my $openssl = `which openssl 2>/dev/null`;
chomp $openssl;
plan skip_all => 'no openssl to make a test certificate' unless $openssl;

my $dir = "hm_h3req_$$";
mkdir $dir or plan skip_all => "cannot make $dir";
my ($cert, $key) = ("$dir/c.pem", "$dir/k.pem");
if (system(qq{$openssl req -x509 -newkey rsa:2048 -keyout $key -out $cert }
         . qq{-days 1 -nodes -subj "/CN=localhost" >/dev/null 2>&1}) != 0) {
    unlink $cert, $key; rmdir $dir;
    plan skip_all => 'openssl could not make a test certificate';
}

# A CA and a client certificate: mTLS over QUIC is the thing that was silently
# missing, and only a real client certificate proves it is not.
my ($ca, $cakey, $ccert, $ckey) =
    ("$dir/ca.pem", "$dir/ca.key", "$dir/cl.pem", "$dir/cl.key");
my $have_mtls = 0;
{
    my $q = ">/dev/null 2>&1";
    my $ok = system(qq{$openssl req -x509 -newkey rsa:2048 -keyout $cakey }
                  . qq{-out $ca -days 1 -nodes -subj "/CN=Test CA" $q}) == 0;
    $ok &&= system(qq{$openssl req -newkey rsa:2048 -keyout $ckey }
                 . qq{-out $dir/cl.csr -nodes -subj "/CN=test-client" $q}) == 0;
    $ok &&= system(qq{$openssl x509 -req -in $dir/cl.csr -CA $ca -CAkey $cakey }
                 . qq{-CAcreateserial -out $ccert -days 1 $q}) == 0;
    $have_mtls = $ok;
    unlink "$dir/cl.csr", "$dir/ca.srl";
}

my ($port) = free_ports(1);
unless ($port) {
    unlink $cert, $key; rmdir $dir;
    plan skip_all => 'no free loopback port';
}

my $BIG = 100_000;

# 32MB, written once and served many times. Big enough that holding it in
# memory would show, which is the whole point of the assertion below.
my $BIGFILE   = "$dir/big.bin";
my $FILESIZE  = 32 * 1024 * 1024;
{
    open my $bf, '>', $BIGFILE or plan skip_all => 'cannot write the test file';
    binmode $bf;
    print $bf ('x' x 65536) for 1 .. ($FILESIZE / 65536);
    close $bf;
}

my $pid = fork;
die "fork: $!" unless defined $pid;
if ($pid == 0) {
    quiet_child();
    require Hyperman;
    Hyperman->run(
        app => sub {
            my $env = shift;
            my $p   = $env->{PATH_INFO};

            if ($p eq '/proto') {
                return [ 200, [ 'Content-Type' => 'text/plain' ],
                         [ "$env->{SERVER_PROTOCOL}|$env->{'psgi.url_scheme'}|"
                         . "$p|$env->{QUERY_STRING}" ] ];
            }
            if ($p eq '/async') {
                return Hyperman->timer(0.05)->then(sub {
                    [ 200, [ 'Content-Type' => 'text/plain' ], ['async-h3'] ];
                });
            }
            if ($p eq '/stream') {
                return sub {
                    my $respond = shift;
                    my $w = $respond->([ 200, [ 'Content-Type' => 'text/plain' ] ]);
                    $w->write('chunk1;');
                    $w->write('chunk2');
                    $w->close;
                };
            }
            if ($p eq '/echo') {
                my $body = '';
                $env->{'psgi.input'}->read($body, 65536)
                    if $env->{'psgi.input'};
                return [ 200, [ 'Content-Type' => 'text/plain' ],
                         [ "echo:$body" ] ];
            }
            # A FILE body, which is a different code path from the
            # in-memory one: the data reader reads it per window into a
            # bounce buffer it must not refill while the previous fill is
            # unacked. Nothing else here exercises that.
            if ($p eq '/file') {
                open my $fh, '<', $BIGFILE or return
                    [ 500, [ 'Content-Type' => 'text/plain' ], ['no file'] ];
                binmode $fh;
                return [ 200, [ 'Content-Type'   => 'application/octet-stream',
                                'Content-Length' => -s $BIGFILE ], $fh ];
            }
            # What the transport reported about the peer's certificate.
            if ($p eq '/peer') {
                return [ 200, [ 'Content-Type' => 'text/plain' ],
                         [ join '|', map { defined $env->{$_} ? $env->{$_} : '-' }
                             qw(HTTPS SSL_PROTOCOL SSL_KTLS
                                SSL_CLIENT_VERIFY SSL_CLIENT_S_DN) ] ];
            }
            if ($p eq '/rss') {
                my $kb = (split ' ', `ps -o rss= -p $$`)[0] || 0;
                return [ 200, [ 'Content-Type' => 'text/plain' ], [$kb] ];
            }
            if ($p eq '/big') {
                return [ 200, [ 'Content-Type' => 'text/plain' ],
                         [ 'x' x $BIG ] ];
            }
            if ($p eq '/detach') {
                my $err = '';
                eval { Hyperman::detach($env); 1 } or $err = "$@";
                $err =~ s/\s+\z//;
                return [ 200, [ 'Content-Type' => 'text/plain' ], [$err] ];
            }
            if ($p eq '/stats') {
                my $s = Hyperman->stats;
                return [ 200, [ 'Content-Type' => 'text/plain' ],
                         [ "h3_conns=$s->{h3_conns} h3_requests=$s->{h3_requests}" ] ];
            }
            return [ 404, [ 'Content-Type' => 'text/plain' ], ['nope'] ];
        },
        host     => '127.0.0.1',
        port     => $port,
        workers  => 1,
        http2    => 1,
        http3    => 1,
        tls_cert => $cert,
        tls_key  => $key,
        # Optional, so every other test in this file still connects without
        # one and only the mTLS case presents a certificate.
        ($have_mtls ? (tls_ca => $ca, tls_verify => 'optional') : ()),
    );
    exit 0;
}

my $CURL = "$curl -s -k --max-time 10";

sub h3 {
    my ($path, @extra) = @_;
    return `$CURL --http3-only @extra https://127.0.0.1:$port$path 2>&1`;
}

# Wait for the QUIC listener, not just the process.
my $up = '';
for (1 .. 100) {
    $up = h3('/proto');
    last if $up =~ /HTTP/;
    Time::HiRes::sleep(0.05);
}
like($up, qr{^HTTP/3\|}, 'a plain GET is answered over HTTP/3')
    or diag "got: $up";

SKIP: {
    skip "no HTTP/3 response at all", 11 unless $up =~ m{^HTTP/3\|};

    my @f = split /\|/, h3('/proto?a=1');
    is($f[0], 'HTTP/3',  'SERVER_PROTOCOL is HTTP/3');
    is($f[1], 'https',   'psgi.url_scheme is https - QUIC has no cleartext mode');
    is($f[2], '/proto',  'PATH_INFO survived QPACK and the :path pseudo-header');
    is($f[3], 'a=1',     'and the query string was split off it');

    is(h3('/nope-not-here'), 'nope', 'an unrouted path reaches the app as a 404');

    is(h3('/async'), 'async-h3',
       'a handler returning a Future parks the stream and answers when it settles');

    is(h3('/stream'), 'chunk1;chunk2',
       'the psgi.streaming responder and its Writer work unchanged over h3');

    is(h3('/echo', '-d', 'payload'), 'echo:payload',
       'a request body arrives, so psgi.input is fed from the QUIC stream');

    # Big enough to cross several flow-control windows and to be handed to
    # nghttp3 as pointers that must stay alive until they are acked. A
    # premature release shows up here as a short or corrupt body.
    my $big = h3('/big');
    is(length $big, $BIG, "a ${BIG}-byte body arrives whole across many windows");
    ok($big !~ /[^x]/, '...and every byte of it is intact');

    # Detaching is impossible on a multiplexed transport, and the message
    # says so rather than leaving the caller to guess.
    my $det = h3('/detach');
    like($det, qr/Hyperman::detach/, 'Hyperman::detach refuses on HTTP/3');
    like($det, qr{HTTP/3},
         '...and the message names HTTP/3, rather than leaving a caller to '
       . 'infer it from an absent env key');
}

# Sustained concurrent large responses.
#
# A regression test for a THROUGHPUT COLLAPSE, not a hang, and the size is
# load-bearing. A stream that runs out of flow-control room is handed to
# nghttp3_conn_block_stream and nghttp3 stops offering it; ngtcp2's
# extend_max_stream_data callback is what puts it back when the peer grants
# more. Without that callback the connection still limps along on
# retransmission timers rather than deadlocking, so a small run looks fine:
# measured A/B/A, 500 requests was identical either way, and 1500 was 0.8s
# against a 25s timeout - a 20x collapse. Hence this size and this deadline.
SKIP: {
    skip 'no HTTP/3 response at all', 2 unless $up =~ m{^HTTP/3\|};

    my $n   = 1500;
    my $cfg = "$dir/big.txt";
    open my $fh, '>', $cfg or skip 'cannot write a curl config', 2;
    print $fh qq{url = "https://127.0.0.1:$port/big"\noutput = "/dev/null"\n}
        for 1 .. $n;
    close $fh;

    # Its own deadline: the failure mode is slowness, so the assertion IS the
    # clock. Generous enough not to fire on a loaded smoker (it takes about a
    # second here) and far under the 25s the broken version needed.
    my $t0 = Time::HiRes::time();
    my $rc = system(qq{$curl -s -k --http3-only --max-time 20 --parallel }
                  . qq{--parallel-max 50 -w "%{size_download}\\n" -K $cfg }
                  . qq{> $dir/sizes.txt 2>&1});
    my $took = Time::HiRes::time() - $t0;

    is($rc, 0, "$n concurrent large HTTP/3 responses completed within the deadline")
        or diag sprintf('curl exited %d after %.1fs - a stream that lost its '
                      . 'flow-control window was never unblocked', $rc, $took);

    my @sizes = do {
        open my $s, '<', "$dir/sizes.txt" or ();
        $s ? (map { chomp; $_ } <$s>) : ();
    };
    my $whole = grep { $_ == $BIG } @sizes;
    is($whole, $n, "...and every one was the full $BIG bytes");
    note(sprintf('%d x %d bytes over HTTP/3 in %.2fs (%.0f req/s)',
                 $n, $BIG, $took, $took > 0 ? $n / $took : 0));
    unlink $cfg, "$dir/sizes.txt";
}

# A FILE body over HTTP/3, and what it costs in memory.
#
# The data reader has two paths and only the in-memory one was covered: a
# file source reads per window into a bounce buffer and must not refill it
# while the previous fill is still unacked. That path was written and never
# run, which is the kind of thing that works until the first large download.
#
# The assertion is on RSS **growth**, never an absolute figure - a worker's
# baseline is a property of the perl and the platform, and t/27-sendfile.t
# learned that from FreeBSD smokers reporting 62-83MB idle.
SKIP: {
    skip 'no HTTP/3 response at all', 3 unless $up =~ m{^HTTP/3\|};

    my $before = h3('/rss');
    chomp $before;
    skip 'no RSS reading on this platform', 3 unless $before =~ /^\d+$/ && $before > 0;

    my $got = h3('/file');
    is(length $got, $FILESIZE,
       "a ${FILESIZE}-byte FILE body arrives whole over HTTP/3");

    my $after = h3('/rss');
    chomp $after;
    my $grew = ($after || 0) - $before;
    note(sprintf('worker RSS %d KB -> %d KB (%+d KB) serving %d MB from a file',
                 $before, $after, $grew, $FILESIZE / (1024 * 1024)));

    # Streaming from the file means the body is never held whole. Slurping
    # it would show as growth on the order of the file itself; the bounce
    # buffer is HM_BSRC_CHUNK. The bound is generous because RSS is noisy,
    # and still an order of magnitude under the file.
    cmp_ok($grew, '<', $FILESIZE / 1024 / 4,
           'and the worker did not grow by anything like the file size, so '
         . 'the body was streamed rather than slurped');

    # Twice, to catch a bounce buffer that is refilled while unacked or
    # never reset: the second download would be short or corrupt.
    my $again = h3('/file');
    is(length $again, $FILESIZE,
       'a second download of the same file is also whole, so the bounce '
     . 'buffer is reset between them');
}

# Client certificates over HTTP/3.
#
# A QUIC handshake IS a TLS handshake, so mTLS has to report identically on
# every transport. It did not: the capture ran off hm_conn, which HTTP/3 does
# not have, so SSL_CLIENT_* was silently absent on QUIC while working on TCP.
# Silently is the problem - an application checking SSL_CLIENT_VERIFY would
# have seen NONE and refused a client that had in fact presented a valid
# certificate.
SKIP: {
    skip 'no HTTP/3 response at all', 4 unless $up =~ m{^HTTP/3\|};
    skip 'no client certificate could be made', 4 unless $have_mtls;

    my @n = split /\|/, h3('/peer');
    is($n[0], 'on', 'HTTPS is on over HTTP/3');
    is($n[2], '0',
       'SSL_KTLS is 0 and present, because there is no kernel record layer '
     . 'for QUIC - said, rather than left absent to read as unknown');
    is($n[3], 'NONE', 'no client certificate reports NONE, not nothing');

    my @m = split /\|/, h3('/peer', "--cert $ccert --key $ckey");
    is($m[3], 'SUCCESS',
       'a client certificate presented over HTTP/3 is verified and reported, '
     . 'exactly as it is over HTTP/1.1 and HTTP/2')
        or diag "got: @m";
    like($m[4] || '', qr/test-client/,
         '...and its subject reaches $env as SSL_CLIENT_S_DN');
}

# Alt-Svc is how a client discovers h3 at all. It belongs on the responses
# that are NOT h3; putting it on an h3 response tells a client what it is
# already using.
{
    my $hdr = sub {
        my ($ver) = @_;
        my $t = `$CURL $ver -D - -o /dev/null https://127.0.0.1:$port/ 2>&1`;
        my ($a) = ($t || '') =~ /^alt-svc:\s*(.*?)\s*$/mi;
        return $a;
    };
    my $a1 = $hdr->('--http1.1');
    my $a2 = $hdr->('--http2');
    my $a3 = $hdr->('--http3-only');
    is($a1, qq{h3=":$port"; ma=86400}, 'Alt-Svc advertises h3 on the HTTP/1.1 response');
    is($a2, qq{h3=":$port"; ma=86400}, '...and on the HTTP/2 response');
    is($a3, undef, '...and never on an HTTP/3 response');
}

# The counters, read back over HTTP/3 itself.
{
    my %s = (h3('/stats') || '') =~ /(\w+)=(\d+)/g;
    cmp_ok($s{h3_conns} || 0, '>', 0, 'stats counted the QUIC handshakes');
    cmp_ok($s{h3_requests} || 0, '>', 0, 'and the HTTP/3 requests served');
}

kill 'TERM', $pid;
server_reap($pid);
unlink $cert, $key, $BIGFILE, $ca, $cakey, $ccert, $ckey;
rmdir $dir;
done_testing();
