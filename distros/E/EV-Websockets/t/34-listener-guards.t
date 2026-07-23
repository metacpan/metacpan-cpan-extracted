use strict;
use warnings;
use Test::More;
use POSIX ();
use IO::Select;
use IO::Socket::INET;
use EV;
use EV::Websockets;

use if -d 'blib', lib => 'blib/lib', 'blib/arch';

EV::Websockets::_set_debug(1) if $ENV{EV_WS_DEBUG};

# Two listener robustness guards:
#
# 1. A half-configured TLS pair must croak. Accepting only one of
#    ssl_cert/ssl_key used to create a PLAINTEXT listener, serving cleartext on
#    a port the caller believed was encrypted.
# 2. A plain (non-upgrade) HTTP request must be answered and closed. With no
#    LWS_CALLBACK_HTTP case the callback returned 0 ("handled") and no response
#    was ever sent, so the connection hung until the peer gave up -- port
#    scanners and health checks accumulated half-open connections.

my %cb = (on_connect => sub { }, on_message => sub { }, on_close => sub { });

# --- 1. TLS pair validation (paths need not exist; the check is on presence) --
{
    my $ctx = EV::Websockets::Context->new();

    my $p1 = eval { $ctx->listen(port => 0, ssl_cert => '/nonexistent/cert.pem', %cb) };
    like($@, qr/ssl_cert and ssl_key/, 'listen(ssl_cert without ssl_key) croaks');

    my $p2 = eval { $ctx->listen(port => 0, ssl_key => '/nonexistent/key.pem', %cb) };
    like($@, qr/ssl_cert and ssl_key/, 'listen(ssl_key without ssl_cert) croaks');

    my $p3 = eval { $ctx->listen(port => 0, %cb) };
    ok(!$@ && defined $p3 && $p3 > 0, 'listen() with neither still creates a plain listener');
}

# --- 2. Plain HTTP gets 426 and is closed -----------------------------------
SKIP: {
    pipe(my $r, my $w) or skip "pipe: $!", 2;
    my $pid = fork;
    skip "fork unavailable: $!", 2 unless defined $pid;

    if (!$pid) {
        close $r;
        my $ctx  = EV::Websockets::Context->new();
        my $port = $ctx->listen(port => 0, %cb);
        syswrite($w, "$port\n");
        close $w;
        EV::run();
        POSIX::_exit(0);
    }

    close $w;
    my $port;
    {
        my $line = '';
        IO::Select->new($r)->can_read(10) and sysread($r, $line, 32);
        ($port) = $line =~ /(\d+)/;
    }
    close $r;
    unless ($port) { kill 'KILL', $pid; waitpid $pid, 0; skip "listener did not start", 2 }

    my ($status, $closed) = ('(no response)', 0);
    if (my $s = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port", Timeout => 5)) {
        syswrite($s, "GET / HTTP/1.1\r\nHost: localhost\r\n\r\n");
        my $buf = '';
        for (1 .. 10) {
            last unless IO::Select->new($s)->can_read(1);
            my $n = sysread($s, my $chunk, 4096);
            last if !defined $n;
            if ($n == 0) { $closed = 1; last }
            $buf .= $chunk;
        }
        ($status) = $buf =~ /^(\S+\s+\d+[^\r\n]*)/ if length $buf;
        $status = '(no response)' unless defined $status;
    }
    kill 'KILL', $pid;
    waitpid $pid, 0;

    like($status, qr{\b426\b}, "plain HTTP request answered 426 Upgrade Required (got: $status)");
    ok($closed, 'server closed the HTTP connection (no half-open socket left)');
}

done_testing;

POSIX::_exit(Test::More->builder->is_passing ? 0 : 1);
