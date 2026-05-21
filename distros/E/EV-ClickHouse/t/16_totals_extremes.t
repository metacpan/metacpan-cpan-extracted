use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;

# WITH TOTALS / extremes — accessible through last_totals / last_extremes.

my $host = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $port = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

my $reachable = 0;
eval {
    require IO::Socket::INET;
    my $s = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port, Timeout => 2);
    $reachable = 1 if $s;
};
plan skip_all => "ClickHouse native port not reachable" unless $reachable;

plan tests => 8;

my $ch;

sub with_native {
    my ($cb) = @_;
    $ch = EV::ClickHouse->new(
        host       => $host,
        port       => $port,
        protocol   => 'native',
        on_connect => sub { $cb->() },
        on_error   => sub { diag("error: $_[0]"); EV::break },
    );
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    $ch->finish if $ch && $ch->is_connected;
}

# 1-4: WITH TOTALS — totals row is captured separately from main result.
with_native(sub {
    $ch->query(
        "SELECT number % 4 AS bucket, count() AS n
           FROM numbers(100)
          GROUP BY bucket
          WITH TOTALS
          ORDER BY bucket",
        sub {
            my ($rows, $err) = @_;
            ok(!$err, "WITH TOTALS: no error") or diag $err;
            is(ref $rows eq 'ARRAY' ? scalar @$rows : -1, 4,
                "WITH TOTALS: 4 buckets in main result");

            my $totals = $ch->last_totals;
            my $row    = (ref $totals eq 'ARRAY' && @$totals == 1)
                ? $totals->[0] : undef;
            ok(defined $row, "last_totals: exactly one totals row")
                or diag explain $totals;
            is($row ? $row->[1] : undef, 100, "last_totals: total count is 100");
            EV::break;
        },
    );
});

# 5-6: query without WITH TOTALS leaves last_totals undef-or-empty
# (depends on whether the prior query state was reset between calls).
with_native(sub {
    $ch->query(
        "SELECT number FROM numbers(3)",
        sub {
            my ($rows, $err) = @_;
            ok(!$err, "no totals: no error") or diag $err;
            my $totals = $ch->last_totals;
            ok(!defined $totals || @$totals == 0,
                "last_totals: empty when query had no WITH TOTALS");
            EV::break;
        },
    );
});

# 7-8: extremes (set extremes=1 in settings).
with_native(sub {
    $ch->query(
        "SELECT number FROM numbers(10)",
        { extremes => 1 },
        sub {
            my ($rows, $err) = @_;
            ok(!$err, "extremes: no error") or diag $err;

            my $ex = $ch->last_extremes;
            # extremes are min/max rows: 2 rows expected
            ok(defined $ex && @$ex == 2,
                "last_extremes: 2 rows (min/max)") or diag explain $ex;
            EV::break;
        },
    );
});
