use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;

# cancel — abort an in-flight long-running query.
# - native: sends CLIENT_CANCEL; the connection stays usable afterwards.
# - HTTP: closes the connection; needs reset (or auto_reconnect).

my $host      = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $http_port = $ENV{TEST_CLICKHOUSE_PORT} || 8123;
my $nat_port  = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

require IO::Socket::INET;
my $http_ok = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $http_port, Timeout => 2) ? 1 : 0;
my $nat_ok  = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nat_port,  Timeout => 2) ? 1 : 0;
plan skip_all => "ClickHouse not reachable" unless $http_ok || $nat_ok;

plan tests => 6;

# 1-3: native cancel — query terminates early, connection stays usable.
# The native protocol's CLIENT_CANCEL causes the server to end the stream
# without raising an exception, so the query's callback fires with either
# an error or a benign EndOfStream — what matters is that it returned well
# before the sleep was supposed to finish, and the connection survives.
SKIP: {
    skip "Native port not reachable", 3 unless $nat_ok;

    use Time::HiRes qw(time);
    my $ch;
    my ($next_ok, $start, $first_elapsed);
    $ch = EV::ClickHouse->new(
        host       => $host,
        port       => $nat_port,
        protocol   => 'native',
        on_connect => sub {
            $start = time();
            # Heavy aggregation that keeps the server busy long enough for
            # the cancel to be observable. ClickHouse's sleep() can't be
            # interrupted mid-call, so use a real workload instead.
            $ch->query(
                "select count() from numbers(50000000000) where number % 7 = 0",
                sub {
                    $first_elapsed = time() - $start;
                    # Follow-up query to prove the connection is still good.
                    $ch->query("select 1+1", sub {
                        my ($rows, $err2) = @_;
                        $next_ok = !$err2 && $rows && $rows->[0][0] == 2;
                        EV::break;
                    });
                },
            );
            our $cancel_timer = EV::timer(0.3, 0, sub { $ch->cancel });
        },
        on_error => sub { diag("native cancel error: $_[0]") },
    );
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;

    cmp_ok($first_elapsed // 0, '<', 3.0,
        "native cancel: query aborted early (${\ ($first_elapsed // 0)}s)");
    ok($ch->is_connected, "native cancel: connection still up");
    ok($next_ok,          "native cancel: follow-up query worked");
    $ch->finish if $ch->is_connected;
}

# 4-6: HTTP cancel — query gets an error; connection is torn down (HTTP
# cancel works by closing the socket, since HTTP has no in-band cancel).
SKIP: {
    skip "HTTP port not reachable", 3 unless $http_ok;

    use Time::HiRes qw(time);
    my $ch;
    my $got_err;
    my $start;
    $ch = EV::ClickHouse->new(
        host       => $host,
        port       => $http_port,
        on_connect => sub {
            $start = time();
            $ch->query("select sleep(3) format TabSeparated", sub {
                my (undef, $err) = @_;
                $got_err = $err;
                EV::break;
            });
            our $cancel_timer = EV::timer(0.3, 0, sub { $ch->cancel });
        },
        on_error => sub { diag("HTTP cancel error: $_[0]") },
    );
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    my $elapsed = $start ? time() - $start : 0;

    ok($got_err, "HTTP cancel: query got an error");
    cmp_ok($elapsed, '<', 2.5,
        "HTTP cancel: aborted before sleep(3) completed (${elapsed}s)");
    ok(!$ch->is_connected,
        "HTTP cancel: connection torn down (next query needs reset)");
    $ch->finish if $ch && $ch->is_connected;
}
