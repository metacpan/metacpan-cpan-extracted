use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;

# on_data streaming callback (native protocol): rows are delivered per-block
# as they arrive; the final callback gets undef rows (no accumulation).

my $host = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $port = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

require IO::Socket::INET;
plan skip_all => "ClickHouse native port not reachable"
    unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port, Timeout => 2);

plan tests => 9;

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
    my $t = EV::timer(15, 0, sub { EV::break });
    EV::run;
    $ch->finish if $ch && $ch->is_connected;
}

# 1-4: streaming a moderate result set produces multiple blocks.
with_native(sub {
    my $blocks = 0;
    my $streamed_rows = 0;

    $ch->query(
        "select number from numbers(100000)",
        {
            on_data => sub {
                my ($rows) = @_;
                $blocks++;
                $streamed_rows += scalar @$rows;
            },
        },
        sub {
            my ($rows, $err) = @_;
            ok(!$err, "streaming: no error") or diag $err;
            ok($blocks > 1, "streaming: got multiple blocks ($blocks)");
            is($streamed_rows, 100000, "streaming: total rows match");
            ok(!defined $rows, "streaming: final callback gets undef rows");
            EV::break;
        },
    );
});

# 5-7: with on_data, last_query_id and column_names still work.
with_native(sub {
    my $blocks = 0;

    $ch->query(
        "select number, toString(number) as s from numbers(50000)",
        {
            query_id => 'streaming-test',
            on_data  => sub { $blocks++ },
        },
        sub {
            my (undef, $err) = @_;
            ok(!$err, "streaming with metadata: no error") or diag $err;
            is($ch->last_query_id, 'streaming-test', "query_id set");
            is_deeply($ch->column_names, ['number', 's'], "column_names captured");
            EV::break;
        },
    );
});

# 8-9: empty result still fires the final callback (and on_data may or may
# not fire, depending on whether the server emits an empty data block).
with_native(sub {
    my $blocks = 0;

    $ch->query(
        "select number from numbers(1) where number > 999",
        { on_data => sub { $blocks++; } },
        sub {
            my ($rows, $err) = @_;
            ok(!$err, "streaming empty: no error") or diag $err;
            ok(!defined $rows, "streaming empty: final rows undef");
            EV::break;
        },
    );
});
