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

plan tests => 9;

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

# Test 1-2: raw TabSeparated — returns body as scalar
with_http(
    tests => 2,
    cb    => sub {
        $ch->query(
            "SELECT number, number*10 FROM system.numbers LIMIT 3 FORMAT TabSeparated",
            { raw => 1 },
            sub {
                my ($body, $err) = @_;
                ok(!$err, 'raw TSV: no error');
                is($body, "0\t0\n1\t10\n2\t20\n", 'raw TSV: body matches');
                EV::break;
            },
        );
    },
);

# Test 3-4: raw CSV — returns CSV body
with_http(
    tests => 2,
    cb    => sub {
        $ch->query(
            "SELECT number, number*10 FROM system.numbers LIMIT 3 FORMAT CSV",
            { raw => 1 },
            sub {
                my ($body, $err) = @_;
                ok(!$err, 'raw CSV: no error');
                is($body, "0,0\n1,10\n2,20\n", 'raw CSV: body matches');
                EV::break;
            },
        );
    },
);

# Test 5-6: raw JSONEachRow
with_http(
    tests => 2,
    cb    => sub {
        $ch->query(
            "SELECT 1 AS n FORMAT JSONEachRow",
            { raw => 1 },
            sub {
                my ($body, $err) = @_;
                ok(!$err, 'raw JSONEachRow: no error');
                like($body, qr/"n":\s*1/, 'raw JSONEachRow: contains expected JSON');
                EV::break;
            },
        );
    },
);

# Test 7: raw with gzip compression — should decompress and return raw body
with_http(
    compress => 1,
    tests    => 1,
    cb       => sub {
        $ch->query(
            "SELECT 42 AS x FORMAT TabSeparated",
            { raw => 1 },
            sub {
                my ($body, $err) = @_;
                ok(!$err && $body eq "42\n", 'raw + gzip: decompressed body correct');
                EV::break;
            },
        );
    },
);

# Test 8: raw=0 still returns parsed rows (non-raw)
with_http(
    tests => 1,
    cb    => sub {
        $ch->query(
            "SELECT 1 FORMAT TabSeparated",
            { raw => 0 },
            sub {
                my ($rows, $err) = @_;
                ok(ref $rows eq 'ARRAY' && $rows->[0][0] eq '1',
                   'raw=0: returns parsed rows');
                EV::break;
            },
        );
    },
);

# Test 9: native protocol + raw croaks
with_native(
    tests => 1,
    cb    => sub {
        my $ok = eval {
            $ch->query("SELECT 1", { raw => 1 }, sub {});
            1;
        };
        ok(!$ok && $@ =~ /raw mode is only supported with the HTTP protocol/,
           'native + raw: croaks');
        EV::break;
    },
);
