#!/usr/bin/env perl
# Regression tests for review-loop round 2: DateTime with column tz,
# JSON UInt64 leaves, iterator surviving foreign EV::break,
# re-queued callbacks during teardown, Pool::shutdown cycles.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use Scalar::Util qw(weaken);
use EV;
use EV::ClickHouse;

my $host  = $ENV{TEST_CLICKHOUSE_HOST}        || '127.0.0.1';
my $hport = $ENV{TEST_CLICKHOUSE_PORT}        || 8123;
my $nport = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

my $nat_ok = !!IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nport, Timeout => 2);
plan skip_all => 'no ClickHouse native at $host:$nport' unless $nat_ok;
plan tests => 14;

my $ch;
sub with_ch {
    my (%args) = @_;
    my $cb = delete $args{cb};
    $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub { $cb->() },
        on_error   => sub { diag("Error: $_[0]"); EV::break },
        %args,
    );
    my $timeout = EV::timer(15, 0, sub { EV::break });
    EV::run;
    $ch->finish if $ch && $ch->is_connected;
}

# --- H1: DateTime text honors the column timezone ---------------------------
with_ch(cb => sub {
    $ch->query('drop table if exists t60_dt', sub {
    $ch->query("create table t60_dt (d DateTime('Asia/Tokyo')) engine=Memory", sub {
        $ch->insert('t60_dt', "2024-06-01 12:00:00\n", sub {
            my (undef, $err) = @_;
            ok(!$err, 'H1: tz insert accepted');
            $ch->query('select toUInt32(d) from t60_dt', sub {
                my ($r) = @_;
                is($r->[0][0], 1717210800, 'H1: wall time read in column tz');
                $ch->query('drop table t60_dt', sub { EV::break });
            });
        });
    }) });
});
with_ch(cb => sub {
    $ch->query('drop table if exists t60_dt64', sub {
    $ch->query("create table t60_dt64 (d DateTime64(3,'America/New_York')) engine=Memory", sub {
        $ch->insert('t60_dt64', "2024-01-15 12:00:00.123\n2024-06-01 12:00:00.456\n", sub {
            $ch->query('select toString(d) from t60_dt64 order by d', sub {
                my ($r) = @_;
                is_deeply([map { $_->[0] } @$r],
                    ['2024-01-15 12:00:00.123', '2024-06-01 12:00:00.456'],
                    'H1: DateTime64 DST both sides round-trips');
                $ch->query('drop table t60_dt64', sub { EV::break });
            });
        });
    }) });
});

# --- H2/M1: JSON UInt64 leaves ----------------------------------------------
my $big = 18446744073709551615;

# The JSON column type is a 25.x feature; 23.8 rejects the CREATE TABLE.
my $have_json = 0;
with_ch(cb => sub {
    $ch->query('create table if not exists t60_jprobe (j JSON) engine=Memory', sub {
        $have_json = !$_[1];
        $ch->query('drop table if exists t60_jprobe', sub { EV::break });
    });
});

SKIP: {
skip 'server has no JSON column type', 5 unless $have_json;
with_ch(cb => sub {
    $ch->query('drop table if exists t60_j', sub {
    $ch->query('create table t60_j (j JSON) engine=Memory', sub {
        $ch->insert('t60_j', [[{n => $big}]] , sub {
            my (undef, $err) = @_;
            ok(!$err, 'H2: uint64 JSON insert accepted');
            $ch->query('select j from t60_j', sub {
                my ($r, $e2) = @_;
                ok(!$e2, 'H2: select back works');
                is($r->[0][0]{n}, $big, 'H2: uint64 survives the round-trip');
                $ch->query('drop table t60_j', sub { EV::break });
            });
        });
    }) });
});
{
    # Server-inferred UInt64 path (via HTTP) must decode natively.
    my ($se, $sv);
    my $h = EV::ClickHouse->new(host => $host, port => $hport,
                                protocol => 'http',
                                on_error => sub { EV::break });
    my $c;
    $h->query('drop table if exists t60_ju', sub {
    $h->query('create table t60_ju (j JSON) engine=Memory', sub {
        $h->insert('t60_ju', "{\"n\":$big}\n", sub {
            $c = EV::ClickHouse->new(host => $host, port => $nport,
                                     protocol => 'native',
                                     on_error => sub { EV::break });
            $c->query('select j from t60_ju', sub {
                my ($r, $e) = @_;
                ($se, $sv) = ($e, $r && $r->[0][0]{n});
                $h->query('drop table t60_ju', sub { EV::break });
            });
        });
    }) });
    my $t = EV::timer(15, 0, sub { EV::break });
    EV::run;
    ok(!$se, 'M1: server-inferred UInt64 path decodes');
    is($sv, $big, 'M1: decoded value is exact');
}
}

# --- H3: iterator waits through a foreign EV::break -------------------------
{
    my $c = EV::ClickHouse->new(host => $host, port => $nport,
                                protocol => 'native',
                                on_connect => sub { EV::break },
                                on_error => sub { EV::break });
    EV::run;
    my $it = $c->iterate('select sleep(2), number from numbers(10)');
    my $t = EV::timer(0.1, 0, sub { EV::break });
    my $t0 = time;
    my $b1 = $it->next;
    is(scalar(@$b1), 10, 'H3: first next() returns the full batch');
    cmp_ok(time - $t0, '>=', 1, 'H3: it waited out the query, not the break');
    $c->finish;
}

# --- M3: re-query during teardown fires --------------------------------------
{
    my $c = EV::ClickHouse->new(host => $host, port => $nport,
                                protocol => 'native',
                                on_connect => sub { EV::break },
                                on_error => sub { EV::break });
    EV::run;
    my $re_fired = 0;
    $c->query('select sleep(2), number from numbers(100)', sub {
        $c->query('select 2', sub { $re_fired = 1 });
    });
    $c->finish;
    is($re_fired, 1, 'M3: entry re-queued during teardown fires');
    is($c->pending_count, 0, 'M3: nothing strands');
}

# --- M2: dropped pool mid-shutdown is freed ----------------------------------
{
    my $srv = IO::Socket::INET->new(LocalAddr => '127.0.0.1:0', Listen => 5,
                                    ReuseAddr => 1, Timeout => 2)
        or die "cannot bind: $!";
    my @held;
    my $aw = EV::io($srv->fileno, EV::READ,
                    sub { my $c = $srv->accept; push @held, $c if $c });
    my $pool = EV::ClickHouse::Pool->new(host => '127.0.0.1',
                                         port => $srv->sockport,
                                         protocol => 'native', size => 1);
    my $weak = $pool; weaken($weak);
    my $cb_fired = 0;
    $pool->{conns}[0]->query('select 1', sub {});
    $pool->shutdown(sub { $cb_fired = 1 });
    undef $pool;
    my $w; $w = EV::timer(2, 0, sub { undef $w; EV::break });
    EV::run;
    ok(!$weak, 'M2: pool is freed, not stranded by the shutdown cycle');
    ok($cb_fired, 'M2: shutdown callback still fires exactly once');
}
