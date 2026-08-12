#!perl
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use Time::HiRes ();
use Hyperman;

# HTTP/2 (h2c, prior-knowledge) via nghttp2. Requires the nghttp2 build and an
# HTTP/2-capable curl for the client side; skips cleanly otherwise.

plan skip_all => 'nghttp2 support not built' unless Hyperman->has_http2;

my $curl = `which curl 2>/dev/null`;
chomp $curl;
plan skip_all => 'curl not found' unless $curl;
plan skip_all => 'curl lacks HTTP/2'
    unless `curl --version 2>/dev/null` =~ /\bHTTP2\b/;

my $port = 22000 + ($$ % 1000);

my $pid = fork;
die "fork: $!" unless defined $pid;
if ($pid == 0) {
    open STDERR, '>', '/dev/null';
    require Hyperman;
    Hyperman->run(
        app => sub {
            my $env = shift;
            my $p = $env->{PATH_INFO};
            if ($p eq '/proto') {
                return [ 200, [ 'Content-Type' => 'text/plain' ],
                         [ $env->{SERVER_PROTOCOL} ] ];
            }
            if ($p eq '/echo') {
                my $body = '';
                $env->{'psgi.input'}->read($body, $env->{CONTENT_LENGTH} || 0)
                    if $env->{'psgi.input'};
                return [ 200, [ 'Content-Type' => 'text/plain' ], [ "echo:$body" ] ];
            }
            if ($p eq '/query') {
                return [ 200, [ 'Content-Type' => 'text/plain' ],
                         [ "q=$env->{QUERY_STRING} path=$env->{PATH_INFO}" ] ];
            }
            if ($p eq '/async') {
                return Hyperman->timer(0.05)->then(sub {
                    [ 200, [ 'Content-Type' => 'text/plain' ], [ 'async-h2' ] ];
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
            [ 404, [ 'Content-Type' => 'text/plain' ], [ 'nope' ] ];
        },
        host => '127.0.0.1', port => $port, workers => 1, http2 => 1,
    );
    exit 0;
}

# wait for listen
for (1 .. 50) {
    my $s = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port");
    last if $s;
    Time::HiRes::sleep(0.1);
}

sub h2 {
    my ($path, @extra) = @_;
    my $url = "http://127.0.0.1:$port$path";
    my $out = `curl -s --http2-prior-knowledge @extra "$url" 2>/dev/null`;
    return $out;
}

is(h2('/proto'), 'HTTP/2', 'SERVER_PROTOCOL is HTTP/2 over h2c (prior knowledge)');

# HTTP/1.1 Upgrade: h2c dance (curl --http2, without prior knowledge)
{
    my $out = `curl -s --http2 "http://127.0.0.1:$port/proto" 2>/dev/null`;
    is($out, 'HTTP/2', 'SERVER_PROTOCOL is HTTP/2 after h2c Upgrade');
    my $v = `curl -s -v --http2 "http://127.0.0.1:$port/proto" 2>&1`;
    like($v, qr/101 Switching Protocols/, 'server sent 101 Switching Protocols');
}
is(h2('/query?a=1&b=2'), 'q=a=1&b=2 path=/query', 'path/query split over h2');
is(h2('/echo', '-d', 'hello=world'), 'echo:hello=world', 'request body over h2');
is(h2('/async'), 'async-h2', 'Future-returning handler over h2');
is(h2('/stream'), 'chunk1;chunk2', 'psgi.streaming (buffered) over h2');

# multiplexing: many streams on one connection (curl reuses the h2 conn),
# with --parallel to issue them concurrently.
#
# --parallel arrived in curl 7.66. An older curl rejects the option and
# writes nothing at all to stdout, which counted as 0 of 20 answered - a
# FAIL that said "the server dropped 20 streams" when the server was never
# asked. Without it the same URL list still goes down a single connection
# as consecutive streams, so what is lost is the concurrency, not the
# multiplexing.
{
    my $parallel = system('curl --parallel --version >/dev/null 2>&1') == 0
        ? '--parallel' : '';
    my @urls = map { "http://127.0.0.1:$port/query?n=$_" } 1 .. 20;
    my $cmd  = "curl -s --http2-prior-knowledge $parallel "
             . join(' ', map { "'$_'" } @urls);
    my $out  = `$cmd 2>/dev/null`;
    my $count = () = $out =~ /path=\/query/g;
    is($count, 20, $parallel
        ? 'multiplexed concurrent streams all answered'
        : 'multiplexed streams all answered (serial; curl has no --parallel)');
}

kill 'TERM', $pid;
waitpid $pid, 0;
done_testing;
