use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestMariaDB;
plan skip_all => 'No MariaDB/MySQL server' unless TestMariaDB::server_available();
plan tests => 33;
use EV;
use EV::MariaDB;

my $m;

sub with_mariadb {
    my (%args) = @_;
    my $cb = delete $args{cb};
    $m = EV::MariaDB->new(
        TestMariaDB::connect_args(),
        on_connect => sub { $cb->() },
        on_error   => sub {
            diag("Error: $_[0]");
            EV::break;
        },
        %args,
    );
    my $timeout = EV::timer(10, 0, sub { diag("timeout"); EV::break });
    EV::run;
    $m->finish if $m && $m->is_connected;
}

# --- Test 1-3: column metadata from text query ---
with_mariadb(cb => sub {
    $m->q("select 1 as foo, 'bar' as baz", sub {
        my ($rows, $err, $fields) = @_;
        ok(!$err, 'fields: query ok');
        is_deeply($fields, ['foo', 'baz'],
                  'fields: correct column names');
        is($rows->[0][0], '1', 'fields: data intact');
        EV::break;
    });
});

# --- Test 4-6: column metadata from prepared statement ---
with_mariadb(cb => sub {
    $m->prepare("select 1 as col_a, 2 as col_b", sub {
        my ($stmt, $err) = @_;
        ok(!$err, 'stmt fields: prepare ok');
        $m->execute($stmt, [], sub {
            my ($rows, $err2, $fields) = @_;
            ok(!$err2, 'stmt fields: execute ok');
            is_deeply($fields, ['col_a', 'col_b'],
                      'stmt fields: correct column names');
            $m->close_stmt($stmt, sub { EV::break });
        });
    });
});

# --- Test 7: DML has no fields (backwards-compatible) ---
with_mariadb(cb => sub {
    $m->q("DO 1", sub {
        my ($result, $err, $fields) = @_;
        ok(!defined $fields, 'DML: no fields arg');
        EV::break;
    });
});

# --- Test 8-9: set_charset ---
with_mariadb(cb => sub {
    $m->set_charset("utf8mb4", sub {
        my ($ok, $err) = @_;
        ok(!$err && $ok, 'set_charset: success');
        my $cs = $m->character_set_name;
        is($cs, 'utf8mb4', 'set_charset: charset changed');
        EV::break;
    });
});

# --- Test 10-13: commit/rollback/autocommit ---
with_mariadb(cb => sub {
    $m->autocommit(0, sub {
        my ($ok, $err) = @_;
        ok(!$err && $ok, 'autocommit(0): success');
        $m->q("create temporary table _txn_test (id int)", sub {
            die $_[1] if $_[1];
            $m->q("insert into _txn_test values (1)", sub {
                die $_[1] if $_[1];
                $m->rollback(sub {
                    my ($ok2, $err2) = @_;
                    ok(!$err2 && $ok2, 'rollback: success');
                    $m->q("select count(*) from _txn_test", sub {
                        my ($rows, $err3) = @_;
                        is($rows->[0][0], '0',
                           'rollback: insert was rolled back');
                        $m->q("insert into _txn_test values (2)", sub {
                            die $_[1] if $_[1];
                            $m->commit(sub {
                                my ($ok3, $err4) = @_;
                                ok(!$err4 && $ok3, 'commit: success');
                                EV::break;
                            });
                        });
                    });
                });
            });
        });
    });
});

# --- Test 14-18: query_stream ---
with_mariadb(cb => sub {
    my @stream_rows;
    $m->query_stream("select 1 as x union all select 2 union all select 3", sub {
        my ($row, $err) = @_;
        if ($err) {
            fail("stream: unexpected error: $err");
            EV::break;
            return;
        }
        if (!defined $row) {
            ok(!defined $err, 'stream: EOF has no error');
            is(scalar @stream_rows, 3, 'stream: got 3 rows');
            is($stream_rows[0][0], '1', 'stream: row 0');
            is($stream_rows[1][0], '2', 'stream: row 1');
            is($stream_rows[2][0], '3', 'stream: row 2');
            EV::break;
            return;
        }
        push @stream_rows, $row;
    });
});

# --- Test 19-20: query_stream with larger result set ---
with_mariadb(cb => sub {
    $m->q("create temporary table _stream_t (v int)", sub {
        die $_[1] if $_[1];
        my $sql = "insert into _stream_t values " .
                  join(",", map { "($_)" } 1..100);
        $m->q($sql, sub {
            die $_[1] if $_[1];
            my $count = 0;
            $m->query_stream("select v from _stream_t order by v", sub {
                my ($row, $err) = @_;
                if ($err) {
                    fail("stream 100: error: $err");
                    EV::break;
                    return;
                }
                if (!defined $row) {
                    is($count, 100, 'stream 100: got all rows');
                    # verify can run normal query after stream
                    $m->q("select 42", sub {
                        my ($r, $e) = @_;
                        ok(!$e && $r->[0][0] == 42,
                           'stream 100: query after stream works');
                        EV::break;
                    });
                    return;
                }
                $count++;
            });
        });
    });
});

# --- Test 21-22: close_async ---
{
    my ($close_ok, $disconnected);
    $m = EV::MariaDB->new(
        TestMariaDB::connect_args(),
        on_connect => sub {
            $m->close_async(sub {
                my ($ok, $err) = @_;
                $close_ok = !$err && $ok;
                $disconnected = !$m->is_connected;
                EV::break;
            });
        },
        on_error => sub { diag("Error: $_[0]"); EV::break },
    );
    my $timeout = EV::timer(10, 0, sub { diag("timeout"); EV::break });
    EV::run;
    ok($close_ok, 'close_async: completed ok');
    ok($disconnected, 'close_async: is_connected false after');
}

# --- Test 23-25: send_long_data ---
with_mariadb(cb => sub {
    $m->q("create temporary table _blob_t (id int, data blob)", sub {
        die $_[1] if $_[1];
        $m->prepare("insert into _blob_t values (?, ?)", sub {
            my ($stmt, $err) = @_;
            ok(!$err, 'send_long_data: prepare ok');
            # bind params first (required before send_long_data)
            $m->bind_params($stmt, [1, ""]);
            my $blob = "x" x 10000;
            $m->send_long_data($stmt, 1, $blob, sub {
                my ($ok, $err2) = @_;
                ok(!$err2 && $ok, 'send_long_data: send ok');
                # execute with undef to skip re-binding (uses long data)
                $m->execute($stmt, undef, sub {
                    my ($affected, $err3) = @_;
                    ok(!$err3, 'send_long_data: execute ok');
                    $m->close_stmt($stmt, sub { EV::break });
                });
            });
        });
    });
});

# --- Test 26-28: query after utility ops (set_charset queues query, ordering) ---
with_mariadb(cb => sub {
    my $charset_done = 0;
    $m->set_charset("latin1", sub {
        my ($ok, $err) = @_;
        ok(!$err, 'set_charset latin1: ok');
        $charset_done = 1;
    });
    $m->q("select 'queued'", sub {
        my ($rows, $err) = @_;
        ok($charset_done, 'query ran after set_charset completed');
        ok(!$err && $rows->[0][0] eq 'queued',
           'query queued during set_charset works');
        EV::break;
    });
});

# --- Test 29: stream + finish from inside row callback ---
with_mariadb(cb => sub {
    $m->query_stream("select 1 union all select 2 union all select 3", sub {
        my ($row, $err) = @_;
        if ($err) {
            EV::break;
            return;
        }
        if (defined $row && $row->[0] eq '1') {
            $m->finish;
            return;
        }
        if (!defined $row) {
            EV::break;
            return;
        }
    });
    ok(1, 'stream+finish: survived finish from row callback');
});

# --- Test 30: close_async on non-connected object ---
{
    my $obj = EV::MariaDB->new(on_error => sub {});
    eval { $obj->close_async(sub {}) };
    like($@, qr/not connected/, 'close_async: croaks when not connected');
}

# --- Test 31-33: stream error for bad SQL + send_long_data error path ---
with_mariadb(cb => sub {
    $m->query_stream("INVALID SQL HERE", sub {
        my ($row, $err) = @_;
        ok($err, 'stream error: got error for bad SQL');
        EV::break;
    });
});

# send_long_data with wrong param_idx (error path)
with_mariadb(cb => sub {
    $m->prepare("select ?", sub {
        my ($stmt, $err) = @_;
        ok(!$err, 'send_long_data error: prepare ok');
        $m->bind_params($stmt, [""]);
        $m->send_long_data($stmt, 99, "data", sub {
            my ($ok, $err2) = @_;
            ok($err2, 'send_long_data error: bad param_idx got error');
            $m->close_stmt($stmt, sub { EV::break });
        });
    });
});
