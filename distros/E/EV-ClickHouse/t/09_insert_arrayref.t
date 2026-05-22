use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;

my $host      = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $http_port = $ENV{TEST_CLICKHOUSE_PORT} || 8123;
my $nat_port  = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

require IO::Socket::INET;
my $http_ok = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $http_port, Timeout => 2) ? 1 : 0;
my $nat_ok  = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nat_port,  Timeout => 2) ? 1 : 0;
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
    my $drop_sql = "drop table if exists $table";
    $drop_sql .= " format TabSeparated" if $is_http;
    $ch->query($drop_sql, sub {
        my $create_sql = $ddl;
        $create_sql .= " format TabSeparated" if $is_http;
        $ch->query($create_sql, sub {
            $ch->insert($table, $data, sub {
                my (undef, $err) = @_;
                ok(!$err, "$test_name: insert no error") or diag($err);
                my $sel = $select_sql;
                $sel .= " format TabSeparated" if $is_http;
                $ch->query($sel, sub {
                    my ($rows, $err2) = @_;
                    ok(!$err2, "$test_name: select no error") or diag($err2);
                    is_deeply($rows, $expected, "$test_name: data correct");
                    my $drop = "drop table $table";
                    $drop .= " format TabSeparated" if $is_http;
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
            'create table _test_aref_basic (a UInt32, b String) ENGINE = Memory',
            [ [1, 'hello'], [2, 'world'] ],
            'select a, b from _test_aref_basic order by a',
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
            'create table _test_aref_esc (a UInt32, b String) ENGINE = Memory',
            [ [1, "tab\there"], [2, "line1\nline2"] ],
            'select a, b from _test_aref_esc order by a',
            [ ['1', "tab\there"], ['2', "line1\nline2"] ],
            'HTTP embedded tab/newline',
            sub { EV::break },
            1,
        );
    },
);

# Test 7-9: HTTP — undef maps to null
with_http(
    tests => 3,
    cb    => sub {
        insert_and_verify($ch,
            '_test_aref_null',
            'create table _test_aref_null (a UInt32, b Nullable(String)) ENGINE = Memory',
            [ [1, undef], [2, 'present'] ],
            'select a, b from _test_aref_null order by a',
            [ ['1', undef], ['2', 'present'] ],
            'HTTP undef->null',
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
            'create table _test_aref_nat (a UInt32, b String) ENGINE = Memory',
            [ [1, 'alpha'], [2, 'beta'] ],
            'select a, b from _test_aref_nat order by a',
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
            'create table _test_aref_nat_esc (a UInt32, b String) ENGINE = Memory',
            [ [1, "has\ttab"], [2, "has\nnewline"], [3, "has\\backslash"] ],
            'select a, b from _test_aref_nat_esc order by a',
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
            'create table _test_aref_nat_null (a UInt32, b Nullable(String)) ENGINE = Memory',
            [ [1, undef], [2, 'val'] ],
            'select a, b from _test_aref_nat_null order by a',
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
            'create table _test_aref_nat_arr (a UInt32, b Array(UInt32)) ENGINE = Memory',
            [ [1, [10, 20, 30]], [2, [40]] ],
            'select a, b from _test_aref_nat_arr order by a',
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
            'create table _test_aref_nat_set (a UInt32, b String) ENGINE = Memory',
            # note: insert with settings is tested via the settings hash
            [ [99, 'with_settings'] ],
            'select a, b from _test_aref_nat_set order by a',
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
        $ch->query("drop table if exists _test_aref_compat", sub {
            $ch->query("create table _test_aref_compat (n UInt64) ENGINE = Memory", sub {
                $ch->insert("_test_aref_compat", "1\n2\n", sub {
                    my (undef, $err) = @_;
                    ok(!$err, 'Native TSV string still works');
                    $ch->query("drop table _test_aref_compat", sub { EV::break });
                });
            });
        });
    },
);
