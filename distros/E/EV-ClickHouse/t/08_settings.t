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

# Test 1-2: HTTP — connection-level setting via getSetting()
with_http(
    settings => { max_threads => 1 },
    tests    => 2,
    cb       => sub {
        $ch->query("SELECT value FROM system.settings WHERE name='max_threads' FORMAT TabSeparated", sub {
            my ($rows, $err) = @_;
            ok(!$err, 'HTTP conn setting: no error');
            is($rows->[0][0], '1', 'HTTP conn setting: max_threads=1');
            EV::break;
        });
    },
);

# Test 3-4: HTTP — per-query setting overrides connection default
with_http(
    settings => { max_threads => 4 },
    tests    => 2,
    cb       => sub {
        $ch->query(
            "SELECT value FROM system.settings WHERE name='max_threads' FORMAT TabSeparated",
            { max_threads => 2 },
            sub {
                my ($rows, $err) = @_;
                ok(!$err, 'HTTP per-query override: no error');
                is($rows->[0][0], '2', 'HTTP per-query override: max_threads=2');
                EV::break;
            },
        );
    },
);

# Test 5-6: HTTP — insert with settings
with_http(
    session_id => "settings_test_$$",
    tests      => 2,
    cb         => sub {
        $ch->query("DROP TABLE IF EXISTS _test_settings_insert", sub {
            $ch->query("CREATE TABLE _test_settings_insert (x UInt32) ENGINE = MergeTree ORDER BY x", sub {
                $ch->insert(
                    "_test_settings_insert", "42\n",
                    { max_threads => 1 },
                    sub {
                        my ($ok, $err) = @_;
                        ok(!$err, 'HTTP insert with settings: no error');
                        $ch->query("SELECT x FROM _test_settings_insert FORMAT TabSeparated", sub {
                            my ($rows, $err2) = @_;
                            is($rows->[0][0], '42', 'HTTP insert with settings: data correct');
                            $ch->query("DROP TABLE _test_settings_insert", sub { EV::break });
                        });
                    },
                );
            });
        });
    },
);

# Test 7-8: HTTP — query_id passthrough
with_http(
    tests => 2,
    cb    => sub {
        my $qid = "ev_ch_test_$$" . "_" . time();
        $ch->query(
            "SELECT 1 FORMAT TabSeparated",
            { query_id => $qid },
            sub {
                my ($rows, $err) = @_;
                ok(!$err, 'HTTP query_id: no error');
                ok(defined $rows, 'HTTP query_id: got result');
                EV::break;
            },
        );
    },
);

# Test 9-10: Native — connection-level setting
with_native(
    settings => { max_threads => 1 },
    tests    => 2,
    cb       => sub {
        $ch->query("SELECT value FROM system.settings WHERE name='max_threads'", sub {
            my ($rows, $err) = @_;
            ok(!$err, 'Native conn setting: no error');
            is($rows->[0][0], '1', 'Native conn setting: max_threads=1');
            EV::break;
        });
    },
);

# Test 11-12: Native — per-query setting overrides connection default
with_native(
    settings => { max_threads => 4 },
    tests    => 2,
    cb       => sub {
        $ch->query(
            "SELECT value FROM system.settings WHERE name='max_threads'",
            { max_threads => 2 },
            sub {
                my ($rows, $err) = @_;
                ok(!$err, 'Native per-query override: no error');
                is($rows->[0][0], '2', 'Native per-query override: max_threads=2');
                EV::break;
            },
        );
    },
);

# Test 13-14: Native — query_id passthrough
with_native(
    tests => 2,
    cb    => sub {
        my $qid = "ev_ch_native_$$" . "_" . time();
        $ch->query(
            "SELECT 1",
            { query_id => $qid },
            sub {
                my ($rows, $err) = @_;
                ok(!$err, 'Native query_id: no error');
                ok(defined $rows, 'Native query_id: got result');
                EV::break;
            },
        );
    },
);

# Test 15-16: Native — insert with settings
with_native(
    tests => 2,
    cb    => sub {
        $ch->query("DROP TABLE IF EXISTS _test_native_settings_ins", sub {
            $ch->query("CREATE TABLE _test_native_settings_ins (x UInt32) ENGINE = MergeTree ORDER BY x", sub {
                $ch->insert(
                    "_test_native_settings_ins", "7\n",
                    { max_threads => 1 },
                    sub {
                        my ($ok, $err) = @_;
                        ok(!$err, 'Native insert with settings: no error');
                        $ch->query("SELECT x FROM _test_native_settings_ins", sub {
                            my ($rows, $err2) = @_;
                            is($rows->[0][0], 7, 'Native insert with settings: data correct');
                            $ch->query("DROP TABLE _test_native_settings_ins", sub { EV::break });
                        });
                    },
                );
            });
        });
    },
);

# Test 17-18: HTTP — async_insert
with_http(
    session_id => "async_ins_http_$$",
    tests      => 2,
    cb         => sub {
        $ch->query("DROP TABLE IF EXISTS _test_async_ins", sub {
            $ch->query("CREATE TABLE _test_async_ins (x UInt32) ENGINE = MergeTree ORDER BY x", sub {
                $ch->insert(
                    "_test_async_ins", "1\n2\n3\n",
                    { async_insert => 1, wait_for_async_insert => 1 },
                    sub {
                        my ($ok, $err) = @_;
                        ok(!$err, 'HTTP async_insert: no error');
                        $ch->query("SELECT count() FROM _test_async_ins FORMAT TabSeparated", sub {
                            my ($rows, $err2) = @_;
                            is($rows->[0][0], '3', 'HTTP async_insert: 3 rows inserted');
                            $ch->query("DROP TABLE _test_async_ins", sub { EV::break });
                        });
                    },
                );
            });
        });
    },
);

# Test 19-20: Native — async_insert
with_native(
    tests => 2,
    cb    => sub {
        $ch->query("DROP TABLE IF EXISTS _test_async_ins_nat", sub {
            $ch->query("CREATE TABLE _test_async_ins_nat (x UInt32) ENGINE = MergeTree ORDER BY x", sub {
                $ch->insert(
                    "_test_async_ins_nat", "10\n20\n",
                    { async_insert => 1, wait_for_async_insert => 1 },
                    sub {
                        my ($ok, $err) = @_;
                        ok(!$err, 'Native async_insert: no error');
                        $ch->query("SELECT count() FROM _test_async_ins_nat", sub {
                            my ($rows, $err2) = @_;
                            is($rows->[0][0], 2, 'Native async_insert: 2 rows inserted');
                            $ch->query("DROP TABLE _test_async_ins_nat", sub { EV::break });
                        });
                    },
                );
            });
        });
    },
);

# Test 21: backwards compat
with_http(
    tests => 1,
    cb    => sub {
        $ch->query("SELECT 1 FORMAT TabSeparated", sub {
            my ($rows, $err) = @_;
            ok(!$err, 'backwards compat query: no error');
            EV::break;
        });
    },
);

# Test 22: error — non-hashref settings croaks
with_http(
    tests => 1,
    cb    => sub {
        my $ok = eval {
            $ch->query("SELECT 1 FORMAT TabSeparated", "not_a_hash", sub {});
            1;
        };
        ok(!$ok && $@ =~ /settings must be a HASH/i,
           'non-hashref settings: croaks');
        EV::break;
    },
);
