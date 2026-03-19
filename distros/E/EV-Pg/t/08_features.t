use strict;
use warnings;
use Test::More;
use EV;
use EV::Pg qw(:verbosity :context :trace);
use lib 't';
use TestHelper;

require_pg;
use File::Temp 'tmpnam';
plan tests => 116;

# notice handler
with_pg(
    on_notice => sub {
        my ($msg) = @_;
        like($msg, qr/hello from notice/, 'on_notice received RAISE NOTICE');
    },
    cb => sub {
        my ($pg) = @_;
        $pg->query("do \$\$ begin raise notice 'hello from notice'; end \$\$", sub {
            my ($data, $err) = @_;
            ok(!$err, 'notice: query completed');
            EV::break;
        });
    },
);

# cancel
{
    my $cancel_timer;
    with_pg(cb => sub {
        my ($pg) = @_;
        $pg->query("select pg_sleep(30)", sub {
            my ($data, $err) = @_;
            ok($err, 'cancel: query received error');
            undef $cancel_timer;
            EV::break;
        });
        $cancel_timer = EV::timer(0.5, 0, sub {
            my $cancel_err = $pg->cancel;
            ok(!defined $cancel_err, 'cancel: PQcancel succeeded');
        });
    });
}

# COPY IN
with_pg(cb => sub {
    my ($pg) = @_;
    $pg->query("create temp table copy_test (id int, name text)", sub {
        my ($data, $err) = @_;
        ok(!$err, 'copy_in: created table');

        $pg->query("copy copy_test from stdin", sub {
            my ($data, $err) = @_;
            if (($data // '') eq 'COPY_IN') {
                is($data, 'COPY_IN', 'copy_in: got COPY_IN');
                $pg->put_copy_data("1\tAlice\n");
                $pg->put_copy_data("2\tBob\n");
                $pg->put_copy_end;
                return;
            }
            ok(!$err, 'copy_in: completed without error');
            ok(defined $data, 'copy_in: got cmd_tuples');
            EV::break;
        });
    });
});

# escape_bytea / unescape_bytea round-trip
with_pg(cb => sub {
    my ($pg) = @_;
    my $binary = "\x00\x01\xff\xfe binary data";
    my $escaped = $pg->escape_bytea($binary);
    ok(defined $escaped, 'escape_bytea returns value');
    my $unescaped = EV::Pg->unescape_bytea($escaped);
    is($unescaped, $binary, 'bytea round-trip preserves data');
    EV::break;
});

# client_encoding
with_pg(cb => sub {
    my ($pg) = @_;
    my $enc = $pg->client_encoding;
    ok(defined $enc && length($enc) > 0, "client_encoding: $enc");
    EV::break;
});

# single row mode
with_pg(cb => sub {
    my ($pg) = @_;
    my @rows;
    $pg->query("select generate_series(1,3) as n", sub {
        my ($data, $err) = @_;
        if (ref $data eq 'ARRAY' && @$data > 0) {
            push @rows, $data->[0][0];
            return;
        }
        # Final TUPLES_OK with 0 rows
        is(scalar @rows, 3, 'single_row: got 3 rows');
        is_deeply(\@rows, ['1', '2', '3'], 'single_row: correct values');
        is(ref $data, 'ARRAY', 'single_row: final is arrayref');
        is(scalar @$data, 0, 'single_row: final has 0 tuples');
        EV::break;
    });
    $pg->set_single_row_mode;
});

# set_single_row_mode returns 0 when no query pending
with_pg(cb => sub {
    my ($pg) = @_;
    is($pg->set_single_row_mode, 0, 'set_single_row_mode: 0 without pending query');
    EV::break;
});

# single row mode: abort via skip_pending after first row
with_pg(cb => sub {
    my ($pg) = @_;
    my @rows;
    $pg->query("select generate_series(1,10) as n", sub {
        my ($data, $err) = @_;
        if (ref $data eq 'ARRAY' && @$data > 0) {
            push @rows, $data->[0][0];
            $pg->skip_pending;
            # defer followup to next iteration so orphan results drain
            my $t; $t = EV::timer(0, 0, sub {
                undef $t;
                $pg->query("select 'after_skip'", sub {
                    my ($d, $e) = @_;
                    is(scalar @rows, 1, 'single_row skip: only 1 row before abort');
                    is($rows[0], '1', 'single_row skip: first row value');
                    ok(!$e, 'single_row skip: followup query ok');
                    is($d->[0][0], 'after_skip', 'single_row skip: followup result');
                    EV::break;
                });
            });
            return;
        }
    });
    $pg->set_single_row_mode;
});

# single row mode: abort via finish after first row
{
    my $pg;
    my @rows;
    my $cb_after_finish = 0;
    $pg = EV::Pg->new(
        conninfo => $conninfo,
        on_connect => sub {
            $pg->query("select generate_series(1,100) as n", sub {
                my ($data, $err) = @_;
                if (ref $data eq 'ARRAY' && @$data > 0) {
                    push @rows, $data->[0][0];
                    $pg->finish;
                    return;
                }
                $cb_after_finish++;
            });
            $pg->set_single_row_mode;
        },
        on_error => sub { diag "Error: $_[0]"; EV::break },
    );
    my $t = EV::timer(3, 0, sub { EV::break });
    EV::run;
    is(scalar @rows, 1, 'single_row finish: got only 1 row before abort');
    is($cb_after_finish, 0, 'single_row finish: no callback after finish');
}

# single row mode: abort via reset after first row
{
    my $pg;
    my @rows;
    my $reconnected = 0;
    my $followup_ok = 0;
    $pg = EV::Pg->new(
        conninfo => $conninfo,
        on_connect => sub {
            if ($reconnected) {
                $pg->query("select 'after_reset'", sub {
                    my ($data, $err) = @_;
                    ok(!$err, 'single_row reset: followup query ok');
                    is($data->[0][0], 'after_reset', 'single_row reset: followup result');
                    $followup_ok = 1;
                    EV::break;
                });
                return;
            }
            $pg->query("select generate_series(1,100) as n", sub {
                my ($data, $err) = @_;
                if (ref $data eq 'ARRAY' && @$data > 0) {
                    push @rows, $data->[0][0];
                    $reconnected = 1;
                    $pg->reset;
                    return;
                }
            });
            $pg->set_single_row_mode;
        },
        on_error => sub { diag "Error: $_[0]"; EV::break },
    );
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    is(scalar @rows, 1, 'single_row reset: got only 1 row before abort');
    ok($reconnected, 'single_row reset: reconnected');
    ok($followup_ok, 'single_row reset: post-reconnect query succeeded');
}

# single row mode: DESTROY during single-row streaming
{
    my @rows;
    my $destroyed = 0;
    my $pg;
    $pg = EV::Pg->new(
        conninfo => $conninfo,
        on_connect => sub {
            $pg->query("select generate_series(1,100) as n", sub {
                my ($data, $err) = @_;
                if (ref $data eq 'ARRAY' && @$data > 0) {
                    push @rows, $data->[0][0];
                    undef $pg;  # triggers DESTROY
                    $destroyed = 1;
                    EV::break;
                    return;
                }
            });
            $pg->set_single_row_mode;
        },
        on_error => sub { diag "Error: $_[0]"; EV::break },
    );
    my $t = EV::timer(3, 0, sub { EV::break });
    EV::run;
    is(scalar @rows, 1, 'single_row destroy: got only 1 row');
    ok($destroyed, 'single_row destroy: DESTROY did not crash');
}

# ssl_attribute (may return undef if not using SSL)
with_pg(cb => sub {
    my ($pg) = @_;
    my $lib = $pg->ssl_attribute("library");
    ok(1, 'ssl_attribute: did not crash');
    EV::break;
});

# set_error_verbosity
with_pg(cb => sub {
    my ($pg) = @_;
    my $prev = $pg->set_error_verbosity(PQERRORS_VERBOSE);
    is($prev, PQERRORS_DEFAULT, 'set_error_verbosity: was DEFAULT');
    my $prev2 = $pg->set_error_verbosity(PQERRORS_DEFAULT);
    is($prev2, PQERRORS_VERBOSE, 'set_error_verbosity: was VERBOSE');
    EV::break;
});

# cancel_async (libpq >= 17)
SKIP: {
    skip 'requires libpq >= 17', 2 unless EV::Pg->lib_version >= 170000;
    my $cancel_timer;
    my ($got_query_err, $got_cancel_ok);
    with_pg(cb => sub {
        my ($pg) = @_;
        $pg->query("select pg_sleep(30)", sub {
            my ($data, $err) = @_;
            ok($err, 'cancel_async: query received error');
            $got_query_err = 1;
            EV::break if $got_cancel_ok;
        });
        $cancel_timer = EV::timer(0.5, 0, sub {
            $pg->cancel_async(sub {
                my ($err) = @_;
                ok(!defined $err, 'cancel_async: no error');
                $got_cancel_ok = 1;
                undef $cancel_timer;
                EV::break if $got_query_err;
            });
        });
    });
}

# cancel_async when not connected
SKIP: {
    skip 'requires libpq >= 17', 1 unless EV::Pg->lib_version >= 170000;
    my $pg = EV::Pg->new(on_error => sub {});
    eval { $pg->cancel_async(sub {}) };
    like($@, qr/not connected/, 'cancel_async when disconnected croaks');
}

# cancel_async double cancel
SKIP: {
    skip 'requires libpq >= 17', 3 unless EV::Pg->lib_version >= 170000;
    my $cancel_timer;
    my ($got_query_err, $got_cancel_ok);
    with_pg(cb => sub {
        my ($pg) = @_;
        $pg->query("select pg_sleep(30)", sub {
            my ($data, $err) = @_;
            ok($err, 'cancel_async double: query received error');
            $got_query_err = 1;
            EV::break if $got_cancel_ok;
        });
        $cancel_timer = EV::timer(0.5, 0, sub {
            $pg->cancel_async(sub {
                my ($err) = @_;
                ok(!defined $err, 'cancel_async double: first cancel ok');
                $got_cancel_ok = 1;
                undef $cancel_timer;
                EV::break if $got_query_err;
            });
            eval { $pg->cancel_async(sub {}) };
            like($@, qr/cancel already in progress/,
                 'cancel_async double: second cancel croaks');
        });
    });
}

# --- error_fields ---
with_pg(cb => sub {
    my ($pg) = @_;
    ok(!defined $pg->error_fields, 'error_fields: undef before any error');
    $pg->query("select no_such_column from nonexistent_table", sub {
        my ($data, $err) = @_;
        ok($err, 'error_fields: got error');
        my $f = $pg->error_fields;
        is(ref $f, 'HASH', 'error_fields: returns hashref');
        is($f->{sqlstate}, '42P01', 'error_fields: sqlstate is 42P01 (undefined table)');
        ok($f->{severity}, 'error_fields: severity present');
        ok($f->{primary}, 'error_fields: primary message present');
        EV::break;
    });
});

# error_fields: unique violation with constraint name
with_pg(cb => sub {
    my ($pg) = @_;
    $pg->query("create temp table ef_test (id int primary key)", sub {
        $pg->query("insert into ef_test values (1)", sub {
            $pg->query("insert into ef_test values (1)", sub {
                my ($data, $err) = @_;
                ok($err, 'error_fields uv: got error');
                my $f = $pg->error_fields;
                is($f->{sqlstate}, '23505', 'error_fields uv: sqlstate 23505');
                ok($f->{detail}, 'error_fields uv: detail present');
                ok($f->{constraint}, 'error_fields uv: constraint name present');
                EV::break;
            });
        });
    });
});

# error_fields in pipeline mode
with_pg(cb => sub {
    my ($pg) = @_;
    $pg->enter_pipeline;
    $pg->query_params("select no_such_col from nonexistent", [], sub {
        my ($data, $err) = @_;
        ok($err, 'error_fields pipeline: got error');
        my $f = $pg->error_fields;
        is(ref $f, 'HASH', 'error_fields pipeline: hashref');
        is($f->{sqlstate}, '42P01', 'error_fields pipeline: sqlstate');
    });
    $pg->pipeline_sync(sub {
        $pg->exit_pipeline;
        EV::break;
    });
});

# --- result_meta ---
with_pg(cb => sub {
    my ($pg) = @_;
    ok(!defined $pg->result_meta, 'result_meta: undef before any query');
    $pg->query("select 1 as col_a, 'hello' as col_b", sub {
        my ($data, $err) = @_;
        ok(!$err, 'result_meta: no error');
        my $m = $pg->result_meta;
        is(ref $m, 'HASH', 'result_meta: returns hashref');
        is($m->{nfields}, 2, 'result_meta: nfields = 2');
        like($m->{cmd_status}, qr/SELECT/, 'result_meta: cmd_status contains SELECT');
        is(ref $m->{fields}, 'ARRAY', 'result_meta: fields is arrayref');
        is($m->{fields}[0]{name}, 'col_a', 'result_meta: field 0 name');
        is($m->{fields}[1]{name}, 'col_b', 'result_meta: field 1 name');
        ok(defined $m->{fields}[0]{type}, 'result_meta: field 0 has type OID');
        EV::break;
    });
});

# result_meta after INSERT
with_pg(cb => sub {
    my ($pg) = @_;
    $pg->query("create temp table rm_test (id int)", sub {
        $pg->query("insert into rm_test values (1), (2)", sub {
            my ($data, $err) = @_;
            ok(!$err, 'result_meta insert: no error');
            my $m = $pg->result_meta;
            like($m->{cmd_status}, qr/INSERT/, 'result_meta insert: cmd_status');
            EV::break;
        });
    });
});

# result_meta during single-row mode
with_pg(cb => sub {
    my ($pg) = @_;
    my $meta_seen = 0;
    $pg->query("select 42 as val, 'x' as tag", sub {
        my ($data, $err) = @_;
        if (ref $data eq 'ARRAY' && @$data > 0) {
            my $m = $pg->result_meta;
            is(ref $m, 'HASH', 'result_meta single_row: hashref during streaming');
            is($m->{nfields}, 2, 'result_meta single_row: nfields = 2');
            is($m->{fields}[0]{name}, 'val', 'result_meta single_row: field 0 name');
            $meta_seen = 1;
            return;
        }
        ok($meta_seen, 'result_meta single_row: meta was available during streaming');
        EV::break;
    });
    $pg->set_single_row_mode;
});

# --- set_chunked_rows_mode (libpq >= 17) ---
SKIP: {
    skip 'requires libpq >= 17', 3 unless EV::Pg->lib_version >= 170000;
    with_pg(cb => sub {
        my ($pg) = @_;
        my @chunks;
        $pg->query("select generate_series(1,10) as n", sub {
            my ($data, $err) = @_;
            if (ref $data eq 'ARRAY' && @$data > 0) {
                push @chunks, scalar @$data;
                return;
            }
            ok(scalar @chunks >= 1, 'chunked_rows: got at least 1 chunk');
            my $total = 0;
            $total += $_ for @chunks;
            is($total, 10, 'chunked_rows: total 10 rows');
            ok(!$err, 'chunked_rows: no error');
            EV::break;
        });
        $pg->set_chunked_rows_mode(3);
    });
}

# --- close_prepared (libpq >= 17) ---
SKIP: {
    skip 'requires libpq >= 17', 2 unless EV::Pg->lib_version >= 170000;
    with_pg(cb => sub {
        my ($pg) = @_;
        $pg->prepare("cp_test", "select 1", sub {
            my ($r, $e) = @_;
            ok(!$e, 'close_prepared: prepared ok');
            $pg->close_prepared("cp_test", sub {
                my ($r2, $e2) = @_;
                ok(!$e2, 'close_prepared: closed ok');
                EV::break;
            });
        });
    });
}

# --- close_portal (libpq >= 17) ---
SKIP: {
    skip 'requires libpq >= 17', 2 unless EV::Pg->lib_version >= 170000;
    with_pg(cb => sub {
        my ($pg) = @_;
        # Use a cursor to create a named portal, then close it
        $pg->query("begin", sub {
            $pg->query("declare test_portal cursor for select generate_series(1,5)", sub {
                my ($r, $e) = @_;
                ok(!$e, 'close_portal: declared cursor');
                $pg->close_portal("test_portal", sub {
                    my ($r2, $e2) = @_;
                    ok(!$e2, 'close_portal: closed ok');
                    $pg->query("end", sub { EV::break });
                });
            });
        });
    });
}

# --- send_pipeline_sync (libpq >= 17) ---
SKIP: {
    skip 'requires libpq >= 17', 2 unless EV::Pg->lib_version >= 170000;
    with_pg(cb => sub {
        my ($pg) = @_;
        $pg->enter_pipeline;
        $pg->query_params("select 1", [], sub {
            my ($data, $err) = @_;
            ok(!$err, 'send_pipeline_sync: query ok');
        });
        $pg->send_pipeline_sync(sub {
            my ($ok) = @_;
            ok($ok, 'send_pipeline_sync: sync ok');
            $pg->exit_pipeline;
            EV::break;
        });
        $pg->send_flush_request;
    });
}

# --- set_error_context_visibility ---
with_pg(cb => sub {
    my ($pg) = @_;
    my $prev = $pg->set_error_context_visibility(PQSHOW_CONTEXT_ALWAYS);
    is($prev, PQSHOW_CONTEXT_ERRORS, 'set_error_context_visibility: was ERRORS');
    my $prev2 = $pg->set_error_context_visibility(PQSHOW_CONTEXT_ERRORS);
    is($prev2, PQSHOW_CONTEXT_ALWAYS, 'set_error_context_visibility: was ALWAYS');
    EV::break;
});

# --- conninfo ---
with_pg(cb => sub {
    my ($pg) = @_;
    my $info = $pg->conninfo;
    is(ref $info, 'HASH', 'conninfo: returns hashref');
    ok(exists $info->{dbname}, 'conninfo: has dbname key');
    EV::break;
});

# --- connection_used_password / connection_used_gssapi ---
with_pg(cb => sub {
    my ($pg) = @_;
    my $used = $pg->connection_used_password;
    ok(defined $used, "connection_used_password: $used");
    my $gss = $pg->connection_used_gssapi;
    ok(defined $gss, "connection_used_gssapi: $gss");
    EV::break;
});

# --- trace / untrace ---
{
    my $trace_file = tmpnam();
    with_pg(cb => sub {
        my ($pg) = @_;
        $pg->trace($trace_file);
        $pg->query("select 'trace_test'", sub {
            my ($data, $err) = @_;
            ok(!$err, 'trace: query ok');
            $pg->untrace;
            ok(-s $trace_file, 'trace: file has content');
            unlink $trace_file;
            EV::break;
        });
    });
}

# --- set_trace_flags ---
with_pg(cb => sub {
    my ($pg) = @_;
    my $trace_file = tmpnam();
    $pg->trace($trace_file);
    $pg->set_trace_flags(PQTRACE_SUPPRESS_TIMESTAMPS);
    $pg->query("select 1", sub {
        $pg->untrace;
        ok(-s $trace_file, 'set_trace_flags: trace file has content');
        unlink $trace_file;
        EV::break;
    });
});

# --- connection_needs_password ---
with_pg(cb => sub {
    my ($pg) = @_;
    is($pg->connection_needs_password, 0, 'connection_needs_password: 0 for local');
    EV::break;
});

# --- hostaddr ---
with_pg(cb => sub {
    my ($pg) = @_;
    ok(defined $pg->hostaddr, 'hostaddr: returns value');
    EV::break;
});

# --- ssl_attribute_names ---
with_pg(cb => sub {
    my ($pg) = @_;
    my $names = $pg->ssl_attribute_names;
    if (defined $names) {
        is(ref $names, 'ARRAY', 'ssl_attribute_names: returns arrayref');
    } else {
        pass('ssl_attribute_names: undef (no SSL)');
    }
    EV::break;
});

# --- protocol_version ---
with_pg(cb => sub {
    my ($pg) = @_;
    ok($pg->protocol_version >= 3, 'protocol_version: >= 3');
    EV::break;
});

# --- encrypt_password ---
with_pg(cb => sub {
    my ($pg) = @_;
    my $enc = $pg->encrypt_password('testpass', 'testuser');
    ok(defined $enc && length($enc) > 0, 'encrypt_password: returns non-empty string');
    like($enc, qr/^(SCRAM-SHA-256\$|md5)/, 'encrypt_password: valid format');
    EV::break;
});

# --- encrypt_password with explicit algorithm ---
with_pg(cb => sub {
    my ($pg) = @_;
    my $enc = $pg->encrypt_password('testpass', 'testuser', 'md5');
    like($enc, qr/^md5/, 'encrypt_password(md5): md5 format');
    EV::break;
});

# --- result_meta inserted_oid ---
with_pg(cb => sub {
    my ($pg) = @_;
    # normal insert should not have inserted_oid (no OID tables in modern PG)
    $pg->query("create temp table oid_test (id int)", sub {
        my (undef, $err) = @_;
        ok(!$err, 'inserted_oid: created table');
        $pg->query("insert into oid_test values (1)", sub {
            my (undef, $err2) = @_;
            ok(!$err2, 'inserted_oid: inserted row');
            my $meta = $pg->result_meta;
            ok(!exists $meta->{inserted_oid}, 'inserted_oid: absent for normal table');
            EV::break;
        });
    });
});

# --- connect_params ---
{
    my $params = EV::Pg->conninfo_parse($conninfo);
    my $done;
    my $pg;
    $pg = EV::Pg->new(
        conninfo_params => $params,
        on_connect => sub {
            $pg->query("select 1 as val", sub {
                my ($rows, $err) = @_;
                ok(!$err, 'connect_params: query ok');
                is($rows->[0][0], '1', 'connect_params: got correct result');
                $done = 1;
                EV::break;
            });
        },
        on_error => sub { diag "Error: $_[0]"; EV::break },
    );
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    ok($done, 'connect_params: connected and queried');
    $pg->finish if $pg && $pg->is_connected;
}

# --- connect_params reset ---
{
    my $params = EV::Pg->conninfo_parse($conninfo);
    my $reset_done;
    my $pg;
    $pg = EV::Pg->new(
        conninfo_params => $params,
        on_error => sub { diag "Error: $_[0]"; EV::break },
    );
    $pg->on_connect(sub {
        if (!$reset_done) {
            $reset_done = 1;
            $pg->on_connect(sub {
                $pg->query("select 1", sub {
                    my ($rows, $err) = @_;
                    ok(!$err, 'connect_params reset: query after reset ok');
                    is($rows->[0][0], '1', 'connect_params reset: correct result');
                    EV::break;
                });
            });
            $pg->reset;
            return;
        }
    });
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    ok($reset_done, 'connect_params reset: reset completed');
    $pg->finish if $pg && $pg->is_connected;
}

# --- conninfo_parse ---
{
    my $params = EV::Pg->conninfo_parse('host=localhost dbname=testdb port=5433');
    is(ref $params, 'HASH', 'conninfo_parse: returns hashref');
    is($params->{host}, 'localhost', 'conninfo_parse: host');
    is($params->{dbname}, 'testdb', 'conninfo_parse: dbname');
    is($params->{port}, '5433', 'conninfo_parse: port');
}

# --- conninfo_parse with URI ---
{
    my $params = EV::Pg->conninfo_parse('postgresql://user@host:5434/mydb');
    is(ref $params, 'HASH', 'conninfo_parse URI: returns hashref');
    is($params->{host}, 'host', 'conninfo_parse URI: host');
    is($params->{dbname}, 'mydb', 'conninfo_parse URI: dbname');
}

# --- disconnected accessor tests for new methods ---
{
    my $pg = EV::Pg->new(on_error => sub {});
    is($pg->connection_needs_password, 0, 'connection_needs_password: 0 when not connected');
    ok(!defined $pg->hostaddr, 'hostaddr: undef when not connected');
    ok(!defined $pg->ssl_attribute_names, 'ssl_attribute_names: undef when not connected');
    is($pg->protocol_version, 0, 'protocol_version: 0 when not connected');
}

# --- keep_alive ---
{
    my $pg = EV::Pg->new(on_error => sub {});
    is($pg->keep_alive, 0, 'keep_alive: default off');
    $pg->keep_alive(1);
    is($pg->keep_alive, 1, 'keep_alive: set on');
    $pg->keep_alive(0);
    is($pg->keep_alive, 0, 'keep_alive: set off');
}

# keep_alive via constructor
{
    my $notified;
    my $pg;
    $pg = EV::Pg->new(
        conninfo   => $conninfo,
        keep_alive => 1,
        on_notify  => sub {
            $notified = 1;
            EV::break;
        },
        on_connect => sub {
            is($pg->keep_alive, 1, 'keep_alive: set via constructor');
            $pg->query("listen ka_test", sub {
                $pg->query("notify ka_test", sub {});
            });
        },
        on_error => sub { diag "Error: $_[0]"; EV::break },
    );
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    ok($notified, 'keep_alive: notification received');
    $pg->finish if $pg && $pg->is_connected;
}
