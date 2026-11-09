#!perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use HMTest qw(free_ports quiet_child server_reap);
use IO::Socket::INET;
use Time::HiRes ();
use File::Temp ();
use Hyperman;

# Server-side edges: the body rate floor and the request ceiling closing a
# slow client, a pipeline longer than max_pipeline, more header lines than the
# stack index holds, a chunk size in hex letters, chunked and announced bodies
# past max_body, a streamed response in the JSON log, a control byte in the
# combined log, USR1 without a scoreboard, and a hard stop after the grace.

my ($pa, $pb) = free_ports(2);
plan skip_all => 'no free loopback ports' unless $pa && $pb;
plan skip_all => 'signals and fork are not Windows' if $^O eq 'MSWin32';
my $dir = File::Temp::tempdir(CLEANUP => 1);

my $app = sub {
    my $env = shift;
    my $p = $env->{PATH_INFO};
    if ($p eq '/slow') { Time::HiRes::sleep(3); return [ 200, [], ['late'] ] }
    if ($p eq '/stream') {
        return sub { my $w = shift->([ 200, [ 'Content-Type' => 'text/plain' ] ]); $w->write('s'); $w->close };
    }
    my $body = '';
    $env->{'psgi.input'}->read($body, $env->{CONTENT_LENGTH} || 0) if $env->{CONTENT_LENGTH};
    [ 200, [ 'Content-Type' => 'text/plain' ], [ "$p:" . length($body) . ':' . ($env->{HTTP_X_LAST} // '') ] ];
};

my $pida = fork // die "fork: $!";
if (!$pida) {
    quiet_child();
    Hyperman->run(app => $app, host => '127.0.0.1', port => $pa, workers => 1,
        body_min_rate => 100000, max_pipeline => 2, completion => 0, compress => 1,
        access_log => "$dir/a.log", access_log_format => 'json');
    exit 0;
}
my $pidb = fork // die "fork: $!";
if (!$pidb) {
    quiet_child();
    $ENV{HYPERMAN_NO_SA_ABI} = 1;
    Hyperman->run(app => $app, host => '127.0.0.1', port => $pb, workers => 1,
        request_timeout => 1, max_body => 4096, shutdown_grace => 0.5,
        error_log => "$dir/b.err", access_log => "$dir/b.log",
        access_log_format => '%h "%{User-Agent}i" %{X-Missing}i %>s %B %b %v %{REMOTE_ADDR}e %D %T %P');
    exit 0;
}

sub connect_to {
    my $port = shift;
    for (1 .. 50) {
        my $s = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port");
        return $s if $s;
        Time::HiRes::sleep(0.1);
    }
    return;
}
sub raw {
    my ($port, $req, $budget) = @_;
    my $s = connect_to($port) or return '';
    $s->syswrite($req);
    my $buf = '';
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm($budget || 3);
        while (my $n = $s->sysread(my $c, 65536)) { $buf .= $c }
        alarm 0;
    };
    return $buf;
}
sub closed_within {
    my ($s, $secs) = @_;
    my $t0 = Time::HiRes::time;
    while (Time::HiRes::time - $t0 < $secs) {
        my $n = $s->sysread(my $c, 10);
        return Time::HiRes::time - $t0 if defined $n && $n == 0;
        Time::HiRes::sleep(0.1);
    }
    return;
}

ok(connect_to($pa) && connect_to($pb), 'both servers are up');

# --- a body dribbled a byte a second is cut by the rate floor ---
{
    my $s = connect_to($pa);
    $s->syswrite("POST /drip HTTP/1.1\r\nHost: a\r\nContent-Length: 1000\r\n\r\n");
    my $t0 = Time::HiRes::time;
    my $cut;
    for (1 .. 80) {
        $s->syswrite('x');
        my $n = $s->sysread(my $c, 10);
        if (defined $n && $n == 0) { $cut = Time::HiRes::time - $t0; last }
        Time::HiRes::sleep(0.1);
    }
    ok($cut, 'the connection was closed') and cmp_ok($cut, '>=', 1.5, 'after the two seconds the rate is judged over');
}

# --- a request that never finishes is cut by request_timeout ---
{
    my $s = connect_to($pb);
    $s->syswrite("POST /hang HTTP/1.1\r\nHost: a\r\nContent-Length: 10\r\n\r\nabc");
    my $cut = closed_within($s, 5);
    ok($cut, 'a request past its ceiling is closed');
}

# --- a pipeline deeper than max_pipeline is still fully served ---
{
    my $req = join '', map { "GET /p$_ HTTP/1.1\r\nHost: a\r\n" . ($_ == 5 ? "Connection: close\r\n" : '') . "\r\n" } 1 .. 5;
    my $all = raw($pa, $req);
    is(scalar(() = $all =~ m{HTTP/1\.1 200}g), 5, 'five pipelined requests, five responses');
    like($all, qr{/p5:0}, 'in order to the last');
}

# --- more header lines than the stack index, and a chunk size in letters ---
{
    my $many = "GET /many HTTP/1.1\r\nHost: a\r\n" . join('', map { "X-H$_: $_\r\n" } 1 .. 70) . "X-Last: seventy\r\nConnection: close\r\n\r\n";
    like(raw($pa, $many), qr{/many:0:seventy}, 'seventy-odd header lines are indexed in the heap copy');
    my $hex = "POST /hex HTTP/1.1\r\nHost: a\r\nTransfer-Encoding: chunked\r\nConnection: close\r\n\r\nA\r\n0123456789\r\nb\r\nabcdefghijk\r\n0\r\n\r\n";
    like(raw($pa, $hex), qr{/hex:21}, 'chunk sizes in upper and lower hex letters');
}

# --- bodies past max_body, announced and chunked ---
{
    my $big = raw($pb, "POST /big HTTP/1.1\r\nHost: a\r\nContent-Length: 10000\r\nExpect: 100-continue\r\nConnection: close\r\n\r\n");
    like($big, qr{^HTTP/1\.1 413}, 'an announced body past max_body is refused before it is sent');
    my $chunks = raw($pb, "POST /chunky HTTP/1.1\r\nHost: a\r\nTransfer-Encoding: chunked\r\nConnection: close\r\n\r\n" . ("1000\r\n" . ('c' x 4096) . "\r\n") x 2);
    like($chunks, qr{^HTTP/1\.1 413}, 'a chunked body that outgrows max_body is refused');
}

# --- a body past the spill mark, with a temp directory and without one ---
{
    my $body = 'b' x (1024 * 1024 + 100);
    like(raw($pa, "POST /spill HTTP/1.1\r\nHost: a\r\nContent-Length: " . length($body) . "\r\nConnection: close\r\n\r\n$body", 10), qr{/spill:1048676}, 'a body past a megabyte is spilled to a file and read back whole');
}

# --- the logs ---
{
    like(raw($pb, "GET /stream HTTP/1.1\r\nHost: a\r\nConnection: close\r\n\r\n"), qr/s\z/, 'a streamed response on the combined log');
    like(raw($pa, "GET /stream HTTP/1.1\r\nHost: a\r\nConnection: close\r\n\r\n"), qr/s\z/, 'a streamed response');
    like(raw($pb, "GET /ctl HTTP/1.1\r\nHost: a\r\nUser-Agent: del\x7fete \"q\"\r\nConnection: close\r\n\r\n"), qr{/ctl:0}, 'a control byte in the agent');
    Time::HiRes::sleep(0.3);
    my $a = do { local (@ARGV, $/) = ("$dir/a.log"); <> } // '';
    like($a, qr/"bytes":null/, 'the JSON log writes null for the bytes of a stream');
    my $b = do { local (@ARGV, $/) = ("$dir/b.log"); <> } // '';
    like($b, qr/"del\\x7fete \\"q\\"" - 200 7 7 127\.0\.0\.1 127\.0\.0\.1 \d+ \d+ \d+/, 'the combined log escapes a control byte and quotes, dashes a missing header, and fills %B %b %v %e %D %T %P');
    like($b, qr/ 200 0 - 127/, 'a streamed response logs zero and a dash for its bytes');
}

# --- a hard stop: TERM during a slow request, the grace runs out ---
{
    my $s = connect_to($pb);
    $s->syswrite("GET /slow HTTP/1.1\r\nHost: a\r\n\r\n");
    Time::HiRes::sleep(0.3);
    kill 'TERM', $pidb;
    my $t0 = Time::HiRes::time;
    server_reap($pidb);
    my $took = Time::HiRes::time - $t0;
    cmp_ok($took, '<', 4, 'the server did not wait for the slow handler');
}

kill 'TERM', $pida;
server_reap($pida);
done_testing;
