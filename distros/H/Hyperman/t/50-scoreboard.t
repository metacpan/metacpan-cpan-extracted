#!perl
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use HMTest qw(free_ports quiet_child server_guard server_reap slurp);
use IO::Socket::INET;
use Time::HiRes ();
use File::Temp ();
use Hyperman;

# THE SCOREBOARD. One row per worker on the Shared::Arena, mirrored from a
# one-second timer and never from a request. Two workers serve requests; the
# rows must show two live workers whose request counts SUM to the requests
# made - converging over ticks, never a fixed sleep - and a worker killed
# outright reads as not alive. USR1 to the supervisor prints the aggregate.

plan skip_all => 'prefork workers are POSIX-only' if $^O eq 'MSWin32';
plan skip_all => 'Shared::Arena is not available to this Hyperman'
    if $ENV{HYPERMAN_NO_SA_ABI} || !eval { require Shared::Arena; 1 };

my ($port) = free_ports(1);
plan skip_all => 'no free loopback port' unless $port;

my $NAME = "hm-t50-$$";
my $ME   = $$;
END { Shared::Arena->destroy($NAME) if $NAME && $$ == $ME }

my $errlog = File::Temp->new;

my $pid = server_guard(fork // die "fork: $!");
if (!$pid) {
    quiet_child(stderr => "$errlog");
    Hyperman->run(
        app => sub {
            my ($env) = @_;
            my $out;
            if ($env->{PATH_INFO} eq '/rows') {
                # a worker reads the whole board too
                my @rows = Hyperman->pool_stats;
                $out = join ';', map { "$_->{pid}:$_->{requests}:$_->{alive}" } @rows;
            }
            elsif ($env->{PATH_INFO} eq '/pool') {
                my $p = Hyperman->stats(pool => 1);
                $out = $p ? "workers=$p->{workers} alive=$p->{alive} requests=$p->{requests}" : 'none';
            }
            else { $out = "pid=$$" }
            [ 200, [ 'Content-Type' => 'text/plain', 'Content-Length' => length $out ], [$out] ];
        },
        host => '127.0.0.1', port => $port, workers => 2, arena_name => $NAME,
    );
    exit 0;
}

sub http_get {
    my ($path) = @_;
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

# ---- requests, then the board converges on them ------------------------------
my $made = 0;
my %pids;
for (1 .. 20) {
    my $b = http_get('/');
    $made++;
    $pids{$1} = 1 if $b =~ /pid=(\d+)/;
}
is($made, 20, 'twenty requests answered');

# From OUTSIDE the pool, by name: the whole point of arena_name.
my $arena = Shared::Arena->attach($NAME);
ok($arena, 'attached to the server arena by name');

# Converge: the rows are mirrored once a second, so poll until the live rows'
# requests account for every request made (the /rows and /pool requests below
# add to the count as they are made, so compare against a running total).
my (@rows, $sum);
for (1 .. 60) {
    my $body = http_get('/rows');
    $made++;
    @rows = map { [ split /:/ ] } split /;/, $body;
    $sum  = 0;
    $sum += $_->[1] for grep { $_->[2] } @rows;
    # every request so far but this one may not be mirrored yet
    last if $sum >= $made - 1 && grep({ $_->[2] } @rows) == 2;
    Time::HiRes::sleep(0.25);
}
is(scalar(grep { $_->[2] } @rows), 2, 'two live rows, one per worker');
cmp_ok($sum, '>=', $made - 1,
       "the live rows' requests sum to the requests made ($sum of $made)");
cmp_ok($sum, '<=', $made, '...and not more');

my $pool = http_get('/pool');
$made++;
like($pool, qr/^workers=\d+ alive=2 requests=\d+$/,
     "stats(pool => 1) sums the board ($pool)");

# ---- USR1: the supervisor prints the aggregate and the rows ------------------
# Poll for the WHOLE dump, not for its first line: the supervisor is writing
# the log while this reads it, and a read that lands mid-dump would see an
# aggregate line with no rows under it and call that a pool with no workers.
kill 'USR1', $pid;
my ($log, @lines) = ('');
for (1 .. 60) {
    $log   = slurp("$errlog");
    @lines = $log =~ /^(Hyperman worker \d+: requests=\d+ .*)$/mg;
    last if $log =~ /Hyperman pool:/ && @lines >= 2;
    Time::HiRes::sleep(0.05);
}
like($log, qr/^Hyperman pool: workers=\d+ alive=2 requests=\d+/m,
     'USR1 printed one aggregate line');
is(scalar @lines, 2, 'and one line per worker')
    or diag("the USR1 dump was:\n$log");
unlike($log, qr/DEAD/, 'with nobody dead');

# ---- a worker killed outright reads as not alive ------------------------------
{
    my ($victim) = sort keys %pids;
    kill 'KILL', $victim;
    my $dead;
    for (1 .. 40) {
        my @r = $arena->scoreboard('workers', fields => [qw(requests accepts denied conns bytes_out datagrams h3)])->all;
        ($dead) = grep { $_->{pid} == $victim && !$_->{alive} } @r;
        last if $dead;
        Time::HiRes::sleep(0.05);
    }
    ok($dead, "the killed worker $victim reads as alive 0 from outside");
}

kill 'TERM', $pid;
server_reap($pid);
done_testing;
