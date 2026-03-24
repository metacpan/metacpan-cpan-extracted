use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestMariaDB;
plan skip_all => 'No MariaDB/MySQL server' unless TestMariaDB::server_available();
plan tests => 30;
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

# --- Test 1-3: NULL values in text query result sets ---
with_mariadb(cb => sub {
    $m->q("select null, 1, null", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'NULL result: no error');
        ok(!defined $rows->[0][0], 'NULL result: first col is undef');
        is($rows->[0][1], '1', 'NULL result: non-NULL col has value');
        EV::break;
    });
});

# --- Test 4-6: prepared statement DML (INSERT) ---
with_mariadb(cb => sub {
    $m->q("create temporary table _test_stmt_dml (id int, v int)", sub {
        my (undef, $err) = @_;
        die "create: $err" if $err;
        $m->prepare("insert into _test_stmt_dml values (?, ?)", sub {
            my ($stmt, $err2) = @_;
            ok(!$err2, 'stmt DML: prepare ok');
            $m->execute($stmt, [1, 42], sub {
                my ($affected, $err3) = @_;
                ok(!$err3, 'stmt DML: no error');
                is($affected, 1, 'stmt DML: 1 row affected');
                $m->close_stmt($stmt, sub { EV::break });
            });
        });
    });
});

# --- Test 7-8: prepared statement error (invalid SQL) ---
with_mariadb(cb => sub {
    $m->prepare("not valid sql !!!", sub {
        my ($stmt, $err) = @_;
        ok($err, 'prepare error: got error for invalid SQL');
        ok(!defined $stmt, 'prepare error: no stmt handle');
        EV::break;
    });
});

# --- Test 9-12: croak() validation paths ---

# query with non-CODE callback
{
    my $obj;
    $obj = EV::MariaDB->new(
        TestMariaDB::connect_args(),
        on_connect => sub {
            eval { $obj->query("select 1", "not a coderef") };
            like($@, qr/CODE reference/, 'croak: query with non-CODE callback');

            eval { $obj->connect($TestMariaDB::host, $TestMariaDB::user, $TestMariaDB::pass, $TestMariaDB::db, $TestMariaDB::port) };
            like($@, qr/already connected/, 'croak: connect when already connected');

            eval { $obj->prepare("select 1", "not a coderef") };
            like($@, qr/CODE reference/, 'croak: prepare with non-CODE callback');

            eval { $obj->ping("not a coderef") };
            like($@, qr/CODE reference/, 'croak: ping with non-CODE callback');

            EV::break;
        },
        on_error => sub { diag("Error: $_[0]"); EV::break },
    );
    my $timeout = EV::timer(5, 0, sub { EV::break });
    EV::run;
    $obj->finish if $obj && $obj->is_connected;
}

# query when not connected
{
    my $obj = EV::MariaDB->new(on_error => sub {});
    eval { $obj->query("select 1", sub {}) };
    like($@, qr/not connected/, 'croak: query when not connected');
}

# escape when not connected
{
    my $obj = EV::MariaDB->new(on_error => sub {});
    eval { $obj->escape("test") };
    like($@, qr/not connected/, 'croak: escape when not connected');
}

# reset with no previous connection
{
    my $obj = EV::MariaDB->new(on_error => sub {});
    eval { $obj->reset };
    like($@, qr/no previous connection/, 'croak: reset with no previous connection');
}

# execute with non-ARRAY params
{
    my $obj;
    $obj = EV::MariaDB->new(
        TestMariaDB::connect_args(),
        on_connect => sub {
            eval { $obj->execute(0, "not_array", sub {}) };
            like($@, qr/invalid statement handle/, 'croak: execute with invalid stmt handle');
            EV::break;
        },
        on_error => sub { diag("Error: $_[0]"); EV::break },
    );
    my $timeout = EV::timer(5, 0, sub { EV::break });
    EV::run;
    $obj->finish if $obj && $obj->is_connected;
}

# --- Test 17-18: aliases ---
with_mariadb(cb => sub {
    is($m->errstr, $m->error_message, 'alias: errstr eq error_message');
    is($m->errno, $m->error_number, 'alias: errno eq error_number');
    EV::break;
});

# --- Test 19: lib_info class method ---
ok(length(EV::MariaDB->lib_info) > 0, 'lib_info: returns non-empty string');

# --- Test 20-21: on_connect / on_error getter ---
{
    my $obj = EV::MariaDB->new(on_error => sub { "test" });
    my $h = $obj->on_error;
    ok(ref $h eq 'CODE', 'on_error getter: returns CODE ref');
    my $h2 = $obj->on_connect;
    ok(!defined $h2, 'on_connect getter: returns undef when unset');
}

# --- Test 22-23: error_message after success ---
with_mariadb(cb => sub {
    $m->q("select 1", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'error_message after success: query ok');
        my $msg = $m->error_message;
        ok(!defined $msg || $msg eq '', 'error_message after success: undef or empty');
        EV::break;
    });
});

# --- Test 24-27: multi-statement drain + subsequent query ---
{
    $m = EV::MariaDB->new(
        TestMariaDB::connect_args(),
        multi_statements => 1,
        on_connect => sub {
            $m->q("select 1; select 2; select 3", sub {
                my ($rows, $err) = @_;
                ok(!$err, 'multi-drain: no error');
                is($rows->[0][0], 1, 'multi-drain: first result correct');
            });
            # this query must succeed after drain completes
            $m->q("select 'after_multi'", sub {
                my ($rows, $err) = @_;
                ok(!$err, 'multi-drain: subsequent query no error');
                is($rows->[0][0], 'after_multi', 'multi-drain: subsequent query correct');
                EV::break;
            });
        },
        on_error => sub {
            diag("Error: $_[0]");
            EV::break;
        },
    );
    my $timeout = EV::timer(10, 0, sub { diag("timeout"); EV::break });
    EV::run;
    $m->finish if $m && $m->is_connected;
}

# --- Test 28-30: prepared statement execute errors ---

# Test 28-29: wrong param count causes croak before bind
with_mariadb(cb => sub {
    $m->prepare("select ?, ?", sub {
        my ($stmt, $err) = @_;
        ok(!$err, 'stmt exec error: prepare ok');
        eval { $m->execute($stmt, [1], sub {}) };
        like($@, qr/parameter count mismatch/, 'stmt exec error: croak on wrong param count');
        $m->close_stmt($stmt, sub { EV::break });
    });
});

# Test 30: server-side execute error delivered via callback
with_mariadb(cb => sub {
    $m->q("create temporary table _test_exec_err (id int primary key)", sub {
        die $_[1] if $_[1];
        $m->q("insert into _test_exec_err values (1)", sub {
            die $_[1] if $_[1];
            $m->prepare("insert into _test_exec_err values (?)", sub {
                my ($stmt, $err) = @_;
                die $err if $err;
                $m->execute($stmt, [1], sub {
                    my ($rows, $err2) = @_;
                    ok($err2, 'stmt exec error: server error on duplicate key');
                    $m->close_stmt($stmt, sub { EV::break });
                });
            });
        });
    });
});
