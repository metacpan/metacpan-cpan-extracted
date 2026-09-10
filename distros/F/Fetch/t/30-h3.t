#!perl
use strict;
use warnings;
use Test::More;
use Fetch;
use IO::Socket::INET;
use File::Temp ();
use POSIX ();

# The HTTP/3 client (include/fetch/ft_h3.h), against a real Hyperman.
#
# Modelled on t/06-h2.t, which is the closest thing here: a forked TLS server,
# a self-signed certificate made with `openssl req`, and skips rather than
# failures wherever the stack is not present. QUIC needs more of it than h2 -
# ngtcp2, nghttp3 and an OpenSSL new enough to hand them its handshake - so
# there are more ways for this file to skip and none of them are a defect.
#
# Three claims are made, and the middle one is the one that is easy to leave
# untested:
#
#   1. a request goes over HTTP/3 at all
#   2. an Alt-Svc header on a response that came back over TCP is what steers
#      a LATER request to h3 - there is no h3:// scheme, so this is the whole
#      discovery mechanism and without it the transport is unreachable
#   3. concurrent requests share ONE connection, unlike HTTP/2 here, which
#      does one request per connection and would make an h3 connection worse
#      than keep-alive

plan skip_all => 'Fetch built without ngtcp2 + nghttp3'
    unless Fetch::_h3_available();
plan skip_all => 'Hyperman required for a server to talk to'
    unless eval { require Hyperman; 1 };
plan skip_all => 'Hyperman built without HTTP/3'
    unless Hyperman->has_http3;
my $openssl = `which openssl 2>/dev/null`;
chomp $openssl;
plan skip_all => 'openssl CLI not found' unless $openssl;

my $dir  = File::Temp::tempdir(CLEANUP => 1);
my $cert = "$dir/cert.pem";
my $key  = "$dir/key.pem";
system(qq{openssl req -x509 -newkey rsa:2048 -nodes -keyout "$key" }
     . qq{-out "$cert" -days 1 -subj "/CN=localhost" >/dev/null 2>&1});
plan skip_all => 'could not create a self-signed cert'
    unless -s $cert && -s $key;

# A port free for BOTH TCP and UDP: HTTP/3 lives on the UDP port of the same
# number the TCP listener uses, and Alt-Svc advertises it as such.
my $port;
for (1 .. 20) {
    my $t = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => 0,
                                  Proto => 'tcp', Listen => 5, ReuseAddr => 1)
        or next;
    my $p = $t->sockport;
    close $t;
    my $u = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => $p,
                                  Proto => 'udp') or next;
    close $u;
    $port = $p;
    last;
}
plan skip_all => 'no port free on both TCP and UDP' unless $port;

my $pid = fork;
plan skip_all => "fork: $!" unless defined $pid;
if (!$pid) {
    # Nothing in the child may hold the harness's TAP pipe, or `make test`
    # hangs on a read that never sees EOF. Test::Builder dups it into its own
    # handles at load, so those go too, and the alarm is the backstop.
    open STDOUT, '>', '/dev/null';
    open STDERR, '>', "$dir/server.err";
    if (my $tb = eval { Test::Builder->new }) {
        for my $h (eval { $tb->output }, eval { $tb->failure_output },
                   eval { $tb->todo_output }) {
            close $h if defined $h;
        }
    }
    alarm 60;
    Hyperman->run(
        app => sub {
            my $env = shift;
            [ 200, [ 'Content-Type' => 'text/plain' ],
              [ "$env->{PATH_INFO}|$env->{SERVER_PROTOCOL}" ] ];
        },
        host => '127.0.0.1', port => $port, workers => 1,
        http2 => 1, http3 => 1, tls_cert => $cert, tls_key => $key,
    );
    POSIX::_exit(0);
}

# Wait for the TCP half to answer; the UDP half comes up with it.
for (1 .. 60) {
    my $s = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port", Proto => 'tcp');
    last if $s;
    select undef, undef, undef, 0.1;
}

my $base = "https://127.0.0.1:$port";

# ---- the transport on its own, before any discovery -------------------------
#
# Driven through the C entry point rather than through $ua->get, so that this
# says something even if the Alt-Svc half below is broken: it is the transport
# that is being tested here, not the plumbing that chooses it.
{
    my $loop = Fetch::Loop::Standalone->new;
    $loop->install_await;
    my $pool = Fetch::_pool_new(4);
    my $f = Fetch::_h3_request($loop, $pool, '127.0.0.1', $port, 0, 10,
                               'GET', 'https', "127.0.0.1:$port", '/direct',
                               [], undef, undef);
    my $r = eval { $f->get };
    ok($r, 'a request completes over HTTP/3') or diag($@);
    SKIP: {
        skip 'no response', 2 unless $r;
        is($r->status, 200, '...with the status the server sent');
        is($r->content, '/direct|HTTP/3',
           '...and the server saw it arrive as HTTP/3');
    }
}

# ---- multiplexing: N requests, one connection -------------------------------
{
    my $loop = Fetch::Loop::Standalone->new;
    $loop->install_await;
    my $pool = Fetch::_pool_new(4);
    my @f = map {
        Fetch::_h3_request($loop, $pool, '127.0.0.1', $port, 0, 10,
                           'GET', 'https', "127.0.0.1:$port", "/mux$_",
                           [], undef, undef)
    } 1 .. 5;

    # None of them can have finished yet: they were all started before the
    # loop ran at all. Inline, one at a time, the first would already be done.
    is(scalar(grep { $_->is_ready } @f), 0,
       'five requests are all outstanding when the calls return');

    my @got = map { my $r = eval { $_->get }; $r ? $r->content : "ERR:$@" } @f;
    is(scalar(grep { /^\/mux\d\|HTTP\/3$/ } @got), 5,
       'all five complete over HTTP/3');

    # The claim that matters: one QUIC connection carried all five. A second
    # connection would mean a second UDP socket, so count them.
    my $udp = `lsof -p $$ 2>/dev/null | grep -c UDP`;
    chomp $udp;
    SKIP: {
        skip 'lsof unavailable', 1 unless $udp =~ /^\d+$/ && $udp > 0;
        is($udp + 0, 1,
           'and they shared ONE connection - which HTTP/2 here does not do');
    }
}

# ---- discovery: Alt-Svc steers a LATER request to h3 ------------------------
#
# The first request has no way to know h3 exists and goes over TCP. Its
# response carries Alt-Svc, which is recorded; the second request finds it and
# goes over QUIC. Without this, ft_h3.h is unreachable from an ordinary get.
{
    my $ua = Fetch->new(timeout => 10);
    my $first = eval { $ua->get("$base/one", tls_verify => 0)->get };
    ok($first, 'the first request is served over TCP') or diag($@);
    SKIP: {
        skip 'no first response', 3 unless $first;
        like($first->content, qr{^/one\|HTTP/(?:1\.1|2)$},
             '...over HTTP/1.1 or HTTP/2, because nothing yet says otherwise');

        my $second = eval { $ua->get("$base/two", tls_verify => 0)->get };
        ok($second, 'a second request to the same origin is served') or diag($@);
        SKIP: {
            skip 'no second response', 1 unless $second;
            is($second->content, '/two|HTTP/3',
               '...over HTTP/3, because the first response advertised it');
        }
    }
}

kill 'TERM', $pid;
waitpid $pid, 0;

done_testing;
