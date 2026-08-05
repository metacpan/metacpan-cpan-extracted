#!perl
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use Time::HiRes ();
use Hyperman;

# Request-framing hardening against HTTP request smuggling (RFC 7230 3.3.3):
#  - Transfer-Encoding is not implemented -> 501 (never mis-frame chunk data
#    as a following pipelined request).
#  - a duplicate or malformed Content-Length -> 400.
# A well-formed request with one valid Content-Length is served normally, and
# no smuggled second request leaks through on the same connection.

my $port = 24500 + ($$ % 400);

my $pid = fork // die "fork: $!";
if (!$pid) {
    open STDERR, '>', '/dev/null';
    Hyperman->run(
        app => sub {
            my $env = shift;
            my $body = '';
            $env->{'psgi.input'}->read($body, $env->{CONTENT_LENGTH} || 0)
                if $env->{'psgi.input'} && $env->{CONTENT_LENGTH};
            [ 200, [ 'Content-Type' => 'text/plain' ],
              [ "ok:$env->{REQUEST_METHOD}:$body" ] ];
        },
        host => '127.0.0.1', port => $port, workers => 1,
    );
    exit 0;
}

for (1 .. 50) {
    my $s = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port");
    last if $s;
    Time::HiRes::sleep(0.1);
}

# Send raw bytes, read the whole (Connection: close) response.
sub raw {
    my $req = shift;
    my $s = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port") or return '';
    $s->syswrite($req);
    my $buf = '';
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm 3;
        while (my $n = $s->sysread(my $c, 4096)) { $buf .= $c }
        alarm 0;
    };
    return $buf;
}

sub status { (($_[0] // '') =~ m{\AHTTP/1\.\d (\d\d\d)}) ? $1 : 'none' }

# Baseline: a normal request with a single valid Content-Length works.
my $ok = raw("POST / HTTP/1.1\r\nHost: a\r\nContent-Length: 5\r\n"
           . "Connection: close\r\n\r\nhello");
is(status($ok), '200', 'valid single Content-Length is served');
like($ok, qr/ok:POST:hello/, 'body framed correctly by Content-Length');

# Transfer-Encoding: chunked is decoded, and the chunk framing must NOT leak a
# smuggled second request (only one HTTP response on the wire).
my $te = raw("POST / HTTP/1.1\r\nHost: a\r\nTransfer-Encoding: chunked\r\n"
           . "Connection: close\r\n\r\n5\r\nhello\r\n0\r\n\r\n");
is(status($te), '200', 'Transfer-Encoding: chunked is decoded and served');
like($te, qr/ok:POST:hello/, 'single-chunk body decoded correctly');
is(scalar(() = $te =~ /HTTP\/1\.\d \d\d\d/g), 1,
   'no smuggled second response from the chunk framing');

# Multi-chunk body (with a chunk-extension and mixed-case hex) reassembles.
my $multi = raw("POST / HTTP/1.1\r\nHost: a\r\nTransfer-Encoding: chunked\r\n"
              . "Connection: close\r\n\r\n"
              . "3;x=1\r\nfoo\r\nB\r\nbarbazquux!\r\n0\r\n\r\n");
like($multi, qr/ok:POST:foobarbazquux!/, 'multi-chunk body (with chunk-ext) reassembled');

# Pipelining: a chunked body on a keep-alive connection must consume exactly
# its encoded bytes, so a request pipelined right after is framed correctly.
{
    my $s = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port") or die;
    $s->syswrite(
        "POST /a HTTP/1.1\r\nHost: a\r\nTransfer-Encoding: chunked\r\n\r\n"
      . "3\r\nfoo\r\n0\r\n\r\n"
      . "GET /b HTTP/1.1\r\nHost: a\r\nConnection: close\r\n\r\n");
    my $buf = '';
    eval { local $SIG{ALRM} = sub { die }; alarm 3;
           while (my $n = $s->sysread(my $c, 4096)) { $buf .= $c } alarm 0; };
    is(scalar(() = $buf =~ /ok:/g), 2, 'chunked body then pipelined request: two clean responses');
    like($buf, qr/ok:POST:foo/, 'pipelined: chunked POST body decoded');
    like($buf, qr/ok:GET:/,     'pipelined: following GET framed correctly');
}

# Unsupported transfer coding -> 501.
is(status(raw("POST / HTTP/1.1\r\nHost: a\r\nTransfer-Encoding: gzip\r\n\r\n")),
   '501', 'an unsupported Transfer-Encoding is 501');

# Transfer-Encoding together with Content-Length -> 400 (TE.CL smuggling).
is(status(raw("POST / HTTP/1.1\r\nHost: a\r\nContent-Length: 5\r\n"
            . "Transfer-Encoding: chunked\r\n\r\n0\r\n\r\n")),
   '400', 'Transfer-Encoding + Content-Length together is rejected');

# Malformed chunk size (non-hex) -> 400.
is(status(raw("POST / HTTP/1.1\r\nHost: a\r\nTransfer-Encoding: chunked\r\n"
            . "Connection: close\r\n\r\nZZ\r\nhello\r\n0\r\n\r\n")),
   '400', 'malformed chunk size is rejected');

# Two conflicting Content-Length headers -> 400.
my $dup = raw("POST / HTTP/1.1\r\nHost: a\r\nContent-Length: 5\r\n"
            . "Content-Length: 6\r\n\r\nhello!");
is(status($dup), '400', 'duplicate Content-Length is rejected');

# Malformed Content-Length values -> 400.
is(status(raw("POST / HTTP/1.1\r\nHost: a\r\nContent-Length: 5abc\r\n\r\n")),
   '400', 'Content-Length with trailing junk is rejected');
is(status(raw("POST / HTTP/1.1\r\nHost: a\r\nContent-Length: +5\r\n\r\n")),
   '400', 'Content-Length with a sign is rejected');
is(status(raw("POST / HTTP/1.1\r\nHost: a\r\nContent-Length: -1\r\n\r\n")),
   '400', 'negative Content-Length is rejected');

kill 'TERM', $pid;
waitpid $pid, 0;
done_testing;
