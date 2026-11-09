#!perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use HMTest qw(free_ports quiet_child server_reap);
use IO::Socket::INET;
use Time::HiRes ();
use File::Temp ();
use Fcntl qw(F_GETFD F_SETFD FD_CLOEXEC);
use POSIX qw(WNOHANG);
use Hyperman;

# The supervisor's edges: a HUP recycle, a worker that stops ticking, the
# caller's alarm met on a tick, USR1 at a pool without a scoreboard, a USR2
# re-exec with a second USR2 while the successor starts, a handover
# environment naming a descriptor that is not a listener and one for a
# listener the new config dropped, a pid file in a directory that cannot be
# written, a chunked body past the spill mark with TMPDIR unset, and a
# listener starved of descriptors.

plan skip_all => 'signals and fork are not Windows' if $^O eq 'MSWin32';
my ($pa, $pb, $pc, $pd, $pe, $pf, $pg) = free_ports(7);
plan skip_all => 'no free loopback ports' unless $pg;
my $dir = File::Temp::tempdir(CLEANUP => 1);

sub connect_to {
    my $port = shift;
    for (1 .. 80) {
        my $s = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port");
        return $s if $s;
        Time::HiRes::sleep(0.1);
    }
    return;
}
sub get {
    my ($port, $path) = @_;
    my $s = connect_to($port) or return '';
    $s->syswrite("GET $path HTTP/1.1\r\nHost: a\r\nConnection: close\r\n\r\n");
    my $buf = '';
    eval { local $SIG{ALRM} = sub { die "timeout\n" }; alarm 5; while (my $n = $s->sysread(my $c, 65536)) { $buf .= $c } alarm 0 };
    return $buf;
}
sub body { my $r = shift; (split /\r\n\r\n/, $r, 2)[1] // '' }
sub slurp { my $f = shift; -f $f ? do { local (@ARGV, $/) = ($f); <> } // '' : '' }
sub wait_for { my ($file, $re, $secs) = @_; for (1 .. ($secs || 5) * 10) { my $t = slurp($file); return $t if $t =~ $re; Time::HiRes::sleep(0.1) } return slurp($file) }
sub wait_gone { my $pid = shift; for (1 .. 100) { return 1 if kill(0, $pid) == 0; Time::HiRes::sleep(0.1) } return 0 }
sub pids_of { my ($port, $n) = @_; my %p; for (1 .. 60) { my $b = body(get($port, '/pid')); $p{$1} = 1 if $b =~ /^w(\d+)/; last if keys %p >= $n } return sort keys %p }

my $app = sub {
    my $env = shift;
    my $p = $env->{PATH_INFO};
    if ($p eq '/pid') { return [ 200, [], [ "w$$" ] ] }
    if ($p eq '/len') {
        my $body = '';
        my $in = $env->{'psgi.input'};
        while ($in->read(my $c, 65536)) { $body .= $c }
        return [ 200, [], [ 'len=' . length($body) . ';' . ref($in) ] ];
    }
    [ 200, [], ['x'] ];
};

# --- HUP: fresh workers, the old ones drained ---
{
    my $pid = fork // die "fork: $!";
    if (!$pid) { quiet_child(); Hyperman->run(app => $app, host => '127.0.0.1', port => $pa, workers => 2); exit 0 }
    my @old = pids_of($pa, 2);
    ok(scalar @old >= 1, 'the pool answers');
    kill 'HUP', $pid;
    my @new;
    for (1 .. 50) { @new = pids_of($pa, 2); last if @new && !grep { my $n = $_; grep { $_ == $n } @old } @new; Time::HiRes::sleep(0.2) }
    ok(@new && !grep({ my $n = $_; grep { $_ == $n } @old } @new), 'after a HUP fresh workers answer') or diag "old @old new @new";
    ok(!grep({ !wait_gone($_) } @old), 'and the old ones are gone');
    kill 'TERM', $pid;
    server_reap($pid);
}

# --- a worker that stops updating its row, and the caller's alarm on a tick ---
{
    my $pid = fork // die "fork: $!";
    if (!$pid) { quiet_child(stderr => "$dir/wedge.err"); alarm 14; Hyperman->run(app => $app, host => '127.0.0.1', port => $pb, workers => 2); exit 0 }
    my @w = pids_of($pb, 2);
    ok(scalar @w >= 1, 'the pool to be wedged answers');
    kill 'STOP', $w[0];
    like(wait_for("$dir/wedge.err", qr/wedged/, 14), qr/worker $w[0] is alive but has not updated its scoreboard row for 9 seconds: wedged\?/, 'a worker whose row stops moving is reported after three ticks');
    kill 'CONT', $w[0];
    my $st = server_reap($pid);
    is($st & 127, 14, 'the alarm met on a tick drains the pool and is then delivered');
}

# --- USR1 at a pool with no scoreboard: every worker prints its own line ---
{
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        quiet_child();
        $ENV{HYPERMAN_NO_SA_ABI} = 1;
        exec $^X, '-Mblib', '-MHyperman', '-e', "Hyperman->run(app => sub { [200, [], ['x']] }, host => '127.0.0.1', port => $pc, workers => 2, error_log => '$dir/usr1.err')";
        exit 1;
    }
    like(get($pc, '/'), qr{^HTTP/1\.1 200}, 'the arena-less pool answers');
    Time::HiRes::sleep(0.5);
    kill 'USR1', $pid;
    my $log = wait_for("$dir/usr1.err", qr/requests=.*\n.*requests=/s);
    is(scalar(() = $log =~ /Hyperman worker \d+: requests=/g), 2, 'USR1 is passed to both workers, each printing its line');
    kill 'TERM', $pid;
    server_reap($pid);
}

# --- USR2: a successor takes over, a second USR2 while it starts is ignored ---
{
    my $pidfile = "$dir/reexec.pid";
    my $sock = "$dir/reexec.sock";
    my $code = "Hyperman->run(app => sub { [200, [], [\"w\$\$\"]] }, host => '127.0.0.1', listen => [ { port => $pd }, { path => '$sock' } ], workers => 2, pid_file => '$pidfile', error_log => '$dir/reexec.err')";
    my $pid = fork // die "fork: $!";
    if (!$pid) { quiet_child(); exec $^X, '-Mblib', '-MHyperman', '-e', $code; exit 1 }
    like(get($pd, '/'), qr{^HTTP/1\.1 200}, 'the pool to be re-executed answers');
    is(slurp($pidfile) + 0, $pid, 'and wrote its pid');
    kill 'USR2', $pid;
    Time::HiRes::sleep(0.05);
    kill 'USR2', $pid;
    my $log = wait_for("$dir/reexec.err", qr/asked to drain/, 20);
    like($log, qr/USR2: successor (\d+) started/, 'a USR2 starts a successor');
    like($log, qr/USR2 ignored: successor \d+ is still starting/, 'and a second USR2 while it starts is ignored');
    like($log, qr/re-exec: pool up, supervisor $pid asked to drain/, 'the successor asks the old supervisor to drain');
    my $reaped = 0;
    for (1 .. 100) { if (waitpid($pid, WNOHANG) == $pid) { $reaped = 1; last } Time::HiRes::sleep(0.1) }
    ok($reaped, 'which exits');
    my $succ = slurp($pidfile) + 0;
    ok($succ && $succ != $pid && kill(0, $succ), 'the pid file names the successor');
    like(get($pd, '/'), qr{^HTTP/1\.1 200}, 'which serves the inherited port');
    kill 'TERM', $succ;
    ok(wait_gone($succ), 'and stops on TERM');
}

# --- a handover environment by hand ---
{
    my $sleeper = fork // die "fork: $!";
    if (!$sleeper) { sleep 30 while 1 }
    open my $plain, '<', $0 or die;
    my $flags = fcntl($plain, F_GETFD, 0);
    fcntl($plain, F_SETFD, $flags & ~FD_CLOEXEC);
    my $fd = fileno $plain;
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        quiet_child(stderr => "$dir/adopt.err");
        $ENV{HYPERMAN_REEXEC} = "sup=$sleeper;arena=hm_t74_adopt;l=127.0.0.1|$pe|$fd|-1";
        exec $^X, '-Mblib', '-MHyperman', '-e', "eval { Hyperman->run(app => sub { [200, [], ['x']] }, host => '127.0.0.1', port => $pe, workers => 1) }; print STDERR \"err=\$\@\"";
        exit 1;
    }
    server_reap($pid);
    like(slurp("$dir/adopt.err"), qr/err=Hyperman->run: re-exec: handed fd $fd for 127\.0\.0\.1 is not the listener it was said to be/, 'a handed descriptor that is not a listener is refused');
    $pid = fork // die "fork: $!";
    if (!$pid) {
        quiet_child(stderr => "$dir/adopt2.err");
        $ENV{HYPERMAN_REEXEC} = "sup=$sleeper;arena=hm_t74_adopt;l=127.0.0.1|1|$fd|-1;u=/no/such|$fd;junk";
        exec $^X, '-Mblib', '-MHyperman', '-e', "Hyperman->run(app => sub { [200, [], ['x']] }, host => '127.0.0.1', port => $pf, workers => 2, error_log => '$dir/adopt2.err')";
        exit 1;
    }
    like(get($pf, '/'), qr{^HTTP/1\.1 200}, 'a handover naming only listeners the config dropped still binds its own');
    waitpid $sleeper, 0;
    is($? & 127, 15, 'and the old supervisor it names is asked to drain');
    kill 'TERM', $pid;
    server_reap($pid);
}

# --- a pid file in a directory that cannot be written ---
SKIP: {
    skip 'root can write anywhere', 3 if $> == 0;
    my $ro = "$dir/ro";
    mkdir $ro or die;
    open my $pf, '>', "$ro/have.pid" or die; print $pf "0\n"; close $pf;
    chmod 0555, $ro;
    eval { Hyperman->run(app => $app, host => '127.0.0.1', port => 0, workers => 1, pid_file => "$ro/new.pid") };
    like($@, qr/pid_file '.*new\.pid': (?:Permission denied|No such file or directory)/, 'a pid file that cannot be created is refused');
    my $pid = fork // die "fork: $!";
    if (!$pid) { quiet_child(); Hyperman->run(app => $app, host => '127.0.0.1', port => $pg, workers => 1, pid_file => "$ro/have.pid"); exit 0 }
    like(get($pg, '/'), qr{^HTTP/1\.1 200}, 'a pid file that exists in such a directory is rewritten in place');
    is(slurp("$ro/have.pid") + 0, $pid, 'with the server\'s pid');
    kill 'TERM', $pid;
    server_reap($pid);
    is(-s "$ro/have.pid", 0, 'and truncated at exit, since it cannot be unlinked');
    chmod 0755, $ro;
}

# --- a chunked body past the spill mark, with no TMPDIR ---
{
    my ($port) = free_ports(1);
    my $pid = fork // die "fork: $!";
    if (!$pid) { quiet_child(); delete $ENV{TMPDIR}; Hyperman->run(app => $app, host => '127.0.0.1', port => $port, workers => 1); exit 0 }
    my $s = connect_to($port) or die;
    my $chunk = 'c' x 65536;
    $s->syswrite("POST /len HTTP/1.1\r\nHost: a\r\nTransfer-Encoding: chunked\r\nConnection: close\r\n\r\n");
    $s->syswrite(sprintf("%x\r\n%s\r\n", length $chunk, $chunk)) for 1 .. 17;
    $s->syswrite("0\r\n\r\n");
    my $buf = '';
    eval { local $SIG{ALRM} = sub { die "timeout\n" }; alarm 10; while (my $n = $s->sysread(my $c, 65536)) { $buf .= $c } alarm 0 };
    like(body($buf), qr/^len=1114112;/, 'a chunked body past a megabyte is handed over through a temp file');
    kill 'TERM', $pid;
    server_reap($pid);
}

# --- a listener starved of descriptors ---
SKIP: {
    skip 'no sh to lower the descriptor limit', 3 unless -x '/bin/sh';
    my ($port) = free_ports(1);
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        quiet_child(stderr => "$dir/starve.err");
        exec '/bin/sh', '-c', "ulimit -n 48 && exec $^X -Mblib -MHyperman -e 'Hyperman->run(app => sub { [200, [], [q{x}]] }, host => q{127.0.0.1}, port => $port, workers => 1, error_log => q{$dir/starve.err})'";
        exit 1;
    }
    like(get($port, '/'), qr{^HTTP/1\.1 200}, 'the starved-to-be server answers');
    my @keep;
    for (1 .. 60) {
        my $s = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port") or last;
        $s->syswrite("GET /ka HTTP/1.1\r\nHost: a\r\n\r\n");
        my $r = '';
        eval { local $SIG{ALRM} = sub { die "timeout\n" }; alarm 3; $s->sysread($r, 4096); alarm 0 };
        push @keep, $s;
    }
    ok(@keep >= 40, 'sixty keep-alive connections were opened past the limit, idle ones reclaimed to admit the next') or diag scalar @keep;
    my @idle;
    for (1 .. 60) {
        my $s = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port") or last;
        push @idle, $s;
    }
    Time::HiRes::sleep(0.5);
    ok(@idle >= 40, 'sixty connections that never speak are accepted as far as the table allows') or diag scalar @idle;
    @idle = ();
    like(get($port, '/'), qr{^HTTP/1\.1 200}, 'with nothing idle to reclaim, the listener rests until the table has room, then answers');
    @keep = ();
    kill 'TERM', $pid;
    server_reap($pid);
}

done_testing;
