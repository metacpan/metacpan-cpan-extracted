#!/usr/bin/env perl
# Regression tests for review-loop round 1: native cancel reports an
# error, concurrent Pool::shutdown chains, grace timer doesn't strand
# the loop, failover port precedence, IPv6 Host brackets, falsy
# query_log_comment, bind_ident arity, Pool size validation,
# track_query_durations order, quoted aggregate arg types, Streamer
# reset/chained-finish guards.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::ClickHouse;

my $host  = $ENV{TEST_CLICKHOUSE_HOST}        || '127.0.0.1';
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

# --- M3: cancelled native query reports an error ---------------------------
with_ch(cb => sub {
    $ch->query('select sleep(2), number from numbers(1000000)', sub {
        my (undef, $err) = @_;
        is($err, 'query cancelled', 'M3: native cancel delivers an error');
        EV::break;
    });
    my $k; $k = EV::timer(0.3, 0, sub { undef $k; $ch->cancel });
});

# --- M2/L7: Pool::shutdown chaining + grace timer --------------------------
{
    my $pool = EV::ClickHouse::Pool->new(host => $host, port => $nport,
                                          protocol => 'native', size => 1);
    $pool->{conns}[0]->query('select sleep(2), number from numbers(100)', sub {});
    my ($cb1, $cb2) = (0, 0);
    $pool->shutdown(sub { $cb1 = 1 });
    my $ok = eval { $pool->shutdown(sub { $cb2 = 1 }); 1 };
    ok($ok, 'M2: concurrent shutdown does not croak') or diag($@);
    my $t; $t = EV::timer(6, 0, sub { undef $t; EV::break });
    EV::run;
    ok($cb1 && $cb2, 'M2: both shutdown callbacks fire');

    my $pool2 = EV::ClickHouse::Pool->new(host => $host, port => $nport,
                                           protocol => 'native', size => 1);
    $pool2->shutdown(5, sub {});
    my $t0 = time;
    EV::run;
    cmp_ok(time - $t0, '<', 2, 'L7: idle shutdown(5) does not strand the loop');
}

# --- L3: explicit port wins on rotation too ---------------------------------
{
    my @trace;
    my $c = EV::ClickHouse->new(hosts => ['127.0.0.1:1', '127.0.0.1:2'],
        port => 59999, protocol => 'native',
        auto_reconnect => 1, reconnect_max_attempts => 2,
        reconnect_delay => 0.1,
        on_trace => sub { push @trace, $_[0] if $_[0] =~ /^connect / },
        on_error => sub { EV::break if @trace >= 2 });
    my $t = EV::timer(8, 0, sub { EV::break });
    EV::run;
    is_deeply(\@trace,
        ['connect 127.0.0.1:59999 (native)', 'connect 127.0.0.1:59999 (native)'],
        'L3: rotation keeps the explicit port');
    $c->finish;
}

# Slurp one HTTP request (headers + body) off $srv without ever
# blocking the loop: a blocking read in the accept handler deadlocks
# when accept is serviced before the client's first write.
sub slurp_one {
    my ($srv, $reply, $done) = @_;
    my $w; $w = EV::io($srv->fileno, EV::READ, sub {
        my $c = $srv->accept or return;
        $c->blocking(0);
        my $buf = '';
        my $cw; $cw = EV::io($c->fileno, EV::READ, sub {
            $c->sysread($buf, 8192, length($buf));
            my $hlen = ($buf =~ /\r\n\r\n/g) ? pos($buf) : 0;
            my ($clen) = $buf =~ /Content-Length:\s*(\d+)/i;
            if ($hlen && length($buf) >= $hlen + ($clen // 0)) {
                $c->syswrite($reply);
                $c->close;
                undef $cw; undef $w;
                $done->($buf);
            }
        });
    });
    return;
}

# --- L1: IPv6 Host header is bracketed --------------------------------------
SKIP: {
    eval { require IO::Socket::IP; 1 } or skip 'no IO::Socket::IP', 1;
    my $srv = IO::Socket::IP->new(LocalAddr => '::1', LocalPort => 0,
                                  Listen => 5, ReuseAddr => 1);
    skip 'no ::1 listener', 1 unless $srv;
    my $got = '';
    slurp_one($srv,
        "HTTP/1.1 200 OK\r\nContent-Length: 3\r\nConnection: close\r\n\r\nOk.\n",
        sub { $got = $_[0]; EV::break });
    my $h = EV::ClickHouse->new(uri => 'clickhouse://[::1]:' . $srv->sockport . '/db',
                                protocol => 'http',
                                on_error => sub { EV::break });
    $h->ping(sub {});
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    like($got, qr/^Host: \[::1\]:\d+\r$/m, 'L1: Host header brackets IPv6');
    $h->finish;
}

# --- L9: falsy query_log_comment disables -----------------------------------
{
    my $srv = IO::Socket::INET->new(LocalAddr => '127.0.0.1:0', Listen => 5,
                                    ReuseAddr => 1, Timeout => 2)
        or die "cannot bind: $!";
    my $got = '';
    slurp_one($srv,
        "HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\n1\n",
        sub { $got = $_[0]; EV::break });
    my $h = EV::ClickHouse->new(host => '127.0.0.1', port => $srv->sockport,
                                protocol => 'http', query_log_comment => '0',
                                on_error => sub { EV::break });
    $h->query('select 1', sub {});
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    unlike($got, qr{/\*}, "L9: query_log_comment '0' sends no comment");
    $h->finish;
}

# --- L2/L11: validation ------------------------------------------------------
{
    my $ok = eval { EV::ClickHouse->bind_ident('a.b.c'); 1 };
    ok(!$ok, 'L2: three-part identifier croaks');
    $ok = eval {
        EV::ClickHouse::Pool->new(host => $host, port => $nport,
                                  protocol => 'native', size => 0);
        1;
    };
    ok(!$ok, 'L11: Pool size 0 croaks');
}

# --- L4: preserved handler runs before tracking ------------------------------
with_ch(cb => sub {
    my $seen;
    $ch->on_query_complete(sub { $seen = $ch->query_duration_count });
    $ch->track_query_durations(64);
    $ch->query('select 1', sub {
        is($seen, 0, 'L4: preserved handler sees the pre-sample count');
        $ch->track_query_durations(0);
        EV::break;
    });
});

# --- L6: quoted aggregate arg types ------------------------------------------
with_ch(cb => sub {
    $ch->query('drop table if exists t59_agg', sub {
    $ch->query("create table t59_agg (d Date, agg_col AggregateFunction(uniqExact, DateTime('UTC'))) engine=AggregatingMergeTree() order by d", sub {
        $ch->insert_aggregated('t59_agg',
            agg_col  => { func => 'uniqExact', args => ["DateTime('UTC')"] },
            key_cols => ['d'],
            rows     => [['2026-10-01', '2026-10-01 10:00:00']],
            cb       => sub {
                my (undef, $err) = @_;
                ok(!$err, 'L6: quoted arg type passes validation') or diag($err);
                $ch->query('select uniqExactMerge(agg_col) from t59_agg', sub {
                    my ($r) = @_;
                    is($r->[0][0], 1, 'L6: aggregated row landed');
                    $ch->query('drop table t59_agg', sub { EV::break });
                });
            });
    }) });
});

# --- L12/L14: reset + chained finish isolation --------------------------------
with_ch(cb => sub {
    $ch->query('drop table if exists t59_rst', sub {
    $ch->query('create table t59_rst (a UInt32) engine=Memory', sub {
        my $s = $ch->insert_streamer('t59_rst', batch_size => 100);
        $s->push_row([1]);
        my ($f2, $w2, $pf) = (0, 0, '');
        my $old_warn = $SIG{__WARN__};
        $SIG{__WARN__} = sub {};
        $s->finish(sub { die "fin1 boom" });
        $s->finish(sub { $f2 = 1 });
        my $s2 = $ch->insert_streamer('t59_rst', batch_size => 100);
        $s2->push_row([2]);
        $s2->await_drain(sub { die "w1 boom" });
        $s2->await_drain(sub { $w2 = 1 });
        $s2->finish(sub { $pf = $_[1] // 'ok' });
        $s2->reset;
        my $w; $w = EV::timer(0.1, 0.1, sub {
            return unless $f2;
            undef $w;
            $SIG{__WARN__} = $old_warn;
            ok($f2, 'L14: chained finish survives a dying predecessor');
            ok($w2 && $pf eq 'streamer reset', 'L12: reset delivers to all waiters');
            $ch->query('drop table t59_rst', sub { EV::break });
        });
    }) });
});
