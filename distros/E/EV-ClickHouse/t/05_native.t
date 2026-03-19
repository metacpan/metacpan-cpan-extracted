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

plan tests => 33;

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

# Test 1-2: connect
with_ch(cb => sub {
    ok(1, 'native: connected');
    ok($ch->is_connected, 'native: is_connected');
    EV::break;
});

# Test 3-5: server_info / server_version
with_ch(cb => sub {
    my $info = $ch->server_info;
    ok(defined $info, 'server_info: defined');
    like($info, qr/\d+\.\d+\.\d+/, 'server_info: contains version');
    like($ch->server_version, qr/^\d+\.\d+\.\d+$/, 'server_version: format');
    EV::break;
});

# Test 6: ping
with_ch(cb => sub {
    $ch->ping(sub {
        my ($ok, $err) = @_;
        ok(!$err, 'native: ping');
        EV::break;
    });
});

# Test 7-8: simple select
with_ch(cb => sub {
    $ch->query("select 1 as n", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'native select: no error');
        is($rows->[0][0], 1, 'native select: value is 1');
        EV::break;
    });
});

# Test 9-11: multi-column
with_ch(cb => sub {
    $ch->query("select 42 as a, toInt64(99) as b, 'hello' as c", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'multi-column: no error');
        is($rows->[0][0], 42, 'multi-column: a=42');
        is($rows->[0][2], 'hello', 'multi-column: c=hello');
        EV::break;
    });
});

# Test 12-14: multi-row
with_ch(cb => sub {
    $ch->query("select number from numbers(5)", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'multi-row: no error');
        is(scalar @$rows, 5, 'multi-row: 5 rows');
        is($rows->[4][0], 4, 'multi-row: last row');
        EV::break;
    });
});

# Test 15-16: NULL (Nullable(Nothing))
with_ch(cb => sub {
    $ch->query("select NULL as x", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'NULL: no error');
        ok(!defined $rows->[0][0], 'NULL: value is undef');
        EV::break;
    });
});

# Test 17-18: multiple NULLs
with_ch(cb => sub {
    $ch->query("select NULL as x from numbers(3)", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'NULL*3: no error');
        is(scalar @$rows, 3, 'NULL*3: 3 rows');
        EV::break;
    });
});

# Test 19-20: mixed columns with NULL
with_ch(cb => sub {
    $ch->query("select 1 as a, NULL as b, 'hi' as c", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'mixed: no error');
        is_deeply($rows->[0], [1, undef, 'hi'], 'mixed: [1,NULL,hi]');
        EV::break;
    });
});

# Test 21: Nullable with value
with_ch(cb => sub {
    $ch->query("select toNullable(toUInt8(42)) as n", sub {
        my ($rows, $err) = @_;
        is($rows->[0][0], 42, 'Nullable(UInt8): value is 42');
        EV::break;
    });
});

# Test 22-23: signed integers
with_ch(cb => sub {
    $ch->query("select toInt8(-42) as i8, toInt16(-1000) as i16, toInt32(-100000) as i32", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'signed ints: no error');
        is_deeply($rows->[0], [-42, -1000, -100000], 'signed ints: values');
        EV::break;
    });
});

# Test 24-25: floats
with_ch(cb => sub {
    $ch->query("select toFloat32(1.5) as f32, toFloat64(2.718281828) as f64", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'floats: no error');
        ok(abs($rows->[0][1] - 2.718281828) < 1e-9, 'floats: Float64 precision');
        EV::break;
    });
});

# Test 26: error handling
with_ch(cb => sub {
    $ch->query("INVALID SQL", sub {
        my ($rows, $err) = @_;
        ok($err, 'syntax error: got error');
        EV::break;
    });
});

# Test 27-28: query after error
with_ch(cb => sub {
    $ch->query("INVALID SQL", sub {
        my ($rows, $err) = @_;
        ok($err, 'after_err: first query errored');
        $ch->query("select 123 as n", sub {
            my ($rows2, $err2) = @_;
            is($rows2->[0][0], 123, 'after_err: second query works');
            EV::break;
        });
    });
});

# Test 29-31: DDL + insert + select
with_ch(cb => sub {
    $ch->query("create table if not exists _ev_native_test (a UInt32, b String) engine = Memory", sub {
        my ($r, $e) = @_;
        ok(!$e, 'DDL: create table');
        $ch->insert("_ev_native_test", "1\thello\n2\tworld\n", sub {
            my ($r2, $e2) = @_;
            ok(!$e2, 'insert: no error');
            $ch->query("select a, b from _ev_native_test order by a", sub {
                my ($r3, $e3) = @_;
                is_deeply($r3, [[1, 'hello'], [2, 'world']], 'select after insert');
                $ch->query("drop table _ev_native_test", sub { EV::break });
            });
        });
    });
});

# Test 32-33: sequential pipeline
with_ch(cb => sub {
    my @results;
    my $remain = 5;
    for my $i (1..5) {
        $ch->query("select $i as n", sub {
            my ($rows, $err) = @_;
            push @results, $rows->[0][0];
            $remain--;
            if ($remain == 0) {
                is(scalar @results, 5, 'pipeline: 5 results');
                is_deeply(\@results, [1,2,3,4,5], 'pipeline: correct order');
                EV::break;
            }
        });
    }
});
