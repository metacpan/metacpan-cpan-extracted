use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;

# auto_reconnect coverage:
# - basic plumbing (flag set, simple query)
# - pre-connect queue drain
# - real mid-session reconnect: HTTP keep_alive_timeout closes the server
#   side after a few idle seconds; the client must recover and dispatch the
#   next query on a fresh socket.
#
# ClickHouse native protocol has no SQL-level disconnect primitive in 26.x
# (no SYSTEM drop CONNECTION; KILL QUERY only kills queries), so a true
# native disconnect-recovery test would need a TCP proxy harness or
# tcp_close_connection_after_queries_seconds in server config — left as
# integration testing.

my $host      = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $nat_port  = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;
my $http_port = $ENV{TEST_CLICKHOUSE_PORT} || 8123;

require IO::Socket::INET;
my $nat_ok  = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nat_port,  Timeout => 2) ? 1 : 0;
my $http_ok = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $http_port, Timeout => 2) ? 1 : 0;
plan skip_all => "ClickHouse not reachable" unless $nat_ok || $http_ok;

plan tests => 7;

SKIP: {
    skip "Native port not reachable", 4 unless $nat_ok;
    my $port = $nat_port;

# 1-2: basic auto_reconnect handshake — connecting and running one query
# with the flag set must work the same as without.
{
    my $ch;
    my ($rows, $err);
    $ch = EV::ClickHouse->new(
        host                => $host,
        port                => $port,
        protocol            => 'native',
        auto_reconnect      => 1,
        reconnect_delay     => 0.1,
        reconnect_max_delay => 1,
        on_connect          => sub {
            $ch->query("select 42", sub {
                ($rows, $err) = @_;
                EV::break;
            });
        },
        on_error            => sub { diag("error: $_[0]") },
    );
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;

    ok(!$err && $rows, "auto_reconnect: simple query works")
        or diag "err=" . ($err // '<undef>');
    is($rows ? $rows->[0][0] : undef, 42, "auto_reconnect: result correct");
    $ch->finish if $ch && $ch->is_connected;
}

# 3-4: queue queries during initial connect, verify they all dispatch.
{
    my $ch;
    my @results;
    $ch = EV::ClickHouse->new(
        host                => $host,
        port                => $port,
        protocol            => 'native',
        auto_reconnect      => 1,
        on_connect          => sub {
            # connect happened — pending queue should drain on its own
        },
        on_error            => sub { diag("error: $_[0]") },
    );

    # Queue immediately, before on_connect can fire.
    for my $i (1..3) {
        $ch->query("select $i", sub {
            my ($rows, $err) = @_;
            push @results, $err ? "ERR: $err" : $rows->[0][0];
            EV::break if @results == 3;
        });
    }

    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;

    is(scalar @results, 3, "queued-pre-connect: all 3 callbacks fired");
    is_deeply([sort @results], [1, 2, 3],
        "queued-pre-connect: results match queries");

    $ch->finish if $ch && $ch->is_connected;
}

}  # end native SKIP block

# 5-7: real mid-session reconnect via HTTP keep_alive_timeout (default 3s).
# Run Q1, wait long enough for the server to drop the socket on idle, then
# run Q2 — auto_reconnect must re-establish on the fly. We arm the idle
# timer only once (on_connect fires on every reconnect, so guarding with a
# flag prevents us from looping forever on Q1).
SKIP: {
    skip "HTTP port not reachable", 3 unless $http_ok;

    my $ch;
    my ($q1_err, $q2_err, $q2_val);
    my $disconnects = 0;
    my $first_connect = 1;
    my $idle_timer;

    $ch = EV::ClickHouse->new(
        host                => $host,
        port                => $http_port,
        auto_reconnect      => 1,
        reconnect_delay     => 0.1,
        reconnect_max_delay => 1,
        on_disconnect       => sub { $disconnects++ },
        on_error            => sub { diag("HTTP reconnect error: $_[0]") },
        on_connect          => sub {
            return unless $first_connect;
            $first_connect = 0;
            $ch->query("select 1 format TabSeparated", sub {
                (undef, $q1_err) = @_;

                # Idle past keep_alive_timeout so the server hangs up,
                # then send Q2 — auto_reconnect must dispatch it onto a
                # fresh socket.
                $idle_timer = EV::timer(4, 0, sub {
                    $ch->query("select 2 format TabSeparated", sub {
                        my ($rows, $err) = @_;
                        $q2_err = $err;
                        $q2_val = ($rows && @$rows) ? $rows->[0][0] : undef;
                        EV::break;
                    });
                });
            });
        },
    );

    my $watchdog = EV::timer(15, 0, sub { EV::break });
    EV::run;

    ok(!$q1_err, "HTTP reconnect: first query ok");
    ok(!$q2_err, "HTTP reconnect: second query ok after server idle-close")
        or diag "q2_err=" . ($q2_err // '<undef>');
    is($q2_val, 2, "HTTP reconnect: second query result correct")
        or diag sprintf("disconnects=%d, q2_val=%s",
                        $disconnects, $q2_val // '<undef>');

    $ch->finish if $ch && $ch->is_connected;
}
