use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;

my $host = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $port = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

my $reachable = 0;
eval {
    require IO::Socket::INET;
    my $s = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port, Timeout => 2);
    $reachable = 1 if $s;
};
plan skip_all => "ClickHouse native port not reachable at $host:$port" unless $reachable;

plan tests => 30;

my $ch;

sub with_ch {
    my (%args) = @_;
    my $cb = delete $args{cb};
    $ch = EV::ClickHouse->new(
        host       => $host,
        port       => $port,
        protocol   => 'native',
        on_connect => sub { $cb->() },
        on_error   => sub {
            diag("Error: $_[0]");
            EV::break;
        },
        %args,
    );
    my $timeout = EV::timer(10, 0, sub { EV::break });
    EV::run;
    $ch->finish if $ch && $ch->is_connected;
}

# Test 1-2: Bool
with_ch(cb => sub {
    $ch->query("select true as t, false as f", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'Bool: no error');
        is_deeply($rows->[0], [1, 0], 'Bool: true=1, false=0');
        EV::break;
    });
});

# Test 3-4: IPv4
with_ch(cb => sub {
    $ch->query("select toIPv4('192.168.1.1') as ip", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'IPv4: no error');
        is($rows->[0][0], '192.168.1.1', 'IPv4: 192.168.1.1');
        EV::break;
    });
});

# Test 5-6: IPv6
with_ch(cb => sub {
    $ch->query("select toIPv6('::1') as ip", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'IPv6: no error');
        is($rows->[0][0], '::1', 'IPv6: ::1');
        EV::break;
    });
});

# Test 7-8: IPv6 full address
with_ch(cb => sub {
    $ch->query("select toIPv6('2001:db8::1') as ip", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'IPv6 full: no error');
        is($rows->[0][0], '2001:db8::1', 'IPv6: 2001:db8::1');
        EV::break;
    });
});

# Test 9-10: Tuple
with_ch(cb => sub {
    $ch->query("select tuple(1, 'hello', 3.14) as t", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'Tuple: no error');
        is_deeply($rows->[0][0], [1, 'hello', 3.14], 'Tuple: (1, hello, 3.14)') ||
            diag explain $rows->[0][0];
        EV::break;
    });
});

# Test 11-12: Tuple multi-row
with_ch(cb => sub {
    $ch->query("select tuple(number, toString(number)) as t from numbers(3)", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'Tuple multi: no error');
        is_deeply($rows, [[[0,'0']], [[1,'1']], [[2,'2']]], 'Tuple multi: 3 rows');
        EV::break;
    });
});

# Test 13-14: Map
with_ch(cb => sub {
    $ch->query("select map('a', 1, 'b', 2) as m", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'Map: no error');
        is_deeply($rows->[0][0], {a => 1, b => 2}, 'Map: {a=>1, b=>2}') ||
            diag explain $rows->[0][0];
        EV::break;
    });
});

# Test 15-16: Map multi-row
with_ch(cb => sub {
    $ch->query("select map('k', number) as m from numbers(3)", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'Map multi: no error');
        is_deeply($rows, [[{k => 0}], [{k => 1}], [{k => 2}]], 'Map multi: 3 rows');
        EV::break;
    });
});

# Test 17-18: Decimal128
with_ch(cb => sub {
    $ch->query("select toDecimal128(12345, 2) as d", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'Decimal128: no error');
        # toDecimal128(12345, 2) = 12345.00; wire integer = 12345 * 10^2 = 1234500
        is($rows->[0][0], '1234500', 'Decimal128: unscaled value');
        EV::break;
    });
});

# Test 19-20: Int128
with_ch(cb => sub {
    $ch->query("select toInt128(-123456789012345) as v", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'Int128: no error');
        is($rows->[0][0], '-123456789012345', 'Int128: negative value');
        EV::break;
    });
});

# Test 21-22: UInt128
with_ch(cb => sub {
    $ch->query("select toUInt128(999999999999999999) as v", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'UInt128: no error');
        is($rows->[0][0], '999999999999999999', 'UInt128: large value');
        EV::break;
    });
});

# Test 23-24: Nullable(IPv4)
with_ch(cb => sub {
    $ch->query("select toNullable(toIPv4('10.0.0.1')) as ip, NULL::Nullable(IPv4) as n", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'Nullable IPv4: no error');
        is($rows->[0][0], '10.0.0.1', 'Nullable IPv4: value');
        EV::break;
    });
});

# Test 25-26: Array of Tuples
with_ch(cb => sub {
    $ch->query("select [tuple(1, 'a'), tuple(2, 'b')] as arr", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'Array(Tuple): no error');
        is_deeply($rows->[0][0], [[1, 'a'], [2, 'b']], 'Array(Tuple): nested') ||
            diag explain $rows->[0][0];
        EV::break;
    });
});

# Test 27-28: LowCardinality in Tuple
with_ch(cb => sub {
    $ch->query("select tuple(toLowCardinality('x'), 42) as t", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'Tuple(LC): no error');
        is_deeply($rows->[0][0], ['x', 42], 'Tuple(LC): values');
        EV::break;
    });
});

# Test 29-30: Empty Map
with_ch(cb => sub {
    $ch->query("select CAST(map() as Map(String, UInt32)) as m", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'Empty Map: no error');
        is_deeply($rows->[0][0], {}, 'Empty Map: {}');
        EV::break;
    });
});
