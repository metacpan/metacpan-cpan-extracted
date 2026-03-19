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

plan tests => 22;

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

# Test 1-2: Parameterized query — HTTP
with_http(
    tests => 2,
    cb    => sub {
        $ch->query(
            "SELECT {x:UInt32} + {y:UInt32} as result FORMAT TabSeparated",
            { params => { x => 10, y => 20 } },
            sub {
                my ($rows, $err) = @_;
                ok(!$err, 'HTTP params: no error');
                is($rows->[0][0], '30', 'HTTP params: 10+20=30');
                EV::break;
            },
        );
    },
);

# Test 3-4: Parameterized query — Native
with_native(
    tests => 2,
    cb    => sub {
        $ch->query(
            "SELECT {x:UInt32} + {y:UInt32} as result",
            { params => { x => 100, y => 200 } },
            sub {
                my ($rows, $err) = @_;
                ok(!$err, 'Native params: no error');
                is($rows->[0][0], 300, 'Native params: 100+200=300');
                EV::break;
            },
        );
    },
);

# Test 5-6: Parameterized query with string param
with_native(
    tests => 2,
    cb    => sub {
        $ch->query(
            "SELECT {s:String} as result",
            { params => { s => 'hello world' } },
            sub {
                my ($rows, $err) = @_;
                ok(!$err, 'Native string param: no error');
                is($rows->[0][0], 'hello world', 'Native string param: correct');
                EV::break;
            },
        );
    },
);

# Test 7-8: Connection URI
SKIP: {
    skip "Native port not reachable", 2 unless $nat_ok;
    my $uri_ch;
    $uri_ch = EV::ClickHouse->new(
        uri        => "clickhouse+native://default:\@$host:$nat_port/default",
        on_connect => sub {
            $uri_ch->query("SELECT 42 as n", sub {
                my ($rows, $err) = @_;
                ok(!$err, 'URI: no error');
                is($rows->[0][0], 42, 'URI: query works');
                EV::break;
            });
        },
        on_error => sub { diag("URI error: $_[0]"); EV::break },
    );
    my $timeout = EV::timer(10, 0, sub { EV::break });
    EV::run;
    $uri_ch->finish if $uri_ch && $uri_ch->is_connected;
}

# Test 9-10: Connection URI — HTTP with query params
SKIP: {
    skip "HTTP port not reachable", 2 unless $http_ok;
    my $uri_ch;
    $uri_ch = EV::ClickHouse->new(
        uri        => "clickhouse://default:\@$host:$http_port/default",
        on_connect => sub {
            $uri_ch->query("SELECT 1 FORMAT TabSeparated", sub {
                my ($rows, $err) = @_;
                ok(!$err, 'URI HTTP: no error');
                is($rows->[0][0], '1', 'URI HTTP: query works');
                EV::break;
            });
        },
        on_error => sub { diag("URI HTTP error: $_[0]"); EV::break },
    );
    my $timeout = EV::timer(10, 0, sub { EV::break });
    EV::run;
    $uri_ch->finish if $uri_ch && $uri_ch->is_connected;
}

# Test 11-12: last_query_id
with_native(
    tests => 2,
    cb    => sub {
        $ch->query(
            "SELECT 1",
            { query_id => 'test_qid_123' },
            sub {
                my ($rows, $err) = @_;
                ok(!$err, 'last_query_id: no error');
                is($ch->last_query_id, 'test_qid_123', 'last_query_id: correct');
                EV::break;
            },
        );
    },
);

# Test 13: last_query_id undef before any query
with_native(
    tests => 1,
    cb    => sub {
        ok(!defined $ch->last_query_id, 'last_query_id: undef initially');
        EV::break;
    },
);

# Test 14-16: on_trace callback
with_native(
    tests => 3,
    cb    => sub {
        my @traces;
        $ch->on_trace(sub { push @traces, $_[0] });
        $ch->query("SELECT 1", sub {
            my ($rows, $err) = @_;
            ok(!$err, 'on_trace: no error');
            ok(@traces >= 1, 'on_trace: got trace messages (' . scalar(@traces) . ')');
            like($traces[0], qr/dispatch/, 'on_trace: dispatch message');
            EV::break;
        });
    },
);

# Test 17-19: Int256 type
with_native(
    tests => 3,
    cb    => sub {
        $ch->query("SELECT toInt256(12345678901234567890) as big", sub {
            my ($rows, $err) = @_;
            ok(!$err, 'Int256: no error');
            is($rows->[0][0], '12345678901234567890', 'Int256: correct value');
        });
        # Also test UInt256
        $ch->query("SELECT toUInt256('99999999999999999999') as big", sub {
            my ($rows, $err) = @_;
            is($rows->[0][0], '99999999999999999999', 'UInt256: correct value');
        });
        $ch->drain(sub { EV::break });
    },
);

# Test 20-22: Keepalive (just verify it doesn't crash and connection stays alive)
SKIP: {
    skip "Native port not reachable", 3 unless $nat_ok;
    my ($ka_ch, $ka_wait);
    $ka_ch = EV::ClickHouse->new(
        host       => $host,
        port       => $nat_port,
        protocol   => 'native',
        keepalive  => 1,
        on_connect => sub {
            ok(1, 'keepalive: connected');
            # Wait a bit, then query
            $ka_wait = EV::timer(0.5, 0, sub {
                ok($ka_ch->is_connected, 'keepalive: still connected');
                $ka_ch->query("SELECT 1", sub {
                    my ($rows, $err) = @_;
                    ok(!$err, 'keepalive: query after wait ok');
                    EV::break;
                });
            });
        },
        on_error => sub { diag("KA error: $_[0]"); EV::break },
    );
    my $timeout = EV::timer(10, 0, sub { EV::break });
    EV::run;
    $ka_ch->finish if $ka_ch && $ka_ch->is_connected;
}
