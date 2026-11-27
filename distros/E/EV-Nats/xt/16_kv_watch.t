use strict;
use warnings;
use Test::More;
use lib 'xt/lib';
use EVNatsHelpers qw(nats_or_skip js_or_skip free_port);
use EV;
use EV::Nats;
use EV::Nats::JetStream;
use EV::Nats::KV;
use POSIX ();

my ($host, $port) = nats_or_skip();
my $nats   = EV::Nats->new(host => $host, port => $port);
my $js     = EV::Nats::JetStream->new(nats => $nats, timeout => 2000);
my $bucket = "evnats_kvw_$$";
my $kv     = EV::Nats::KV->new(js => $js, bucket => $bucket);

js_or_skip($nats, sub { my ($d) = @_; $kv->create_bucket({ max_history => 5 }, sub { $d->($_[1]) }) });

# run the loop until $done->() is true or $secs pass
sub wait_for {
    my ($done, $secs) = @_;
    EV::now_update;
    my $t = EV::timer 0.02, 0.02, sub { EV::break if $done->() };
    my $g = EV::timer $secs, 0, sub { EV::break };
    EV::run;
    return $done->();
}

sub kv_do {   # run one KV call to completion
    my ($meth, @args) = @_;
    my @r;
    $kv->$meth(@args, sub { @r = (1, @_) });
    wait_for(sub { @r }, 5);
    return @r[1 .. $#r];
}

subtest 'stored changes arrive in order, each once' => sub {
    plan tests => 2;
    my (@ev, $ready);
    my $sid = $kv->watch('alpha', sub { push @ev, "@_[2, 0, 1]" }, { ready => sub { $ready = 1 } });
    ok wait_for(sub { $ready }, 5), 'ready';
    kv_do(put => 'alpha', 'one');
    kv_do(put => 'alpha', 'two');
    kv_do(delete => 'alpha');
    kv_do(purge => 'alpha');
    wait_for(sub { @ev >= 4 }, 5);
    is_deeply \@ev, ['PUT alpha one', 'PUT alpha two', 'DEL alpha ', 'PURGE alpha '], 'exactly the stored writes';
    $nats->unsubscribe($sid);
};

subtest 'a write the bucket rejects is not reported' => sub {
    plan tests => 3;
    my (@ev, $ready);
    my $sid = $kv->watch('lock', sub { push @ev, "@_[2, 0, 1]" }, { ready => sub { $ready = 1 } });
    wait_for(sub { $ready }, 5);
    my ($rev) = kv_do(create => 'lock', 'a');
    my (undef, $err) = kv_do(create => 'lock', 'b');
    like $err, qr/wrong last sequence/, 'the second create was refused';
    (undef, $err) = kv_do(update => 'lock', 'c', $rev + 10);
    like $err, qr/wrong last sequence/, 'and a stale update';
    wait_for(sub { 0 }, 0.5);
    is_deeply \@ev, ['PUT lock a'], 'only the stored value was reported';
    $nats->unsubscribe($sid);
};

subtest 'initial delivers the current values, then changes' => sub {
    plan tests => 2;
    kv_do(put => 'cfg.a', '1');
    kv_do(put => 'cfg.b', '2');
    kv_do(put => 'cfg.a', '3');
    my (@ev, $ready_at);
    my $sid = $kv->watch('cfg.>', sub { push @ev, "$_[0]=$_[1]" },
        { initial => 1, ready => sub { $ready_at = scalar @ev } });
    wait_for(sub { defined $ready_at }, 5);
    kv_do(put => 'cfg.c', '4');
    wait_for(sub { @ev >= 3 }, 5);
    is_deeply [sort @ev[0, 1]], ['cfg.a=3', 'cfg.b=2'], 'the latest value per key';
    is_deeply [$ready_at, $ev[2]], [2, 'cfg.c=4'], 'ready after them, then the change';
    $nats->unsubscribe($sid);
};

# the server deletes consumers asynchronously: poll until the count is $want
sub consumers {
    my ($want) = @_;
    my $n;
    for (1 .. 25) {
        undef $n;
        $js->consumer_list("KV_$bucket", sub { $n = $_[0] ? scalar @{ $_[0]{consumers} || [] } : -1 });
        wait_for(sub { defined $n }, 5);
        last if !defined $want || ($n // -1) == $want;
        wait_for(sub { 0 }, 0.2);
    }
    return $n;
}

subtest 'unsubscribe stops the watch and removes its consumer' => sub {
    plan tests => 4;
    is consumers(0), 0, 'the earlier watches left no consumer';
    my ($n, $ready) = (0);
    my $sid = $kv->watch('stop', sub { $n++ }, { ready => sub { $ready = 1 } });
    wait_for(sub { $ready }, 5);
    is consumers(1), 1, 'one consumer while watching';
    $nats->unsubscribe($sid);
    kv_do(put => 'stop', 'x');
    wait_for(sub { 0 }, 0.5);
    is $n, 0, 'nothing delivered after unsubscribe';
    is consumers(0), 0, 'and its consumer is gone';
};

subtest 'a watch resumes after a drop without missing a write' => sub {
    my $socat = `which socat 2>/dev/null`;
    chomp $socat;
    plan skip_all => 'socat not found' unless $socat && -x $socat;
    plan tests => 4;
    my $pport = free_port();
    my $proxy = sub {   # one connection, then exits
        my $pid = fork // die "fork: $!";
        if (!$pid) {
            open STDERR, '>', '/dev/null';
            { exec $socat, "TCP-LISTEN:$pport,reuseaddr", "TCP:$host:$port" }
            POSIX::_exit(1);
        }
        select undef, undef, undef, 0.3;
        return $pid;
    };
    my $pid = $proxy->();
    my ($connects, @ev, $ready) = (0);
    my $wnats = EV::Nats->new(host => '127.0.0.1', port => $pport,
        reconnect => 1, reconnect_delay => 100, max_reconnect_delay => 300,
        on_error => sub {}, on_connect => sub { $connects++ });
    my $wkv = EV::Nats::KV->new(js => EV::Nats::JetStream->new(nats => $wnats, timeout => 2000),
                                bucket => $bucket);
    $wkv->watch('gap.>', sub { push @ev, "$_[0]=$_[1]" }, { ready => sub { $ready = 1 } });
    wait_for(sub { $ready }, 5);
    kv_do(put => 'gap.before', '1');
    wait_for(sub { @ev >= 1 }, 5);
    kill 'TERM', $pid;
    waitpid $pid, 0;
    wait_for(sub { !$wnats->is_connected }, 5);
    kv_do(put => 'gap.during', '2');
    $pid = $proxy->();
    ok wait_for(sub { $connects >= 2 }, 10), 'reconnected through the proxy';
    kv_do(put => 'gap.after', '3');
    wait_for(sub { @ev >= 3 }, 5);
    is_deeply \@ev, ['gap.before=1', 'gap.during=2', 'gap.after=3'], 'the write made while down arrived';
    ok $wnats->is_connected, 'still connected';
    is consumers(1), 1, 'the replaced consumer was deleted';
    $wnats->disconnect;
    kill 'TERM', $pid;
    waitpid $pid, 0;
};

subtest 'a watch does not keep EV::run going after disconnect' => sub {
    plan tests => 1;
    my $wnats = EV::Nats->new(host => $host, port => $port, reconnect => 1, on_error => sub {});
    my $wkv = EV::Nats::KV->new(js => EV::Nats::JetStream->new(nats => $wnats, timeout => 2000),
                                bucket => $bucket);
    my $ready;
    $wkv->watch('idle', sub {}, { ready => sub { $ready = 1 } });
    wait_for(sub { $ready }, 5);
    $nats->disconnect;   # its own watchers would keep the loop going
    $wnats->disconnect;
    my $t0 = time;
    my $g = EV::timer 5, 0, sub { EV::break };
    $g->keepalive(0);
    EV::run;   # returns once only keepalive(0) watchers are left
    cmp_ok time - $t0, '<', 3, 'EV::run returned';
    $nats->connect($host, $port);
    wait_for(sub { $nats->is_connected }, 5);
};

kv_do('delete_bucket');
$nats->disconnect;
done_testing;
