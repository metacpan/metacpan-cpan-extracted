use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;

my $host     = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $nat_port = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

my $nat_ok = 0;
eval {
    require IO::Socket::INET;
    my $s = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nat_port, Timeout => 2);
    $nat_ok = 1 if $s;
};
plan skip_all => "ClickHouse native port not reachable" unless $nat_ok;

plan tests => 18;

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

# Test 1-3: column_types accessor
with_native(
    tests => 3,
    cb    => sub {
        $ch->query("SELECT toUInt32(1) as a, 'hello' as b, toDate('2024-01-01') as c", sub {
            my ($rows, $err) = @_;
            ok(!$err, 'column_types: no error');
            my $types = $ch->column_types;
            is(ref $types, 'ARRAY', 'column_types: returns arrayref');
            is_deeply($types, ['UInt32', 'String', 'Date'], 'column_types: correct types');
            EV::break;
        });
    },
);

# Test 4-5: last_error_code
with_native(
    tests => 2,
    cb    => sub {
        $ch->query("SELECT * FROM _nonexistent_table_12345", sub {
            my ($rows, $err) = @_;
            ok($err, 'last_error_code: got error');
            is($ch->last_error_code, 60, 'last_error_code: 60 = UNKNOWN_TABLE');
            EV::break;
        });
    },
);

# Test 6-8: profile_info (rows_before_limit)
with_native(
    tests => 3,
    cb    => sub {
        $ch->query("SELECT number FROM numbers(100) LIMIT 10", sub {
            my ($rows, $err) = @_;
            ok(!$err, 'profile_info: no error');
            is(scalar @$rows, 10, 'profile_info: 10 rows returned');
            ok($ch->profile_rows_before_limit >= 10,
               'profile_rows_before_limit: >= 10 (got ' . $ch->profile_rows_before_limit . ')');
            EV::break;
        });
    },
);

# Test 9-12: totals separation
with_native(
    tests => 4,
    cb    => sub {
        $ch->query("SELECT number % 2 as g, count() as c FROM numbers(10) GROUP BY g WITH TOTALS ORDER BY g", sub {
            my ($rows, $err) = @_;
            ok(!$err, 'totals: no error');
            is(scalar @$rows, 2, 'totals: 2 data rows');
            my $totals = $ch->last_totals;
            ok(defined $totals && ref $totals eq 'ARRAY', 'totals: has totals');
            is($totals->[0][1], 10, 'totals: total count = 10');
            EV::break;
        });
    },
);

# Test 13-15: LowCardinality multi-block
with_native(
    tests => 3,
    cb    => sub {
        # Use max_block_size=5 to force multiple blocks
        $ch->query(
            "SELECT toLowCardinality(toString(number % 3)) as lc FROM numbers(20)",
            { max_block_size => '5' },
            sub {
                my ($rows, $err) = @_;
                ok(!$err, 'LC multi-block: no error') or diag($err);
                is(scalar @$rows, 20, 'LC multi-block: 20 rows');
                is($rows->[0][0], '0', 'LC multi-block: first value correct');
                EV::break;
            },
        );
    },
);

# Test 16-18: reconnect_delay option (just verify it doesn't crash)
SKIP: {
    skip "Native port not reachable", 3 unless $nat_ok;
    my $rc_ch;
    $rc_ch = EV::ClickHouse->new(
        host              => $host,
        port              => $nat_port,
        protocol          => 'native',
        auto_reconnect    => 1,
        reconnect_delay   => 0.1,
        reconnect_max_delay => 2,
        on_connect => sub {
            ok(1, 'reconnect_delay: connected');
            $rc_ch->query("SELECT 1", sub {
                my ($rows, $err) = @_;
                ok(!$err, 'reconnect_delay: query ok');
                is($rows->[0][0], 1, 'reconnect_delay: value correct');
                EV::break;
            });
        },
        on_error => sub { diag("RC error: $_[0]"); EV::break },
    );
    my $timeout = EV::timer(10, 0, sub { EV::break });
    EV::run;
    $rc_ch->finish if $rc_ch && $rc_ch->is_connected;
}
