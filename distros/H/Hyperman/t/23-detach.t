#!perl
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use HMTest qw(free_ports);
use IO::Socket::INET;
use Time::HiRes ();
use Hyperman;

# Hyperman::detach: the protocol-upgrade seam. An app takes the client
# socket over - the server stops watching it, forgets the connection and
# does not close it - and then drives it itself through the worker loop,
# while the worker keeps serving ordinary HTTP on other connections.

my ($port) = free_ports(1);
plan skip_all => "no free loopback port" unless $port;

my $pid = fork // die "fork: $!";
if (!$pid) {
    open STDERR, '>', '/dev/null';
    my %echo;      # fd => the raw socket we own after detaching
    Hyperman->run(
        app => sub {
            my $env = shift;
            my $path = $env->{PATH_INFO};

            if ($path eq '/detach') {
                my $fd = eval { Hyperman::detach($env) };
                return [ 500, [ 'Content-Type' => 'text/plain' ], ["$@"] ]
                    if $@;
                # the socket is ours now: greet, then echo every line
                open my $sock, '+<&=', $fd or die "fdopen: $!";
                $sock->autoflush(1);
                $echo{$fd} = $sock;
                syswrite $sock, "HELLO\n";
                $env->{'psgix.loop'}->watch_io($sock, 'r', sub {
                    my $n = sysread $sock, my $buf, 4096;
                    if (!$n) {                       # EOF or error
                        $env->{'psgix.loop'}->unwatch_io($sock, 'r');
                        delete $echo{$fd};
                        close $sock;
                        return;
                    }
                    syswrite $sock, uc $buf;
                });
                return [ 101, [], [] ];              # discarded
            }

            if ($path eq '/detach-twice') {
                my $fd = eval { Hyperman::detach($env) };
                my $second = eval { Hyperman::detach($env); "no error\n" }
                    || "$@";
                # report the second attempt over the socket we now own
                open my $sock, '+<&=', $fd or die "fdopen: $!";
                syswrite $sock, $second;
                close $sock;
                return [ 101, [], [] ];
            }

            # an ordinary 101 (no detach): proves the reason phrase
            return [ 101, [ 'Upgrade' => 'nothing' ], [] ]
                if $path eq '/one-oh-one';

            [ 200, [ 'Content-Type' => 'text/plain' ], ["ok:$path"] ];
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

sub connect_to {
    my $s = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port")
        or die "connect: $!";
    $s->autoflush(1);
    return $s;
}

# One ordinary HTTP request/response over its own connection.
sub http_get {
    my ($path) = @_;
    my $s = connect_to();
    syswrite $s, "GET $path HTTP/1.1\r\nHost: x\r\nConnection: close\r\n\r\n";
    my $buf = '';
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm 3;
        while (my $n = sysread $s, my $c, 4096) { $buf .= $c }
        alarm 0;
    };
    return $buf;
}

sub read_line_from {
    my ($s, $secs) = @_;
    my $line = '';
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm($secs || 3);
        while (sysread $s, my $c, 1) {
            $line .= $c;
            last if $c eq "\n";
        }
        alarm 0;
    };
    return $line;
}

# ---- the detached socket is ours, and stays open --------------------------
{
    my $s = connect_to();
    syswrite $s, "GET /detach HTTP/1.1\r\nHost: x\r\n\r\n";
    is(read_line_from($s), "HELLO\n",
        'the app owns the socket after detach and writes to it directly');

    syswrite $s, "ping one\n";
    is(read_line_from($s), "PING ONE\n", 'the app reads what the client sends');
    syswrite $s, "ping two\n";
    is(read_line_from($s), "PING TWO\n", 'and keeps reading (persistent watcher)');

    # ---- the worker still serves ordinary HTTP meanwhile ------------------
    like(http_get('/plain'), qr/^HTTP\/1\.1 200 OK/,
        'a second connection gets normal HTTP service');
    like(http_get('/plain'), qr/ok:\/plain/, 'with the right body');

    syswrite $s, "last\n";
    is(read_line_from($s), "LAST\n", 'the detached socket is unaffected by them');
    close $s;
}

# ---- 101 keeps its reason phrase (hm_reason) ------------------------------
{
    my $r = http_get('/one-oh-one');
    like($r, qr{^HTTP/1\.1 101 Switching Protocols},
        '101 serialises with its real reason phrase');
}

# ---- detaching twice is refused -------------------------------------------
{
    my $s = connect_to();
    syswrite $s, "GET /detach-twice HTTP/1.1\r\nHost: x\r\n\r\n";
    my $said = read_line_from($s);
    like($said, qr/already detached/,
        'a second detach on the same connection croaks');
    close $s;
}

# ---- fd reuse: churn connections after a detach ---------------------------
{
    my $held = connect_to();
    syswrite $held, "GET /detach HTTP/1.1\r\nHost: x\r\n\r\n";
    is(read_line_from($held), "HELLO\n", 'detached and held open');

    like(http_get("/churn$_"), qr/ok:\/churn$_/, "churn $_ served normally")
        for 1 .. 5;

    syswrite $held, "still here\n";
    is(read_line_from($held), "STILL HERE\n",
        'the held socket survived the fd churn (no cross-talk)');
    close $held;
}

# ---- the server survives all of it -----------------------------------------
like(http_get('/final'), qr/ok:\/final/, 'worker still healthy at the end');

kill 'TERM', $pid;
waitpid $pid, 0;

done_testing();
