use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;

# Coverage gaps surfaced during review:
# - HTTP ping() callback fires with truthy result
# - decode_decimal precision boundary (Decimal128 round-trip)
# - per-query settings actually applied to the wire (positive proof, not
#   just "it didn't crash")
# - very large insert batch (10k rows)

my $host      = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $http_port = $ENV{TEST_CLICKHOUSE_PORT} || 8123;
my $nat_port  = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

require IO::Socket::INET;
my $http_ok = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $http_port, Timeout => 2) ? 1 : 0;
my $nat_ok  = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nat_port,  Timeout => 2) ? 1 : 0;
plan skip_all => "ClickHouse not reachable" unless $http_ok || $nat_ok;

plan tests => 15;

# 0: HTTP arrayref insert with a nested arrayref column must croak rather
# than silently send ARRAY(0x...) garbage. The TSV serialiser has no
# column-type info from the server (HTTP doesn't ship a sample block),
# so nested types are native-only by design.
SKIP: {
    skip "HTTP port not reachable", 1 unless $http_ok;

    my $ch;
    $ch = EV::ClickHouse->new(
        host       => $host,
        port       => $http_port,
        on_connect => sub { EV::break },
        on_error   => sub { diag "ctor error: $_[0]" },
    );
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;

    eval {
        $ch->insert("nope", [ [1, [10, 20]] ], sub { EV::break });
        EV::run;
    };
    like($@, qr/native protocol/i,
        "HTTP arrayref insert croaks on nested ref instead of corrupting TSV")
        or diag "no croak — got: " . ($@ || '<no exception>');
    $ch->finish if $ch->is_connected;
}

# 1-2: HTTP ping() callback fires with truthy result and no error.
SKIP: {
    skip "HTTP port not reachable", 2 unless $http_ok;

    my $ch;
    my ($got, $err);
    $ch = EV::ClickHouse->new(
        host       => $host,
        port       => $http_port,
        on_connect => sub {
            $ch->ping(sub {
                ($got, $err) = @_;
                EV::break;
            });
        },
        on_error   => sub { diag "ping error: $_[0]" },
    );
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;

    ok(!$err, "HTTP ping: no error") or diag "err=" . ($err // '<undef>');
    ok($got, "HTTP ping: callback got truthy result");
    $ch->finish if $ch->is_connected;
}

# 3-4: native ping() — protocol-level CLIENT_PING / SERVER_PONG round trip.
SKIP: {
    skip "Native port not reachable", 2 unless $nat_ok;

    my $ch;
    my ($got, $err);
    $ch = EV::ClickHouse->new(
        host       => $host,
        port       => $nat_port,
        protocol   => 'native',
        on_connect => sub {
            $ch->ping(sub {
                ($got, $err) = @_;
                EV::break;
            });
        },
        on_error   => sub { diag "native ping error: $_[0]" },
    );
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;

    ok(!$err, "native ping: no error") or diag "err=" . ($err // '<undef>');
    ok($got, "native ping: callback got truthy result");
    $ch->finish if $ch->is_connected;
}

# 5-7: decode_decimal precision (native).
# Decimal64 round-trip is exact within float64 mantissa; Decimal128 with
# many digits may lose precision but should still round-trip the
# integer-scale boundary cleanly.
SKIP: {
    skip "Native port not reachable", 3 unless $nat_ok;

    my $ch;
    my $rows;
    $ch = EV::ClickHouse->new(
        host           => $host,
        port           => $nat_port,
        protocol       => 'native',
        decode_decimal => 1,
        on_connect     => sub {
            $ch->query("
                select
                    toDecimal64('0.50',          2)  as small,
                    toDecimal64('1234567.89',    2)  as mid,
                    toDecimal128('999999.999999',6)  as big
            ", sub { ($rows, undef) = @_; EV::break });
        },
        on_error => sub { diag "decimal error: $_[0]" },
    );
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;

    my $r = ($rows && @$rows) ? $rows->[0] : [];
    cmp_ok(abs(($r->[0] // 0) - 0.5),         '<', 0.0001, "decimal: 0.5 round-trip");
    cmp_ok(abs(($r->[1] // 0) - 1234567.89),  '<', 0.01,   "decimal: 1234567.89 round-trip");
    cmp_ok(abs(($r->[2] // 0) - 999999.999999),'<',1e-6,   "decimal: 999999.999999 round-trip");
    $ch->finish if $ch->is_connected;
}

# 8-10: per-query settings end-to-end. Use max_result_rows + throw mode to
# prove the server received the setting (without it the query returns 10
# rows; with it the server raises CODE 396 / TOO_MANY_ROWS_OR_BYTES).
SKIP: {
    skip "Native port not reachable", 3 unless $nat_ok;

    my $ch;
    my (@rows_no, @rows_yes, $err_yes, $err_code);
    $ch = EV::ClickHouse->new(
        host       => $host,
        port       => $nat_port,
        protocol   => 'native',
        on_connect => sub {
            # Without settings: full 10 rows.
            $ch->query("select number from numbers(10)", sub {
                my ($r, $e) = @_;
                @rows_no = @{$r // []};

                # With settings: server should raise.
                $ch->query(
                    "select number from numbers(10)",
                    { max_result_rows => 1, result_overflow_mode => 'throw' },
                    sub {
                        my ($r2, $e2) = @_;
                        $err_yes = $e2;
                        $err_code = $ch->last_error_code;
                        @rows_yes = @{$r2 // []};
                        EV::break;
                    },
                );
            });
        },
        on_error => sub { diag "settings error: $_[0]" },
    );
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;

    is(scalar @rows_no, 10, "settings: baseline returns 10 rows");
    ok($err_yes, "settings: capped query raises on the server");
    is($err_code, 396,
        "settings: error code is TOO_MANY_ROWS_OR_BYTES (396)")
        or diag "got code: " . ($err_code // '<undef>');
    $ch->finish if $ch->is_connected;
}

# 11-14: 10 000-row insert round-trip on a temporary Memory table.
SKIP: {
    skip "Native port not reachable", 4 unless $nat_ok;

    my $ch;
    my ($insert_err, $count_rows, $sum_rows);
    my $N = 10_000;
    my $table = '_ev_ch_big_' . $$;

    $ch = EV::ClickHouse->new(
        host       => $host,
        port       => $nat_port,
        protocol   => 'native',
        on_connect => sub {
            $ch->query("
                create temporary table $table (id UInt32, val String)
                ENGINE = Memory
            ", sub {
                my $rows = [ map [ $_, "row-$_" ], 1 .. $N ];
                $ch->insert($table, $rows, sub {
                    (undef, $insert_err) = @_;
                    $ch->query("select count() from $table", sub {
                        my ($r) = @_;
                        $count_rows = $r;
                        $ch->query("select sum(id) from $table", sub {
                            my ($r2) = @_;
                            $sum_rows = $r2;
                            EV::break;
                        });
                    });
                });
            });
        },
        on_error => sub { diag "big insert error: $_[0]" },
    );
    my $t = EV::timer(30, 0, sub { EV::break });
    EV::run;

    ok(!$insert_err, "large insert: $N rows, no error")
        or diag "err=" . ($insert_err // '<undef>');
    ok($count_rows && @$count_rows, "large insert: count() returned a row");
    is($count_rows && @$count_rows ? $count_rows->[0][0] : undef, $N,
        "large insert: row count matches");
    is($sum_rows && @$sum_rows ? $sum_rows->[0][0] : undef, $N * ($N + 1) / 2,
        "large insert: sum(id) matches arithmetic series");
    $ch->finish if $ch->is_connected;
}
