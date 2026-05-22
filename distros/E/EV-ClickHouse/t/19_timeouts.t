use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;

# connect_timeout and query_timeout firing.

my $host = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $port = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

require IO::Socket::INET;
plan skip_all => "ClickHouse native port not reachable"
    unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port, Timeout => 2);

plan tests => 4;

use Time::HiRes qw(time);

# 1-2: connect_timeout — point at TEST-NET-1 (RFC 5737), which black-holes.
# Assert both an error and that the timeout fired in roughly the configured
# window (so a misconfigured stack returning ECONNREFUSED instantly doesn't
# masquerade as a successful timeout test).
{
    my $ch;
    my $err;
    my $start = time();
    $ch = EV::ClickHouse->new(
        host            => '192.0.2.1',
        port            => 9000,
        protocol        => 'native',
        connect_timeout => 1,
        on_error        => sub { $err = $_[0]; EV::break },
        on_connect      => sub { EV::break },
    );
    my $watchdog = EV::timer(5, 0, sub { EV::break });
    EV::run;
    my $elapsed = time() - $start;

    ok(defined $err, "connect_timeout: error fired");
    cmp_ok($elapsed, '>=', 0.8,
        "connect_timeout: waited at least ~1s (took ${elapsed}s)");
    $ch->finish if $ch && $ch->is_connected;
}

# 3-4: query_timeout — set the connection-level default, run a sleep query.
{
    my $ch;
    my ($rows, $err);
    my $start;
    $ch = EV::ClickHouse->new(
        host          => $host,
        port          => $port,
        protocol      => 'native',
        query_timeout => 1,
        on_connect    => sub {
            $start = time();
            $ch->query("select sleep(3)", sub {
                ($rows, $err) = @_;
                EV::break;
            });
        },
        on_error => sub { diag("error: $_[0]") },
    );
    my $watchdog = EV::timer(8, 0, sub { EV::break });
    EV::run;
    my $elapsed = $start ? time() - $start : 0;

    ok(defined $err, "query_timeout: query errored")
        or diag "rows: " . (defined $rows ? "defined" : "undef");
    cmp_ok($elapsed, '<', 2.5,
        "query_timeout: aborted before sleep(3) completed (${elapsed}s)");
    $ch->finish if $ch && $ch->is_connected;
}
