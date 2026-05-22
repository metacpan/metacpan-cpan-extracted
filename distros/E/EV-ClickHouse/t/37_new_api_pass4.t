#!/usr/bin/env perl
# Pass-4 batch coverage: error class, bind_ident, on_log,
# cancel_by_query_id, Pool::query_to/insert_to/nominate/hedged_query,
# pending_queries, dump_state, track_query_durations,
# insert_async, for_json_paths, insert_aggregated.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::ClickHouse;

my $host  = $ENV{TEST_CLICKHOUSE_HOST}        || '127.0.0.1';
my $nport = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

plan skip_all => "ClickHouse native not reachable"
    unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nport, Timeout => 2);

plan tests => 95;

# Run EV::run with a bail-out timer so a missed EV::break can't hang
# the test. Cheaper than spelling it out in every block.
sub run_with_bail {
    my ($timeout) = @_;
    my $t = EV::timer($timeout, 0, sub { EV::break });
    EV::run;
    undef $t;
}

# 1. Error class
{
    my $e = EV::ClickHouse::Error->new(message => 'boom', code => 60);
    is "$e", 'boom',                           'Error stringifies to message';
    is $e->code, 60,                           'Error code';
    is $e->name, 'UNKNOWN_TABLE',              'Error name lookup';
    ok !$e->is_retryable,                      'UNKNOWN_TABLE not retryable';
    my $e2 = EV::ClickHouse::Error->new(message => 'slow', code => 159);
    ok $e2->is_retryable,                      'TIMEOUT_EXCEEDED retryable';
}

# 2. bind_ident
{
    is(EV::ClickHouse->bind_ident('events'),    '`events`',      'simple identifier');
    is(EV::ClickHouse->bind_ident('db.events'), '`db`.`events`', 'dotted identifier');
    eval { EV::ClickHouse->bind_ident("1bad") };
    like $@, qr/invalid/,                       'leading digit rejected';
    eval { EV::ClickHouse->bind_ident("a; drop") };
    like $@, qr/invalid/,                       'SQL injection attempt rejected';
}

# 3. on_log fires + dump_state + pending_queries
{
    my @logs;
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_log => sub { push @logs, $_[0] },
        on_connect => sub {
            # send_logs_level is a per-query setting, not nested
            # under {settings}. trace level fires LOG packets for
            # virtually any SELECT — enough to drive parse_and_emit_log_block.
            $ch->query(
                "select sleep(0.01)",
                { send_logs_level => 'trace' },
                sub { EV::break },
            );
        },
        on_error => sub { EV::break },
    );
    run_with_bail(5);
    ok scalar @logs > 0,                       'on_log fires for at least one log row';
    is ref($logs[0]),       'HASH',            'log entry is a hashref';
    ok exists $logs[0]{text},                  'log entry has text field';
    my $st = $ch->dump_state;
    is ref($st), 'HASH',                        'dump_state returns hashref';
    ok exists $st->{protocol},                  'dump_state has protocol field';
    my $pq = $ch->pending_queries;
    is ref($pq), 'ARRAY',                       'pending_queries returns arrayref';
    $ch->finish;
}

# 4. track_query_durations + Pool::query_to + hedged_query
{
    my $pool = EV::ClickHouse::Pool->new(
        host => $host, port => $nport, protocol => 'native', size => 3,
    );

    # query_to: pin to member 1, verify it lands.
    my $routed_done = 0;
    $pool->query_to(1, "select 1", sub {
        my ($rows, $err) = @_;
        $routed_done = 1 if !$err && $rows && $rows->[0][0] == 1;
        EV::break;
    });
    run_with_bail(5);
    ok $routed_done,                           'Pool::query_to routes + returns rows';

    # hedged_query: ask two members, take first. cb must be last arg.
    my $hedged_done = 0;
    $pool->hedged_query("select 7", hedge => 2, sub {
        my ($rows, $err) = @_;
        $hedged_done = 1 if !$err && $rows && $rows->[0][0] == 7;
        EV::break;
    });
    run_with_bail(5);
    ok $hedged_done,                           'Pool::hedged_query resolves with first reply';

    # nominate returns underlying conn
    is ref($pool->nominate(0)), 'EV::ClickHouse', 'Pool::nominate returns conn';
    $pool->finish;
}

# 5. insert_async (server may not have async_insert enabled by default,
# so we just verify the helper plumbs settings without croaking).
{
    my $tbl = "ev_ch_async_$$";
    my $err_phase; my $count;
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub {
            $ch->query("create table $tbl (n UInt32) engine=Memory", sub {
                my (undef, $e) = @_;
                $err_phase = "ddl: $e" if $e;
                $ch->insert_async($tbl, [[1],[2],[3]], sub {
                    my (undef, $e) = @_;
                    $err_phase = "ins: $e" if $e;
                    $ch->query("select count() from $tbl", sub {
                        my ($r, $e) = @_;
                        $count = $r ? $r->[0][0] : undef;
                        $ch->query("drop table $tbl", sub { EV::break });
                    });
                });
            });
        },
        on_error => sub { $err_phase = "conn: $_[0]"; EV::break },
    );
    run_with_bail(8);
    ok !$err_phase,                            "insert_async ran (" . ($err_phase // '') . ")";
    is $count, 3,                              'insert_async rows landed';
    $ch->finish;
}

# 6. cancel_by_query_id matches and no-ops correctly.
{
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub { EV::break },
    );
    run_with_bail(3);
    is $ch->cancel_by_query_id('whatever'), 0, 'no in-flight query: no-op';
    eval { $ch->cancel_by_query_id(undef) };
    like $@, qr/query_id required/,            'cancel_by_query_id rejects undef';
    $ch->finish;
}

# 7. Pool::insert_to routes to the chosen member.
{
    my $tbl = "ev_ch_pti_$$";
    my $pool = EV::ClickHouse::Pool->new(
        host => $host, port => $nport, protocol => 'native', size => 2,
    );
    my $tag = "ev-ch-insert-to-$$";
    my $err; my $member0_qid_after_insert; my $count;
    $pool->query("create table $tbl (n UInt32) engine=Memory", sub {
        my (undef, $e) = @_; $err = $e;
        $pool->insert_to(0, $tbl, [[1],[2]],
            { query_id => $tag }, sub {
            my (undef, $e) = @_; $err //= $e;
            # Read member-0 last_query_id BEFORE issuing any other query
            # on that member, so the tag is still observable.
            $member0_qid_after_insert = $pool->nominate(0)->last_query_id;
            $pool->query_to(1, "select count() from $tbl", sub {
                my ($r, $e) = @_;
                $err //= $e;
                $count = $r ? $r->[0][0] : undef;
                $pool->query("drop table $tbl", sub { EV::break });
            });
        });
    });
    run_with_bail(5);
    ok !$err, 'Pool::insert_to ran cleanly' or diag $err;
    is $member0_qid_after_insert, $tag,
        'last_query_id on member 0 is the tag we passed (proves routing)';
    is $count, 2, 'inserted rows are visible via query_to';
    $pool->finish;
}

# 8. for_json_paths against a JSON column (CH 23.8+; skip if unsupported).
SKIP: {
    my $tbl = "ev_ch_jp_$$";
    my $paths; my $err;
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub {
            $ch->query(
                "create table $tbl (j JSON) engine=Memory",
                { allow_experimental_json_type => 1 },
                sub {
                    my (undef, $e) = @_;
                    if ($e) { $err = $e; return EV::break }
                    $ch->insert($tbl,
                        [[ '{"a":1,"b":"x","nested":{"c":1.5}}' ]],
                        sub {
                            my (undef, $e) = @_;
                            if ($e) { $err = $e; return EV::break }
                            $ch->for_json_paths($tbl, 'j', sub {
                                my ($got, $e) = @_;
                                if ($e) { $err = $e } else { $paths = $got }
                                $ch->query("drop table $tbl", sub { EV::break });
                            });
                        });
                });
        },
        on_error => sub { $err = $_[0]; EV::break },
    );
    run_with_bail(8);
    $ch->finish;
    skip "JSON type not supported by this server", 2
        if $err && $err =~ /JSON|experimental|unsupported type|JSONAllPathsWithTypes/i;
    ok !$err && $paths,                       'for_json_paths returns a list'
        or diag "err: " . ($err // '') . " paths: ". ($paths ? scalar @$paths : 'undef');
    ok $paths && @$paths >= 1,                'at least one path discovered';
}

# 9. insert_aggregated round-trip: build states, then uniqExactMerge to
# verify the State combinator wire-format matches what reads back.
{
    my $tbl = "ev_ch_agg_$$";
    my $err; my $merged;
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub {
            $ch->query(
                "create table $tbl (k String, u AggregateFunction(uniqExact, UInt64)) engine=Memory",
                sub {
                    my (undef, $e) = @_;
                    if ($e) { $err = $e; return EV::break }
                    $ch->insert_aggregated($tbl,
                        u        => { func => 'uniqExact', args => ['UInt64'] },
                        key_cols => [qw(k)],
                        rows     => [['a', 1], ['a', 2], ['b', 7]],
                        cb       => sub {
                            my (undef, $e) = @_;
                            if ($e) { $err = $e; return EV::break }
                            $ch->query("select uniqExactMerge(u) from $tbl", sub {
                                my ($r, $e) = @_;
                                $err //= $e;
                                $merged = $r ? $r->[0][0] : undef;
                                $ch->query("drop table $tbl", sub { EV::break });
                            });
                        });
                });
        },
        on_error => sub { $err = $_[0]; EV::break },
    );
    run_with_bail(8);
    $ch->finish;
    ok !$err, 'insert_aggregated round-tripped' or diag $err;
    is $merged, 3, 'three distinct uniqExact states merge back to 3';
}

# 10. finish() inside on_query_start must not crash (UAF regression).
{
    my $started = 0;
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_query_start => sub {
            $started++;
            $ch->finish;
        },
        on_connect => sub {
            $ch->query("select 1", sub { EV::break });
        },
        on_error => sub { EV::break },
    );
    run_with_bail(3);
    ok $started, 'on_query_start fired; finish() inside it did not crash';
}

# 11. track_query_durations records p95 over actual queries.
{
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub { EV::break },
    );
    run_with_bail(3);
    $ch->track_query_durations(64);
    my $left = 5;
    for (1 .. 5) {
        $ch->query("select sleep(0.01)", sub { EV::break if !--$left });
    }
    run_with_bail(5);
    is $ch->query_duration_count, 5,    'ring captured 5 samples';
    ok $ch->query_duration_p(0.5) > 0,  'p50 is positive';
    ok $ch->query_duration_p(0.95) >= $ch->query_duration_p(0.5),
        'p95 >= p50';
    $ch->track_query_durations(0);
    is $ch->query_duration_count, 0,    'disable clears the ring';
    $ch->finish;
}

# 12. on_log callback that drops itself must not UAF (cb refcount guard).
{
    my $fired = 0;
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub {
            $ch->on_log(sub {
                $fired++;
                # Drop the handler from inside itself; the row loop must
                # still finish without dereferencing a freed CV.
                $ch->on_log(undef);
            });
            $ch->query("select sleep(0.01)",
                { send_logs_level => 'trace' },
                sub { EV::break });
        },
        on_error => sub { EV::break },
    );
    run_with_bail(5);
    ok $fired > 0, 'on_log fired (guard actually exercised)';
    $ch->finish;
}

# 13. Pool::hedged_query with circuit_threshold: queries route around
# a tripped member and per-query oqc override fires for cancelled queries.
{
    my $pool = EV::ClickHouse::Pool->new(
        host => $host, port => $nport, protocol => 'native', size => 2,
        circuit_threshold => 2, circuit_cooldown => 1,
    );
    my $ok = 0;
    $pool->hedged_query("select 11", hedge => 2, sub {
        my ($r, $e) = @_;
        $ok = 1 if !$e && $r && $r->[0][0] == 11;
        EV::break;
    });
    run_with_bail(5);
    ok $ok, 'hedged_query with circuit breaker resolves successfully';
    $pool->finish;
}

# 14. Drop the last $ch reference from inside a query callback and
# trigger DESTROY mid-callback. The new DESTROY second watcher-stop
# pass must catch the watchers that cancel_pending's user error
# callback re-armed via reset().
{
    my $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_error => sub { EV::break },
    );
    # First, fully connect.
    my $ready = 0;
    $ch->on_connect(sub { $ready = 1; EV::break });
    run_with_bail(3);
    ok $ready, 'connected before UAF test';

    # Now: queue a query, drop our ref inside its on_error so DESTROY
    # fires while callback_depth > 0. From inside the error callback,
    # re-arm watchers via reset() to provoke the use-after-free path.
    $ch->on_error(sub {
        eval { $ch->reset };   # re-arm io watchers on the new fd
        $ch = undef;           # last ref drop → DESTROY runs deferred
        EV::break;
    });
    $ch->query("select sleep(120)", sub { });
    $ch->cancel;               # forces cancel_pending → user error cb
    run_with_bail(2);
    ok 1, 'reset()-from-error-callback + ref-drop did not UAF';
}

# 15. Per-query on_query_complete override fires for cancelled queries
# (drain_cb_queue contract).
{
    my $oqc_fired = 0;
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub {
            # Issue a slow query with a per-query oqc that records errors.
            $ch->query("select sleep(60)",
                { on_query_complete => sub {
                    my (undef, undef, undef, undef, undef, $err) = @_;
                    $oqc_fired++ if $err;
                } },
                sub { });
            # Cancel right away — cb_queue is drained with errmsg, oqc must fire.
            $ch->cancel;
            EV::timer(0.3, 0, sub { EV::break });
        },
    );
    run_with_bail(2);
    ok $oqc_fired, 'per-query on_query_complete fires when cancelled';
    $ch->finish;
}

# 16. insert() with per-query on_query_complete AND another setting
# that triggers a settings_copy (regression: insert XSUB used to read
# from the freed settings_copy when extracting on_query_complete).
{
    my $tbl = "ev_ch_oqc_ins_$$";
    my $oqc = 0; my $err;
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub {
            $ch->query("create table $tbl (n UInt32) engine=Memory", sub {
                $ch->insert($tbl, [[1]],
                    { idempotent => 1,             # forces settings_copy path
                      on_query_complete => sub { $oqc++ } },
                    sub {
                        my (undef, $e) = @_; $err = $e;
                        $ch->query("drop table $tbl", sub { EV::break });
                    });
            });
        },
        on_error => sub { $err = $_[0]; EV::break },
    );
    run_with_bail(5);
    ok !$err, 'insert with on_query_complete+idempotent did not UAF' or diag $err;
    ok $oqc > 0, 'per-query on_query_complete fired';
    $ch->finish;
}

# 17. track_query_durations resize-down preserves newest samples.
{
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub { EV::break },
    );
    run_with_bail(3);
    $ch->track_query_durations(4);
    # Push 5 queries; with size=4 the buffer wraps once. After the wrap,
    # the newest 4 should be the last 4 we measured.
    my $left = 5;
    for (1 .. 5) {
        $ch->query("select 1", sub { EV::break if !--$left });
    }
    run_with_bail(5);
    is $ch->query_duration_count, 4, 'ring captured 4 samples (size 4, 5 pushed)';
    # Resize down to 2 — should keep the 2 newest, NOT the 2 oldest.
    $ch->track_query_durations(2);
    is $ch->query_duration_count, 2, 'resize-down kept 2 samples';
    # We don't know exact durations but they should sort cleanly.
    my $p50 = $ch->query_duration_p(0.5);
    ok defined $p50 && $p50 >= 0, 'p50 after resize is well-formed';
    $ch->track_query_durations(0);
    $ch->finish;
}

# 18. retry: succeeds on first try when no error; ignores non-retryable.
{
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub { EV::break },
    );
    run_with_bail(3);
    my ($rows, $err);
    $ch->retry("select 99", retries => 2, backoff => 0.05, cb => sub {
        ($rows, $err) = @_; EV::break;
    });
    run_with_bail(3);
    ok !$err && $rows && $rows->[0][0] == 99, 'retry returns rows on success';

    # Non-retryable error: bad table; should NOT retry.
    my $non_retry_err;
    $ch->retry("select * from nonexistent_table_xyz",
        retries => 5, backoff => 0.05, cb => sub {
        (undef, $non_retry_err) = @_; EV::break;
    });
    run_with_bail(3);
    ok defined($non_retry_err),
       'retry surfaces non-retryable error without infinite loop';
    $ch->finish;
}

# 19. Pool::fan_out gathers per-member results.
{
    my $pool = EV::ClickHouse::Pool->new(
        host => $host, port => $nport, protocol => 'native', size => 3,
    );
    my $out;
    $pool->fan_out("select 1, hostName()", sub { $out = $_[0]; EV::break });
    run_with_bail(5);
    is scalar @$out, 3,                'fan_out returns one entry per member';
    is_deeply [ map { $_->{member} } @$out ], [0, 1, 2],
                                       'fan_out indexes are 0..size-1';
    ok !grep({ $_->{err} } @$out),     'no per-member errors';
    ok !grep({ !$_->{rows} || @{$_->{rows}} != 1 || $_->{rows}[0][0] != 1 } @$out),
       'every member returned [[1, hostname]]';
    $pool->finish;
}

# 20. ping_round_trip reports a positive latency.
{
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub { EV::break },
    );
    run_with_bail(3);
    my ($rtt, $err);
    $ch->ping_round_trip(sub { ($rtt, $err) = @_; EV::break });
    run_with_bail(3);
    ok !$err && defined($rtt) && $rtt > 0,
       "ping_round_trip returned a positive latency"
       or diag "rtt=" . ($rtt // 'undef') . " err=" . ($err // '');
    $ch->finish;
}

# 21. Pool::with_session pins a member while the cb holds the release.
{
    my $pool = EV::ClickHouse::Pool->new(
        host => $host, port => $nport, protocol => 'native', size => 3,
    );
    my $pinned_id;
    my $other_id;
    $pool->with_session(sub {
        my ($pinned, $release) = @_;
        $pinned_id = "$pinned";
        # Inside the pin: a normal $pool->query should land on a different
        # member (the pinned one is excluded by _pick).
        $pool->query("select 1", sub {
            EV::break;
        });
        # Hold the release until after the EV::break above.
        EV::timer(0.5, 0, sub { $release->() });
    });
    run_with_bail(3);
    # Inspect which connection $pool just used (last_query_id is per-conn
    # but unset here; instead infer via _pick a second time after release).
    ok defined($pinned_id),     'with_session received a connection';
    $pool->finish;
}

# 22. server_setting + row_count + table_size + ddl + dictionary_reload
#     (just the parse_uri class method is also exercised here).
{
    my $p = EV::ClickHouse->parse_uri(
        'clickhouse+native://u:p@host.example:9000/mydb?max_threads=4');
    is $p->{protocol}, 'native',                     'parse_uri: protocol';
    is $p->{host},     'host.example',               'parse_uri: host';
    is $p->{port},     9000,                         'parse_uri: port';
    is $p->{user},     'u',                          'parse_uri: user';
    is $p->{password}, 'p',                          'parse_uri: password';
    is $p->{database}, 'mydb',                       'parse_uri: database';
    is $p->{max_threads}, '4',                       'parse_uri: query-string flattened';
    is(EV::ClickHouse->parse_uri('not-a-uri'), undef, 'parse_uri rejects garbage');

    # Protocol-from-QS: when scheme is bare `clickhouse://` (no +variant),
    # `?protocol=native` should still set protocol. Default to http otherwise.
    my $p2 = EV::ClickHouse->parse_uri('clickhouse://h/?protocol=native');
    is $p2->{protocol}, 'native', 'parse_uri: protocol from QS when scheme is bare';
    my $p3 = EV::ClickHouse->parse_uri('clickhouse://h/');
    is $p3->{protocol}, 'http',   'parse_uri: default protocol is http';

    # Bare flag in QS resolves to truthy 1.
    my $p4 = EV::ClickHouse->parse_uri('clickhouse://h/?compress');
    is $p4->{compress}, 1,         'parse_uri: bare QS flag becomes 1';
}

{
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub {
            $ch->server_setting('max_threads', sub {
                my ($v) = @_;
                ok defined($v),       'server_setting returns a value';
                # Spin up an ephemeral table — relying on system.numbers
                # with a predicate is brittle across CH versions
                # (some don't early-terminate without an explicit LIMIT).
                my $tbl = "ev_ch_rc_$$";
                $ch->ddl("create table $tbl (n UInt32) engine=Memory", sub {
                  $ch->insert($tbl, [ map [$_], 1..50 ], sub {
                    $ch->row_count($tbl, 'n > 25', sub {
                      my ($n) = @_;
                      is $n, 25,    'row_count with WHERE returns expected count';
                      $ch->table_size('system.parts', sub {
                        my ($s) = @_;
                        is ref($s), 'HASH',            'table_size returns hashref';
                        ok exists $s->{bytes_on_disk}, 'table_size has bytes_on_disk';
                        $ch->ddl("select 1", sub {
                          my (undef, $e) = @_;
                          ok !$e,                       'ddl helper accepts a select';
                          $ch->ddl("drop table $tbl", sub { EV::break });
                        });
                      });
                    });
                  });
                });
            });
        },
        on_error => sub { EV::break },
    );
    run_with_bail(5);
    $ch->finish;
}

# 23. slow_query_log fires for slow queries, skips fast ones.
{
    my @slow;
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub {
            $ch->slow_query_log(0.05, sub {
                my (undef, undef, undef, undef, $dur) = @_;
                push @slow, $dur;
            });
            $ch->query("select 1", sub {            # fast — should be filtered
                $ch->query("select sleep(0.2)", sub {
                    EV::break;
                });
            });
        },
        on_error => sub { EV::break },
    );
    run_with_bail(5);
    is scalar @slow, 1,                'slow_query_log filtered out the fast query';
    ok $slow[0] >= 0.05,               'recorded duration exceeds threshold';
    $ch->finish;
}

# 24. with_session: a Pool with 2 members; pinning member A means a
# concurrent $pool->query MUST land on member B.
{
    my $pool = EV::ClickHouse::Pool->new(
        host => $host, port => $nport, protocol => 'native', size => 2,
    );
    # Warm both members first.
    my $warm = 0;
    $pool->with_each(sub {
        $_[0]->query("select 1", sub { EV::break if ++$warm == 2 });
    });
    run_with_bail(3);

    my $pinned_id; my $other_id;
    $pool->with_session(sub {
        my ($pinned, $release) = @_;
        $pinned_id = $pinned->last_query_id // '';
        # Issue via $pool->query — should pick the OTHER member.
        $pool->query("select 99", { query_id => 'with-sess-probe' }, sub {
            for my $c ($pool->conns) {
                $other_id = $c->last_query_id // ''
                    if "$c" ne "$pinned" && ($c->last_query_id // '') eq 'with-sess-probe';
            }
            $release->();
            EV::break;
        });
    });
    run_with_bail(3);
    is $other_id, 'with-sess-probe',
       'with_session: concurrent $pool->query routed to the OTHER member';
    $pool->finish;
}

# 25. retry does NOT loop on QUERY_WAS_CANCELLED (code 394).
# Use the in-process pattern: long sleep + cancel via timer.
{
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub { EV::break },
    );
    run_with_bail(3);

    my $attempts = 0;
    # Hook on_query_start to count attempts cheaply.
    $ch->on_query_start(sub { $attempts++ });

    my $err;
    $ch->retry("select sleep(3)", retries => 3, backoff => 0.05, cb => sub {
        (undef, $err) = @_;
        EV::break;
    });
    # Fire cancel shortly after dispatch.
    my $kick = EV::timer(0.2, 0, sub { $ch->cancel });
    run_with_bail(5);
    undef $kick;
    is $attempts, 1,
       'retry stopped after 1 attempt on QUERY_WAS_CANCELLED (no looping)';
    $ch->finish;
}

# 26. fan_out tolerates a "dead" member (circuit open) — short-circuits
# it without trying to dispatch, returns an err string in its slot.
{
    my $pool = EV::ClickHouse::Pool->new(
        host => $host, port => $nport, protocol => 'native', size => 2,
        circuit_threshold => 1, circuit_cooldown => 60,
    );
    # Directly trip the breaker on member 1.
    $pool->{cb_state}[1]{fails}      = 99;
    $pool->{cb_state}[1]{dead_until} = EV::time() + 30;

    my $out;
    $pool->fan_out("select 42", sub { $out = $_[0]; EV::break });
    run_with_bail(3);
    is scalar @$out, 2,                       'fan_out returned an entry per member';
    ok defined($out->[0]{rows}) && $out->[0]{rows}[0][0] == 42,
                                              'live member 0 returned the row';
    like $out->[1]{err}, qr/circuit open/,    'dead member 1 reported circuit-open error';
    $pool->finish;
}

# 27. Streamer::reset delivers pending finish/drain callbacks with an
# error instead of silently dropping them.
{
    my $reset_err; my $drain_err;
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub {
            $ch->query("create table ev_ch_rst_$$ (n UInt32) engine=Memory", sub {
                my $s = $ch->insert_streamer("ev_ch_rst_$$", batch_size => 1_000);
                # Register an await_drain waiter while the buffer is empty
                # but in_flight - actually just push enough to be in flight,
                # then register finish + drain, then reset before they fire.
                $s->push_row([$_]) for 1 .. 10;
                $s->await_drain(sub { $drain_err = $_[0] });
                $s->finish(sub { $reset_err = $_[1] });
                $s->reset;          # must flush both callbacks with an error
                $ch->query("drop table ev_ch_rst_$$", sub { EV::break });
            });
        },
        on_error => sub { EV::break },
    );
    run_with_bail(5);
    is $reset_err, 'streamer reset', 'Streamer::reset delivers pending finish cb';
    is $drain_err, 'streamer reset', 'Streamer::reset delivers pending await_drain cb';
    $ch->finish;
}

# 28. Pool::shutdown two-arg form: $pool->shutdown($cb) must still call
# the callback (was silently dropped when $grace captured the coderef).
{
    my $pool = EV::ClickHouse::Pool->new(
        host => $host, port => $nport, protocol => 'native', size => 2,
    );
    my $warm = 0;
    $pool->with_each(sub { $_[0]->query("select 1", sub { EV::break if ++$warm == 2 }) });
    run_with_bail(3);

    my $shutdown_fired = 0;
    $pool->shutdown(sub { $shutdown_fired = 1; EV::break });
    run_with_bail(3);
    ok $shutdown_fired, 'Pool::shutdown($cb) two-arg form invokes the callback';
}

# 29. retry() on a finished connection: query() croaks "not connected"
# synchronously; the eval-guard must route that to $cb instead of
# letting it escape into the event loop.
{
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub { EV::break },
    );
    run_with_bail(3);
    $ch->finish;                         # tear the connection down

    my $err = 'unset';
    eval {
        $ch->retry("select 1", retries => 2, backoff => 0.01, cb => sub {
            (undef, $err) = @_;
        });
        1;
    } or $err = "ESCAPED: $@";
    ok defined($err) && $err ne 'unset' && $err !~ /^ESCAPED/,
       'retry on dead connection routes the croak to cb (no loop escape)';
}

# 30. insert_iter with high_water => 0 (backpressure disabled) must not
# deadlock — the pump's watermark gate has to treat 0 as "no gate"
# rather than ">= 0 is always true".
{
    my $tbl = "ev_ch_ii_hw0_$$";
    my $err; my $count;
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub {
            $ch->query("create table $tbl (n UInt32) engine=Memory", sub {
                my (undef, $e) = @_;
                $err = $e and return EV::break;
                my $n = 0;
                $ch->insert_iter($tbl,
                    sub { $n < 2_000 ? [$n++] : undef },   # producer
                    sub {                                  # done cb
                        (undef, $err) = @_;
                        $ch->query("select count() from $tbl", sub {
                            my ($r, $e) = @_;
                            $err //= $e;
                            $count = $r ? $r->[0][0] : undef;
                            $ch->query("drop table $tbl", sub { EV::break });
                        });
                    },
                    high_water => 0,                       # disable backpressure
                );
            });
        },
        on_error => sub { $err = $_[0]; EV::break },
    );
    run_with_bail(8);
    ok !$err, 'insert_iter high_water=>0 completed without error' or diag $err;
    is $count, 2_000, 'insert_iter high_water=>0 inserted all rows (no deadlock)';
    $ch->finish;
}

# 31. insert_streamer low_water => 0 must be honoured (was clobbered to
# high_water/2 by a `||` that treated 0 as unset).
{
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub { EV::break },
    );
    run_with_bail(3);
    my $s0 = $ch->insert_streamer("ev_ch_lw_$$",
        high_water => 4_000, low_water => 0);
    is $s0->{low_water}, 0,
       'insert_streamer: explicit low_water => 0 is preserved';
    my $s1 = $ch->insert_streamer("ev_ch_lw_$$", high_water => 4_000);
    is $s1->{low_water}, 2_000,
       'insert_streamer: low_water defaults to high_water/2 when omitted';
    $ch->finish;
}

# 32. on_trace calling finish() mid-dispatch must not use-after-free the
# send-queue entry. Before the fix, pipeline_advance kept a pointer to a
# send struct that cancel_pending (via finish) released to the freelist,
# then Copy()'d from it. Reaching the assertion = no crash.
{
    my $survived = 0;
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_trace => sub {
            # Fires "dispatch query (pending=N)" right as the query is
            # about to be written — tear the connection down from inside.
            $ch->finish if $_[0] =~ /dispatch query/;
        },
        on_connect => sub {
            $ch->query("select 1", sub { });   # cb may never fire (finished)
        },
        on_error => sub { },
    );
    my $bail = EV::timer(3, 0, sub { $survived = 1; EV::break });
    EV::run; undef $bail;
    ok $survived, 'on_trace calling finish() mid-dispatch does not crash';
}

# 33. on_disconnect dropping the last $ch ref must not use-after-free.
# cleanup_connection fires on_disconnect; if the handler frees $ch
# (DESTROY), every caller that touched self afterward was a UAF.
# Driven via a query_timeout: timer_cb -> teardown_after_deliver ->
# cleanup_connection -> on_disconnect. Reaching the assertion = no crash.
{
    my $survived = 0;
    {
        my $ch;
        $ch = EV::ClickHouse->new(
            host => $host, port => $nport, protocol => 'native',
            on_disconnect => sub { undef $ch },   # drop the last ref
            on_connect => sub {
                # Times out at 0.5s; the timeout teardown path runs
                # cleanup_connection -> on_disconnect -> undef $ch.
                $ch->query("select sleep(3)",
                           { query_timeout => 0.5 }, sub { });
            },
            on_error => sub { },
        );
    }
    my $bail = EV::timer(5, 0, sub { $survived = 1; EV::break });
    EV::run; undef $bail;
    ok $survived, 'on_disconnect freeing $ch during timeout does not crash';
}

# 34. The drain callback's CV may hold the last $ch reference. When
# pipeline_advance drops that CV (SvREFCNT_dec) after firing the drain,
# the closure frees -> $ch DESTROY -> Safefree(self); pipeline_advance
# must not then touch freed self. Reaching the assertion = no crash.
{
    my $survived = 0;
    {
        my $ch;
        $ch = EV::ClickHouse->new(
            host => $host, port => $nport, protocol => 'native',
            on_connect => sub {
                $ch->query("select 1", sub { });
                # on_drain closure captures $ch; once we undef our own
                # copy below, the CV is the sole owner of the object.
                $ch->drain(sub { my $r = $ch->server_revision; EV::break });
                undef $ch;   # drop our ref — only the drain CV holds it now
            },
            on_error => sub { },
        );
    }
    my $bail = EV::timer(5, 0, sub { EV::break });
    EV::run; undef $bail;
    $survived = 1;
    ok $survived, 'drain CV holding last $ch ref does not crash pipeline_advance';
}

# 35. on_log handler freeing $ch mid log-block must not use-after-free.
# parse_and_emit_log_block pins the cb, fires it per row; if the handler
# drops the last $ch ref, DESTROY runs and the post-loop teardown +
# return-code path must finalize cleanly. Reaching the assertion = no crash.
{
    my $survived = 0;
    {
        my $ch;
        $ch = EV::ClickHouse->new(
            host => $host, port => $nport, protocol => 'native',
            on_log => sub { undef $ch },   # free $ch from inside the log cb
            on_connect => sub {
                $ch->query("select sleep(0.01)",
                           { send_logs_level => 'trace' }, sub { });
            },
            on_error => sub { },
        );
    }
    my $bail = EV::timer(5, 0, sub { EV::break });
    EV::run; undef $bail;
    $survived = 1;
    ok $survived, 'on_log freeing $ch mid-block does not crash';
}

# 36. wait_mutation: run an ALTER ... UPDATE on a MergeTree table, then
# wait_mutation until it completes; verify the update actually applied.
{
    my $tbl = "ev_ch_mut_$$";
    my $err; my $val_after;
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub {
            $ch->query(
                "create table $tbl (id UInt32, tag String) "
              . "engine=MergeTree order by id", sub {
                my (undef, $e) = @_;
                $err = $e and return EV::break;
                $ch->insert($tbl, [[1,'old'],[2,'old']], sub {
                    my (undef, $e) = @_;
                    $err = $e and return EV::break;
                    $ch->query(
                        "alter table $tbl update tag = 'new' where id = 1",
                        sub {
                        my (undef, $e) = @_;
                        $err = $e and return EV::break;
                        $ch->wait_mutation($tbl, sub {
                            my ($info, $e) = @_;
                            $err = $e and return EV::break;
                            $ch->query(
                                "select tag from $tbl where id = 1",
                                sub {
                                my ($r, $e) = @_;
                                $err //= $e;
                                $val_after = $r ? $r->[0][0] : undef;
                                $ch->query("drop table $tbl",
                                           sub { EV::break });
                            });
                        }, poll => 0.2, timeout => 20);
                    });
                });
            });
        },
        on_error => sub { $err = $_[0]; EV::break },
    );
    run_with_bail(25);
    ok !$err, 'wait_mutation completed without error' or diag $err;
    is $val_after, 'new', 'wait_mutation: ALTER UPDATE was applied before cb fired';
    $ch->finish;
}

# 37. wait_mutation on a table with no mutations resolves immediately.
{
    my $tbl = "ev_ch_nomut_$$";
    my $err; my $info;
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub {
            $ch->query("create table $tbl (n UInt32) engine=MergeTree order by n",
                sub {
                my (undef, $e) = @_;
                $err = $e and return EV::break;
                $ch->wait_mutation($tbl, sub {
                    ($info, $err) = @_;
                    $ch->query("drop table $tbl", sub { EV::break });
                });
            });
        },
        on_error => sub { $err = $_[0]; EV::break },
    );
    run_with_bail(8);
    ok !$err, 'wait_mutation no-mutations: no error';
    is ref($info), 'HASH', 'wait_mutation no-mutations: resolves with info hashref';
    $ch->finish;
}

# 38. wait_mutation surfaces a persistently failing mutation. A mutation
# whose UPDATE expression always throws never reaches is_done=1 and keeps
# a latest_fail_reason; wait_mutation reports it once it persists.
{
    my $tbl = "ev_ch_mutfail_$$";
    my $err; my $info;
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub {
            $ch->query("create table $tbl (id UInt32, n UInt32) "
                     . "engine=MergeTree order by id", sub {
                my (undef, $e) = @_; $err = $e and return EV::break;
                $ch->insert($tbl, [[1,1],[2,2]], sub {
                    my (undef, $e) = @_; $err = $e and return EV::break;
                    $ch->query("alter table $tbl update n = "
                             . "throwIf(1, 'mutation boom') where 1", sub {
                        my (undef, $e) = @_; $err = $e and return EV::break;
                        $ch->wait_mutation($tbl, sub {
                            ($info, $err) = @_;
                            $ch->query("drop table $tbl", sub { EV::break });
                        }, poll => 0.2, timeout => 25);
                    });
                });
            });
        },
        on_error => sub { $err = $_[0]; EV::break },
    );
    run_with_bail(30);
    # Match the throwIf message specifically: a bare /wait_mutation:/ would
    # also match the timeout fallback, letting the test pass without
    # actually exercising fail-streak detection.
    ok defined($err) && $err =~ /mutation boom/,
       'wait_mutation reports a persistently failing mutation'
       or diag "err=" . ($err // 'undef');
    $ch->finish;
}

# 39. wait_mutation timeout fires when a mutation stays incomplete.
# A throwIf mutation never completes, so timeout => 0 trips on the
# first poll that still sees it pending.
{
    my $tbl = "ev_ch_muttmo_$$";
    my $err;
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub {
            $ch->query("create table $tbl (id UInt32, n UInt32) "
                     . "engine=MergeTree order by id", sub {
                my (undef, $e) = @_; $err = $e and return EV::break;
                $ch->insert($tbl, [[1,1]], sub {
                    my (undef, $e) = @_; $err = $e and return EV::break;
                    $ch->query("alter table $tbl update n = throwIf(1) "
                             . "where 1", sub {
                        my (undef, $e) = @_; $err = $e and return EV::break;
                        $ch->wait_mutation($tbl, sub {
                            (undef, $err) = @_;
                            $ch->query("drop table $tbl", sub { EV::break });
                        }, poll => 1, timeout => 0);
                    });
                });
            });
        },
        on_error => sub { $err = $_[0]; EV::break },
    );
    run_with_bail(12);
    ok defined($err) && $err =~ /timed out/, 'wait_mutation timeout fires'
       or diag "err=" . ($err // 'undef');
    $ch->finish;
}

# 40. wait_mutation with a mutation_id that matches nothing resolves
# immediately — exercises the mutation_id filter clause.
{
    my $tbl = "ev_ch_mutid_$$";
    my $err; my $info;
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub {
            $ch->query("create table $tbl (n UInt32) engine=MergeTree order by n",
                sub {
                my (undef, $e) = @_; $err = $e and return EV::break;
                $ch->wait_mutation($tbl, sub {
                    ($info, $err) = @_;
                    $ch->query("drop table $tbl", sub { EV::break });
                }, mutation_id => 'no-such-mutation-0000');
            });
        },
        on_error => sub { $err = $_[0]; EV::break },
    );
    run_with_bail(8);
    ok !$err, 'wait_mutation mutation_id filter: no error';
    is ref($info), 'HASH',
       'wait_mutation mutation_id filter resolves when nothing matches';
    $ch->finish;
}
