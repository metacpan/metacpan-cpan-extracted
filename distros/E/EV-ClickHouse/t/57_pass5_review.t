#!/usr/bin/env perl
# Regression tests for the fifth pre-release adversarial review pass:
# Nullable(UUID/IP) nulls, RST-teardown queue strand, pre-hello params
# on old servers, Decimal256/Time encoders, insert_err context,
# on_batch_error guard, track(0) stacking, option validation, undef
# settings, skip_pending from on_query_start.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use Socket qw(SOL_SOCKET SO_LINGER);
use EV;
use EV::ClickHouse;

my $host    = $ENV{TEST_CLICKHOUSE_HOST}        || '127.0.0.1';
my $hport   = $ENV{TEST_CLICKHOUSE_PORT}        || 8123;
my $nport   = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;
my $oldport = $ENV{TEST_CLICKHOUSE_22_PORT}     || 19001;

my $nat_ok = !!IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nport, Timeout => 2);
plan skip_all => 'no ClickHouse native at $host:$nport' unless $nat_ok;
plan tests => 35;

my @kids;
END { kill 'TERM', @kids if @kids; waitpid $_, 0 for @kids; }

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

# --- H1: Nullable(UUID/IPv4/IPv6) nulls ------------------------------------
with_ch(cb => sub {
    $ch->query('DROP TABLE IF EXISTS t57_n', sub {
    $ch->query('CREATE TABLE t57_n (u Nullable(UUID), i Nullable(IPv4), v Nullable(IPv6)) ENGINE=Memory', sub {
        my $u = '550e8400-e29b-41d4-a716-446655440000';
        $ch->insert('t57_n', [[undef, undef, undef], [$u, '1.2.3.4', '::1']], sub {
            my (undef, $err) = @_;
            ok(!$err, 'H1: arrayref nulls into Nullable(UUID/IP) accepted');
            $ch->insert('t57_n', "\\N\t\\N\t\\N", sub {
                my (undef, $err2) = @_;
                ok(!$err2, 'H1: TSV nulls accepted');
                $ch->query('SELECT count(), countIf(isNull(u)) FROM t57_n', sub {
                    my ($r) = @_;
                    is($r->[0][0], 3, 'H1: all null rows landed');
                    is($r->[0][1], 2, 'H1: nulls stored as NULL');
                    $ch->insert('t57_n', [['abc', undef, undef]], sub {
                        my (undef, $err3) = @_;
                        like($err3 // '', qr/column 'u' \(/, 'H1: bad value still fails, names column');
                        $ch->query('DROP TABLE t57_n', sub { EV::break });
                    });
                });
            });
        });
    }) });
});

# --- H2: RST mid-query reconnects, preserved queue runs --------------------
{
    my $lsn = IO::Socket::INET->new(Listen => 5, LocalAddr => '127.0.0.1',
                                    LocalPort => 0, ReuseAddr => 1) or die "listen: $!";
    my $port = $lsn->sockport;
    my $pid = fork; die "fork: $!" unless defined $pid;
    if (!$pid) {
        my $c1 = $lsn->accept;
        my $buf = ''; $c1->recv($buf, 65536);
        setsockopt($c1, SOL_SOCKET, SO_LINGER, pack("ii", 1, 0));
        close $c1;
        my $c2 = $lsn->accept;
        $buf = ''; my $req = '';
        while ($req !~ /\r\n\r\n/) { $c2->recv($buf, 65536) or last; $req .= $buf; }
        my $body = "42\n";
        print $c2 "HTTP/1.1 200 OK\r\nContent-Length: " . length($body) . "\r\nConnection: close\r\n\r\n$body";
        sleep 5;
        exit 0;
    }
    push @kids, $pid;
    my ($q1, $q2, $oerr);
    my $h;
    $h = EV::ClickHouse->new(
        host => $host, port => $port, protocol => 'http',
        auto_reconnect => 1, reconnect_delay => 0.2,
        on_connect => sub {
            $h->query('select 41 format TabSeparated', sub { $q1 = $_[1] });
            $h->query('select 42 format TabSeparated', sub {
                $q2 = $_[1] ? "ERR $_[1]" : $_[0][0][0]; EV::break });
        },
        on_error => sub { $oerr = $_[0] },
    );
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    ok($q1, 'H2: in-flight query errors on RST');
    is($q2, 42, 'H2: preserved query runs after reconnect');
    like($oerr // '', qr/reset/i, 'H2: on_error reports the RST');
    $h->finish if $h->is_connected;
    kill 'TERM', $pid; waitpid $pid, 0; @kids = grep { $_ != $pid } @kids;
}

# --- M3: pre-hello builds ---------------------------------------------------
{
    my ($v, $e);
    my $c = EV::ClickHouse->new(host => $host, port => $nport, protocol => 'native',
        on_error => sub { $e = $_[0]; EV::break });
    $c->query('select 42', sub { ($v, $e) = ($_[0][0][0], $_[1]); EV::break });
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    is($v, 42, 'M3: pre-hello query works on modern server');
    $c->finish if $c->is_connected;
}
{
    my $old_ok = !!IO::Socket::INET->new(PeerAddr => $host, PeerPort => $oldport, Timeout => 2);
    SKIP: {
        skip "no 22.x server at \$host:$oldport (TEST_CLICKHOUSE_22_PORT)", 3 unless $old_ok;
        my ($v, $pe, $c2);
        my $c = EV::ClickHouse->new(host => $host, port => $oldport, protocol => 'native',
            query_timeout => 8, on_error => sub {});
        $c->query('select 42', sub {
            $v = $_[1] ? "ERR $_[1]" : $_[0][0][0];
            $c2 = EV::ClickHouse->new(host => $host, port => $oldport, protocol => 'native',
                query_timeout => 8, on_error => sub {});
            my $croaked = $@ unless eval {
                $c2->query('SELECT {x:UInt32}', {param_x => 1}, sub {
                    $pe = $_[1] // 'none'; EV::break }); 1 };
            ok(!$croaked, 'M3: pre-hello params do not croak synchronously');
        });
        my $t = EV::timer(20, 0, sub { EV::break });
        EV::run;
        is($v, 42, 'M3: pre-hello query works on pre-54459 server');
        like($pe // '', qr/require server revision/, 'M3: pre-hello params fail loudly on old server');
        $c->finish if $c->is_connected;
    }
}

# --- R1F3: Decimal256 text --------------------------------------------------
with_ch(cb => sub {
    $ch->query('DROP TABLE IF EXISTS t57_d', sub {
    $ch->query('CREATE TABLE t57_d (d Decimal256(2)) ENGINE=Memory', sub {
        $ch->insert('t57_d', "123.45\n-999.001", sub {
            my (undef, $err) = @_;
            ok(!$err, 'R1F3: Decimal256 text accepted');
            my $raw = pack('V*', 1234500, (0) x 7);
            $ch->insert('t57_d', [[$raw]], sub {
                my (undef, $err2) = @_;
                ok(!$err2, 'R1F3: raw 32-byte SV still accepted');
                $ch->query('SELECT toString(d) FROM t57_d ORDER BY d', sub {
                    my ($r) = @_;
                    is_deeply([map { $_->[0] } @$r], ['-999', '123.45', '12345'],
                        'R1F3: values exact (text + raw)');
                    $ch->insert('t57_d', [['12x.5']], sub {
                        my (undef, $err3) = @_;
                        like($err3 // '', qr/column 'd' \(Decimal\(76, 2\)\)/,
                            'R1F3: garbage fails, names column');
                        $ch->insert('t57_d', [['9' x 80 . '.1']], sub {
                            my (undef, $err4) = @_;
                            like($err4 // '', qr/encoding failed/,
                                'R1F3: overflow fails loudly');
                            $ch->query('DROP TABLE t57_d', sub { EV::break });
                        });
                    });
                });
            });
        });
    }) });
});

# --- Time/Time64 encoders ---------------------------------------------------
# Time and Time64 are 25.x types; older servers reject the CREATE TABLE.
my $have_time = 0;
with_ch(cb => sub {
    $ch->query("SELECT CAST('12:34:56' AS Time)", sub {
        $have_time = !$_[1];
        EV::break;
    });
});

SKIP: {
    skip 'server has no Time/Time64 type', 5 unless $have_time;
with_ch(cb => sub {
    $ch->query('DROP TABLE IF EXISTS t57_t', sub {
    $ch->query('CREATE TABLE t57_t (t Time, t64 Time64(3)) ENGINE=Memory', sub {
        $ch->insert('t57_t', "12:34:56\t12:34:56.123\n-00:00:01\t-00:00:01.5", sub {
            my (undef, $err) = @_;
            ok(!$err, 'TIME: TSV text accepted');
            $ch->insert('t57_t', [[45296, 45296123], ['25:00:00', '-12:34:56.5']], sub {
                my (undef, $err2) = @_;
                ok(!$err2, 'TIME: SV int + text accepted');
                $ch->query('SELECT toInt32(t), toString(t64) FROM t57_t ORDER BY t', sub {
                    my ($r) = @_;
                    is_deeply([map { $_->[0] } @$r], [-1, 45296, 45296, 90000],
                        'TIME: seconds exact');
                    is($r->[1][1], '12:34:56.123', 'TIME: Time64 fraction exact');
                    $ch->insert('t57_t', [['abc', '00:00:00']], sub {
                        my (undef, $err3) = @_;
                        like($err3 // '', qr/column 't' \(Time\)/,
                            'TIME: bad value fails, names column');
                        $ch->query('DROP TABLE t57_t', sub { EV::break });
                    });
                });
            });
        });
    }) });
});
}

# --- on_batch_error guard ---------------------------------------------------
{
    my $warn = '';
    local $SIG{__WARN__} = sub { $warn .= $_[0] };
    with_ch(cb => sub {
        $ch->query('DROP TABLE IF EXISTS t57_s', sub {
        $ch->query('CREATE TABLE t57_s (a UInt32) ENGINE=Memory', sub {
            my $s = $ch->insert_streamer('t57_s',
                on_batch_error => sub { die "boom\n" });
            $s->push_row(['not-a-number']);
            $s->finish(sub {
                my (undef, $err) = @_;
                ok($err, 'BATCH: finish fires with sticky error');
                like($warn, qr/on_batch_error died: boom/, 'BATCH: handler death warned, not stranded');
                $ch->query('DROP TABLE t57_s', sub { EV::break });
            });
        }) });
    });
}

# --- track(0) keeps stacked helpers -----------------------------------------
with_ch(cb => sub {
    my $slow = 0;
    $ch->track_query_durations(16);
    my $w1 = $ch->on_query_complete;
    $ch->slow_query_log(0, sub { $slow++ });
    $ch->track_query_durations(0);
    my $cur = $ch->on_query_complete;
    ok($cur && $cur != $w1, 'TRACK: stacked handler survives track(0)');
    $ch->query('select 1', sub { EV::break });
});
with_ch(cb => sub {
    my $slow = 0;
    $ch->track_query_durations(16);
    $ch->slow_query_log(0, sub { $slow++ });
    $ch->track_query_durations(0);
    $ch->query('select 1', sub {
        is($slow, 1, 'TRACK: stacked handler still fires');
        EV::break;
    });
});

# --- unknown options --------------------------------------------------------
{
    my $c = EV::ClickHouse->new(host => $host, port => $nport, protocol => 'native',
        on_error => sub {});
    my $e1 = eval { $c->retry('select 1', cb => sub {}, bogus => 1); 1 } ? '' : $@;
    like($e1, qr/unknown option/, 'OPTS: retry rejects typos');
    my $e2 = eval { $c->wait_mutation('t', sub {}, bogus => 1); 1 } ? '' : $@;
    like($e2, qr/unknown option/, 'OPTS: wait_mutation rejects typos');
    my $pool = EV::ClickHouse::Pool->new(host => $host, port => $nport,
        protocol => 'native', size => 1);
    my $e3 = eval { $pool->fan_out('select 1', bogus => 1, sub {}); 1 } ? '' : $@;
    like($e3, qr/unknown option/, 'OPTS: fan_out rejects typos');
    $c->finish;
    $pool->shutdown(2, sub {});
}

# --- undef settings values --------------------------------------------------
{
    my $warn = '';
    local $SIG{__WARN__} = sub { $warn .= $_[0] };
    my ($v, $hv, $h);
    my $c;
    $c = EV::ClickHouse->new(host => $host, port => $nport, protocol => 'native',
        on_error => sub { EV::break });
    $c->query('select 42', {query_id => undef, max_threads => undef}, sub {
        ($v) = $_[1] ? ('ERR') : $_[0][0][0];
        $h = EV::ClickHouse->new(host => $host, port => $hport, protocol => 'http',
            on_error => sub { EV::break });
        $h->query('select 43 format TabSeparated', {query_id => undef}, sub {
            ($hv) = $_[1] ? ('ERR') : $_[0][0][0];
            EV::break;
        });
    });
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    is($v, 42, 'UNDEF: native query with undef settings works');
    is($hv, 43, 'UNDEF: http query with undef query_id works');
    unlike($warn, qr/uninitialized/, 'UNDEF: no warnings');
    $c->finish if $c->is_connected;
}

# --- skip_pending from on_query_start ---------------------------------------
{
    my ($r1, $r2, $count);
    my $skipped = 1;
    my $c;
    $c = EV::ClickHouse->new(host => $host, port => $nport, protocol => 'native',
        on_query_start => sub { $c->skip_pending unless $skipped++ },
        on_connect => sub {
            $c->query('DROP TABLE IF EXISTS t57_skip', sub {
            $c->query('CREATE TABLE t57_skip (a UInt32) ENGINE=Memory', sub {
                $skipped = 0;
                $c->insert('t57_skip', [[41]], sub {
                    $r1 = $_[1] // 'none';
                    $c->query('SELECT count() FROM t57_skip', sub {
                        $count = $_[0][0][0];
                        $c->query('select 42', sub {
                            $r2 = $_[1] ? "ERR $_[1]" : $_[0][0][0];
                            $c->query('DROP TABLE t57_skip', sub { EV::break });
                        });
                    });
                });
            }) });
        },
        on_error => sub {});
    my $t = EV::timer(15, 0, sub { EV::break });
    EV::run;
    is($r1, 'skipped', 'SKIP: staged insert reports skipped');
    is($count, 0, 'SKIP: skipped bytes never reach the server');
    is($r2, 42, 'SKIP: connection healthy afterwards');
    $c->finish if $c->is_connected;
}
