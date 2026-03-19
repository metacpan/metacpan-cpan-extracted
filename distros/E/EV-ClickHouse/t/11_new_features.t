use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;

my $host      = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $http_port = $ENV{TEST_CLICKHOUSE_PORT} || 8123;
my $nat_port  = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

my $http_ok = 0;
eval {
    require IO::Socket::INET;
    my $s = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $http_port, Timeout => 2);
    $http_ok = 1 if $s;
};
my $nat_ok = 0;
eval {
    require IO::Socket::INET;
    my $s = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nat_port, Timeout => 2);
    $nat_ok = 1 if $s;
};
plan skip_all => "ClickHouse not reachable" unless $http_ok || $nat_ok;

plan tests => 30;

my $ch;

sub with_http {
    my (%args) = @_;
    my $cb    = delete $args{cb};
    my $tests = delete $args{tests} || 1;
    SKIP: {
        skip "HTTP port not reachable", $tests unless $http_ok;
        $ch = EV::ClickHouse->new(
            host       => $host,
            port       => $http_port,
            on_connect => sub { $cb->() },
            on_error   => sub { diag("HTTP error: $_[0]"); EV::break },
            %args,
        );
        my $timeout = EV::timer(10, 0, sub { EV::break });
        EV::run;
        $ch->finish if $ch && $ch->is_connected;
    }
}

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

# Test 1-2: server_timezone accessor (native)
with_native(
    tests => 2,
    cb    => sub {
        my $tz = $ch->server_timezone;
        ok(defined $tz, 'server_timezone: defined');
        like($tz, qr/\w+/, 'server_timezone: non-empty string');
        EV::break;
    },
);

# Test 3: server_timezone undef for HTTP
with_http(
    tests => 1,
    cb    => sub {
        my $tz = $ch->server_timezone;
        ok(!defined $tz, 'server_timezone: undef for HTTP');
        EV::break;
    },
);

# Test 4-6: column_names accessor (native)
with_native(
    tests => 3,
    cb    => sub {
        $ch->query("SELECT 1 as foo, 'bar' as baz", sub {
            my ($rows, $err) = @_;
            ok(!$err, 'column_names: no error');
            my $names = $ch->column_names;
            is_deeply($names, ['foo', 'baz'], 'column_names: correct names');
            is(scalar @$rows, 1, 'column_names: 1 row');
            EV::break;
        });
    },
);

# Test 7: column_names undef before query
with_native(
    tests => 1,
    cb    => sub {
        # Before any query, column_names should be undef
        # Actually after connect we have done ServerHello, but no data block yet
        my $names = $ch->column_names;
        ok(!defined $names, 'column_names: undef before query');
        EV::break;
    },
);

# Test 8-10: decode_datetime (Date/DateTime as strings)
with_native(
    decode_datetime => 1,
    tests           => 3,
    cb              => sub {
        $ch->query("SELECT toDate('2024-01-15') as d, toDateTime(0, 'UTC') as dt", sub {
            my ($rows, $err) = @_;
            ok(!$err, 'decode_datetime: no error');
            is($rows->[0][0], '2024-01-15', 'decode_datetime: Date as string');
            is($rows->[0][1], '1970-01-01 00:00:00', 'decode_datetime: DateTime as string');
            EV::break;
        });
    },
);

# Test 11-12: decode_decimal (Decimal scaling)
with_native(
    decode_decimal => 1,
    tests          => 2,
    cb             => sub {
        $ch->query("SELECT toDecimal32(123.45, 2) as d", sub {
            my ($rows, $err) = @_;
            ok(!$err, 'decode_decimal: no error');
            ok(abs($rows->[0][0] - 123.45) < 0.001, "decode_decimal: value is 123.45 (got $rows->[0][0])");
            EV::break;
        });
    },
);

# Test 13-14: decode_enum (Enum labels)
with_native(
    decode_enum => 1,
    tests       => 2,
    cb          => sub {
        $ch->query("DROP TABLE IF EXISTS _test_enum_decode", sub {
            $ch->query("CREATE TABLE _test_enum_decode (e Enum8('hello' = 1, 'world' = 2)) ENGINE = Memory", sub {
                $ch->insert("_test_enum_decode", "1\n2\n", sub {
                    $ch->query("SELECT e FROM _test_enum_decode ORDER BY e", sub {
                        my ($rows, $err) = @_;
                        ok(!$err, 'decode_enum: no error');
                        is_deeply([map { $_->[0] } @$rows], ['hello', 'world'], 'decode_enum: labels returned');
                        $ch->query("DROP TABLE _test_enum_decode", sub { EV::break });
                    });
                });
            });
        });
    },
);

# Test 15-17: named_rows (results as hashrefs)
with_native(
    named_rows => 1,
    tests      => 3,
    cb         => sub {
        $ch->query("SELECT 42 as a, 'hi' as b", sub {
            my ($rows, $err) = @_;
            ok(!$err, 'named_rows: no error');
            is(ref $rows->[0], 'HASH', 'named_rows: row is hashref');
            is_deeply($rows->[0], { a => 42, b => 'hi' }, 'named_rows: correct keys/values');
            EV::break;
        });
    },
);

# Test 18-19: on_disconnect callback (native)
with_native(
    tests => 2,
    cb    => sub {
        ok($ch->is_connected, 'on_disconnect: connected');
        my $disconnected = 0;
        $ch->on_disconnect(sub { $disconnected = 1 });
        $ch->finish;
        ok($disconnected, 'on_disconnect: callback fired');
        EV::break;
    },
);

# Test 20-21: on_disconnect callback (HTTP)
with_http(
    tests => 2,
    cb    => sub {
        ok($ch->is_connected, 'on_disconnect HTTP: connected');
        my $disconnected = 0;
        $ch->on_disconnect(sub { $disconnected = 1 });
        $ch->finish;
        ok($disconnected, 'on_disconnect HTTP: callback fired');
        EV::break;
    },
);

# Test 22-23: error code in error messages (native)
with_native(
    tests => 2,
    cb    => sub {
        $ch->query("SELECT nonexistent_column FROM system.one", sub {
            my ($rows, $err) = @_;
            ok($err, 'error_code: got error');
            like($err, qr/Code: \d+/, 'error_code: contains Code: N');
            EV::break;
        });
    },
);

# Test 24-26: streaming on_data callback (native)
with_native(
    tests => 3,
    cb    => sub {
        my @blocks;
        $ch->query(
            "SELECT number FROM numbers(100)",
            { on_data => sub { push @blocks, $_[0] } },
            sub {
                my ($rows, $err) = @_;
                ok(!$err, 'on_data: no error');
                ok(@blocks >= 1, "on_data: received " . scalar(@blocks) . " block(s)");
                # Final callback should have empty/undef rows since on_data consumed them
                my $total = 0;
                $total += scalar @$_ for @blocks;
                is($total, 100, 'on_data: total 100 rows across blocks');
                EV::break;
            },
        );
    },
);

# Test 27-28: query_timeout (should timeout on a long query)
with_native(
    tests => 2,
    cb    => sub {
        $ch->query(
            "SELECT count() FROM system.numbers LIMIT 1",
            { query_timeout => 1 },
            sub {
                my ($rows, $err) = @_;
                ok($err, 'query_timeout: got error');
                like($err, qr/timeout/i, 'query_timeout: error mentions timeout');
                EV::break;
            },
        );
    },
);

# Test 29-30: cancel (native)
with_native(
    tests => 2,
    cb    => sub {
        $ch->query("SELECT count() FROM system.numbers LIMIT 1", sub {
            my ($rows, $err) = @_;
            ok($err, 'cancel: got error');
            ok(1, 'cancel: callback delivered');
            EV::break;
        });
        # cancel after a short delay
        my $t = EV::timer(0.5, 0, sub {
            $ch->cancel;
        });
    },
);
