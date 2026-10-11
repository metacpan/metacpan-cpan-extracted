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

# HTTP/2 hardening: max_body applies to a stream's request body, a Date
# header is sent, an underscored request header name is dropped, a client's
# :scheme does not rewrite psgi.url_scheme, and - over TLS with ALPN - the
# h2 request sees the same HTTPS / SSL_* environment the HTTP/1.1 one does.

plan skip_all => 'nghttp2 support not built' unless Hyperman->has_http2;
my $curl = `which curl 2>/dev/null`;
chomp $curl;
plan skip_all => 'curl not found' unless $curl;
plan skip_all => 'curl lacks HTTP/2'
    unless `curl --version 2>/dev/null` =~ /\bHTTP2\b/;

my ($port, $tport) = free_ports(2);
plan skip_all => "no free loopback port" unless $port && $tport;

my $dir = File::Temp::tempdir(CLEANUP => 1);
my ($cert, $key) = ("$dir/srv.pem", "$dir/srv.key");
my $have_tls = Hyperman->has_tls && `which openssl 2>/dev/null`;
if ($have_tls) {
    system(qq{openssl req -x509 -newkey rsa:2048 -nodes -keyout "$key" -out "$cert" }
         . qq{-days 1 -subj "/CN=localhost" >/dev/null 2>&1});
    $have_tls = -s $cert && -s $key;
}

my $app = sub {
    my $env = shift;
    my $p = $env->{PATH_INFO};
    if ($p eq '/env') {
        my $body = join '|',
            $env->{'psgi.url_scheme'},
            $env->{HTTPS} // 'no-https',
            $env->{SSL_PROTOCOL} // 'no-proto',
            $env->{HTTP_X_FOO} // 'none',
            $env->{HTTP_HOST} // 'none';
        return [ 200, [ 'Content-Type' => 'text/plain' ], [ $body ] ];
    }
    if ($p eq '/upload') {
        my $len = 0;
        while ($env->{'psgi.input'}->read(my $c, 65536)) { $len += length $c }
        return [ 200, [ 'Content-Type' => 'text/plain' ], [ "got $len" ] ];
    }
    [ 404, [], [ 'nope' ] ];
};

my $pid = fork // die "fork: $!";
if (!$pid) {
    quiet_child();
    my @listen = ({ host => '127.0.0.1', port => $port, http2 => 1 });
    push @listen, { host => '127.0.0.1', port => $tport, http2 => 1,
                    tls_cert => $cert, tls_key => $key } if $have_tls;
    Hyperman->run(app => $app, listen => \@listen, workers => 1,
                  max_body => 4096);
    exit 0;
}

for (1 .. 50) {
    my $s = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port");
    last if $s;
    Time::HiRes::sleep(0.1);
}

my $base = "http://127.0.0.1:$port";

{
    my $out = `curl -s --http2-prior-knowledge -H 'X-Foo: good' -H 'X_Foo: evil' "$base/env" 2>/dev/null`;
    is $out, "http|no-https|no-proto|good|127.0.0.1:$port",
        'h2c: cleartext scheme, the underscored header dropped, Host from :authority';
}
{
    my $hdrs = `curl -s -D - -o /dev/null --http2-prior-knowledge "$base/env" 2>/dev/null`;
    like $hdrs, qr/^date: [A-Z][a-z]{2}, \d\d [A-Z][a-z]{2} \d{4} \d\d:\d\d:\d\d GMT\r?$/m,
        'h2 responses carry a Date header';
}
{
    my $small = "x" x 1000;
    my $code = `curl -s -o /dev/null -w '%{http_code}' --http2-prior-knowledge --data-binary '$small' "$base/upload" 2>/dev/null`;
    is $code, '200', 'a body under max_body is accepted over h2';
    my $f = "$dir/big";
    open my $fh, '>', $f or die $!;
    print $fh "y" x 65536;
    close $fh;
    $code = `curl -s -o /dev/null -w '%{http_code}' --http2-prior-knowledge --data-binary \@$f "$base/upload" 2>/dev/null`;
    is $code, '413', 'a body over max_body is refused with 413 over h2';
    my $out = `curl -s --http2-prior-knowledge "$base/env" 2>/dev/null`;
    like $out, qr/\Ahttp\|/, 'the connection and worker are fine afterwards';
}

SKIP: {
    skip 'no TLS in this build, or no openssl CLI', 2 unless $have_tls;
    my $out = `curl -sk --http2 "https://127.0.0.1:$tport/env" 2>/dev/null`;
    like $out, qr/\Ahttps\|on\|TLSv1\.[23]\|/,
        'over ALPN h2 the request sees HTTPS=on and SSL_PROTOCOL';
    my $v = `curl -sk -v --http2 "https://127.0.0.1:$tport/env" 2>&1`;
    like $v, qr/using HTTP\/2|ALPN.*h2/i, '...and it really was HTTP/2';
}

kill 'TERM', $pid;
waitpid $pid, 0;
done_testing;
