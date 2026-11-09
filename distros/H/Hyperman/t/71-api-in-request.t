#!perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use HMTest qw(free_ports quiet_child server_reap);
use IO::Socket::INET;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);
use Time::HiRes ();
use File::Temp ();
use Hyperman;

# The API as a handler sees it: io_ready on a descriptor of its own, the pool
# views with a scoreboard, detach and stream refusing bad tickets, a stream
# handle aborted or dropped, the bus refusing an oversize message, a worker
# hook that dies, and the glob spellings of the two logs.

my ($pa, $pb) = free_ports(2);
plan skip_all => 'no free loopback ports' unless $pa && $pb;
plan skip_all => 'fork is not Windows' if $^O eq 'MSWin32';
my $dir = File::Temp::tempdir(CLEANUP => 1);

my $app = sub {
    my $env = shift;
    my $p = $env->{PATH_INFO};
    my $out = sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ join ';', @_ ] ] };
    if ($p eq '/io_ready') {
        socketpair(my $r, my $w, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "socketpair: $!";
        my $f = Hyperman->io_ready($r, 'r');
        syswrite($w, 'ping');
        $f->get;
        sysread($r, my $got, 10);
        return $out->("got=$got");
    }
    if ($p eq '/io_ready_closed') {
        open my $fh, '<', $0 or die;
        close $fh;
        my $err = eval { Hyperman->io_ready($fh); 'none' } // $@;
        return $out->($err);
    }
    if ($p eq '/pool') {
        my $s = Hyperman->stats(pool => 1);
        my @rows = Hyperman->pool_stats;
        my $lease = Hyperman->leader('t71', ttl => 5);
        my @dc = Hyperman->distinct_clients;
        return $out->("workers=$s->{workers}", "rows=" . scalar(@rows), 'leader=' . (ref $lease || 'none'), 'dc=' . scalar(@dc));
    }
    if ($p eq '/detach_bad') {
        my @e = map { my $x = $_; eval { Hyperman::detach($x); 'none' } // $@ } 'not a hash', { }, { 'psgix.hyperman.conn' => [] };
        return $out->(@e);
    }
    if ($p eq '/detach_twice') {
        my $fd = Hyperman::detach($env);
        my $again = eval { Hyperman::detach($env); 'none' } // $@;
        my $stale = eval { Hyperman::detach({ 'psgix.hyperman.conn' => [ 99999, 1 ] }); 'none' } // $@;
        open my $sock, '+<&=', $fd or die "fdopen: $!";
        syswrite($sock, "HTTP/1.1 200 OK\r\nContent-Length: " . length("$again|$stale") . "\r\nConnection: close\r\n\r\n$again|$stale");
        close $sock;
        return [ 200, [], [] ];
    }
    if ($p eq '/detach_draining') {
        return sub {
            my $w = shift->([ 200, [ 'Content-Type' => 'text/plain' ] ]);
            $w->write('x' x (8 * 1024 * 1024));
            my $err = eval { Hyperman::detach($env); 'none' } // $@;
            $w->write("|$err");
            $w->close;
        };
    }
    if ($p eq '/stream_bad') {
        my @e = map { my $x = $_; eval { Hyperman::stream(@$x); 'none' } // $@ } ['not a hash'], [{}], [$env, 200, 'not a list'];
        return $out->(@e);
    }
    if ($p eq '/stream_abort') {
        return sub {
            my $w = Hyperman::stream($env, 200, [ 'Content-Type' => 'text/plain' ]);
            $w->write('partial');
            $w->abort;
        };
    }
    if ($p eq '/stream_drop') {
        return sub {
            my $w = Hyperman::stream($env, 200, [ 'Content-Type' => 'text/plain' ]);
            $w->write('dropped');
        };
    }
    if ($p eq '/big') { return [ 200, [], [ 'b' x (8 * 1024 * 1024) ] ] }
    if ($p eq '/bus') {
        my $big = Hyperman->publish('t71', 'x' x 100000);
        my $ok = Hyperman->publish('t71', 'small');
        return $out->("big=$big", "ok=$ok");
    }
    $out->('default');
};

my $hook_log = "$dir/hook.log";
open my $bigfh, '>', "$dir/big.bin" or die; print $bigfh 'b' x (8 * 1024 * 1024); close $bigfh;
my $pid = fork // die "fork: $!";
if (!$pid) {
    quiet_child(stderr => "$dir/stderr");
    open my $alog, '>>', "$dir/access.log" or die;
    open my $elog, '>>', "$dir/error.log" or die;
    Hyperman->on_worker_start(sub { open my $fh, '>>', $hook_log or die; print $fh "started $$\n"; close $fh; die "hook boom\n" });
    Hyperman->run(app => $app, host => '127.0.0.1', port => [ $pa, $pb ], workers => 1, max_pipeline => 2,
        access_log => $alog, error_log => $elog, compress => 1, compress_level => 5,
        distinct_clients => 1, bus_slot_size => 1024);
    exit 0;
}

sub connect_to {
    my $port = shift;
    for (1 .. 60) {
        my $s = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port");
        return $s if $s;
        Time::HiRes::sleep(0.1);
    }
    return;
}
sub get {
    my ($port, $path, $pause) = @_;
    my $s = connect_to($port) or return '';
    $s->syswrite("GET $path HTTP/1.1\r\nHost: a\r\nConnection: close\r\n\r\n");
    Time::HiRes::sleep($pause) if $pause;
    my $buf = '';
    eval { local $SIG{ALRM} = sub { die "timeout\n" }; alarm 15; while (my $n = $s->sysread(my $c, 1 << 20)) { $buf .= $c } alarm 0 };
    return $buf;
}
sub body { my $r = shift; (split /\r\n\r\n/, $r, 2)[1] // '' }

ok(connect_to($pa), 'the first listener is up');
like(get($pb, '/'), qr/default\z/, 'and the second, from the port list');
like(body(get($pa, '/io_ready')), qr/got=ping/, 'io_ready on a socket of the handler\'s own resolves');
like(body(get($pa, '/io_ready_closed')), qr/not an open filehandle/, 'io_ready on a closed handle is refused');
like(body(get($pa, '/pool')), qr/workers=\d+;rows=\d+;leader=Shared::Arena::Lease;dc=2/, 'the pool views answer inside a worker with a scoreboard');
like(body(get($pa, '/detach_bad')), qr/give it the PSGI env hashref.*no psgix\.hyperman\.conn.*malformed psgix\.hyperman\.conn/s, 'detach refuses a string, an env without a ticket, and a malformed one');
like(body(get($pa, '/detach_twice')), qr/already detached.*connection is gone/s, 'a second detach and a stale ticket are refused');
like(get($pa, '/detach_draining', 1), qr/response is still draining/, 'detach while a response drains is refused: the client reads nothing while the handler runs');
like(body(get($pa, '/stream_bad')), qr/give it the PSGI env hashref.*no usable psgix\.hyperman\.stream.*headers must be an array reference/s, 'stream refuses a string, an env without a ticket, and headers that are not a list');
my $aborted = get($pa, '/stream_abort');
like($aborted, qr/partial/, 'a stream abort leaves what was written');
unlike($aborted, qr/aborted=/, 'and the response that follows goes nowhere');
like(get($pa, '/stream_drop'), qr/dropped\z/, 'a stream handle dropped without close still ends the body');
like(body(get($pa, '/bus')), qr/big=-1;ok=[01]/, 'the bus refuses a message past the slot size');
Time::HiRes::sleep(0.3);
like(do { local (@ARGV, $/) = ("$dir/access.log"); <> } // '', qr/GET \/io_ready/, 'the access log glob received the lines');
like(do { local (@ARGV, $/) = ("$dir/stderr"); <> } // '', qr/on_worker_start callback died: hook boom/, 'a worker hook that dies is reported');
ok(-s $hook_log, 'after it ran');

kill 'TERM', $pid;
server_reap($pid);
done_testing;
