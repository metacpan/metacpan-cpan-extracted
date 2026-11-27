use strict;
use warnings;
use Test::More;
use lib 'xt/lib';
use EVNatsHelpers qw(nats_bin_or_skip free_port spawn_nats);
use File::Temp ();
use Time::HiRes ();
use EV;
use EV::Nats;
use EV::Nats::JetStream;
use EV::Nats::KV;
use EV::Nats::ObjectStore;
use JSON::PP ();

# fetch, acks and KV against a real JetStream server this test owns, so it
# can kill and stop it.

my $bin = nats_bin_or_skip();
plan tests => 21;

sub mono { Time::HiRes::clock_gettime(Time::HiRes::CLOCK_MONOTONIC()) }

sub wait_for {
    my ($cond, $secs) = @_;
    EV::now_update;
    my $timed_out;
    my $g = EV::timer $secs // 10, 0, sub { $timed_out = 1 };
    EV::run(EV::RUN_ONCE) until $cond->() || $timed_out;
    return !$timed_out;
}

my ($port, $pid, $nats, $js);
my $dir = File::Temp::tempdir(CLEANUP => 1);

sub start {
    $port = free_port();
    $pid = spawn_nats($bin, '-js', '-sd', $dir, '-a', '127.0.0.1', '-p', $port,
        '-l', "$dir/server.log");
    my $up;
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $port, no_responders => 1,
        on_connect => sub { $up = 1 }, on_error => sub { },
    );
    wait_for(sub { $up }) or BAIL_OUT('cannot connect to the spawned nats-server');
    $js = EV::Nats::JetStream->new(nats => $nats, timeout => 3000, with_status => 1);
}

sub call {
    my ($method, @args) = @_;
    my $r;
    $js->$method(@args, sub { $r = [@_] });
    wait_for(sub { $r }) or return [undef, 'test timeout'];
    return $r;
}

sub setup {
    my $r = call(stream_create => { name => 'S', subjects => ['s.>'] });
    die "stream_create: $r->[1]" if $r->[1] && $r->[1] !~ /already in use/;
    $r = call(consumer_create => 'S', {
        durable_name => 'C', ack_policy => 'explicit', ack_wait => 20_000_000_000,
    });
    die "consumer_create: $r->[1]" if $r->[1];
}

start();
setup();

# A pull whose inbox lost interest still receives a message, which then
# waits out ack_wait; cancel must hand it back at once.
my $called;
my $h = $js->fetch('S', 'C', { batch => 1, expires => 10_000_000_000 }, sub { $called++ });
my $fenced; $nats->flush(sub { $fenced = 1 }); wait_for(sub { $fenced });
$h->cancel;
call(js_publish => 's.x', 'm1');
my $t0 = mono();
my $r = call(fetch => 'S', 'C', { batch => 1, expires => 15_000_000_000 });
is scalar @{ $r->[0] || [] }, 1, 'cancelled fetch: the message was redelivered';
ok mono() - $t0 < 5, '... without waiting out ack_wait';
ok !$called, '... and the cancelled callback never fired';

is $js->ack($r->[0][0]), 1, 'ack sent';
wait_for(sub { 0 }, 0.3);
$r = call(consumer_info => 'S', 'C');
is $r->[0]{num_ack_pending}, 0, 'ack applied';

call(js_publish => 's.x', 'm1b');
$r = call(fetch => 'S', 'C', { batch => 1, expires => 2_000_000_000 });
my $msg = $r->[0][0];
my $synced;
$js->ack_sync($msg, sub { $synced = [@_] });
wait_for(sub { $synced });
$r = call(consumer_info => 'S', 'C');
is_deeply [@$synced, $r->[0]{num_ack_pending}], [1, undef, 0], 'ack_sync confirmed an applied ack';
(my $gone = $msg->{reply}) =~ s/\.C\./.GONE./;
$synced = undef;
$js->ack_sync($gone, sub { $synced = [@_] });
wait_for(sub { $synced });
is_deeply $synced, [undef, 'no responders'], 'ack_sync for a missing consumer';

call(js_publish => 's.x', 'm2');
$r = call(fetch => 'S', 'C', { batch => 1, expires => 2_000_000_000 });
$js->term($r->[0][0], 'poison');
$r = call(fetch => 'S', 'C', { batch => 1, no_wait => 1 });
is_deeply [$r->[0], $r->[2]{code}], [[], 404], 'term: not redelivered, no_wait ends with 404';

# Recent servers answer an unknown consumer 503; 2.10 does not answer.
$r = call(fetch => 'S', 'NOPE', { batch => 1, no_wait => 1 });
ok +(($r->[1] // '') eq 'fetch failed: NATS/1.0 503'
     && $r->[2] && $r->[2]{code} == 503 && $r->[2]{description} eq '')
    || (ref $r->[0] && !@{ $r->[0] } && !defined $r->[1] && !defined $r->[2]),
    'unknown consumer: 503 status, or an empty batch once the wait runs out'
    or diag explain $r;

$r = call(consumer_info => 'S', 'NOPE');
is $r->[2]{err_code}, 10014, 'API error object carries err_code';

my $kv = EV::Nats::KV->new(js => $js, bucket => 'b');
my $made; $kv->create_bucket({}, sub { $made = [@_] }); wait_for(sub { $made });
my $put; $kv->put('k', 'v1', sub { $put = [@_] }); wait_for(sub { $put });
my $got; $kv->get_entry('k', sub { $got = [@_] }); wait_for(sub { $got });
is_deeply $got->[0], { value => 'v1', revision => $put->[0] },
    'KV get_entry carries the revision';

# Values past ~3/4 max_payload cannot come back through STREAM.MSG.GET
# (base64 in JSON); Direct Get returns them raw.
my $big = join '', map { chr($_ % 256) } 1 .. 900 * 1024;
$put = undef; $kv->put('big', $big, sub { $put = [@_] }); wait_for(sub { $put });
$got = undef; $kv->get_entry('big', sub { $got = [@_] }); wait_for(sub { $got }, 10);
ok $got->[0] && $got->[0]{value} eq $big, 'a 900 KB KV value reads back under a 1 MB max_payload'
    or diag explain [$got->[1]];
my $dg; $js->direct_get('KV_b', { last_by_subj => '$KV.b.big' }, sub { $dg = [@_] }); wait_for(sub { $dg });
is $dg->[0]{seq}, $put->[0], 'direct_get reports the sequence';

my $made_legacy;
$js->stream_create({ name => 'KV_old', subjects => ['$KV.old.>'], max_msgs_per_subject => 1,
    allow_rollup_hdrs => JSON::PP::true(), deny_delete => JSON::PP::true() }, sub { $made_legacy = [@_] });
wait_for(sub { $made_legacy });
my $old = EV::Nats::KV->new(js => EV::Nats::JetStream->new(nats => $nats), bucket => 'old');
$put = undef; $old->put('k', 'v-old', sub { $put = [@_] }); wait_for(sub { $put });
$got = undef; $old->get('k', sub { $got = [@_] }); wait_for(sub { $got });
is $got->[0], 'v-old', 'a bucket without allow_direct is still read';

my $os = EV::Nats::ObjectStore->new(js => $js, bucket => 'objs', chunk_size => 900 * 1024);
$made = undef; $os->create_bucket({}, sub { $made = [@_] }); wait_for(sub { $made });
my $blob = $big x 2;
my $stored; $os->put('blob', $blob, sub { $stored = [@_] }); wait_for(sub { $stored }, 20);
my $read; $os->get('blob', sub { $read = [@_] }); wait_for(sub { $read }, 20);
ok defined $read->[0] && $read->[0] eq $blob, 'ObjectStore chunks near max_payload read back'
    or diag explain [$stored->[1], $read->[1]];

# A stopping server ends a waiting fetch at once: 409 Server Shutdown
# where the server sends it, else the dropped connection.
my $f;
$js->fetch('S', 'C', { batch => 1, expires => 20_000_000_000 }, sub { $f = [@_] });
$fenced = 0; $nats->flush(sub { $fenced = 1 }); wait_for(sub { $fenced });
kill 'TERM', $pid;
wait_for(sub { $f }, 5);
ok $f && (($f->[2] && $f->[2]{code} == 409 && $f->[2]{description} eq 'Server Shutdown')
          || ($f->[1] // '') eq 'disconnected'), 'TERM: the fetch ended at once'
    or diag explain $f;
waitpid $pid, 0;
$nats->disconnect;

# A killed server fails the fetch with disconnected at once.
start();
setup();
$f = undef;
$js->fetch('S', 'C', { batch => 1, expires => 20_000_000_000 }, sub { $f = [@_] });
$fenced = 0; $nats->flush(sub { $fenced = 1 }); wait_for(sub { $fenced });
$t0 = mono();
kill 'KILL', $pid;
waitpid $pid, 0;
ok wait_for(sub { $f }, 10), 'KILL: the fetch answered';
is $f->[1], 'disconnected', '... with disconnected';
ok mono() - $t0 < 3, '... at once';

# A fetch armed after the loop blocked still waits its whole expires.
start();
setup();
my $blocked;
my $kick = EV::timer 0, 0, sub {
    Time::HiRes::sleep(2.5);
    $t0 = mono();
    $js->fetch('S', 'C', { batch => 1, expires => 1_500_000_000 }, sub { $blocked = [@_] });
};
wait_for(sub { $blocked }, 10);
ok mono() - $t0 >= 1.4, 'fetch after a blocking callback waited its expires';
is $blocked->[2]{code}, 408, '... and ended with the server 408';

$nats->disconnect;
kill 'TERM', $pid;
waitpid $pid, 0;
