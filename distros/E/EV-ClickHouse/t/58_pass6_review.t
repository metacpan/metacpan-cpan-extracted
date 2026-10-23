#!/usr/bin/env perl
# Regression tests for the sixth pre-release adversarial review pass:
# LC(Nullable) round-trip, Decimal128 native encoder, Decimal256/128
# precision limits, Nullable(Time) nulls, arrayref snapshot, CRLF
# reject, handshake-window queueing, loop lifetime, Streamer option
# validation, drain-waiter isolation.
use strict;
use warnings;
use Scalar::Util qw(weaken);
use Test::More;
use IO::Socket::INET;
use EV;
use EV::ClickHouse;

my $host  = $ENV{TEST_CLICKHOUSE_HOST}        || '127.0.0.1';
my $nport = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

my $nat_ok = !!IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nport, Timeout => 2);
plan skip_all => 'no ClickHouse native at $host:$nport' unless $nat_ok;
plan tests => 20;

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

# --- R5F1: LC(Nullable(String)) round-trip ----------------------------------
with_ch(cb => sub {
    $ch->query('DROP TABLE IF EXISTS t58_lc', sub {
    $ch->query('CREATE TABLE t58_lc (s LowCardinality(Nullable(String))) ENGINE=Memory', sub {
        $ch->insert('t58_lc', "a\nb\n\\N\n", sub {
            my (undef, $err) = @_;
            ok(!$err, 'R5F1: TSV insert into LC(Nullable) accepted');
            $ch->query('SELECT s FROM t58_lc ORDER BY s', sub {
                my ($r, $e2) = @_;
                ok(!$e2, 'R5F1: select back works');
                is_deeply([sort map { $_->[0] // '' } @$r], ['', 'a', 'b'],
                    'R5F1: values incl NULL round-trip');
                $ch->query('DROP TABLE t58_lc', sub { EV::break });
            });
        });
    }) });
});

# --- R5F3: Decimal128 native encoder ----------------------------------------
my $D38 = '9' x 38;
with_ch(cb => sub {
    $ch->query('DROP TABLE IF EXISTS t58_d128', sub {
    $ch->query('CREATE TABLE t58_d128 (v Decimal128(0)) ENGINE=Memory', sub {
        $ch->insert('t58_d128', "$D38\n", sub {
            my (undef, $err) = @_;
            ok(!$err, 'R5F3: 38-digit Decimal128 TSV insert accepted');
            $ch->insert('t58_d128', "-$D38\n", sub {
                my (undef, $e2) = @_;
                ok(!$e2, 'R5F3: negative 38-digit accepted');
                $ch->insert('t58_d128', '9' x 39 . "\n", sub {
                    my (undef, $e3) = @_;
                    like($e3 // '', qr/native INSERT encoding failed/,
                        'R5F3: 39-digit overflow fails loudly');
                    $ch->insert('t58_d128', [['12345678901234567890123456789012345678']], sub {
                        my (undef, $e4) = @_;
                        ok(!$e4, 'R5F3: arrayref Decimal128 insert accepted');
                        $ch->query('SELECT v FROM t58_d128 ORDER BY v', sub {
                            my ($r) = @_;
                            is($r->[2][0], $D38, 'R5F3: max value round-trips exactly');
                            $ch->query('DROP TABLE t58_d128', sub { EV::break });
                        });
                    });
                });
            });
        });
    }) });
});

# --- R5F2: Decimal256 precision limits --------------------------------------
my $N76 = '9' x 76;
with_ch(cb => sub {
    $ch->query('DROP TABLE IF EXISTS t58_d256', sub {
    $ch->query('CREATE TABLE t58_d256 (w Decimal256(0)) ENGINE=Memory', sub {
        $ch->insert('t58_d256', "$N76\n", sub {
            my (undef, $err) = @_;
            ok(!$err, 'R5F2: 76-digit Decimal256 insert accepted');
            $ch->insert('t58_d256', '9' x 77 . "\n", sub {
                my (undef, $e2) = @_;
                like($e2 // '', qr/native INSERT encoding failed/,
                    'R5F2: 77-digit value fails loudly (server: error 69)');
                $ch->query('DROP TABLE t58_d256', sub { EV::break });
            });
        });
    }) });
});

# --- R2F1: Nullable(Time) nulls ---------------------------------------------
with_ch(cb => sub {
    $ch->query('DROP TABLE IF EXISTS t58_time', sub {
    $ch->query('CREATE TABLE t58_time (t Nullable(Time)) ENGINE=Memory', sub {
        $ch->insert('t58_time', "\\N\n", sub {
            my (undef, $err) = @_;
            ok(!$err, 'R2F1: TSV null into Nullable(Time) accepted');
            $ch->insert('t58_time', [[undef]], sub {
                my (undef, $e2) = @_;
                ok(!$e2, 'R2F1: arrayref null into Nullable(Time) accepted');
                $ch->query('DROP TABLE t58_time', sub { EV::break });
            });
        });
    }) });
});

# --- R3F1: caller-side AV mutation after insert() ---------------------------
with_ch(cb => sub {
    $ch->query('DROP TABLE IF EXISTS t58_snap', sub {
    $ch->query('CREATE TABLE t58_snap (a UInt32) ENGINE=Memory', sub {
        my $rows = [[1], [2]];
        $ch->insert('t58_snap', $rows, sub {
            $ch->query('SELECT count() FROM t58_snap', sub {
                my ($r) = @_;
                is($r->[0][0], 2, 'R3F1: clearing caller AV after insert loses nothing');
                $ch->query('DROP TABLE t58_snap', sub { EV::break });
            });
        });
        @$rows = ();
        $rows->[0] = [99];
    }) });
});

# --- R3F2: CRLF rejected like the server ------------------------------------
with_ch(cb => sub {
    $ch->query('DROP TABLE IF EXISTS t58_crlf', sub {
    $ch->query('CREATE TABLE t58_crlf (s String) ENGINE=Memory', sub {
        $ch->insert('t58_crlf', "hello\r\n", sub {
            my (undef, $err) = @_;
            like($err // '', qr/\\r/, 'R3F2: CRLF insert fails loudly, names the cause');
            $ch->query('DROP TABLE t58_crlf', sub { EV::break });
        });
    }) });
});

# --- R4F1: query during TLS/ServerHello window queues -----------------------
{
    my $srv = IO::Socket::INET->new(LocalAddr => '127.0.0.1:0', Listen => 5,
                                    ReuseAddr => 1, Timeout => 2);
    if (!$srv) {
        ok(0, 'R4F1: cannot bind blackhole listener') for 1..2;
    } else {
        my $err;
        my $c = EV::ClickHouse->new(host => '127.0.0.1', port => $srv->sockport,
            protocol => 'native', connect_timeout => 2,
            on_error => sub { $err = $_[0]; EV::break });
        my $w = EV::timer(0.3, 0, sub {
            my $ok = eval { $c->query('SELECT 1', sub {}); 1 };
            ok($ok, 'R4F1: query in handshake window queues instead of croaking')
                or diag($@);
        });
        my $t = EV::timer(6, 0, sub { EV::break });
        EV::run;
        like($err // '', qr/timeout/i, 'R4F1: stalled handshake still times out');
        $c->finish;
    }
}

# --- R1F1: connection keeps a custom loop alive -----------------------------
{
    my $loop = EV::Loop->new;
    my $val;
    my $c = EV::ClickHouse->new(host => $host, port => $nport, protocol => 'native',
                                loop => $loop);
    my $keep = $loop; weaken($keep); undef $loop;
    $c->query('SELECT 42 AS x', sub {
        my ($r, $err) = @_;
        $val = $err ? "err: $err" : $r->[0][0];
        $c->finish; EV::break($keep);
    });
    $keep->run;
    is($val, 42, 'R1F1: query works after user drops the loop ref');
    undef $keep; undef $c;
}

# --- R1F2: Streamer rejects unknown options ---------------------------------
{
    my $d = EV::ClickHouse->new(host => $host, port => $nport, protocol => 'native');
    my $ok = eval { $d->insert_streamer('t58_nope', batch_siez => 5); 1 };
    like($@, qr/unknown option.*batch_siez/, 'R1F2: option typo dies loudly');
    $d->finish;
}

# --- R1F3: dying drain waiter starves neither peers nor finish -------------
with_ch(cb => sub {
    $ch->query('DROP TABLE IF EXISTS t58_w', sub {
    $ch->query('CREATE TABLE t58_w (a UInt32) ENGINE=Memory', sub {
        my $s = $ch->insert_streamer('t58_w', batch_size => 100);
        $s->push_row([1]);
        my ($second, $warn, $fin);
        $s->await_drain(sub { die "waiter1 boom" });
        $s->await_drain(sub { $second = 1 });
        my $old_warn = $SIG{__WARN__};
        $SIG{__WARN__} = sub { $warn .= $_[0] };
        $s->finish(sub { $fin = $_[1] // 'ok' });
        # finish callback runs on a later tick; poll via timer
        my $w; $w = EV::timer(0.1, 0.1, sub {
            return unless defined $fin;
            undef $w;
            $SIG{__WARN__} = $old_warn;
            ok($second, 'R1F3: second waiter still fires');
            like($warn // '', qr/await_drain callback died/,
                'R1F3: dying waiter warns instead of escaping');
            $ch->query('DROP TABLE t58_w', sub { EV::break });
        });
    }) });
});
