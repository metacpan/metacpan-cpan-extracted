#!perl
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use HMTest qw(free_ports quiet_child);
use IO::Socket::INET;
use Time::HiRes ();
use File::Temp ();
use Hyperman;

# TLS/HTTPS via OpenSSL. Needs the OpenSSL build, the `openssl` CLI to make a
# throwaway self-signed cert, and an HTTPS-capable curl; skips otherwise.

plan skip_all => 'OpenSSL support not built' unless Hyperman->has_tls;
my $openssl = `which openssl`; chomp $openssl;
plan skip_all => 'openssl CLI not found' unless $openssl;
my $curl = `which curl`; chomp $curl;
plan skip_all => 'curl not found' unless $curl;

my $dir  = File::Temp::tempdir(CLEANUP => 1);
my $cert = "$dir/cert.pem";
my $key  = "$dir/key.pem";
system(qq{openssl req -x509 -newkey rsa:2048 -nodes -keyout "$key" -out "$cert" }
     . qq{-days 1 -subj "/CN=localhost" >/dev/null 2>&1});
plan skip_all => 'could not create self-signed cert'
    unless -s $cert && -s $key;

my ($port) = free_ports(1);
plan skip_all => "no free loopback port" unless $port;

my $pid = fork;
die "fork: $!" unless defined $pid;
if ($pid == 0) {
    quiet_child();
    Hyperman->run(
        app => sub {
            my $env = shift;
            my $p = $env->{PATH_INFO};
            if ($p eq '/scheme') {
                return [ 200, [ 'Content-Type' => 'text/plain' ],
                         [ "$env->{'psgi.url_scheme'} $env->{SERVER_PROTOCOL}" ] ];
            }
            if ($p eq '/echo') {
                my $body = '';
                $env->{'psgi.input'}->read($body, $env->{CONTENT_LENGTH} || 0)
                    if $env->{'psgi.input'};
                return [ 200, [ 'Content-Type' => 'text/plain' ], [ "echo:$body" ] ];
            }
            if ($p eq '/async') {
                return Hyperman->timer(0.05)->then(sub {
                    [ 200, [ 'Content-Type' => 'text/plain' ], [ 'async-tls' ] ];
                });
            }
            # A 101 stream handle: the tunnel a WebSocket over TLS rides,
            # since the socket cannot be detached from under the session.
            if ($p eq '/tunnel') {
                Hyperman::_abi_stream_open($env, 101,
                    [ 'Upgrade' => 'echo', 'Connection' => 'Upgrade' ])
                    or return [ 500, [ 'Content-Type' => 'text/plain' ],
                                ['no tunnel'] ];
                Hyperman::_abi_stream_read();
                Hyperman::_abi_stream_write("hello-tunnel;");
                return [ 101, [], [] ];
            }
            if ($p eq '/tunnel-rx') {
                my ($n, $len, $bytes) = Hyperman::_abi_stream_rx();
                return [ 200, [ 'Content-Type' => 'text/plain' ], [$bytes] ];
            }
            if ($p eq '/tunnel-close') {
                my $r = Hyperman::_abi_stream_close();
                return [ 200, [ 'Content-Type' => 'text/plain' ], ["close=$r"] ];
            }
            [ 200, [ 'Content-Type' => 'text/plain' ], [ 'hello-tls' ] ];
        },
        host => '127.0.0.1', port => $port, workers => 1,
        tls_cert => $cert, tls_key => $key,
        ($ENV{HM_TLS_H2} && Hyperman->has_http2 ? (http2 => 1) : ()),
    );
    exit 0;
}

# wait for the port to listen
for (1 .. 50) {
    my $s = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port");
    last if $s;
    Time::HiRes::sleep(0.1);
}

sub https {
    my ($path, @extra) = @_;
    my $out = `curl -sk @extra "https://127.0.0.1:$port$path" 2>/dev/null`;
    return $out;
}

# plaintext request to a TLS port must NOT succeed as HTTP
{
    my $s = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port");
    ok($s, 'connected');
    $s->print("GET /scheme HTTP/1.0\r\n\r\n");
    my $buf = '';
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm 2;
        $s->sysread($buf, 100);
        alarm 0;
    };
    unlike($buf, qr/^HTTP/, 'plaintext GET on the TLS port is not served as HTTP');
}

like(https('/scheme'), qr{^https\b}, 'psgi.url_scheme is https over TLS');
is(https('/'), 'hello-tls', 'basic HTTPS response body');
is(https('/echo', '-d', 'secret=42'), 'echo:secret=42', 'request body over HTTPS');
is(https('/async'), 'async-tls', 'Future-returning handler over HTTPS');

# keep-alive: two requests on one TLS connection
{
    my $out = `curl -sk "https://127.0.0.1:$port/" "https://127.0.0.1:$port/scheme" 2>/dev/null`;
    like($out, qr/hello-tls/,    'keep-alive request 1');
    like($out, qr/https HTTP/,   'keep-alive request 2 on same TLS conn');
}

# ---- a 101 tunnel over TLS ------------------------------------------------
#
# The case the stream seam's 101 exists for: an upgrade the server keeps
# hold of, because the TLS session's state belongs to it and conn_detach
# refuses (-3). Bytes go both ways through SSL_write and SSL_read, and the
# read half sees what the client sent after the 101.
SKIP: {
    skip 'IO::Socket::SSL not installed', 6
        unless eval { require IO::Socket::SSL; 1 };
    my $t = IO::Socket::SSL->new(PeerAddr => "127.0.0.1:$port",
                                 SSL_verify_mode => 0, Timeout => 5);
    ok($t, 'TLS client connected for the tunnel') or skip 'no TLS client', 5;
    syswrite $t, "GET /tunnel HTTP/1.1\r\nHost: 127.0.0.1\r\n"
               . "Upgrade: echo\r\nConnection: Upgrade\r\n\r\n";
    my $got = '';
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm 5;
        while ($got !~ /hello-tunnel;/) {
            my $n = sysread($t, my $b, 4096);
            last unless $n;
            $got .= $b;
        }
        alarm 0;
    };
    my ($head, $body) = split /\r\n\r\n/, $got, 2;
    like($head || '', qr{^HTTP/1\.1 101 }, 'a 101 over TLS');
    unlike($head || '', qr/Connection: close/i, 'without a Connection: close');
    is($body, 'hello-tunnel;', 'the first write reached the client through the session');
    syswrite $t, 'ping-over-tls';
    Time::HiRes::sleep(0.2);
    is(https('/tunnel-rx'), 'ping-over-tls',
       'what the client sent after the 101 reached the read half, decrypted');
    is(https('/tunnel-close'), 'close=0', 'closing the handle ends the tunnel');
    close $t;
}

kill 'TERM', $pid;
waitpid $pid, 0;
done_testing;
