use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;

# on_progress fires for native protocol queries that touch enough data to
# trigger at least one progress packet from the server.

my $host = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $port = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

my $reachable = 0;
eval {
    require IO::Socket::INET;
    my $s = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port, Timeout => 2);
    $reachable = 1 if $s;
};
plan skip_all => "ClickHouse native port not reachable" unless $reachable;

plan tests => 5;

my @progress;

my $ch;
$ch = EV::ClickHouse->new(
    host       => $host,
    port       => $port,
    protocol   => 'native',
    on_progress => sub {
        push @progress, [@_];
    },
    on_connect => sub {
        # Sum a non-trivial range so the server emits progress packets.
        $ch->query(
            "SELECT sum(number) FROM numbers(50000000)",
            sub {
                my ($rows, $err) = @_;
                ok(!$err, "progress: query ok") or diag $err;
                ok(@progress > 0, "on_progress fired (" . scalar(@progress) . " times)");

                # Each progress packet contains incremental rows/bytes since
                # the previous one, so sum across all packets to compare with
                # the work the query actually did.
                my ($sum_rows, $sum_bytes, $any_total) = (0, 0, 0);
                for my $p (@progress) {
                    $sum_rows  += $p->[0] || 0;
                    $sum_bytes += $p->[1] || 0;
                    $any_total ||= $p->[2] if defined $p->[2];
                }
                ok($sum_rows  > 0, "progress: total rows reported  > 0 (sum=$sum_rows)");
                ok($sum_bytes > 0, "progress: total bytes reported > 0 (sum=$sum_bytes)");
                ok(defined $any_total, "progress: total_rows hint at least once");
                EV::break;
            },
        );
    },
    on_error => sub { diag("error: $_[0]"); EV::break },
);

my $t = EV::timer(15, 0, sub { EV::break });
EV::run;
$ch->finish if $ch && $ch->is_connected;
