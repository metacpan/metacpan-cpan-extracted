use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;

my $host     = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $nat_port = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

require IO::Socket::INET;
my $nat_ok = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nat_port, Timeout => 2) ? 1 : 0;
plan skip_all => "ClickHouse native port not reachable" unless $nat_ok;

plan tests => 22;

my $ch;

sub with_native {
    my (%args) = @_;
    my $cb    = delete $args{cb};
    my $tests = delete $args{tests} || 1;
    SKIP: {
        skip "Native port not reachable", $tests unless $nat_ok;
        $ch = EV::ClickHouse->new(
            host       => $host,
            port       => $nat_port,
            protocol   => 'native',
            on_connect => sub { $cb->() },
            on_error   => sub { diag("Native error: $_[0]"); EV::break },
            %args,
        );
        my $timeout = EV::timer(10, 0, sub { EV::break });
        EV::run;
        $ch->finish if $ch && $ch->is_connected;
    }
}

# Test 1-2: Decimal128 scaling
with_native(
    decode_decimal => 1,
    tests          => 2,
    cb             => sub {
        $ch->query("select toDecimal128(12345.67, 4) as d", sub {
            my ($rows, $err) = @_;
            ok(!$err, 'Decimal128 scale: no error');
            ok(abs($rows->[0][0] - 12345.67) < 0.01,
               "Decimal128 scale: value ~12345.67 (got $rows->[0][0])");
            EV::break;
        });
    },
);

# Test 3-4: DateTime with timezone
with_native(
    decode_datetime => 1,
    tests           => 2,
    cb              => sub {
        # epoch 0 in UTC is '1970-01-01 00:00:00'; in America/New_York it's '1969-12-31 19:00:00'
        $ch->query("select toDateTime(0, 'America/New_York') as dt", sub {
            my ($rows, $err) = @_;
            ok(!$err, 'DateTime tz: no error');
            is($rows->[0][0], '1969-12-31 19:00:00',
               'DateTime tz: America/New_York offset applied');
            EV::break;
        });
    },
);

# Test 5-6: DateTime64 with timezone
with_native(
    decode_datetime => 1,
    tests           => 2,
    cb              => sub {
        $ch->query("select toDateTime64(0, 3, 'America/New_York') as dt64", sub {
            my ($rows, $err) = @_;
            ok(!$err, 'DateTime64 tz: no error');
            is($rows->[0][0], '1969-12-31 19:00:00.000',
               'DateTime64 tz: America/New_York offset applied');
            EV::break;
        });
    },
);

# Test 7-8: DateTime without timezone (should use UTC)
with_native(
    decode_datetime => 1,
    tests           => 2,
    cb              => sub {
        $ch->query("select toDateTime(0, 'UTC') as dt", sub {
            my ($rows, $err) = @_;
            ok(!$err, 'DateTime UTC: no error');
            is($rows->[0][0], '1970-01-01 00:00:00',
               'DateTime UTC: correct UTC');
            EV::break;
        });
    },
);

# Test 9-11: SimpleAggregateFunction
with_native(
    tests => 3,
    cb    => sub {
        $ch->query("drop table if exists _test_saf", sub {
            $ch->query(
                "create table _test_saf (k UInt32, v SimpleAggregateFunction(max, UInt64)) "
                . "engine = AggregatingMergeTree order by k",
                sub {
                    $ch->insert("_test_saf", "1\t100\n2\t200\n", sub {
                        $ch->query("select k, v from _test_saf order by k", sub {
                            my ($rows, $err) = @_;
                            ok(!$err, 'SimpleAggregateFunction: no error');
                            is($rows->[0][1], 100, 'SAF: first value');
                            is($rows->[1][1], 200, 'SAF: second value');
                            $ch->query("drop table _test_saf", sub { EV::break });
                        });
                    });
                },
            );
        });
    },
);

# Test 12-14: Nested type
with_native(
    tests => 3,
    cb    => sub {
        $ch->query("drop table if exists _test_nested", sub {
            $ch->query(
                "create table _test_nested (id UInt32, n Nested(x UInt32, y String)) "
                . "ENGINE = Memory",
                sub {
                    # Nested columns are stored as separate arrays
                    $ch->query(
                        "insert into _test_nested values (1, [10, 20], ['a', 'b'])",
                        sub {
                            $ch->query("select n.x, n.y from _test_nested", sub {
                                my ($rows, $err) = @_;
                                ok(!$err, 'Nested: no error');
                                is_deeply($rows->[0][0], [10, 20], 'Nested: n.x array');
                                is_deeply($rows->[0][1], ['a', 'b'], 'Nested: n.y array');
                                $ch->query("drop table _test_nested", sub { EV::break });
                            });
                        },
                    );
                },
            );
        });
    },
);

# Test 15-17: drain — fires after pending queries complete
with_native(
    tests => 3,
    cb    => sub {
        my @order;
        $ch->query("select 1", sub {
            push @order, 'q1';
        });
        $ch->query("select 2", sub {
            push @order, 'q2';
        });
        $ch->drain(sub {
            push @order, 'drain';
            is(scalar @order, 3, 'drain: fired after both queries');
            is($order[0], 'q1', 'drain: q1 first');
            is($order[2], 'drain', 'drain: last');
            EV::break;
        });
    },
);

# Test 18-19: drain — fires immediately when nothing pending
with_native(
    tests => 2,
    cb    => sub {
        my $fired = 0;
        $ch->drain(sub {
            $fired = 1;
        });
        ok($fired, 'drain immediate: fired synchronously');
        is($ch->pending_count, 0, 'drain immediate: pending_count is 0');
        EV::break;
    },
);

# Test 20-22: drain then finish (graceful shutdown)
with_native(
    tests => 3,
    cb    => sub {
        my $done = 0;
        my $disconnected = 0;
        $ch->on_disconnect(sub { $disconnected = 1 });
        $ch->query("select 1", sub {
            my ($rows, $err) = @_;
            ok(!$err, 'drain+finish: query ok');
        });
        $ch->drain(sub {
            $done = 1;
            ok($done, 'drain+finish: drain fired');
            $ch->finish;
            ok($disconnected, 'drain+finish: on_disconnect fired after finish');
            EV::break;
        });
    },
);
