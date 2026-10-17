#!perl
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use HMTest qw(free_ports quiet_child server_reap);
use IO::Socket::INET;
use Time::HiRes ();
use Hyperman;

# The 0.62 review pass, the cases that fit in one file:
#  - a Future method on something that is not a future croaks (it segfaulted)
#  - ->get in list context after the nested loop grew the Perl stack
#  - a stop asked for while a handler's ->get pumps the loop is honoured
#  - a continuation awaited from inside the fire queue settles
#  - followed_by on a cancelled future does not run, and a callback that
#    cancels its own future does not have it flipped to done
#  - run() refuses a negative or non-numeric count, and a numeric user with
#    no passwd entry and no group
#  - the psgi.* booleans are per-request copies: BufferedStreaming works
#  - a second responder call, and a die with a writer kept alive, end the
#    connection without the terminating chunk; a lexical writer's unwind
#    still ends the body as a dropped writer always has
#  - Content-Length that is not a number is ignored for a streamed response
#  - ->write returns 1 with room, -1 on a stale writer
#  - a bare LF in a chunk extension or a trailer is a 400
#  - redirect_https keeps a bracketed IPv6 Host whole
#  - a partial PROXY header does not spin the worker, and completes later;
#    an IPv4-mapped address in it is reported as the IPv4

# ---- in process ----------------------------------------------------------

{
    my $err;
    eval { Hyperman::Future->done(1) };
    like $@, qr/not a future object/, 'done() on a class name croaks, not a crash';
    eval { Hyperman::Future->get };
    like $@, qr/not a future object/, 'get() on a class name croaks instead of spinning';
    eval { Hyperman::Future::on_ready({}, sub {}) };
    like $@, qr/not a future object/, 'on_ready on a hash reference croaks';
    my $f = Hyperman::Future->done_future(\"not a class");
    ok $f->is_done, 'done_future with a reference invocant takes the default class';
    is ref $f, 'Hyperman::Future', '...which is Hyperman::Future';
}

{
    my $loop = Hyperman::Loop->new;
    my $f = Hyperman::Future->new;
    my @got;
    # The wait pumps the loop, the other timer's callback grows the Perl
    # stack by a few hundred thousand slots, and the results are pushed
    # through a pointer taken before that: SPAGAIN or a write into freed
    # memory.
    $loop->timer(0.02, sub { my @big = map { $_ } 1 .. 300_000; $f->done(1, 2, 3) });
    $loop->timer(0.005, sub { @got = $f->get; $loop->stop });
    local $SIG{ALRM} = sub { die "hung\n" };
    alarm 10;
    $loop->run;
    alarm 0;
    is_deeply \@got, [1, 2, 3], '->get in list context after the stack moved under it';
}

{
    my $loop = Hyperman::Loop->new;
    my ($err, $t0);
    $loop->timer(0.02, sub { $loop->stop });
    $loop->timer(0.005, sub { eval { $loop->timer_f(30)->get }; $err = $@ });
    local $SIG{ALRM} = sub { die "hung\n" };
    alarm 10;
    $t0 = Time::HiRes::time();
    my $ok = eval { $loop->run; 1 };
    alarm 0;
    ok $ok, 'the loop returned after a stop under a nested ->get' or diag $@;
    cmp_ok(Time::HiRes::time() - $t0, '<', 5, '...promptly, not after the 30s timer');
    like $err, qr/loop stopped/, 'the waiting ->get died with the loop-stopped message';
}

{
    my $loop = Hyperman::Loop->new;
    my $got;
    # on_ready runs from the fire queue; a ->then->get inside it waits on a
    # continuation that only the queue can run.
    $loop->timer_f(0.005)->on_ready(sub {
        $got = eval {
            $loop->timer_f(0.005)->then(sub { Hyperman::Future->done_future(42) })->get;
        } // "died: $@";
        $loop->stop;
    });
    local $SIG{ALRM} = sub { die "hung\n" };
    alarm 10;
    my $ok = eval { $loop->run; 1 };
    alarm 0;
    ok $ok, 'a continuation awaited from inside the fire queue settled' or diag $@;
    is $got, 42, '...with its value';
}

{
    my $f = Hyperman::Future->new;
    my $ran = 0;
    my $n = $f->followed_by(sub { $ran++; Hyperman::Future->done_future('x') });
    $n->cancel;
    $f->done(1);
    ok $n->is_cancelled, 'followed_by on a cancelled derived future stays cancelled';
    is $ran, 0, '...and its callback did not run';

    my $g = Hyperman::Future->new;
    my $m;
    $m = $g->then(sub { $m->cancel; Hyperman::Future->done_future('x') });
    $g->done(1);
    ok $m->is_cancelled, 'a then callback that cancels its own future leaves it cancelled';
}

{
    my $app = sub { [200, [], []] };
    for my $case (['max_body', -1], ['max_body', '10M'], ['body_min_rate', 'fast'],
                  ['http3_max_conns', -5]) {
        my ($k, $v) = @$case;
        eval { Hyperman->run(app => $app, port => 1, workers => 1, $k => $v) };
        like $@, qr/\Q$k\E must be a non-negative number/, "$k => '$v' is refused";
    }
    eval { Hyperman->run(app => $app, port => 1, workers => 1, user => '4242424') };
    like $@, qr/no passwd entry; name a group/, 'a numeric user with no entry needs a group';
}

# ---- the server ------------------------------------------------------------

my ($port, $rport, $pport) = free_ports(3);
plan skip_all => "no free loopback ports" unless $port && $rport && $pport;

our $KEEP;
my $pid = fork // die "fork: $!";
if (!$pid) {
    quiet_child();
    my $app = sub {
        my $env = shift;
        my $p = $env->{PATH_INFO};
        if ($p eq '/echo') {
            return [200, ['Content-Type' => 'text/plain'], [$env->{REMOTE_ADDR} // 'none']];
        }
        if ($p eq '/stream') {
            return sub { my $r = shift; my $w = $r->([200, ['Content-Type' => 'text/plain']]);
                         $w->write('hello'); $w->close };
        }
        if ($p eq '/double') {
            return sub {
                my $r = shift;
                my $w = $r->([200, ['Content-Type' => 'text/plain']]);
                $w->write('a');
                $KEEP = $w;                       # outlives the die below
                $r->([200, ['Content-Type' => 'text/plain']]);
                $w->write('never');
                $w->close;
            };
        }
        if ($p eq '/keep-die') {
            return sub {
                my $r = shift;
                my $w = $r->([200, ['Content-Type' => 'text/plain']]);
                $w->write('part');
                $KEEP = $w;
                die "boom\n";
            };
        }
        if ($p eq '/lex-die') {
            return sub {
                my $r = shift;
                my $w = $r->([200, ['Content-Type' => 'text/plain']]);
                $w->write('part');
                die "boom\n";
            };
        }
        if ($p eq '/clen-abc') {
            return sub { my $r = shift;
                         my $w = $r->([200, ['Content-Type' => 'text/plain',
                                             'Content-Length' => 'abc']]);
                         $w->write('hello'); $w->close };
        }
        if ($p eq '/wret') {
            return sub { my $r = shift;
                         my $w = $r->([200, ['Content-Type' => 'text/plain']]);
                         my $rc = $w->write('x');
                         $w->write("rc=$rc");
                         $w->close;
                         my $after = $w->write('late');
                         $KEEP = "after=$after" };
        }
        if ($p eq '/wret-after') {
            return [200, ['Content-Type' => 'text/plain'], [$KEEP // 'unset']];
        }
        if ($p eq '/bs') {
            # BufferedStreaming assigns psgi.streaming into $env
            require Plack::Middleware::BufferedStreaming;
            my $inner = sub { my $e = shift;
                              return sub { my $r = shift;
                                           my $w = $r->([200, ['Content-Type' => 'text/plain']]);
                                           $w->write("streaming=$e->{'psgi.streaming'}");
                                           $w->close } };
            return Plack::Middleware::BufferedStreaming->wrap($inner)->($env);
        }
        return [404, ['Content-Type' => 'text/plain'], ['?']];
    };
    Hyperman->run(
        app     => $app,
        listen  => [ { host => '127.0.0.1', port => $port },
                     { host => '127.0.0.1', port => $rport, redirect_https => 8443 },
                     { host => '127.0.0.1', port => $pport, proxy_protocol => 1 } ],
        workers => 1,
    );
    exit 0;
}

my $connect = sub {
    my ($p) = @_;
    $p ||= $port;
    my $s;
    for (1 .. 100) {
        $s = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $p, Proto => 'tcp');
        last if $s;
        Time::HiRes::sleep(0.05);
    }
    return $s;
};
my $read_all = sub {
    my ($s, $timeout) = @_;
    require IO::Select;
    my $sel = IO::Select->new($s);
    my $got = '';
    my $deadline = Time::HiRes::time() + ($timeout || 5);
    while (1) {
        my $left = $deadline - Time::HiRes::time();
        last if $left <= 0 || !$sel->can_read($left);
        my $n = sysread($s, my $b, 65536);
        last unless $n;
        $got .= $b;
    }
    return $got;
};
my $raw = sub {
    my ($req, $p) = @_;
    my $s = $connect->($p) or return '';
    syswrite $s, $req;
    my $got = $read_all->($s);
    close $s;
    return $got;
};
my $get = sub {
    my ($path, $p) = @_;
    $raw->("GET $path HTTP/1.1\r\nHost: t\r\nConnection: close\r\n\r\n", $p);
};
# keep-alive, so a streamed response is chunked; read to EOF or a short
# timeout, since the connection is meant to survive some of these
my $keep = sub {
    my ($path) = @_;
    my $s = $connect->() or return '';
    syswrite $s, "GET $path HTTP/1.1\r\nHost: t\r\n\r\n";
    my $got = $read_all->($s, 1.5);
    close $s;
    return $got;
};

ok $connect->(), 'the server is up';

{
    my $r = $get->('/bs');
    like $r, qr{^HTTP/1\.1 200 }, 'Plack::Middleware::BufferedStreaming served a 200';
    like $r, qr/streaming=1/, '...having assigned into psgi.streaming without dying';
}

{
    my $r = $keep->('/double');
    like $r, qr{^HTTP/1\.1 200 .*Transfer-Encoding: chunked}s, 'double responder: the first response began';
    like $r, qr/\r\n1\r\na\r\n/, '...the first chunk went out';
    unlike $r, qr/0\r\n\r\n\z/, '...and the body was NOT sealed as complete';
    unlike $r, qr/never|HTTP\/1\.1 200 OK\r\n.*HTTP\/1\.1/s, '...nor was a second status line written into it';
}

{
    my $r = $keep->('/keep-die');
    like $r, qr/\r\n4\r\npart\r\n/, 'die with the writer kept alive: the part written went out';
    unlike $r, qr/0\r\n\r\n\z/, '...the body was not sealed as complete';
    unlike $r, qr/500/, '...and no 500 was written into it';
}

{
    my $r = $keep->('/lex-die');
    like $r, qr/\r\n4\r\npart\r\n0\r\n\r\n\z/, 'a lexical writer unwound by the die ended its body, as a dropped writer does';
}

{
    my $r = $keep->('/clen-abc');
    like $r, qr{Transfer-Encoding: chunked}, 'Content-Length "abc" is ignored: chunked framing';
    like $r, qr/\r\n5\r\nhello\r\n0\r\n\r\n\z/, '...and the body is intact';
}

{
    my $r = $keep->('/wret');
    like $r, qr/rc=1/, '->write returns 1 with room on the connection';
    like $get->('/wret-after'), qr/after=-1/, '->write after ->close returns -1';
}

{
    my $r = $raw->("POST /echo HTTP/1.1\r\nHost: t\r\nTransfer-Encoding: chunked\r\n\r\n"
                 . "0\r\nX-Trailer: a\n\nGET /smuggle HTTP/1.1\r\nHost: t\r\n\r\n");
    like $r, qr{^HTTP/1\.1 400 }, 'a bare LF in a trailer is a 400';
    $r = $raw->("POST /echo HTTP/1.1\r\nHost: t\r\nTransfer-Encoding: chunked\r\n\r\n"
              . "5;ext\nhello\r\n0\r\n\r\n");
    like $r, qr{^HTTP/1\.1 400 }, 'a bare LF after a chunk extension is a 400';
    $r = $raw->("POST /echo HTTP/1.1\r\nHost: t\r\nTransfer-Encoding: chunked\r\n"
              . "Connection: close\r\n\r\n5;ext\r\nhello\r\n0\r\nX-Trailer: a\r\n\r\n");
    like $r, qr{^HTTP/1\.1 200 }, 'a well-formed extension and trailer still parse';
}

{
    my $r = $raw->("GET /p?q=1 HTTP/1.1\r\nHost: [::1]:8080\r\nConnection: close\r\n\r\n", $rport);
    like $r, qr{^HTTP/1\.1 301 }, 'redirect_https answers 301';
    like $r, qr{Location: https://\[::1\]:8443/p\?q=1\r\n}, '...with the bracketed IPv6 host kept whole';
}

{
    my $cpu = sub {
        my $t = `ps -o time= -p $pid 2>/dev/null`;
        $t =~ s/^\s+|\s+$//g;
        my ($h, $m, $s) = (0, 0, 0);
        if ($t =~ /\A(?:(\d+):)?(\d+):([\d.]+)\z/) { ($h, $m, $s) = ($1 || 0, $2, $3) }
        return $h * 3600 + $m * 60 + $s;
    };
    my $s = $connect->($pport);
    ok $s, 'connected to the proxy-protocol listener';
    my $before = $cpu->();
    syswrite $s, "PROXY TCP4 1";                     # a partial header
    Time::HiRes::sleep(1.5);
    my $after = $cpu->();
    cmp_ok $after - $before, '<', 1.0,
        "a partial PROXY header did not spin the worker (" . ($after - $before) . "s CPU over 1.5s)";
    syswrite $s, ".2.3.4 5.6.7.8 1234 80\r\n"        # ...completed later
               . "GET /echo HTTP/1.1\r\nHost: t\r\nConnection: close\r\n\r\n";
    my $r = $read_all->($s);
    close $s;
    like $r, qr{^HTTP/1\.1 200 .*\r\n\r\n1\.2\.3\.4\z}s, '...and the completed header was read and honoured';

    $r = $raw->("PROXY TCP6 ::ffff:9.8.7.6 ::1 1 2\r\n"
              . "GET /echo HTTP/1.1\r\nHost: t\r\nConnection: close\r\n\r\n", $pport);
    like $r, qr/\r\n\r\n9\.8\.7\.6\z/, 'an IPv4-mapped PROXY address is reported as the IPv4';
}

kill 'TERM', $pid;
server_reap($pid);
done_testing();
