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

# The pool's edges: a server without the arena printing its own USR1 line, a
# reuseport pool whose workers bind for themselves with an arena too small for
# a scoreboard, USR1 at a supervisor with a board, and a supervisor whose
# caller's alarm comes due.

my ($pa, $pb, $pc) = free_ports(3);
plan skip_all => 'no free loopback ports' unless $pa && $pb && $pc;
plan skip_all => 'signals and fork are not Windows' if $^O eq 'MSWin32';
my $dir = File::Temp::tempdir(CLEANUP => 1);

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
    my ($port, $path) = @_;
    my $s = connect_to($port) or return '';
    $s->syswrite("GET $path HTTP/1.1\r\nHost: a\r\nConnection: close\r\n\r\n");
    my $buf = '';
    eval { local $SIG{ALRM} = sub { die "timeout\n" }; alarm 5; while (my $n = $s->sysread(my $c, 4096)) { $buf .= $c } alarm 0 };
    return $buf;
}
sub slurp { my $f = shift; -f $f ? do { local (@ARGV, $/) = ($f); <> } // '' : '' }
sub wait_for { my ($file, $re) = @_; for (1 .. 30) { my $t = slurp($file); return $t if $t =~ $re; Time::HiRes::sleep(0.1) } return slurp($file) }

# --- a fresh perl without the arena: the worker prints its own USR1 line ---
{
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        quiet_child();
        $ENV{HYPERMAN_NO_SA_ABI} = 1;
        exec $^X, '-Mblib', '-MHyperman', '-e',
            "Hyperman->run(app => sub { [200, [], ['x']] }, host => '127.0.0.1', port => $pa, workers => 1, error_log => '$dir/a.err')";
        exit 1;
    }
    like(get($pa, '/'), qr{^HTTP/1\.1 200}, 'the arena-less server answers');
    kill 'USR1', $pid;
    like(wait_for("$dir/a.err", qr/requests=/), qr/Hyperman worker \d+: requests=\d+ accepts=\d+ conns=\d+ bytes_out=\d+ backend=\w+/, 'USR1 without a scoreboard prints the worker line');
    kill 'TERM', $pid;
    server_reap($pid);
}

# --- a reuseport pool with an arena too small for its scoreboard ---
{
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        quiet_child(stderr => "$dir/b.stderr");
        Hyperman->run(app => sub { [ 200, [], [ "w$$" ] ] }, host => '127.0.0.1', port => $pb, workers => 2,
            reuseport => 1, arena_size => 4096, error_log => "$dir/b.err");
        exit 0;
    }
    my %seen;
    for (1 .. 40) {
        my $r = get($pb, '/');
        $seen{$1}++ if $r =~ /w(\d+)\z/;
        last if keys %seen >= 2;
    }
    ok(scalar(keys %seen) >= 1, 'the reuseport workers bound their own listeners and answer');
    like(wait_for("$dir/b.stderr", qr/could not carve/), qr/could not carve the "deny" map in the arena/, 'an arena too small warns of what it cannot carve');
    kill 'USR1', $pid;
    Time::HiRes::sleep(0.5);
    kill 'TERM', $pid;
    is(server_reap($pid) >> 8, 0, 'the pool stops cleanly');
}

# --- USR1 at a supervisor with a scoreboard prints every row ---
{
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        quiet_child(stderr => "$dir/c.stderr");
        Hyperman->run(app => sub { [ 200, [], ['x'] ] }, host => '127.0.0.1', port => $pc, workers => 2, error_log => "$dir/c.err");
        exit 0;
    }
    like(get($pc, '/'), qr{^HTTP/1\.1 200}, 'the pool answers');
    Time::HiRes::sleep(0.5);
    kill 'USR1', $pid;
    like(wait_for("$dir/c.stderr", qr/\S/), qr/\d/, 'the supervisor prints the scoreboard on USR1');
    kill 'TERM', $pid;
    server_reap($pid);
}

# --- the caller's own alarm ends the pool and is then delivered ---
{
    my ($pd) = free_ports(1);
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        quiet_child();
        alarm 2;
        Hyperman->run(app => sub { [ 200, [], ['x'] ] }, host => '127.0.0.1', port => $pd, workers => 2);
        exit 0;
    }
    like(get($pd, '/'), qr{^HTTP/1\.1 200}, 'the pool under an alarm answers');
    my $st = server_reap($pid);
    is($st & 127, 14, 'the supervisor shut the pool and died of the alarm');
}

done_testing;
