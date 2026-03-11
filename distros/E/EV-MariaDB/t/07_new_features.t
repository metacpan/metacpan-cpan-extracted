use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestMariaDB;
plan skip_all => 'No MariaDB/MySQL server' unless TestMariaDB::server_available();
plan tests => 25;
use EV;
use EV::MariaDB;

my $m;

sub with_mariadb {
    my ($cb) = @_;
    $m = EV::MariaDB->new(
        TestMariaDB::connect_args(),
        on_connect => sub { $cb->() },
        on_error   => sub {
            diag("Error: $_[0]");
            EV::break;
        },
    );
    my $timeout = EV::timer(5, 0, sub { EV::break });
    EV::run;
    $m->finish if $m->is_connected;
}

# Test 1-2: error_number and sqlstate after successful connection
with_mariadb(sub {
    is($m->error_number, 0, 'errno: 0 after connect');
    ok(defined $m->sqlstate, 'sqlstate: defined after connect');
    EV::break;
});

# Test 3: errno alias
with_mariadb(sub {
    is($m->errno, 0, 'errno alias works');
    EV::break;
});

# Test 4-5: error_number and sqlstate after failed query
with_mariadb(sub {
    $m->q("invalid sql gibberish", sub {
        my ($rows, $err) = @_;
        ok($m->error_number > 0, 'errno: nonzero after error');
        like($m->sqlstate, qr/^\w{5}$/, 'sqlstate: 5-char code after error');
        EV::break;
    });
});

# Test 6-7: insert_id
with_mariadb(sub {
    $m->q("create temporary table _test_insert_id (id int auto_increment primary key, v int)", sub {
        my (undef, $err) = @_;
        die "create: $err" if $err;
        $m->q("insert into _test_insert_id (v) values (42)", sub {
            my (undef, $err2) = @_;
            die "insert: $err2" if $err2;
            my $id = $m->insert_id;
            ok(defined $id, 'insert_id: defined after insert');
            cmp_ok($id, '>', 0, 'insert_id: positive after auto_increment insert');
            EV::break;
        });
    });
});

# Test 8: warning_count
with_mariadb(sub {
    # A clean query should have 0 warnings
    $m->q("select 1", sub {
        is($m->warning_count, 0, 'warning_count: 0 after clean query');
        EV::break;
    });
});

# Test 9: info — null for most queries, defined for insert/update/etc
with_mariadb(sub {
    $m->q("select 1", sub {
        my $info = $m->info;
        # info is typically undef for select
        ok(!defined $info || $info eq '', 'info: undef or empty after select');
        EV::break;
    });
});

# Test 10-11: ping
with_mariadb(sub {
    $m->ping(sub {
        my ($ok, $err) = @_;
        ok(!$err, 'ping: no error');
        is($ok, 1, 'ping: returns 1 on success');
        EV::break;
    });
});

# Test 12-13: select_db
with_mariadb(sub {
    $m->select_db($TestMariaDB::db, sub {
        my ($ok, $err) = @_;
        ok(!$err, 'select_db: no error');
        is($ok, 1, 'select_db: returns 1 on success');
        EV::break;
    });
});

# Test 14: select_db with invalid db
with_mariadb(sub {
    $m->select_db("nonexistent_db_xyzzy_" . $$, sub {
        my ($ok, $err) = @_;
        ok($err, 'select_db: error for nonexistent db');
        EV::break;
    });
});

# Test 15-16: change_user (back to same user)
with_mariadb(sub {
    $m->change_user($TestMariaDB::user, $TestMariaDB::pass, $TestMariaDB::db, sub {
        my ($ok, $err) = @_;
        ok(!$err, 'change_user: no error');
        is($ok, 1, 'change_user: returns 1 on success');
        EV::break;
    });
});

# Test 17: change_user with undef db
with_mariadb(sub {
    $m->change_user($TestMariaDB::user, $TestMariaDB::pass, undef, sub {
        my ($ok, $err) = @_;
        ok(!$err, 'change_user: undef db ok');
        EV::break;
    });
});

# Test 18-19: reset_connection
with_mariadb(sub {
    # Set a session variable, then reset, then check it's gone
    $m->q("set \@test_var = 123", sub {
        my (undef, $err) = @_;
        die "set: $err" if $err;
        $m->reset_connection(sub {
            my ($ok, $err2) = @_;
            ok(!$err2, 'reset_connection: no error');
            is($ok, 1, 'reset_connection: returns 1');
            EV::break;
        });
    });
});

# Test 20: reset_connection actually resets session state
with_mariadb(sub {
    $m->q("set \@test_rc = 999", sub {
        my (undef, $err) = @_;
        die "set: $err" if $err;
        $m->reset_connection(sub {
            my ($ok, $err2) = @_;
            die "reset: $err2" if $err2;
            $m->q("select \@test_rc", sub {
                my ($rows, $err3) = @_;
                die "select: $err3" if $err3;
                ok(!defined $rows->[0][0] || $rows->[0][0] eq '',
                    'reset_connection: session variable cleared');
                EV::break;
            });
        });
    });
});

# Test 21-22: stmt_reset
with_mariadb(sub {
    $m->prepare("select ?", sub {
        my ($stmt, $err) = @_;
        die "prepare: $err" if $err;
        ok($stmt, 'stmt_reset: prepared ok');
        $m->stmt_reset($stmt, sub {
            my ($ok, $err2) = @_;
            ok(!$err2, 'stmt_reset: no error');
            # verify stmt still works after reset
            $m->execute($stmt, [7], sub {
                my ($rows, $err3) = @_;
                die "execute after reset: $err3" if $err3;
                $m->close_stmt($stmt, sub { EV::break });
            });
        });
    });
});

# Test 23-24: multi_statements option
{
    $m = EV::MariaDB->new(
        TestMariaDB::connect_args(),
        multi_statements => 1,
        on_connect => sub {
            $m->q("select 1; select 2", sub {
                my ($rows, $err) = @_;
                ok(!$err, 'multi_statements: no error on multi-query');
                # first result set
                is($rows->[0][0], 1, 'multi_statements: first result correct');
                EV::break;
            });
        },
        on_error => sub {
            diag("Error: $_[0]");
            EV::break;
        },
    );
    my $timeout = EV::timer(5, 0, sub { EV::break });
    EV::run;
    $m->finish if $m->is_connected;
}

# Test 25: connection option — charset
{
    $m = EV::MariaDB->new(
        TestMariaDB::connect_args(),
        charset    => 'utf8mb4',
        on_connect => sub {
            is($m->character_set_name, 'utf8mb4', 'charset option: utf8mb4 applied');
            EV::break;
        },
        on_error => sub {
            diag("Error: $_[0]");
            EV::break;
        },
    );
    my $timeout = EV::timer(5, 0, sub { EV::break });
    EV::run;
    $m->finish if $m->is_connected;
}
