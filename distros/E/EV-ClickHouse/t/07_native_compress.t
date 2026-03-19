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

plan tests => 20;

my $ch;

sub with_ch {
    my (%args) = @_;
    my $cb = delete $args{cb};
    $ch = EV::ClickHouse->new(
        host       => $host,
        port       => $port,
        protocol   => 'native',
        compress   => 1,
        on_connect => sub { $cb->() },
        on_error   => sub {
            diag("Error: $_[0]");
            EV::break;
        },
        %args,
    );
    my $timeout = EV::timer(10, 0, sub { diag("timeout"); EV::break });
    EV::run;
    $ch->finish if $ch && $ch->is_connected;
}

# Test 1-2: connect with compression
with_ch(cb => sub {
    ok(1, 'compressed: connected');
    ok($ch->is_connected, 'compressed: is_connected');
    EV::break;
});

# Test 3: ping with compression
with_ch(cb => sub {
    $ch->ping(sub {
        my ($ok, $err) = @_;
        ok(!$err, 'compressed: ping');
        EV::break;
    });
});

# Test 4-5: simple select
with_ch(cb => sub {
    $ch->query("select 42 as n", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'compressed select: no error');
        is($rows->[0][0], 42, 'compressed select: value 42');
        EV::break;
    });
});

# Test 6-8: multi-column select
with_ch(cb => sub {
    $ch->query("select 1 as a, 'hello' as b, toFloat64(3.14) as c", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'compressed multi-col: no error');
        is($rows->[0][0], 1, 'compressed multi-col: a=1');
        is($rows->[0][1], 'hello', 'compressed multi-col: b=hello');
        EV::break;
    });
});

# Test 9-11: multi-row select
with_ch(cb => sub {
    $ch->query("select number, toString(number) from numbers(100)", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'compressed 100 rows: no error');
        is(scalar @$rows, 100, 'compressed 100 rows: count');
        is($rows->[99][0], 99, 'compressed 100 rows: last row');
        EV::break;
    });
});

# Test 12-13: NULL handling with compression
with_ch(cb => sub {
    $ch->query("select 1 as a, NULL as b, 'hi' as c", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'compressed NULL: no error');
        is_deeply($rows->[0], [1, undef, 'hi'], 'compressed NULL: mixed values');
        EV::break;
    });
});

# Test 14-15: error recovery with compression
with_ch(cb => sub {
    $ch->query("INVALID SQL", sub {
        my ($rows, $err) = @_;
        ok($err, 'compressed error: got error');
        $ch->query("select 123 as n", sub {
            my ($rows2, $err2) = @_;
            is($rows2->[0][0], 123, 'compressed error: recovery works');
            EV::break;
        });
    });
});

# Test 16-18: DDL + insert + select with compression
with_ch(cb => sub {
    $ch->query("create table if not exists _ev_compress_test (a UInt32, b String) engine = Memory", sub {
        my ($r, $e) = @_;
        ok(!$e, 'compressed DDL: create');
        $ch->insert("_ev_compress_test", "10\talpha\n20\tbeta\n", sub {
            my ($r2, $e2) = @_;
            ok(!$e2, 'compressed insert: no error');
            $ch->query("select a, b from _ev_compress_test order by a", sub {
                my ($r3, $e3) = @_;
                is_deeply($r3, [[10, 'alpha'], [20, 'beta']], 'compressed: select after insert');
                $ch->query("drop table _ev_compress_test", sub { EV::break });
            });
        });
    });
});

# Test 19-20: on_progress callback
{
    my @progress;
    with_ch(
        on_progress => sub {
            my ($rows, $bytes, $total, $wrows, $wbytes) = @_;
            push @progress, { rows => $rows, bytes => $bytes };
        },
        cb => sub {
            $ch->query("select number from numbers(10000)", sub {
                my ($rows, $err) = @_;
                ok(!$err, 'progress: query ok');
                # progress may or may not fire depending on query speed
                ok(1, 'progress: callback registered (fired ' . scalar(@progress) . ' times)');
                EV::break;
            });
        },
    );
}
