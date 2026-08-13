#!perl
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use HMTest qw(free_ports);

unless ( $ENV{HM_LISTEN_TESTS} ) {
    plan( skip_all => "multi-listener tests skipped; set HM_LISTEN_TESTS to run" );
}

use IO::Socket::INET;
use Time::HiRes ();
use Hyperman;

# Multiple listeners in one run(): several plain ports, a built-in
# https-redirect port, and (when OpenSSL is built) a TLS port beside a plain
# one in the same server.

my ($p1, $p2, $p3) = free_ports(3);
plan skip_all => "no free loopback ports" unless $p3;

sub wait_up {
    my $port = shift;
    for (1 .. 50) {
        my $s = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port");
        return 1 if $s;
        Time::HiRes::sleep(0.1);
    }
    return 0;
}

# Send a raw request and slurp the whole (Connection: close) response.
sub req {
    my ($port, $raw) = @_;
    my $s = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port") or return '';
    $s->print($raw);
    my $buf = '';
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm 3;
        while (my $n = $s->sysread(my $c, 4096)) { $buf .= $c }
        alarm 0;
    };
    return $buf;
}

my $pid = fork // die "fork: $!";
if (!$pid) {
    open STDERR, '>', '/dev/null';
    Hyperman->run(
        app => sub {
            my $env = shift;
            [ 200, [ 'Content-Type' => 'text/plain' ],
              [ "port:$env->{SERVER_PORT}" ] ];
        },
        workers => 1,
        listen  => [
            { host => '127.0.0.1', port => $p1 },
            { host => '127.0.0.1', port => $p2 },
            { host => '127.0.0.1', port => $p3, redirect_https => 8443 },
        ],
    );
    exit 0;
}

wait_up($_) or BAIL_OUT("port $_ never came up") for ($p1, $p2, $p3);

like(req($p1, "GET / HTTP/1.0\r\nHost: a\r\n\r\n"), qr/port:$p1/,
     'listener 1 serves the app, SERVER_PORT is its own port');
like(req($p2, "GET / HTTP/1.0\r\nHost: a\r\n\r\n"), qr/port:$p2/,
     'listener 2 serves the app on its own port in the same run');

my $r3 = req($p3, "GET /foo?x=1 HTTP/1.0\r\nHost: example.test:80\r\n\r\n");
like($r3, qr{^HTTP/1\.1 301}, 'redirect listener answers 301');
like($r3, qr{Location:\s*https://example\.test:8443/foo\?x=1}i,
     'redirect strips the Host port and targets the https port + full URI');
unlike($r3, qr/port:/, 'the app is never invoked on a redirect listener');

# A Host header carrying a bare LF must not inject a header into the 301
# response (response-splitting via the reflected Location).
my $inj = req($p3, "GET /x HTTP/1.0\r\nHost: good.test\x0aSet-Cookie: pwned=1\r\n\r\n");
like($inj,   qr{^HTTP/1\.1 301}, 'redirect still answers 301 on a malformed Host');
unlike($inj, qr/Set-Cookie/i,   'bare-LF Host does not inject a response header');
like($inj,   qr{Location:\s*https://good\.test:8443/x\b},
     'reflected Host is truncated at the injected LF');

kill 'TERM', $pid;
waitpid $pid, 0;

# TLS listener beside a plain listener in one run().
SKIP: {
    skip 'OpenSSL support not built', 3 unless Hyperman->has_tls;
    my $openssl = `which openssl`; chomp $openssl;
    skip 'openssl CLI not found', 3 unless $openssl;
    my $curl = `which curl`; chomp $curl;
    skip 'curl not found', 3 unless $curl;

    require File::Temp;
    my $dir  = File::Temp::tempdir(CLEANUP => 1);
    my $cert = "$dir/cert.pem";
    my $key  = "$dir/key.pem";
    system(qq{openssl req -x509 -newkey rsa:2048 -nodes -keyout "$key" -out "$cert" }
         . qq{-days 1 -subj "/CN=localhost" >/dev/null 2>&1});
    skip 'could not create self-signed cert', 3 unless -s $cert && -s $key;

    my ($hp, $sp) = free_ports(2);
    skip 'no free loopback ports', 3 unless $sp;
    my $pid2 = fork // die "fork: $!";
    if (!$pid2) {
        open STDERR, '>', '/dev/null';
        Hyperman->run(
            app => sub {
                my $env = shift;
                [ 200, [ 'Content-Type' => 'text/plain' ],
                  [ "scheme:$env->{'psgi.url_scheme'}" ] ];
            },
            workers => 1,
            listen  => [
                { host => '127.0.0.1', port => $hp },
                { host => '127.0.0.1', port => $sp,
                  tls_cert => $cert, tls_key => $key },
            ],
        );
        exit 0;
    }
    wait_up($_) for ($hp, $sp);

    like(req($hp, "GET / HTTP/1.0\r\nHost: a\r\n\r\n"), qr/scheme:http\b/,
         'plain listener serves http alongside a TLS listener');
    like(`curl -sk "https://127.0.0.1:$sp/" 2>/dev/null`, qr/scheme:https/,
         'TLS listener serves https in the same run');
    is(`curl -sk "https://127.0.0.1:$hp/" 2>/dev/null`, '',
       'an https handshake fails on the plain listener');

    kill 'TERM', $pid2;
    waitpid $pid2, 0;
}

done_testing;
