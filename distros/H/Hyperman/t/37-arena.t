#!perl
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use HMTest qw(free_ports quiet_child server_reap);
use IO::Socket::INET;
use Time::HiRes ();
use Hyperman;

# THE ONE ARENA. Hyperman creates a Shared::Arena before it forks, from Perl,
# so Hyperman->arena in a worker is the real object with every tenant on it
# and the same region in every worker. This drives the four things that are
# promised about it: it exists and is anonymous by default; a name makes it
# attachable from outside and survives a restart; the size can be overridden;
# and without the table the server runs exactly as it did before.

plan skip_all => 'prefork workers are POSIX-only' if $^O eq 'MSWin32';
plan skip_all => 'Shared::Arena is not available to this Hyperman '
              . '(HYPERMAN_NO_SA_ABI, or not installed)'
    if $ENV{HYPERMAN_NO_SA_ABI} || !eval { require Shared::Arena; 1 };

my @ports = free_ports(4);
plan skip_all => 'no free loopback ports' unless @ports == 4;

is(Hyperman->arena, undef, 'no arena before run');

my $NAME = "hm-t37-$$";
# Only THIS process unlinks the name at the end. A forked server inherits the
# END block, and its exit would take the region away from the server that
# restarts after it - which is the very thing the restart case proves.
my $ME = $$;
END { Shared::Arena->destroy($NAME) if $NAME && $$ == $ME }

# The app every server runs: reports on the arena, stores into a map on it,
# reads the map back. The map is carved by whichever worker first asks.
my $APP = sub {
    my ($env) = @_;
    my $path = $env->{PATH_INFO} || '/';
    my $a    = Hyperman->arena;
    my $out;
    if ($path eq '/info') {
        $out = $a ? sprintf('arena=%s size=%d created=%d', ref $a, $a->size,
                            $a->created ? 1 : 0)
                  : 'arena=none';
    }
    elsif ($path eq '/store') {
        my $m = $a->map('t37', slots => 16, slot_size => 64);
        $out = 'stored=' . $m->store('k', "from-$$");
    }
    elsif ($path eq '/fetch') {
        my $m = $a->map('t37', slots => 16, slot_size => 64);
        my ($v) = $m->fetch('k');
        $out = 'value=' . (defined $v ? $v : 'none');
    }
    else { $out = 'ok' }
    return [ 200, [ 'Content-Type' => 'text/plain',
                    'Content-Length' => length $out ], [$out] ];
};

sub start_server {
    my ($port, %extra) = @_;
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        quiet_child();
        Hyperman->run(app => $APP, host => '127.0.0.1', port => $port,
                      workers => 2, %extra);
        exit 0;
    }
    return $pid;
}

# A server in a FRESH perl, so an environment variable read at Hyperman's
# BOOT is read: this process resolved the table long before the test began.
sub start_server_fresh {
    my ($port, %env) = @_;
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        quiet_child();
        $ENV{$_} = $env{$_} for keys %env;
        my $code = q{
            use Hyperman;
            my $port = shift @ARGV;
            Hyperman->run(app => sub {
                my $a = Hyperman->arena;
                my $out = $a ? 'arena=' . ref $a : 'arena=none';
                [200, ['Content-Type' => 'text/plain',
                       'Content-Length' => length $out], [$out]];
            }, host => '127.0.0.1', port => $port, workers => 1);
        };
        exec $^X, (map { "-I$_" } @INC), '-e', $code, $port
            or die "exec: $!";
    }
    return $pid;
}

sub http_get {
    my ($port, $path) = @_;
    for (1 .. 100) {
        my $s = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $port,
                                      Proto => 'tcp', Timeout => 2);
        if (!$s) { Time::HiRes::sleep(0.05); next }
        syswrite $s, "GET $path HTTP/1.0\r\nHost: x\r\n\r\n";
        local $/;
        my $res = <$s>;
        close $s;
        return $1 if defined $res && $res =~ /\r\n\r\n(.*)\z/s && length $1;
        Time::HiRes::sleep(0.05);
    }
    return '';
}

sub stop_server {
    my ($pid) = @_;
    kill 'TERM', $pid;
    my $st = server_reap($pid);
    return $st;
}

# ---- anonymous by default, and big enough for every table ------------------
{
    my $pid  = start_server($ports[0]);
    my $info = http_get($ports[0], '/info');
    like($info, qr/^arena=Shared::Arena /, 'a worker sees a Shared::Arena');
    my ($size) = $info =~ /size=(\d+)/;
    cmp_ok($size, '>', 4_000_000,
           "sized for the denylist, the counters and the ring ($size bytes)");
    like($info, qr/created=1/, 'and this server created it');
    stop_server($pid);
}

# ---- a name: attachable from outside, and kept across a restart -----------
{
    my $pid = start_server($ports[1], arena_name => $NAME);
    is(http_get($ports[1], '/store'), 'stored=1',
       'a worker stored into a map on the named arena');

    # From THIS process, which is no relation of the workers: by name.
    my $outside = Shared::Arena->attach($NAME);
    ok($outside, 'a separate process attached to it by name');
    SKIP: {
        skip 'no attach', 1 unless $outside;
        my ($v) = $outside->map('t37', slots => 16, slot_size => 64)->fetch('k');
        like($v, qr/^from-\d+$/, "and read what the worker stored ($v)");
    }
    undef $outside;
    stop_server($pid);

    # A restart attaches to the region the last server left, map and all.
    my $pid2 = start_server($ports[2], arena_name => $NAME);
    like(http_get($ports[2], '/info'), qr/created=0/,
         'a restarted server attached rather than creating afresh');
    like(http_get($ports[2], '/fetch'), qr/^value=from-\d+$/,
         'and the map the previous server filled is still there');
    stop_server($pid2);
}

# ---- arena_size overrides the computed size --------------------------------
{
    my $pid  = start_server($ports[3], arena_size => 262_144);
    my $info = http_get($ports[3], '/info');
    my ($size) = $info =~ /size=(\d+)/;
    cmp_ok($size, '>=', 262_144, 'arena_size is honoured');
    cmp_ok($size, '<', 1_000_000, '...rather than the computed default');
    stop_server($pid);
}

# ---- and without the table, exactly the server there was before ------------
{
    my $pid = start_server_fresh($ports[0], HYPERMAN_NO_SA_ABI => 1);
    is(http_get($ports[0], '/'), 'arena=none',
       'HYPERMAN_NO_SA_ABI: no arena, and the server serves regardless');
    stop_server($pid);
}

done_testing;
