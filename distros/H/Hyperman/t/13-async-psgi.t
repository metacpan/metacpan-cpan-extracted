#!perl
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use Time::HiRes ();
use File::Temp ();

# Async PSGI (plan/04-async-psgi.md): Future-returning handlers, psgix.loop /
# psgix.io, failure -> 500 with the connection kept alive, and cancellation
# of the response Future when the client disconnects.

my $marker = File::Temp::tempdir(CLEANUP => 1) . '/cancelled';
my $port   = 19000 + ($$ % 1000);

my $app = sub {
    my $env = shift;
    my $p = $env->{PATH_INFO};
    if ($p eq '/future') {
        return Hyperman->timer(0.02)->then(sub {
            [ 200, [ 'Content-Type' => 'text/plain' ], [ 'from-future' ] ];
        });
    }
    if ($p eq '/env') {
        my $body = join '|',
            (ref($env->{'psgix.loop'}) || 'none'),
            (defined fileno($env->{'psgix.io'}) ? 'io-fd' : 'no-io'),
            $env->{'psgi.nonblocking'} ? 'nb' : 'blocking';
        return [ 200, [ 'Content-Type' => 'text/plain' ], [ $body ] ];
    }
    if ($p eq '/loopkey') {   # psgix.loop is usable: make a Future on it
        my $f = $env->{'psgix.loop'}->timer_f(0.02);
        return $f->then(sub { [ 200, [], [ 'loop-timer' ] ] });
    }
    if ($p eq '/fail') {
        return Hyperman->timer(0.02)->then(sub { die "kaboom\n" });
    }
    if ($p eq '/cancelme') {
        my $resp = Hyperman->timer(5)->then(sub { [ 200, [], [ 'too late' ] ] });
        $resp->on_ready(sub {
            my $g = shift;
            if ($g->is_cancelled) {
                open my $fh, '>', $marker or return;
                print $fh "cancelled\n";
                close $fh;
            }
        });
        return $resp;
    }
    if ($p eq '/cpan-future') {
        return [ 501, [], [ 'no Future.pm' ] ]
            unless eval { require Future; 1 };
        my $f = Future->new;
        Hyperman->loop->defer(sub { $f->done([ 200, [], [ 'cpan-future' ] ]) });
        return $f;
    }
    return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'ok' ] ];
};

my $pid = fork;
die "fork: $!" unless defined $pid;
if ($pid == 0) {
    open STDERR, '>', '/dev/null';
    require Hyperman;
    Hyperman->run(app => $app, host => '127.0.0.1', port => $port, workers => 1);
    exit 0;
}

sub connect_srv {
    for (1 .. 50) {
        my $s = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1', PeerPort => $port, Proto => 'tcp');
        return $s if $s;
        Time::HiRes::sleep(0.1);
    }
    die "server did not come up on port $port";
}

# one request on an open (keep-alive) socket; returns (status, body)
sub req {
    my ($s, $path) = @_;
    $s->print("GET $path HTTP/1.1\r\nHost: t\r\n\r\n");
    my ($hdr, $buf) = ('', '');
    while ($s->sysread(my $chunk, 4096)) {
        $buf .= $chunk;
        last if $buf =~ /\r\n\r\n/;
    }
    ($hdr, $buf) = split /\r\n\r\n/, $buf, 2;
    my ($status) = $hdr =~ m{^HTTP/1\.\d (\d+)};
    my ($cl) = $hdr =~ m{^Content-Length:\s*(\d+)}mi;
    $cl = 0 unless defined $cl;
    while (length($buf) < $cl) {
        last unless $s->sysread(my $chunk, 4096);
        $buf .= $chunk;
    }
    return ($status, $buf);
}

my $s = connect_srv();

# ---- Future-returning handler --------------------------------------------
{
    my $t0 = Time::HiRes::time();
    my ($st, $body) = req($s, '/future');
    is($st, 200, 'future handler: 200');
    is($body, 'from-future', 'future handler: body');
    cmp_ok(Time::HiRes::time() - $t0, '<', 2, 'resolved promptly');
}

# ---- psgix.loop / psgix.io -----------------------------------------------
{
    my ($st, $body) = req($s, '/env');
    is($body, 'Hyperman::Loop|io-fd|nb',
        'psgix.loop is the worker loop, psgix.io has a real fd, psgi.nonblocking set');
    ($st, $body) = req($s, '/loopkey');
    is($body, 'loop-timer', 'psgix.loop creates working loop Futures');
}

# ---- failed async response: 500, connection stays usable ------------------
{
    my ($st, $body) = req($s, '/fail');
    is($st, 500, 'failed future -> 500');
    my ($st2, $body2) = req($s, '/');
    is($st2, 200, 'same connection still keep-alive after async failure');
    is($body2, 'ok', 'and serves normally');
}

# ---- CPAN Future as a response (any on_ready object) ----------------------
SKIP: {
    skip 'CPAN Future not installed', 1 unless eval { require Future; 1 };
    my (undef, $body) = req($s, '/cpan-future');
    is($body, 'cpan-future', 'handler may return a CPAN Future');
}

# ---- client disconnect cancels the pending response Future ---------------
{
    my $c = connect_srv();
    $c->print("GET /cancelme HTTP/1.1\r\nHost: t\r\n\r\n");
    Time::HiRes::sleep(0.3);   # let the request park
    close $c;                  # walk away
    my $seen = 0;
    for (1 .. 30) {
        if (-e $marker) { $seen = 1; last }
        Time::HiRes::sleep(0.1);
    }
    ok($seen, 'response Future cancelled when the client disconnected');
}

close $s;
kill 'TERM', $pid;
waitpid $pid, 0;
done_testing;
