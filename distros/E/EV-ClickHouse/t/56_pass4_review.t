#!/usr/bin/env perl
# Regression tests for the fourth pre-release adversarial review pass:
# handler refcycle vs finish(), insert_iter producer exceptions, strict
# native UUID/IP/FixedString encoders, on_disconnect/backoff admission,
# pre-54459 params gate, Streamer double finish,
# Pool for_table breaker observation, Time/Time64 decode.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::ClickHouse;

my $host  = $ENV{TEST_CLICKHOUSE_HOST}        || '127.0.0.1';
my $nport = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;
my $oldport = $ENV{TEST_CLICKHOUSE_22_PORT}   || 19001;

my $nat_ok = !!IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nport, Timeout => 2);
plan skip_all => 'no ClickHouse native at $host:$nport' unless $nat_ok;

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

# --- F1: finish() breaks handler refcycles -------------------------------
{
    { package Guard56; our $n = 0; sub DESTROY { $n++ } }
    local $Guard56::n = 0;
    my $g = bless {}, 'Guard56';
    my $c;
    $c = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub { $c->query('select 1', sub {}) if 0; $g },
        on_error   => sub {},
    );
    $c->finish;
    is($c->on_connect, undef, 'F1: finish clears connection handlers');
    undef $c;
    undef $g;
    is($Guard56::n, 1, 'F1: capturing handler no longer pins the handle');
}

# --- F2: insert_iter producer exception ------------------------------------
with_ch(cb => sub {
    $ch->query('DROP TABLE IF EXISTS t56_iter', sub {
    $ch->query('CREATE TABLE t56_iter (a UInt32) ENGINE=Memory', sub {
        my @rows = ([1], [2]);
        my $n = 0;
        $ch->insert_iter('t56_iter', sub {
            $n++;
            die "producer boom" if $n > 2;
            return $rows[$n - 1];
        }, sub {
            my (undef, $err) = @_;
            like($err // '', qr/producer died: producer boom/, 'F2: producer death reaches $cb');
            $ch->query('SELECT count() FROM t56_iter', sub {
                my ($r) = @_;
                is($r->[0][0], 2, 'F2: rows pumped before death are kept');
                $ch->query('DROP TABLE t56_iter', sub { EV::break });
            });
        });
    }) });
});

# --- F3: strict UUID/IPv4/IPv6/FixedString ---------------------------------
with_ch(cb => sub {
    $ch->query('DROP TABLE IF EXISTS t56_types', sub {
    $ch->query('CREATE TABLE t56_types (u UUID, ip4 IPv4, ip6 IPv6, fs FixedString(2)) ENGINE=Memory', sub {
        my $good_u = '550e8400-e29b-41d4-a716-446655440000';
        my @cases = (
            [['abc', '1.2.3.4', '::1', 'ab'], qr/encoding failed/, 'F3: short UUID rejected'],
            [['550e8400-e29b-41d4-a716-44665544000g', '1.2.3.4', '::1', 'ab'], qr/encoding failed/, 'F3: bad-hex UUID rejected'],
            [['not-an-ip', '1.2.3.4', '::1', 'ab'], qr/encoding failed/, 'F3: garbage UUID rejected'],
            [[$good_u, 'not-an-ip', '::1', 'ab'], qr/encoding failed/, 'F3: bad IPv4 rejected'],
            [[$good_u, '01.02.03.04', '::1', 'ab'], qr/encoding failed/, 'F3: leading-zero IPv4 rejected'],
            [[$good_u, '1.2.3.4', 'not-an-ip', 'ab'], qr/encoding failed/, 'F3: bad IPv6 rejected'],
            [[$good_u, '1.2.3.4', '::1', 'abc'], qr/encoding failed/, 'F3: overlong FixedString rejected'],
            [['550e8400e29b41d4a716446655440000', '1.2.3.4', '::1', 'a'], undef, 'F3: undashed UUID accepted'],
        );
        my $run;
        $run = sub {
            my $case = shift @cases;
            unless ($case) {
                $ch->query('SELECT u, ip4, ip6, hex(fs) FROM t56_types', sub {
                    my ($r) = @_;
                    is(scalar @$r, 1, 'F3: only the valid row landed');
                    is($r->[0][0], $good_u, 'F3: undashed UUID stored correctly');
                    is($r->[0][3], '6100', 'F3: short FixedString zero-padded');
                    $ch->query('DROP TABLE t56_types', sub { EV::break });
                });
                return;
            }
            $ch->insert('t56_types', [$case->[0]], sub {
                my (undef, $err) = @_;
                if ($case->[1]) { like($err // '', $case->[1], $case->[2]) }
                else            { ok(!$err, $case->[2]) }
                $run->();
            });
        };
        $run->();
    }) });
});

# --- F4: queue from on_disconnect + backoff window -------------------------
{
    my $warn = '';
    local $SIG{__WARN__} = sub { $warn .= $_[0] };
    my ($disc_fired, $got, $did_reset);
    my $c2;
    $c2 = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub { $c2->reset unless $did_reset++ },
        on_disconnect => sub {
            $disc_fired++;
            return if $disc_fired > 1;
            $c2->query('select 42', sub { $got = $_[0][0][0]; EV::break });
        },
        on_error => sub {},
    );
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    is($disc_fired, 1, 'F4: on_disconnect fired once');
    is($got, 42, 'F4: query queued from on_disconnect dispatches on reconnect');
    unlike($warn, qr/not connected/, 'F4: no "not connected" croak from handler');
    $c2->finish if $c2->is_connected;
}
{
    my ($saw_timeout, $late_ok, $late_croak, $late_timer, $did_sleep);
    my $c3;
    $c3 = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        auto_reconnect => 1, reconnect_delay => 3, query_timeout => 1,
        on_connect => sub {
            return if $did_sleep++;
            $c3->query('SELECT sleep(3)', sub { $saw_timeout = $_[1] });
        },
        on_disconnect => sub {
            $late_timer = EV::timer(0.5, 0, sub {
                my $ok = eval {
                    $c3->query('select 7', sub {
                        $late_ok = $_[0][0][0] unless $_[1]; EV::break });
                    1;
                };
                $late_croak = $@ unless $ok;
            });
        },
        on_error => sub {},
    );
    my $t = EV::timer(12, 0, sub { EV::break });
    EV::run;
    like($saw_timeout // '', qr/timeout/, 'F4: sleep query timed out');
    ok(!$late_croak, 'F4: backoff-window query admitted, not croaked');
    is($late_ok, 7, 'F4: backoff-window query runs after reconnect');
    $c3->finish if $c3->is_connected;
}

 # --- F6: pre-54459 servers (22.1-22.7) -------------------------------------
{
    my $old_ok = !!IO::Socket::INET->new(PeerAddr => $host, PeerPort => $oldport, Timeout => 2);
    SKIP: {
        skip 'no 22.x server at $host:$oldport (TEST_CLICKHOUSE_22_PORT)', 3 unless $old_ok;
        my ($sel, $sum, $p_croak);
        my $co;
        $co = EV::ClickHouse->new(
            host => $host, port => $oldport, protocol => 'native', query_timeout => 8,
            on_connect => sub {
                $co->query('select 42', sub {
                    $sel = $_[0][0][0] unless $_[1];
                    $co->query('DROP TABLE IF EXISTS t56_old', sub {
                    $co->query('CREATE TABLE t56_old (a UInt32) ENGINE=Memory', sub {
                    $co->insert('t56_old', [[1],[2]], sub {
                    $co->query('SELECT sum(a) FROM t56_old', sub {
                        $sum = $_[0][0][0] unless $_[1];
                        $p_croak = $@ unless eval {
                            $co->query('SELECT {x:UInt32}', {param_x => 1}, sub {}); 1 };
                        $co->query('DROP TABLE t56_old', sub { EV::break });
                    }) }) }) });
                });
            },
            on_error => sub {},
        );
        my $t = EV::timer(25, 0, sub { EV::break });
        EV::run;
        is($sel, 42, 'F6: select works against pre-54459 server');
        is($sum, 3, 'F6: insert round-trip works against pre-54459 server');
        like($p_croak // '', qr/require server revision/, 'F6: params fail loudly on old server');
        $co->finish if $co->is_connected;
    }
}

# --- F7: Streamer double finish --------------------------------------------
with_ch(cb => sub {
    $ch->query('DROP TABLE IF EXISTS t56_s', sub {
    $ch->query('CREATE TABLE t56_s (a UInt32) ENGINE=Memory', sub {
        my $s = $ch->insert_streamer('t56_s');
        my @fired;
        $s->push_row([1]);
        $s->finish(sub { push @fired, 'cb1' });
        $s->finish(sub {
            push @fired, 'cb2';
            is_deeply(\@fired, ['cb1', 'cb2'], 'F7: both finish waiters fire in order');
            $ch->query('DROP TABLE t56_s', sub { EV::break });
        });
    }) });
});

# --- F8: Pool for_table trips the breaker ----------------------------------
{
    my $pool = EV::ClickHouse::Pool->new(
        host => $host, port => $nport, protocol => 'native', size => 2,
        circuit_threshold => 1, circuit_cooldown => 60,
    );
    $pool->for_table('no_such_table_zzz_56', sub {
        my (undef, $err) = @_;
        ok($err, 'F8: for_table on missing table errors');
        my $tripped = grep { $_->{fails} > 0 } @{ $pool->{cb_state} };
        ok($tripped, 'F8: failure observed by the circuit breaker');
        $pool->shutdown(5, sub { EV::break });
    });
    my $t = EV::timer(15, 0, sub { EV::break });
    EV::run;
}

# --- U3: Time/Time64 decode -------------------------------------------------
# Time and Time64 are 25.x types; older servers reject the cast outright.
my $have_time = 0;
with_ch(cb => sub {
    $ch->query("SELECT CAST('12:34:56' AS Time)", sub {
        $have_time = !$_[1];
        EV::break;
    });
});

SKIP: {
    skip 'server has no Time/Time64 type', 3 unless $have_time;
    with_ch(cb => sub {
        $ch->query("SELECT CAST('12:34:56' AS Time), CAST('12:34:56.123' AS Time64(3))", sub {
            my ($r, $err) = @_;
            ok(!$err, 'U3: Time/Time64 select does not hang');
            is($r->[0][0], 12*3600 + 34*60 + 56, 'U3: Time decodes to seconds');
            is($r->[0][1], (12*3600 + 34*60 + 56) * 1000 + 123, 'U3: Time64 decodes to scaled int');
            EV::break;
        });
    });
}

done_testing;
