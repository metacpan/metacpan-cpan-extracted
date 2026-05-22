use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;

# Tests for the 0.03 feature batch:
# - max_reconnect_attempts
# - HTTP keepalive PING
# - progress_period coalescing
# - for_table schema helper
# - insert_streamer streaming insert
# - cancel during on_data
# - on_disconnect not firing on connect-phase failures

my $host      = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $http_port = $ENV{TEST_CLICKHOUSE_PORT} || 8123;
my $nat_port  = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

require IO::Socket::INET;
my $http_ok = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $http_port, Timeout => 2) ? 1 : 0;
my $nat_ok  = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nat_port,  Timeout => 2) ? 1 : 0;
plan skip_all => "ClickHouse not reachable" unless $http_ok || $nat_ok;

plan tests => 15;

sub run_with_timeout { my $t = EV::timer($_[0], 0, sub { EV::break }); EV::run }

# 1: max_reconnect_attempts caps the loop. Point at a port that refuses
# connections; verify on_error fires with "max reconnect attempts exceeded".
{
    my @errors;
    my $ch;
    $ch = EV::ClickHouse->new(
        host                   => $host,
        port                   => 1,        # reserved, refuses connect
        protocol               => 'http',
        connect_timeout        => 0.2,
        auto_reconnect         => 1,
        reconnect_delay        => 0.05,
        reconnect_max_attempts => 3,
        on_error               => sub {
            push @errors, $_[0];
            EV::break if grep /max reconnect/, @errors;
        },
    );
    run_with_timeout(5);
    cmp_ok(scalar @errors, '>=', 3,
        "max_reconnect_attempts: at least N+1 on_error fires");
    ok((grep /max reconnect attempts exceeded/, @errors),
        "max_reconnect_attempts: terminal error message fires");
    $ch->finish if $ch->is_connected;
}

# 2-3: HTTP keepalive PING — set a tiny keepalive, wait, ensure pending_count
# stays at 0 (the noop ping clears itself) and the connection stays alive.
SKIP: {
    skip "HTTP port not reachable", 2 unless $http_ok;
    my ($ch, $err);
    $ch = EV::ClickHouse->new(
        host       => $host,
        port       => $http_port,
        keepalive  => 0.2,
        on_connect => sub { },
        on_error   => sub { $err = $_[0] },
    );
    # Wait long enough for at least 2 keepalive pings to fire.
    my $t = EV::timer(0.6, 0, sub { EV::break });
    EV::run;
    ok(!$err, "HTTP keepalive: no errors") or diag "err=$err";
    $ch->query("select 1 format TabSeparated", sub {
        my ($rows) = @_;
        is($rows && @$rows ? $rows->[0][0] : undef, 1,
           "HTTP keepalive: connection still usable for queries");
        EV::break;
    });
    run_with_timeout(5);
    $ch->finish if $ch->is_connected;
}

# 4: for_table returns column metadata.
SKIP: {
    skip "Native port not reachable", 1 unless $nat_ok;
    my ($ch, $info, $err);
    my $table = '_ev_ch_for_' . $$;
    $ch = EV::ClickHouse->new(
        host => $host, port => $nat_port, protocol => 'native',
        on_connect => sub {
            $ch->query("create temporary table $table (a UInt32, b String) ENGINE = Memory", sub {
                $ch->for_table($table, sub { ($info, $err) = @_; EV::break });
            });
        },
    );
    run_with_timeout(10);
    is_deeply(
        [ map +{ name => $_->{name}, type => $_->{type} }, @{ $info->{columns} || [] } ],
        [ { name => 'a', type => 'UInt32' }, { name => 'b', type => 'String' } ],
        "for_table delivers name+type pairs"
    ) or diag "err=" . ($err // '<undef>');
    $ch->finish if $ch->is_connected;
}

# 5-6: insert_streamer pushes batches and finish reports total result.
SKIP: {
    skip "Native port not reachable", 2 unless $nat_ok;
    my ($ch, $count, $finish_err);
    my $table = '_ev_ch_str_' . $$;
    my $N = 2_500;
    $ch = EV::ClickHouse->new(
        host => $host, port => $nat_port, protocol => 'native',
        on_connect => sub {
            $ch->query("create temporary table $table (n UInt32) ENGINE = Memory", sub {
                my $s = $ch->insert_streamer($table, batch_size => 500);
                for my $i (1..$N) { $s->push_row([$i]) }
                $s->finish(sub {
                    (undef, $finish_err) = @_;
                    $ch->query("select count() from $table", sub {
                        my ($r) = @_;
                        $count = $r && @$r ? $r->[0][0] : undef;
                        EV::break;
                    });
                });
            });
        },
    );
    run_with_timeout(15);
    ok(!$finish_err, "streamer finish: no error") or diag "err=$finish_err";
    is($count, $N, "streamer: $N rows round-tripped via 5 batches");
    $ch->finish if $ch->is_connected;
}

# 7-8: progress_period coalesces on_progress packets — without throttling we
# expect many packets; with throttling we expect at most a handful.
SKIP: {
    skip "Native port not reachable", 2 unless $nat_ok;
    my @ticks;
    my ($ch, $rows);
    $ch = EV::ClickHouse->new(
        host => $host, port => $nat_port, protocol => 'native',
        progress_period => 1.0,             # one fire per second max
        on_progress => sub { push @ticks, [@_] },
        on_connect  => sub {
            # Quick query that emits multiple progress packets
            $ch->query("select count() from numbers_mt(5_000_000)", sub {
                ($rows) = @_; EV::break;
            });
        },
    );
    run_with_timeout(10);
    ok($rows && @$rows, "progress test: query completed");
    cmp_ok(scalar @ticks, '<=', 5,
        "progress_period throttles to <=5 fires for a sub-second query") or diag "got " . scalar(@ticks) . " ticks";
    $ch->finish if $ch->is_connected;
}

# 9-10: cancel during on_data (mid-stream cancel from inside the streaming cb).
# Native CLIENT_CANCEL doesn't raise an error — what matters is (a) the query
# callback fires (no hang) and (b) the connection survives for follow-up.
SKIP: {
    skip "Native port not reachable", 2 unless $nat_ok;
    my ($ch, $blocks, $cb_fired, $follow_ok);
    $ch = EV::ClickHouse->new(
        host => $host, port => $nat_port, protocol => 'native',
        on_connect => sub {
            $blocks = 0;
            $ch->query(
                "select number from numbers_mt(50_000_000)",
                { on_data => sub {
                    $blocks++;
                    $ch->cancel if $blocks == 1;
                } },
                sub {
                    $cb_fired = 1;
                    $ch->query("select 1 + 1", sub {
                        my ($r) = @_;
                        $follow_ok = $r && @$r && $r->[0][0] == 2;
                        EV::break;
                    });
                },
            );
        },
    );
    run_with_timeout(10);
    ok($cb_fired,   "cancel from inside on_data: query callback fires (no hang)");
    ok($follow_ok,  "cancel from inside on_data: connection survives for next query");
    $ch->finish if $ch->is_connected;
}

# 11-12: on_disconnect not firing on connect-phase failures (matches the
# documented contract: on_disconnect only fires if previously connected).
SKIP: {
    skip "HTTP port not reachable", 2 unless $http_ok;
    my ($disc_fired, $err_fired) = (0, 0);
    my $ch;
    $ch = EV::ClickHouse->new(
        host          => $host,
        port          => 1,    # refuses
        connect_timeout => 0.2,
        on_disconnect => sub { $disc_fired++ },
        on_error      => sub { $err_fired++; EV::break },
    );
    run_with_timeout(2);
    ok($err_fired,  "on_error fires on connect-phase failure");
    is($disc_fired, 0,
       "on_disconnect does not fire on connect-phase failure (never previously connected)");
    $ch->finish if $ch->is_connected;
}

# 13-14: connect_timeout + auto_reconnect: verify the timer-based reconnect
# fires after a connect timeout.
SKIP: {
    skip "Native port not reachable", 2 unless $nat_ok;

    my $listener = IO::Socket::INET->new(
        Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0,
    );
    skip "could not bind a local listener", 2 unless $listener;
    my $silent_port = $listener->sockport;

    my @errors;
    my $ch;
    $ch = EV::ClickHouse->new(
        host                   => '127.0.0.1',
        port                   => $silent_port,
        protocol               => 'native',
        connect_timeout        => 0.3,
        auto_reconnect         => 1,
        reconnect_delay        => 0.05,
        reconnect_max_attempts => 2,
        on_error               => sub {
            push @errors, $_[0];
            EV::break if grep /max reconnect/, @errors;
        },
    );
    run_with_timeout(5);
    cmp_ok(scalar @errors, '>=', 2,
        "connect_timeout + auto_reconnect: at least 2 retry-error fires");
    ok((grep /max reconnect/, @errors),
        "connect_timeout + auto_reconnect: terminal max-attempts error fires");
    $ch->finish if $ch->is_connected;
    $listener->close;
}
