#!perl
use strict;
use warnings;
use Test::More;
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

my $port = 23000 + ($$ % 1000);

my $pid = fork;
die "fork: $!" unless defined $pid;
if ($pid == 0) {
    open STDERR, '>', '/dev/null';
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

kill 'TERM', $pid;
waitpid $pid, 0;
done_testing;
