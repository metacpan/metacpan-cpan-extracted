use strict;
use warnings;
use Test::More;
use EV;
use EV::Pg;
use lib 't';
use TestHelper;

require_pg;
use Socket;
plan tests => 45;

# --- handler getter round-trip ---
with_pg(cb => sub {
    my ($pg) = @_;
    my $orig = sub { 1 };
    $pg->on_notify($orig);
    my $got = $pg->on_notify;
    is(ref $got, 'CODE', 'handler getter returns CODE ref');
    # getter must NOT destroy the handler
    my $got2 = $pg->on_notify;
    is(ref $got2, 'CODE', 'handler getter preserves handler on second call');
    # clear with undef
    $pg->on_notify(undef);
    my $got3 = $pg->on_notify;
    ok(!defined $got3 || $got3 eq '', 'handler cleared with undef');
    EV::break;
});

# --- connection info accessors ---
with_pg(cb => sub {
    my ($pg) = @_;
    ok($pg->server_version > 0, 'server_version is positive');
    ok(defined $pg->user && length($pg->user) > 0, 'user returns value');
    ok(defined $pg->host, 'host returns value');
    ok(defined $pg->port && $pg->port =~ /^\d+$/, 'port returns numeric value');
    is($pg->ssl_in_use, 0, 'ssl_in_use returns 0 for local conn');
    EV::break;
});

# --- set_client_encoding ---
with_pg(cb => sub {
    my ($pg) = @_;
    my $orig = $pg->client_encoding;
    ok(defined $orig, "client_encoding: $orig");
    $pg->set_client_encoding('SQL_ASCII');
    is($pg->client_encoding, 'SQL_ASCII', 'set_client_encoding to SQL_ASCII');
    $pg->set_client_encoding($orig);
    is($pg->client_encoding, $orig, 'restored original encoding');
    EV::break;
});

# --- NULL values in results ---
with_pg(cb => sub {
    my ($pg) = @_;
    $pg->query("select 42::int as num, null::text as empty", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'null test: no error');
        is($rows->[0][0], '42', 'null test: non-null value');
        ok(!defined $rows->[0][1], 'null test: NULL is undef');
        EV::break;
    });
});

# --- describe_portal ---
with_pg(cb => sub {
    my ($pg) = @_;
    $pg->query("begin", sub {
        my ($data, $err) = @_;
        ok(!$err, 'describe_portal: BEGIN');

        $pg->query("declare test_cursor cursor for select 1 as val", sub {
            my ($data2, $err2) = @_;
            ok(!$err2, 'describe_portal: DECLARE CURSOR');

            $pg->describe_portal("test_cursor", sub {
                my ($meta, $err3) = @_;
                ok(!$err3, 'describe_portal: no error');
                is($meta->{nfields}, 1, 'describe_portal: 1 field');
                is($meta->{fields}[0]{name}, 'val', 'describe_portal: field name is val');

                $pg->query("rollback", sub { EV::break });
            });
        });
    });
});

# --- COPY OUT ---
with_pg(cb => sub {
    my ($pg) = @_;
    $pg->query("create temp table copyout_test (id int, name text)", sub {
        my ($data, $err) = @_;
        ok(!$err, 'copy_out: created table');

        $pg->query("insert into copyout_test values (1, 'Alice'), (2, 'Bob')", sub {
            my ($data2, $err2) = @_;
            ok(!$err2, 'copy_out: inserted rows');

            my @rows;
            $pg->query("copy copyout_test to stdout", sub {
                my ($data3, $err3) = @_;
                if (defined $data3 && !ref($data3) && $data3 eq 'COPY_OUT') {
                    # drain copy data synchronously -- safe for small,
                    # local results where data is already buffered
                    while (1) {
                        my $line = $pg->get_copy_data;
                        if (!defined $line) {
                            # data not buffered yet; shouldn't happen
                            # for small local results
                            fail('copy data not available');
                            EV::break;
                            return;
                        }
                        elsif ($line eq '-1') {
                            last;
                        }
                        else {
                            push @rows, $line;
                        }
                    }
                    return;
                }
                is(scalar @rows, 2, 'copy_out: got 2 rows');
                EV::break;
            });
        });
    });
});

# --- on_drain accessor ---
with_pg(cb => sub {
    my ($pg) = @_;
    ok(!defined $pg->on_drain, 'on_drain: initially undef');
    my $drain_cb = sub { };
    $pg->on_drain($drain_cb);
    is(ref $pg->on_drain, 'CODE', 'on_drain: getter returns CODE ref');
    $pg->on_drain(undef);
    ok(!defined $pg->on_drain, 'on_drain: cleared with undef');
    EV::break;
});

# --- put_copy_end with error (abort COPY) ---
with_pg(cb => sub {
    my ($pg) = @_;
    $pg->query("create temp table copy_abort (id int)", sub {
        $pg->query("copy copy_abort from stdin", sub {
            my ($data, $err) = @_;
            if (($data // '') eq 'COPY_IN') {
                $pg->put_copy_data("1\n");
                $pg->put_copy_end("user aborted");
                return;
            }
            ok($err, 'copy abort: got error from put_copy_end errmsg');
            like($err, qr/user aborted/, 'copy abort: error contains abort message');
            EV::break;
        });
    });
});

# --- on_drain fires during COPY IN backpressure ---
# Shrink SO_SNDBUF so PQflush returns 1 (can't flush all), activating the
# write watcher.  When the socket drains, io_write_cb fires on_drain.
{
    my $drain_count = 0;
    my $pg;
    $pg = EV::Pg->new(
        conninfo => $conninfo,
        on_connect => sub {
            # shrink send buffer to force backpressure
            open my $fh, "+<&", $pg->socket or die "dup: $!";
            setsockopt($fh, SOL_SOCKET, SO_SNDBUF, pack("i", 4096))
                or diag "setsockopt SO_SNDBUF: $!";
            close $fh;

            $pg->query("create temp table drain_test (payload text)", sub {
                my (undef, $err) = @_;
                die $err if $err;

                $pg->on_drain(sub { $drain_count++ });

                $pg->query("copy drain_test from stdin", sub {
                    my ($data, $err) = @_;
                    if (($data // '') eq 'COPY_IN') {
                        # blast 16MB into a ~4KB socket buffer
                        my $chunk = ("x" x 8000) . "\n";
                        $pg->put_copy_data($chunk) for 1 .. 2_000;
                        $pg->put_copy_end;
                        return;
                    }
                    ok(!$err, 'drain: copy completed');
                    ok($drain_count > 0,
                       "drain: on_drain fired ($drain_count times)");
                    $pg->on_drain(undef);
                    EV::break;
                });
            });
        },
        on_error => sub { diag "Error: $_[0]"; EV::break },
    );
    my $t = EV::timer(15, 0, sub { EV::break });
    EV::run;
    $pg->finish if $pg && $pg->is_connected;
}

# --- "not connected" accessor branches ---
{
    my $pg = EV::Pg->new(on_error => sub {});
    # integer accessors return defaults
    is($pg->status, 1, 'status: CONNECTION_BAD when not connected');
    is($pg->transaction_status, 4, 'transaction_status: PQTRANS_UNKNOWN when not connected');
    is($pg->socket, -1, 'socket: -1 when not connected');
    is($pg->backend_pid, 0, 'backend_pid: 0 when not connected');
    is($pg->server_version, 0, 'server_version: 0 when not connected');
    is($pg->ssl_in_use, 0, 'ssl_in_use: 0 when not connected');
    is($pg->is_connected, 0, 'is_connected: 0 when not connected');
    # string accessors return undef
    ok(!defined $pg->error_message, 'error_message: undef when not connected');
    ok(!defined $pg->db, 'db: undef when not connected');
    ok(!defined $pg->user, 'user: undef when not connected');
    ok(!defined $pg->host, 'host: undef when not connected');
    ok(!defined $pg->port, 'port: undef when not connected');
    is($pg->pipeline_status, 0, 'pipeline_status: 0 when not connected');
}

# --- describe_portal error (non-existent portal) ---
with_pg(cb => sub {
    my ($pg) = @_;
    $pg->query("begin", sub {
        my (undef, $err) = @_;
        die $err if $err;
        $pg->describe_portal("nonexistent_portal", sub {
            my ($meta, $err) = @_;
            ok($err, 'describe_portal error: got error for non-existent portal');
            $pg->query("rollback", sub { EV::break });
        });
    });
});

# --- unescape_bytea with invalid input ---
# PQunescapeBytea on truly invalid input may still succeed (it's lenient),
# but a NULL return triggers croak
{
    # valid escaped bytea round-trips fine (already tested in t/08)
    # test that the class method works with empty input
    my $empty = EV::Pg->unescape_bytea('');
    is($empty, '', 'unescape_bytea: empty input returns empty string');
}

# --- connection failure ---
{
    my $err_received;
    my $pg_bad = EV::Pg->new(
        conninfo => 'host=127.0.0.1 port=1 dbname=nonexistent connect_timeout=1',
        on_connect => sub {
            fail('should not connect');
            EV::break;
        },
        on_error => sub {
            $err_received = $_[0];
            EV::break;
        },
    );
    my $timeout = EV::timer(3, 0, sub { EV::break });
    EV::run;
    ok(defined $err_received, 'connection failure: on_error called');
}
