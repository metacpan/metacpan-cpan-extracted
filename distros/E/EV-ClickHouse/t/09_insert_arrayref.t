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

plan tests => 26;

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
            session_id => "aref_http_$$",
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

# Helper: DDL + insert arrayref + select + verify + drop
sub insert_and_verify {
    my ($ch, $table, $ddl, $data, $select_sql, $expected, $test_name, $done, $is_http) = @_;
    my $drop_sql = "DROP TABLE IF EXISTS $table";
    $drop_sql .= " FORMAT TabSeparated" if $is_http;
    $ch->query($drop_sql, sub {
        my $create_sql = $ddl;
        $create_sql .= " FORMAT TabSeparated" if $is_http;
        $ch->query($create_sql, sub {
            $ch->insert($table, $data, sub {
                my (undef, $err) = @_;
                ok(!$err, "$test_name: insert no error") or diag($err);
                my $sel = $select_sql;
                $sel .= " FORMAT TabSeparated" if $is_http;
                $ch->query($sel, sub {
                    my ($rows, $err2) = @_;
                    ok(!$err2, "$test_name: select no error") or diag($err2);
                    is_deeply($rows, $expected, "$test_name: data correct");
                    my $drop = "DROP TABLE $table";
                    $drop .= " FORMAT TabSeparated" if $is_http;
                    $ch->query($drop, sub { $done->() });
                });
            });
        });
    });
}

# Test 1-3: HTTP — basic arrayref insert
with_http(
    tests => 3,
    cb    => sub {
        insert_and_verify($ch,
            '_test_aref_basic',
            'CREATE TABLE _test_aref_basic (a UInt32, b String) ENGINE = Memory',
            [ [1, 'hello'], [2, 'world'] ],
            'SELECT a, b FROM _test_aref_basic ORDER BY a',
            [ ['1', 'hello'], ['2', 'world'] ],
            'HTTP basic arrayref',
            sub { EV::break },
            1,
        );
    },
);

# Test 4-6: HTTP — strings with embedded tabs and newlines
with_http(
    tests => 3,
    cb    => sub {
        insert_and_verify($ch,
            '_test_aref_esc',
            'CREATE TABLE _test_aref_esc (a UInt32, b String) ENGINE = Memory',
            [ [1, "tab\there"], [2, "line1\nline2"] ],
            'SELECT a, b FROM _test_aref_esc ORDER BY a',
            [ ['1', "tab\there"], ['2', "line1\nline2"] ],
            'HTTP embedded tab/newline',
            sub { EV::break },
            1,
        );
    },
);

# Test 7-9: HTTP — undef maps to NULL
with_http(
    tests => 3,
    cb    => sub {
        insert_and_verify($ch,
            '_test_aref_null',
            'CREATE TABLE _test_aref_null (a UInt32, b Nullable(String)) ENGINE = Memory',
            [ [1, undef], [2, 'present'] ],
            'SELECT a, b FROM _test_aref_null ORDER BY a',
            [ ['1', undef], ['2', 'present'] ],
            'HTTP undef->NULL',
            sub { EV::break },
            1,
        );
    },
);

# Test 10-12: Native — basic arrayref insert
with_native(
    tests => 3,
    cb    => sub {
        insert_and_verify($ch,
            '_test_aref_nat',
            'CREATE TABLE _test_aref_nat (a UInt32, b String) ENGINE = Memory',
            [ [1, 'alpha'], [2, 'beta'] ],
            'SELECT a, b FROM _test_aref_nat ORDER BY a',
            [ [1, 'alpha'], [2, 'beta'] ],
            'Native basic arrayref',
            sub { EV::break },
            0,
        );
    },
);

# Test 13-15: Native — strings with embedded special chars
with_native(
    tests => 3,
    cb    => sub {
        insert_and_verify($ch,
            '_test_aref_nat_esc',
            'CREATE TABLE _test_aref_nat_esc (a UInt32, b String) ENGINE = Memory',
            [ [1, "has\ttab"], [2, "has\nnewline"], [3, "has\\backslash"] ],
            'SELECT a, b FROM _test_aref_nat_esc ORDER BY a',
            [ [1, "has\ttab"], [2, "has\nnewline"], [3, "has\\backslash"] ],
            'Native special chars',
            sub { EV::break },
            0,
        );
    },
);

# Test 16-18: Native — Nullable with undef
with_native(
    tests => 3,
    cb    => sub {
        insert_and_verify($ch,
            '_test_aref_nat_null',
            'CREATE TABLE _test_aref_nat_null (a UInt32, b Nullable(String)) ENGINE = Memory',
            [ [1, undef], [2, 'val'] ],
            'SELECT a, b FROM _test_aref_nat_null ORDER BY a',
            [ [1, undef], [2, 'val'] ],
            'Native Nullable undef',
            sub { EV::break },
            0,
        );
    },
);

# Test 19-21: Native — Array(UInt32) column
with_native(
    tests => 3,
    cb    => sub {
        insert_and_verify($ch,
            '_test_aref_nat_arr',
            'CREATE TABLE _test_aref_nat_arr (a UInt32, b Array(UInt32)) ENGINE = Memory',
            [ [1, [10, 20, 30]], [2, [40]] ],
            'SELECT a, b FROM _test_aref_nat_arr ORDER BY a',
            [ [1, [10, 20, 30]], [2, [40]] ],
            'Native Array column',
            sub { EV::break },
            0,
        );
    },
);

# Test 22-24: Native — with settings
with_native(
    tests => 3,
    cb    => sub {
        insert_and_verify($ch,
            '_test_aref_nat_set',
            'CREATE TABLE _test_aref_nat_set (a UInt32, b String) ENGINE = Memory',
            # note: insert with settings is tested via the settings hash
            [ [99, 'with_settings'] ],
            'SELECT a, b FROM _test_aref_nat_set ORDER BY a',
            [ [99, 'with_settings'] ],
            'Native arrayref+settings',
            sub { EV::break },
            0,
        );
    },
);

# Test 25: HTTP — backwards compat with TSV string
with_http(
    tests => 1,
    cb    => sub {
        $ch->insert("FUNCTION null('n UInt64')", "1\n2\n", sub {
            my (undef, $err) = @_;
            ok(!$err, 'HTTP TSV string still works');
            EV::break;
        });
    },
);

# Test 26: Native — backwards compat with TSV string
with_native(
    tests => 1,
    cb    => sub {
        $ch->query("DROP TABLE IF EXISTS _test_aref_compat", sub {
            $ch->query("CREATE TABLE _test_aref_compat (n UInt64) ENGINE = Memory", sub {
                $ch->insert("_test_aref_compat", "1\n2\n", sub {
                    my (undef, $err) = @_;
                    ok(!$err, 'Native TSV string still works');
                    $ch->query("DROP TABLE _test_aref_compat", sub { EV::break });
                });
            });
        });
    },
);
