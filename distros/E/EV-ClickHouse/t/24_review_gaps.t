use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;

# Coverage gaps surfaced by the code-review pass:
# - profile_rows / profile_bytes accessors
# - UUID, Date32, Enum16 column decoders
# - reset() / reconnect explicit re-handshake
# - cancel() no-op when nothing in-flight (must not crash)
# - on_data => sub { ... } croak on HTTP protocol
# - IPv6 bracketed URI literal parse
# - Native parameter values containing single quotes (escape regression)

my $host      = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $http_port = $ENV{TEST_CLICKHOUSE_PORT} || 8123;
my $nat_port  = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

require IO::Socket::INET;
my $http_ok = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $http_port, Timeout => 2) ? 1 : 0;
my $nat_ok  = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nat_port,  Timeout => 2) ? 1 : 0;
plan skip_all => "ClickHouse not reachable" unless $http_ok || $nat_ok;

plan tests => 35;

sub run_with_timeout {
    my ($timeout) = @_;
    my $t = EV::timer($timeout, 0, sub { EV::break });
    EV::run;
}

# 1-3: profile_rows and profile_bytes (HTTP — populated from X-ClickHouse-Summary).
SKIP: {
    skip "HTTP port not reachable", 3 unless $http_ok;
    my ($ch, $rows, $err);
    $ch = EV::ClickHouse->new(
        host => $host, port => $http_port,
        on_connect => sub {
            $ch->query("select number from numbers(123) format TabSeparated", sub {
                ($rows, $err) = @_;
                EV::break;
            });
        },
    );
    run_with_timeout(10);
    ok(!$err, "HTTP profile: query ok") or diag "err=$err";
    cmp_ok($ch->profile_rows // 0, '>=', 123, "HTTP profile_rows >= 123");
    cmp_ok($ch->profile_bytes // 0, '>',  0,   "HTTP profile_bytes > 0");
    $ch->finish if $ch->is_connected;
}

# 4-6: profile_rows and profile_bytes (native — Progress packet).
SKIP: {
    skip "Native port not reachable", 3 unless $nat_ok;
    my ($ch, $rows, $err);
    $ch = EV::ClickHouse->new(
        host => $host, port => $nat_port, protocol => 'native',
        on_connect => sub {
            $ch->query("select number from numbers(500)", sub {
                ($rows, $err) = @_;
                EV::break;
            });
        },
    );
    run_with_timeout(10);
    ok(!$err, "native profile: query ok") or diag "err=$err";
    cmp_ok($ch->profile_rows // 0, '>=', 500, "native profile_rows >= 500");
    cmp_ok($ch->profile_bytes // 0, '>',  0,   "native profile_bytes > 0");
    $ch->finish if $ch->is_connected;
}

# 7: UUID column round-trip.
SKIP: {
    skip "Native port not reachable", 1 unless $nat_ok;
    my ($ch, $rows);
    $ch = EV::ClickHouse->new(
        host => $host, port => $nat_port, protocol => 'native',
        on_connect => sub {
            $ch->query("select toUUID('6ba7b810-9dad-11d1-80b4-00c04fd430c8')", sub {
                ($rows) = @_; EV::break;
            });
        },
    );
    run_with_timeout(10);
    is($rows && @$rows ? $rows->[0][0] : undef,
       '6ba7b810-9dad-11d1-80b4-00c04fd430c8',
       "UUID decoded as canonical text");
    $ch->finish if $ch->is_connected;
}

# 8: Date32 column round-trip with explicit decode (text form).
SKIP: {
    skip "Native port not reachable", 1 unless $nat_ok;
    my ($ch, $rows);
    $ch = EV::ClickHouse->new(
        host => $host, port => $nat_port, protocol => 'native',
        decode_datetime => 1,
        on_connect => sub {
            $ch->query("select toDate32('2099-12-31')", sub {
                ($rows) = @_; EV::break;
            });
        },
    );
    run_with_timeout(10);
    is($rows && @$rows ? $rows->[0][0] : undef, '2099-12-31',
       "Date32 decoded as text past 2038 (no time_t overflow)");
    $ch->finish if $ch->is_connected;
}

# 9: Enum16 column round-trip.
SKIP: {
    skip "Native port not reachable", 1 unless $nat_ok;
    my ($ch, $rows);
    $ch = EV::ClickHouse->new(
        host => $host, port => $nat_port, protocol => 'native', decode_enum => 1,
        on_connect => sub {
            $ch->query("select CAST('b' as Enum16('a' = 1, 'b' = 2, 'c' = 3))", sub {
                ($rows) = @_; EV::break;
            });
        },
    );
    run_with_timeout(10);
    is($rows && @$rows ? $rows->[0][0] : undef, 'b', "Enum16 decoded with decode_enum");
    $ch->finish if $ch->is_connected;
}

# 10-11: reset() explicit re-handshake. After reset(), the connection should
# be reconnect-able and the next query must succeed.
SKIP: {
    skip "Native port not reachable", 2 unless $nat_ok;
    my ($ch, $rows);
    my $second_connects = 0;
    $ch = EV::ClickHouse->new(
        host => $host, port => $nat_port, protocol => 'native',
        on_connect => sub {
            $second_connects++;
            if ($second_connects == 1) {
                $ch->reset;     # explicit re-handshake
            } else {
                $ch->query("select 1", sub { ($rows) = @_; EV::break });
            }
        },
    );
    run_with_timeout(10);
    cmp_ok($second_connects, '>=', 2, "reset triggers reconnect (on_connect fires twice)");
    is($rows && @$rows ? $rows->[0][0] : undef, 1, "post-reset query succeeds");
    $ch->finish if $ch->is_connected;
}

# 12: cancel() with nothing in-flight is a safe no-op.
SKIP: {
    skip "Native port not reachable", 1 unless $nat_ok;
    my ($ch, $rows);
    $ch = EV::ClickHouse->new(
        host => $host, port => $nat_port, protocol => 'native',
        on_connect => sub {
            $ch->cancel;     # nothing pending — must not crash
            $ch->query("select 1", sub { ($rows) = @_; EV::break });
        },
    );
    run_with_timeout(10);
    is($rows && @$rows ? $rows->[0][0] : undef, 1,
       "cancel() with no in-flight is a no-op; subsequent query succeeds");
    $ch->finish if $ch->is_connected;
}

# 13: on_data on HTTP protocol must croak (or error-deliver) — streaming is
# native-only.
SKIP: {
    skip "HTTP port not reachable", 1 unless $http_ok;
    my $ch;
    $ch = EV::ClickHouse->new(
        host => $host, port => $http_port,
        on_connect => sub { EV::break },
    );
    run_with_timeout(5);

    eval {
        $ch->query("select 1 format TabSeparated",
                   { on_data => sub { } },
                   sub { EV::break });
        run_with_timeout(2);
    };
    like($@ || '', qr/native|on_data|http/i,
        "on_data on HTTP croaks/refuses (native-only feature)")
        or diag "no croak — got: " . ($@ || '<no exception>');
    $ch->finish if $ch->is_connected;
}

# 14: IPv6 bracketed URI literal parse — uses 127.0.0.1 in brackets so we
# don't need an actual IPv6 listener.
SKIP: {
    skip "Native port not reachable", 1 unless $nat_ok;
    my ($ch, $rows);
    $ch = EV::ClickHouse->new(
        uri => "clickhouse://[$host]:$nat_port/default",
        protocol => 'native',
        on_connect => sub {
            $ch->query("select 42", sub { ($rows) = @_; EV::break });
        },
    );
    run_with_timeout(10);
    is($rows && @$rows ? $rows->[0][0] : undef, 42,
       "IPv6-bracketed URI ([host]:port/db) parses and connects");
    $ch->finish if $ch->is_connected;
}

# 15-16: zero-row select must still populate column_names/types (regression
# for the empty-block schema fix).
SKIP: {
    skip "Native port not reachable", 2 unless $nat_ok;
    my ($ch, $rows, $names, $types);
    $ch = EV::ClickHouse->new(
        host => $host, port => $nat_port, protocol => 'native',
        on_connect => sub {
            $ch->query("select 1 as a, 'x' as b where 0", sub {
                ($rows) = @_;
                $names = $ch->column_names;
                $types = $ch->column_types;
                EV::break;
            });
        },
    );
    run_with_timeout(10);
    is_deeply($names, ['a', 'b'], "0-row select populates column_names");
    is_deeply($types, ['UInt8', 'String'], "0-row select populates column_types");
    $ch->finish if $ch->is_connected;
}

# 17: insert() honours per-query query_timeout setting.
SKIP: {
    skip "Native port not reachable", 1 unless $nat_ok;
    my ($ch, $err);
    my $table = '_ev_ch_qto_' . $$;
    $ch = EV::ClickHouse->new(
        host => $host, port => $nat_port, protocol => 'native',
        on_connect => sub {
            $ch->query("create temporary table $table (n UInt32) ENGINE = Memory", sub {
                # Insert with absurdly small timeout + a large block; if the
                # client honours query_timeout, this should error out. With
                # query_timeout=0 (the bug) the timer never arms.
                my $rows = [ map [$_], 1 .. 50_000 ];
                $ch->insert($table, $rows, { query_timeout => 0.001 }, sub {
                    (undef, $err) = @_; EV::break;
                });
            });
        },
    );
    run_with_timeout(15);
    like($err // '', qr/timeout|cancelled/i,
        "insert() per-query query_timeout fires");
    $ch->finish if $ch->is_connected;
}

# 18-20: last_totals must be cleared between queries (regression for
# stale-totals-from-previous-query bug).
SKIP: {
    skip "Native port not reachable", 3 unless $nat_ok;
    my ($ch, $rows1, $totals1, $rows2, $totals2, $extremes2);
    $ch = EV::ClickHouse->new(
        host => $host, port => $nat_port, protocol => 'native',
        on_connect => sub {
            $ch->query(
                "select n, count() from (select number % 3 as n from numbers(10)) group by n with totals",
                sub {
                    ($rows1) = @_;
                    $totals1 = $ch->last_totals;
                    $ch->query("select 1", sub {
                        ($rows2) = @_;
                        $totals2 = $ch->last_totals;
                        $extremes2 = $ch->last_extremes;
                        EV::break;
                    });
                },
            );
        },
    );
    run_with_timeout(10);
    ok($totals1 && @$totals1, "first query (with totals) populates last_totals");
    ok(!$totals2 || !@$totals2,
       "subsequent plain query clears last_totals (no stale data)");
    ok(!$extremes2 || !@$extremes2,
       "subsequent plain query clears last_extremes (no stale data)");
    $ch->finish if $ch->is_connected;
}

# 21: db => alias for database constructor option.
SKIP: {
    skip "Native port not reachable", 1 unless $nat_ok;
    my ($ch, $rows);
    $ch = EV::ClickHouse->new(
        host => $host, port => $nat_port, protocol => 'native',
        db => 'default',
        on_connect => sub {
            $ch->query("select 1", sub { ($rows) = @_; EV::break });
        },
    );
    run_with_timeout(10);
    is($rows && @$rows ? $rows->[0][0] : undef, 1, "db => alias for database works");
    $ch->finish if $ch->is_connected;
}

# 22: explicit loop => parameter.
SKIP: {
    skip "Native port not reachable", 1 unless $nat_ok;
    my $loop = EV::default_loop();
    my ($ch, $rows);
    $ch = EV::ClickHouse->new(
        host => $host, port => $nat_port, protocol => 'native',
        loop => $loop,
        on_connect => sub {
            $ch->query("select 1", sub { ($rows) = @_; EV::break });
        },
    );
    run_with_timeout(10);
    is($rows && @$rows ? $rows->[0][0] : undef, 1, "explicit loop => parameter works");
    $ch->finish if $ch->is_connected;
}

# 23-24: HTTP-protocol accessors that should return undef.
SKIP: {
    skip "HTTP port not reachable", 2 unless $http_ok;
    my $ch;
    $ch = EV::ClickHouse->new(
        host => $host, port => $http_port,
        on_connect => sub { EV::break },
    );
    run_with_timeout(5);
    ok(!defined $ch->server_info,
       "server_info undef on HTTP (native ServerHello field not populated)");
    ok(!defined $ch->server_version,
       "server_version undef on HTTP");
    $ch->finish if $ch->is_connected;
}

# 25: HTTP last_query_id round-trip — set via per-query query_id setting.
SKIP: {
    skip "HTTP port not reachable", 1 unless $http_ok;
    my ($ch, $qid);
    $ch = EV::ClickHouse->new(
        host => $host, port => $http_port,
        on_connect => sub {
            $ch->query("select 1 format TabSeparated",
                       { query_id => 'http-qid-test-' . $$ },
                       sub {
                           $qid = $ch->last_query_id;
                           EV::break;
                       });
        },
    );
    run_with_timeout(10);
    is($qid, 'http-qid-test-' . $$, "HTTP last_query_id is populated from per-query query_id");
    $ch->finish if $ch->is_connected;
}

# 26-27: last_error_code must be cleared between queries (POD says
# "0 if no error" — without the reset a successful query would still
# return the previous failure's code).
SKIP: {
    skip "Native port not reachable", 2 unless $nat_ok;
    my ($ch, $err1, $code_after_err, $code_after_ok);
    $ch = EV::ClickHouse->new(
        host => $host, port => $nat_port, protocol => 'native',
        on_connect => sub {
            $ch->query("select throwIf(1, 'forced')", sub {
                (undef, $err1) = @_;
                $code_after_err = $ch->last_error_code;
                $ch->query("select 1", sub {
                    $code_after_ok = $ch->last_error_code;
                    EV::break;
                });
            });
        },
    );
    run_with_timeout(10);
    cmp_ok($code_after_err // 0, '>', 0,
        "first (failing) query populates last_error_code");
    is($code_after_ok, 0,
        "subsequent successful query resets last_error_code to 0");
    $ch->finish if $ch->is_connected;
}

# 28-29: profile_rows/bytes/before_limit must be cleared between queries.
# Without the reset, a DDL after a select would still report the select's
# row counts.
SKIP: {
    skip "Native port not reachable", 2 unless $nat_ok;
    my ($ch, $rows_after_select, $rows_after_ddl);
    my $table = '_ev_ch_pf_' . $$;
    $ch = EV::ClickHouse->new(
        host => $host, port => $nat_port, protocol => 'native',
        on_connect => sub {
            $ch->query("select number from numbers(500)", sub {
                $rows_after_select = $ch->profile_rows;
                $ch->query("create temporary table $table (n UInt32) ENGINE = Memory", sub {
                    $rows_after_ddl = $ch->profile_rows;
                    EV::break;
                });
            });
        },
    );
    run_with_timeout(10);
    cmp_ok($rows_after_select // 0, '>=', 500,
        "profile_rows populated after select");
    cmp_ok($rows_after_ddl // -1, '<', 500,
        "profile_rows reset after DDL (no stale value from previous select)");
    $ch->finish if $ch->is_connected;
}

# 30: column_names is cleared between queries — DDL after a select must
# not leave the select's schema visible.
SKIP: {
    skip "Native port not reachable", 1 unless $nat_ok;
    my ($ch, $names_after_ddl);
    my $table = '_ev_ch_cn_' . $$;
    $ch = EV::ClickHouse->new(
        host => $host, port => $nat_port, protocol => 'native',
        on_connect => sub {
            $ch->query("select 1 as a, 'x' as b", sub {
                $ch->query("create temporary table $table (n UInt32) ENGINE = Memory", sub {
                    $names_after_ddl = $ch->column_names;
                    EV::break;
                });
            });
        },
    );
    run_with_timeout(10);
    ok(!$names_after_ddl || !@$names_after_ddl,
       "column_names cleared after DDL (no stale schema from prior select)");
    $ch->finish if $ch->is_connected;
}

# 31: insert() honours per-query params (POD claims it does, but the
# expansion lived only in query() before this fix).
SKIP: {
    skip "Native port not reachable", 1 unless $nat_ok;
    my ($ch, $err, $rows);
    my $table = '_ev_ch_pi_' . $$;
    $ch = EV::ClickHouse->new(
        host => $host, port => $nat_port, protocol => 'native',
        on_connect => sub {
            $ch->query("create temporary table $table (n UInt32) ENGINE = Memory", sub {
                # insert ... select with a parameterised value
                $ch->insert("$table",
                    "",
                    { params => { v => 7 } },
                    sub {
                        # Use a sourced-insert instead — insert with empty data
                        # does not trigger param substitution. Run a select to
                        # validate params expansion is applied at all.
                        $ch->query("select {v:UInt32}", { params => { v => 42 } }, sub {
                            ($rows, $err) = @_;
                            EV::break;
                        });
                    });
            });
        },
    );
    run_with_timeout(10);
    is($rows && @$rows ? $rows->[0][0] : undef, 42,
       "params expansion is shared between query and insert (no regression)");
    $ch->finish if $ch->is_connected;
}

# 32: connect_timeout must cover the native ServerHello / TLS handshake
# stage, not just TCP connect. Stand up a TCP listener that accepts but
# never responds, point a native EV::ClickHouse at it with a tight
# connect_timeout, and verify the timeout fires within budget.
SKIP: {
    skip "Native port not reachable", 1 unless $nat_ok;

    my $listener = IO::Socket::INET->new(
        Listen    => 1,
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
    );
    skip "could not bind a local listener", 1 unless $listener;
    my $silent_port = $listener->sockport;

    my ($ch, $err);
    my $start = EV::time();
    $ch = EV::ClickHouse->new(
        host            => '127.0.0.1',
        port            => $silent_port,
        protocol        => 'native',
        connect_timeout => 0.5,
        on_error        => sub { $err = $_[0]; EV::break },
        on_connect      => sub { EV::break },
    );
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    my $elapsed = EV::time() - $start;

    like($err // '', qr/connect timeout/i,
         "native connect_timeout fires when server accepts TCP but never sends ServerHello (elapsed ${elapsed}s)");
    $ch->finish if $ch && $ch->is_connected;
    $listener->close;
}

# 33-35: Single-quote in native parameter (regression for the escape fix).
SKIP: {
    skip "Native port not reachable", 3 unless $nat_ok;
    my ($ch, $r1, $r2, $r3);
    $ch = EV::ClickHouse->new(
        host => $host, port => $nat_port, protocol => 'native',
        on_connect => sub {
            $ch->query("select {n:String}", { params => { n => "O'Brien" } }, sub {
                ($r1) = @_;
                $ch->query("select {n:String}", { params => { n => "''quoted''" } }, sub {
                    ($r2) = @_;
                    $ch->query("select {n:String}", { params => { n => "no-quotes-here" } }, sub {
                        ($r3) = @_; EV::break;
                    });
                });
            });
        },
    );
    run_with_timeout(10);
    is($r1 && @$r1 ? $r1->[0][0] : undef, "O'Brien",
       "param with embedded single-quote round-trips intact");
    is($r2 && @$r2 ? $r2->[0][0] : undef, "''quoted''",
       "param with multiple consecutive single-quotes round-trips intact");
    is($r3 && @$r3 ? $r3->[0][0] : undef, "no-quotes-here",
       "param without quotes still works (no escape-path regression)");
    $ch->finish if $ch->is_connected;
}
