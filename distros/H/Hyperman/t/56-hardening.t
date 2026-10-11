#!perl
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use HMTest qw(free_ports quiet_child);
use IO::Socket::INET;
use Time::HiRes ();
use Hyperman;

# The HTTP/1.1 hardening pass:
#  - HEAD answers with the GET's headers and no body, and the connection
#    stays in frame for the next request
#  - every response carries a Date header
#  - a request header with an underscore in its name is dropped (it would
#    alias the hyphenated name in $env)
#  - whitespace before a header's colon, a bare LF in the header block and a
#    chunk-size line of unbounded digits are all 400
#  - a leading CRLF before the request line is ignored
#  - an application header carrying CR or LF is refused as a 500, and a hole
#    in the header array is skipped rather than dereferenced
#  - REMOTE_ADDR assigned by one request does not leak into the next on the
#    same keep-alive connection
#  - a synchronous handler that awaits survives its client leaving, a die
#    inside a timer callback does not take the loop down, and a writer
#    dropped without close still ends its connection
#  - a response that sets a cookie is never compressed

my ($port) = free_ports(1);
plan skip_all => "no free loopback port" unless $port;

my $BIG = join '', map { "line $_ of a body that compresses well\n" } 1 .. 200;

my $pid = fork // die "fork: $!";
if (!$pid) {
    quiet_child();
    Hyperman->run(
        app => sub {
            my $env = shift;
            my $p = $env->{PATH_INFO};
            if ($p eq '/echo') {
                my $body = join '|',
                    $env->{REQUEST_METHOD},
                    $env->{REMOTE_ADDR} // 'none',
                    $env->{HTTP_X_FOO} // 'none',
                    $env->{HTTP_X_FORWARDED_FOR} // 'none';
                return [ 200, [ 'Content-Type' => 'text/plain' ], [ $body ] ];
            }
            if ($p eq '/setaddr') {
                $env->{REMOTE_ADDR} = '10.0.0.1';
                return [ 200, [ 'Content-Type' => 'text/plain' ],
                         [ $env->{REMOTE_ADDR} ] ];
            }
            if ($p eq '/badhdr') {
                return [ 200, [ 'Content-Type' => 'text/plain',
                                'X-Inject' => "a\r\nSet-Cookie: pwned=1" ],
                         [ 'never' ] ];
            }
            if ($p eq '/holey') {
                my @h = ('Content-Type', 'text/plain');
                $#h = 3;                    # two undef slots
                return [ 200, \@h, [ 'holey' ] ];
            }
            if ($p eq '/await') {
                Hyperman->timer(0.3)->get;  # pumps the loop re-entrantly
                return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'late' ] ];
            }
            if ($p eq '/die') { die "handler died\n" }
            if ($p eq '/timerdie') {
                Hyperman->loop->timer(0.01, sub { die "timer died\n" });
                return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'armed' ] ];
            }
            if ($p eq '/drop') {
                return sub {
                    my $respond = shift;
                    my $w = $respond->([ 200, [ 'Content-Type' => 'text/plain' ] ]);
                    $w->write('partial');
                    # $w goes out of scope here without ->close
                };
            }
            if ($p eq '/cookie') {
                return [ 200, [ 'Content-Type' => 'text/plain',
                                'Set-Cookie'   => 'sid=abc; Path=/' ], [ $BIG ] ];
            }
            if ($p eq '/big') {
                return [ 200, [ 'Content-Type' => 'text/plain' ], [ $BIG ] ];
            }
            [ 404, [ 'Content-Type' => 'text/plain' ], [ 'nope' ] ];
        },
        host => '127.0.0.1', port => $port, workers => 1,
        compress => 1, compress_min_length => 100,
    );
    exit 0;
}

for (1 .. 50) {
    my $s = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port");
    last if $s;
    Time::HiRes::sleep(0.1);
}

sub connect_to {
    IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port") or die "connect: $!";
}

# Read one response off $s: returns (status, \%headers, body). Framed by
# Content-Length, or to EOF when there is none; a HEAD response ($want_body
# false) has no body, and whatever followed its headers is kept for the
# next call on the same socket.
my %pending;
sub read_response {
    my ($s, $want_body) = @_;
    $want_body = 1 unless defined $want_body;
    my $buf = delete $pending{fileno $s} // '';
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm 5;
        until ($buf =~ /\r\n\r\n/) {
            my $n = $s->sysread(my $c, 4096);
            last unless $n;
            $buf .= $c;
        }
        alarm 0;
    };
    return ('none', {}, '') unless $buf =~ s{\A(.*?)\r\n\r\n}{}s;
    my $head = $1;
    my ($status) = $head =~ m{\AHTTP/1\.\d (\d\d\d)};
    my %h;
    for (split /\r\n/, $head) {
        next unless /\A([^:]+):\s*(.*)\z/;
        $h{lc $1} = $2;
    }
    if (!$want_body) {
        $pending{fileno $s} = $buf;
        return ($status, \%h, '');
    }
    my $body = $buf;
    my $cl = $h{'content-length'};
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm 5;
        if (defined $cl) {
            while (length($body) < $cl) {
                my $n = $s->sysread(my $c, 4096);
                last unless $n;
                $body .= $c;
            }
        } else {
            while (my $n = $s->sysread(my $c, 4096)) { $body .= $c }
        }
        alarm 0;
    };
    if (defined $cl && length($body) > $cl) {
        $pending{fileno $s} = substr($body, $cl);
        $body = substr($body, 0, $cl);
    }
    return ($status, \%h, $body);
}

sub raw {
    my ($req) = @_;
    my $s = connect_to();
    $s->syswrite($req);
    my @r = read_response($s);
    close $s;
    return @r;
}

# ---- HEAD and Date ---------------------------------------------------------
{
    my $s = connect_to();
    $s->syswrite("HEAD /echo HTTP/1.1\r\nHost: t\r\n\r\n"
               . "GET /echo HTTP/1.1\r\nHost: t\r\n\r\n");
    my ($st, $h, $body) = read_response($s, 0);
    is $st, 200, 'HEAD is answered';
    ok $h->{'content-length'} > 0, 'HEAD carries the GET\'s Content-Length';
    like $h->{date}, qr/\A[A-Z][a-z]{2}, \d\d [A-Z][a-z]{2} \d{4} \d\d:\d\d:\d\d GMT\z/,
        'Date header is an IMF-fixdate';
    my ($st2, $h2, $body2) = read_response($s);
    is $st2, 200, 'the pipelined GET behind the HEAD was framed correctly';
    like $body2, qr/\AGET\|127\.0\.0\.1\|/, '...and answered with its body';
    close $s;
}

# ---- request header hygiene ------------------------------------------------
{
    my ($st, $h, $body) = raw("GET /echo HTTP/1.1\r\nHost: t\r\n"
                            . "X-Foo: good\r\nX_Foo: evil\r\n"
                            . "X_Forwarded_For: 1.2.3.4\r\n\r\n");
    is $st, 200, 'underscored header names: request served';
    is $body, 'GET|127.0.0.1|good|none',
        'the underscored names were dropped, the hyphenated one kept';
}
{
    my ($st) = raw("GET /echo HTTP/1.1\r\nHost: t\r\nContent-Length : 5\r\n\r\nhello");
    is $st, 400, 'whitespace before a header colon is 400';
}
{
    my ($st) = raw("GET /echo HTTP/1.1\r\nHost: t\r\nX-A: x\nContent-Length: 5\r\n\r\nhello");
    is $st, 400, 'a bare LF inside the header block is 400';
}
{
    my ($st) = raw("POST /echo HTTP/1.1\r\nHost: t\r\nTransfer-Encoding: chunked\r\n\r\n"
                 . ("0" x 40) . "1\r\nX\r\n0\r\n\r\n");
    is $st, 400, 'a chunk-size line of forty digits is 400';
}
{
    my ($st, $h, $body) = raw("\r\n\r\nGET /echo HTTP/1.1\r\nHost: t\r\n\r\n");
    is $st, 200, 'leading CRLFs before the request line are ignored';
    like $body, qr/\AGET\|/, '...and the method is the real one';
}

# ---- response header hygiene ----------------------------------------------
{
    my ($st, $h) = raw("GET /badhdr HTTP/1.1\r\nHost: t\r\n\r\n");
    is $st, 500, 'a header value carrying CRLF is refused as a 500';
    ok !exists $h->{'set-cookie'}, '...and the injected header never left';
}
{
    my ($st, $h, $body) = raw("GET /holey HTTP/1.1\r\nHost: t\r\n\r\n");
    is $st, 200, 'a hole in the header array is skipped';
    is $body, 'holey', '...and the body is served';
}

# ---- REMOTE_ADDR does not leak across keep-alive requests -------------------
{
    my $s = connect_to();
    $s->syswrite("GET /setaddr HTTP/1.1\r\nHost: t\r\n\r\n");
    my ($st, $h, $body) = read_response($s);
    is $body, '10.0.0.1', 'the handler rewrote REMOTE_ADDR for its own request';
    $s->syswrite("GET /echo HTTP/1.1\r\nHost: t\r\n\r\n");
    ($st, $h, $body) = read_response($s);
    like $body, qr/\AGET\|127\.0\.0\.1\|/,
        'the next request on the connection sees the real peer address';
    close $s;
}

# ---- loop re-entrancy and callback failures --------------------------------
{
    my $s = connect_to();
    $s->syswrite("GET /await HTTP/1.1\r\nHost: t\r\n\r\n");
    close $s;                       # leave while the handler is awaiting
    Time::HiRes::sleep(0.5);
    my ($st, $h, $body) = raw("GET /echo HTTP/1.1\r\nHost: t\r\n\r\n");
    is $st, 200, 'the worker survives a client leaving mid-await';
    ($st, $h, $body) = raw("GET /await HTTP/1.1\r\nHost: t\r\n\r\n");
    is $body, 'late', 'a synchronous await still answers a patient client';
}
{
    my ($st) = raw("GET /die HTTP/1.1\r\nHost: t\r\n\r\n");
    is $st, 500, 'a handler that dies is a 500';
    ($st) = raw("GET /timerdie HTTP/1.1\r\nHost: t\r\n\r\n");
    is $st, 200, 'a timer whose callback will die is armed';
    Time::HiRes::sleep(0.1);
    my (undef, undef, $body) = raw("GET /echo HTTP/1.1\r\nHost: t\r\n\r\n");
    like $body, qr/\AGET\|/, 'the loop is still serving after the timer callback died';
}
{
    my $s = connect_to();
    $s->syswrite("GET /drop HTTP/1.1\r\nHost: t\r\n\r\n");
    my $t0 = Time::HiRes::time();
    my ($st, $h, $body) = read_response($s);
    is $st, 200, 'a streaming response began';
    is $body, 'partial', 'the dropped writer ended the body (EOF arrived)';
    cmp_ok Time::HiRes::time() - $t0, '<', 4, '...promptly, not at the read timeout';
    close $s;
}

# ---- compression leaves a Set-Cookie response alone -------------------------
SKIP: {
    skip 'no zlib in this build', 2 unless Hyperman->has_compression;
    my ($st, $h) = raw("GET /big HTTP/1.1\r\nHost: t\r\nAccept-Encoding: gzip\r\n\r\n");
    is $h->{'content-encoding'}, 'gzip', 'a plain large body is compressed';
    ($st, $h) = raw("GET /cookie HTTP/1.1\r\nHost: t\r\nAccept-Encoding: gzip\r\n\r\n");
    ok !exists $h->{'content-encoding'}, 'the same body with Set-Cookie is not';
}

kill 'TERM', $pid;
waitpid $pid, 0;
done_testing;
