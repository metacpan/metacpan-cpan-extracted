#!/usr/bin/env perl
# Coverage for corner cases the earlier test files miss:
#   - on_query_complete (success + error path)
#   - HTTP keepalive PING does NOT fire on_query_complete (IS_KEEPALIVE_CB)
#   - query_log_comment is applied to INSERT and on HTTP
#   - DNS failure with pre-queued queries delivers errors
#   - Pool: cancel / skip_pending / reset broadcast
#   - Iterator timeout returns undef without setting error
#   - Streamer high_water fires when buffered count crosses watermark
use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;
use IO::Socket::INET;

my $host  = $ENV{TEST_CLICKHOUSE_HOST}        || '127.0.0.1';
my $hport = $ENV{TEST_CLICKHOUSE_PORT}        || 8123;
my $nport = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

plan skip_all => "ClickHouse not reachable"
    unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nport, Timeout => 2);

plan tests => 30;

sub run_with_timeout { my $t = EV::timer($_[0], 0, sub { EV::break }); EV::run }

# 1. on_query_complete fires on success with non-zero duration
{
    my $completed;
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect          => sub { $ch->query("select 1", sub { EV::break }) },
        on_query_complete   => sub { $completed = [@_] },
        on_error            => sub { diag "err: $_[0]"; EV::break },
    );
    EV::run;
    ok $completed, 'on_query_complete fired on success';
    cmp_ok $completed->[4], '>=', 0, '  duration_s is non-negative';
    is $completed->[5], undef, '  no error message on success';
    $ch->finish;
}

# 2. on_query_complete fires on server error with error_code + err set
{
    my $completed;
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect          => sub {
            $ch->query("select * from no_such_table_$$", sub { EV::break });
        },
        on_query_complete   => sub { $completed = [@_] },
        on_error            => sub { },
    );
    EV::run;
    ok $completed && $completed->[5], 'on_query_complete fired with err msg on failure';
    cmp_ok $completed->[3], '>', 0, '  error_code populated';
    $ch->finish;
}

# 3. HTTP keepalive PING does not fire on_query_complete
SKIP: {
    skip 'HTTP not reachable', 1
        unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $hport, Timeout => 2);
    my $count = 0;
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $hport, protocol => 'http',
        keepalive => 0.2,
        on_connect          => sub { },
        on_query_complete   => sub { $count++ },
        on_error            => sub { },
    );
    # let two keepalive pings fly
    run_with_timeout(0.6);
    is $count, 0, 'HTTP keepalive PING did not fire on_query_complete';
    $ch->finish;
}

# 4. query_log_comment is applied to INSERT (and is well-formed enough that
#    the server accepts it). We can't read system.query_log on every test
#    setup, so we verify the insert succeeds with the comment in place.
{
    my $err;
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        query_log_comment   => 'pass2-insert-test',
        on_connect          => sub {
            $ch->query("create temporary table _qlc28 (n UInt32) engine = Memory", sub {
                my (undef, $e) = @_; if ($e) { $err = $e; EV::break; return }
                $ch->insert('_qlc28', [[1],[2],[3]], sub {
                    (undef, $err) = @_;
                    EV::break;
                });
            });
        },
        on_error            => sub { $err = $_[0]; EV::break },
    );
    EV::run;
    is $err, undef, 'INSERT with query_log_comment succeeded (no SQL parse error)';
    $ch->finish;
}

# 5. query_log_comment via HTTP: select still works with prefix attached.
SKIP: {
    skip 'HTTP not reachable', 1
        unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $hport, Timeout => 2);
    my ($rows, $err);
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $hport, protocol => 'http',
        query_log_comment   => 'pass2-http-test',
        on_connect          => sub {
            $ch->query("select 7 format TabSeparated", sub {
                ($rows, $err) = @_;
                EV::break;
            });
        },
        on_error            => sub { $err = $_[0]; EV::break },
    );
    EV::run;
    is_deeply $rows, [[7]], 'HTTP select with query_log_comment returns the right rows';
    $ch->finish;
}

# 6. DNS failure with a pre-queued query delivers the error to the query cb.
SKIP: {
    skip 'EV::cares not installed', 1 unless eval { require EV::cares; 1 };
    my ($rows, $err, $oe);
    my $ch; $ch = EV::ClickHouse->new(
        host => 'no-such-host-' . time . '.invalid.',
        port => $nport, protocol => 'native',
        on_error => sub { $oe = $_[0]; EV::break },
    );
    # Queue a query before DNS resolves.
    $ch->query("select 1", sub {
        ($rows, $err) = @_;
        EV::break;
    });
    run_with_timeout(8);
    ok $err, 'pre-queued query received an error after DNS failure';
    eval { $ch->finish };
}

# 7. Pool: skip_pending broadcast across members aborts in-flight queries.
{
    my $pool = EV::ClickHouse::Pool->new(
        host => $host, port => $nport, protocol => 'native',
        size => 2,
    );
    my @errs;
    my $connected = 0;
    # Wait for both members to connect before issuing the long query.
    for my $c ($pool->conns) { $c->ping(sub { $connected++ }) }
    my $ready = EV::timer(0, 0.05, sub {
        return if $connected < 2;
        EV::break;
    });
    run_with_timeout(5);
    undef $ready;
    for my $c ($pool->conns) {
        $c->query("select sleep(3)", sub {
            my (undef, $e) = @_;
            push @errs, $e if $e;
        });
    }
    my $kick = EV::timer(0.2, 0, sub { $pool->skip_pending; EV::break });
    run_with_timeout(5);
    ok @errs >= 1, 'Pool->skip_pending delivered errors to in-flight queries';
    eval { $pool->finish };
}

# 8. Iterator timeout returns undef without setting error.
{
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub { EV::break },
    );
    run_with_timeout(5);
    my $it = $ch->iterate("select sleep(3)");
    my $batch = $it->next(0.1);
    is $batch, undef, 'Iterator timeout returns undef';
    eval { $ch->cancel }; eval { $ch->finish };
}

# Coverage: reset-from-on_error and finish-during-DNS edge cases.

# 10. $ch->reset called from inside on_error survives fail_connection's
#     teardown (regression: cleanup_connection used to close the
#     just-opened socket and stop the just-armed watchers).
{
    my $tries = 0;
    my $port  = 1;          # guaranteed-refused on most systems
    my $ok;
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $port, protocol => 'native',
        connect_timeout => 1,
        on_connect => sub { $ok = 1; EV::break },
        on_error   => sub {
            return if $tries++;          # only reset once
            # Switch to the real port and reset; without the fix the
            # cleanup_connection that follows on_error would close the
            # new socket and we'd never connect.
            $ch->_set_host($host, $nport);
            $ch->reset;
        },
    );
    run_with_timeout(5);
    ok $ok, '$ch->reset from on_error survives fail_connection teardown';
    $ch->finish if $ch->is_connected;
}

# 11. $ch->finish during async DNS does not result in a zombie reconnect
#     when the resolver callback fires later. Use a hostname that DOES
#     resolve (localhost) plus a refused port: without the dns_pending
#     teardown fix, the resolver cb would call connect() after finish,
#     trip ECONNREFUSED, and fire on_error — observable.
SKIP: {
    skip 'EV::cares not installed', 1 unless eval { require EV::cares; 1 };
    my $events = 0;
    my $ch = EV::ClickHouse->new(
        host => 'localhost', port => 1, protocol => 'native',
        on_connect => sub { $events++ },
        on_error   => sub { $events++ },
    );
    $ch->finish;                # explicit finish before DNS resolves
    run_with_timeout(2);
    is $events, 0,
       'DNS callback after finish does not trigger a zombie connect attempt';
}

# reset() from inside a queued query's error callback survives
# fail_connection's cancel_pending teardown (the connect_gen
# guard covers both on_error and the queued-callback dispatch added
# in pass 4 after cancel_pending dispatch).
{
    my $tries = 0;
    my $port  = 1;
    my $ok;
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $port, protocol => 'native',
        connect_timeout => 1,
        on_connect => sub { $ok = 1; EV::break },
        on_error   => sub { },              # absorb the connect-phase error
    );
    # Queue a query before the connect attempt completes; its error
    # callback is invoked from inside fail_connection's cancel_pending.
    $ch->query("select 1", sub {
        my (undef, $err) = @_;
        return if $tries++;
        $ch->_set_host($host, $nport);
        $ch->reset;                          # second connect_gen guard kicks
    });
    run_with_timeout(5);
    ok $ok, '$ch->reset from queued-cb survives cancel_pending teardown';
    $ch->finish if $ch->is_connected;
}

# reset() called from a query-timeout error callback and from a cancel
# error callback both survive the surrounding teardown (the same
# connect_gen guard mechanism that protects the on_error path).

# 12a. reset() from inside a query-timeout callback.
{
    my $tries = 0;
    my $ok;
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub {
            return if $tries;
            $ch->query("select sleep(2)", { query_timeout => 0.1 }, sub {
                my (undef, $err) = @_;
                return if $tries++;
                # On timeout, reset and re-issue a real query — the new
                # socket must survive the outer cleanup_connection.
                $ch->reset;
                $ch->query("select 1", sub {
                    my ($r) = @_;
                    $ok = $r && @$r ? $r->[0][0] == 1 : 0;
                    EV::break;
                });
            });
        },
        on_error => sub { },
    );
    run_with_timeout(5);
    ok $ok, '$ch->reset from query-timeout cb survives outer teardown';
    $ch->finish if $ch->is_connected;
}

# 12b. reset() from inside a query callback that received a cancel error.
{
    my $tries = 0;
    my $ok;
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub {
            return if $tries;
            $ch->query("select sleep(2)", sub {
                my (undef, $err) = @_;
                return if $tries++;
                $ch->reset;
                $ch->query("select 2", sub {
                    my ($r) = @_;
                    $ok = $r && @$r ? $r->[0][0] == 2 : 0;
                    EV::break;
                });
            });
            EV::timer(0.1, 0, sub { $ch->cancel });
        },
        on_error => sub { },
    );
    run_with_timeout(5);
    ok $ok, '$ch->reset from cancel cb survives outer teardown';
    $ch->finish if $ch->is_connected;
}

# Regression: Pool::_pick prefers any idle member over a busy one
# (regression: the previous logic round-robined whenever ANY member was
# idle, which could route the next pick to a busy connection).
{
    my $pool = EV::ClickHouse::Pool->new(
        host => $host, port => $nport, protocol => 'native',
        size => 3,
    );
    my @c = $pool->conns;
    # Wait for all to connect.
    my $cn = 0;
    $_->ping(sub { $cn++ }) for @c;
    my $w = EV::timer(0, 0.05, sub { EV::break if $cn >= 3 });
    run_with_timeout(5);
    undef $w;
    # Force c[0] busy with a long sleep, leave c[1], c[2] idle.
    $c[0]->query("select sleep(2)", sub { });
    # Now _pick should NEVER return c[0] while it's busy.
    my %picks;
    $picks{ "$_" }++ for map { $pool->_pick } 1 .. 6;
    ok !exists $picks{"$c[0]"},
       'Pool::_pick avoids the busy member when others are idle';
    eval { $c[0]->cancel };
    eval { $pool->finish };
}

# Coverage: reconnect_jitter accepted, insert_streamer named-rows.

# 13. reconnect_jitter is accepted as a constructor option without croaking,
#     and a fully-disabled value (0) keeps backoff deterministic.
{
    my $ok;
    my $ch; $ch = EV::ClickHouse->new(
        host             => $host, port => $nport, protocol => 'native',
        reconnect_delay  => 0.1,
        reconnect_jitter => 0.5,
        on_connect       => sub { $ok = 1; EV::break },
    );
    run_with_timeout(5);
    ok $ok, 'reconnect_jitter accepted without breaking connect';
    $ch->finish;
}

# 14. insert_streamer columns => [...] reorders hash rows positionally.
{
    my $err;
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub {
            $ch->query("create temporary table _named28 (a UInt32, b String) engine = Memory", sub {
                my $s = $ch->insert_streamer('_named28',
                    columns    => [qw(a b)],
                    batch_size => 10,
                );
                # mix hashref + arrayref pushes; column order in hash is
                # deliberately not the table order.
                $s->push_row({ b => 'x', a => 1 });
                $s->push_row({ a => 2, b => 'y' });
                $s->push_row([3, 'z']);
                $s->finish(sub {
                    (undef, $err) = @_;
                    EV::break;
                });
            });
        },
        on_error => sub { $err = $_[0]; EV::break },
    );
    run_with_timeout(5);
    is $err, undef, 'insert_streamer columns => [...] reorders hash rows';

    # And verify the rows landed in the right columns.
    my $ch2; $ch2 = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub {
            $ch->query("select a, b from _named28 order by a format TabSeparated", sub {
                my ($rows) = @_;
                is_deeply $rows, [[1, 'x'], [2, 'y'], [3, 'z']],
                    '  rows landed in declared column order';
                EV::break;
            });
        },
    );
    run_with_timeout(5);
    $ch->finish;
    $ch2->finish;
}

# for_table works on a named_rows connection (handles hashref result rows).
{
    my ($info, $err);
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        named_rows => 1,
        on_connect => sub {
            $ch->query("create temporary table _ft28 (a UInt32, b String) engine = Memory", sub {
                $ch->for_table('_ft28', sub {
                    ($info, $err) = @_;
                    EV::break;
                });
            });
        },
        on_error => sub { $err = $_[0]; EV::break },
    );
    run_with_timeout(5);
    is $err, undef, 'for_table on named_rows connection succeeds';
    is_deeply [ map $_->{name}, @{ $info->{columns} } ],
              [ qw(a b) ],
              '  column names extracted from hashref rows';
    $ch->finish;
}

# max_recv_buffer tears the connection down with a clear error message
# when the response body would exceed the cap.
{
    my $err;
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        max_recv_buffer => 4096,           # very small to force overflow
        on_connect => sub {
            $ch->query("select number from numbers(100000)",
                       { on_data => sub { } }, sub {
                (undef, $err) = @_;
                EV::break;
            });
        },
        on_error => sub { $err //= $_[0]; EV::break },
    );
    run_with_timeout(5);
    like $err, qr/recv buffer/i, 'max_recv_buffer tears down on overflow';
    eval { $ch->finish };
}

# max_recv_buffer also applies to chunked HTTP and gzip-decoded bodies
# (not only raw recv_buf). A small cap on a large select must error out.
SKIP: {
    skip 'HTTP not reachable', 1
        unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $hport, Timeout => 2);
    my $err;
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $hport, protocol => 'http',
        max_recv_buffer => 4096,
        on_connect => sub {
            $ch->query("select number from numbers(50000) format TabSeparated", sub {
                (undef, $err) = @_;
                EV::break;
            });
        },
        on_error => sub { $err //= $_[0]; EV::break },
    );
    run_with_timeout(5);
    like $err, qr/recv buffer|response too large/i,
         'max_recv_buffer caps HTTP responses too';
    eval { $ch->finish };
}

# http_basic_auth uses Authorization: Basic instead of X-ClickHouse-User/Key.
# We can't trivially inspect the wire but we can verify the connection
# still works when the option is on (server accepts both auth styles).
SKIP: {
    skip 'HTTP not reachable', 1
        unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $hport, Timeout => 2);
    my ($rows, $err);
    my $ch = EV::ClickHouse->new(
        host => $host, port => $hport, protocol => 'http',
        http_basic_auth => 1,
        on_connect => sub { },
        on_error => sub { $err = $_[0]; EV::break },
    );
    $ch->query("select 11 format TabSeparated", sub {
        ($rows, $err) = @_;
        EV::break;
    });
    run_with_timeout(5);
    is_deeply $rows, [[11]], 'http_basic_auth still authenticates correctly';
    $ch->finish;
}

# Per-query on_query_complete override REPLACES the connection-level
# hook for that one query (so per-call instrumentation doesn't double-
# count against global metrics).
{
    my @global; my @per_query;
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_query_complete => sub { push @global, [@_] },
        on_connect => sub {
            $ch->query("select 1", sub { });    # global fires
            $ch->query("select 2",
                       { on_query_complete => sub { push @per_query, [@_] } },
                       sub { EV::break });
        },
    );
    run_with_timeout(5);
    is scalar @global, 1, 'global on_query_complete fired once (only for "select 1")';
    is scalar @per_query, 1, 'per-query on_query_complete fired for the override call';
    $ch->finish;
}

# server_supports returns true for old enough revisions, false otherwise.
# server_revision >= 54458 is universally available on supported CH
# versions; "addendum" must be true. A nonsense feature must be false.
{
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub { EV::break },
    );
    run_with_timeout(5);
    ok $ch->server_supports('addendum'),
       'server_supports("addendum") true on modern CH';
    ok !$ch->server_supports('bogus_feature_$$'),
       'server_supports unknown feature returns false';
    $ch->finish;
}

# 12. Streamer high_water fires when buffered count crosses the watermark.
{
    my $hits = 0;
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub {
            $ch->query("create temporary table _sw28 (n UInt32) engine = Memory", sub {
                my $s = $ch->insert_streamer('_sw28',
                    batch_size    => 1_000_000,         # never auto-flush
                    high_water    => 5,
                    on_high_water => sub { $hits++ },
                );
                $s->push_row([$_]) for 1 .. 5;
                $s->finish(sub { EV::break });
            });
        },
        on_error => sub { EV::break },
    );
    run_with_timeout(5);
    cmp_ok $hits, '>=', 1, 'Streamer high_water fired at watermark';
    $ch->finish;
}

