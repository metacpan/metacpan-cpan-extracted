use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestMariaDB;
plan skip_all => 'No MariaDB/MySQL server' unless TestMariaDB::server_available();
plan tests => 24;
use EV;
use EV::MariaDB;
use POSIX ();

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

# --- HIGH: finish() from callback (tests 1-3) ---
with_mariadb(cb => sub {
    my @results;
    my $checked;
    for my $i (1..3) {
        $m->q("select $i", sub {
            my ($rows, $err) = @_;
            push @results, $err ? "err" : $rows->[0][0];
            $m->finish if $i == 1;
            if (@results == 3 && !$checked++) {
                is($results[0], '1', 'finish from cb: first query ok');
                is($results[1], 'err', 'finish from cb: second got error');
                is($results[2], 'err', 'finish from cb: third got error');
                EV::break;
            }
        });
    }
});

# --- HIGH: reset() from callback (tests 4-7) ---
{
    my @results;
    $m = EV::MariaDB->new(
        TestMariaDB::connect_args(),
        on_connect => sub {
            for my $i (1..3) {
                $m->q("select $i", sub {
                    my ($rows, $err) = @_;
                    push @results, $err ? "err" : $rows->[0][0];
                    if ($i == 1) {
                        $m->on_connect(sub {
                            $m->q("select 'post_reset'", sub {
                                my ($r, $e) = @_;
                                is($results[0], '1', 'reset from cb: first query ok');
                                like($results[1], qr/^err/, 'reset from cb: second got error');
                                like($results[2], qr/^err/, 'reset from cb: third got error');
                                ok(!$e && $r->[0][0] eq 'post_reset',
                                   'reset from cb: query after reconnect works');
                                EV::break;
                            });
                        });
                        $m->reset;
                    }
                });
            }
        },
        on_error => sub { diag("Error: $_[0]"); EV::break },
    );
    my $timeout = EV::timer(10, 0, sub { diag("timeout"); EV::break });
    EV::run;
    $m->finish if $m && $m->is_connected;
}

# --- HIGH: multi-statement secondary error (tests 8-10) ---
{
    my ($first_ok, $on_err_msg, $subsequent_ok);
    $m = EV::MariaDB->new(
        TestMariaDB::connect_args(),
        multi_statements => 1,
        on_connect => sub {
            $m->q("select 1; INVALID SQL HERE", sub {
                my ($rows, $err) = @_;
                $first_ok = !$err && $rows->[0][0] == 1;
            });
            $m->q("select 'after_err'", sub {
                my ($rows, $err) = @_;
                $subsequent_ok = !$err && $rows->[0][0] eq 'after_err';
                ok($first_ok, 'multi-stmt secondary error: first result ok');
                ok($on_err_msg, 'multi-stmt secondary error: on_error fired');
                ok($subsequent_ok, 'multi-stmt secondary error: subsequent query works');
                EV::break;
            });
        },
        on_error => sub {
            $on_err_msg = $_[0];
        },
    );
    my $timeout = EV::timer(10, 0, sub { diag("timeout"); EV::break });
    EV::run;
    $m->finish if $m && $m->is_connected;
}

# --- HIGH: send failure via dup2 (tests 11-12) ---
# Replace socket fd with /dev/null so reads return EOF, triggering error paths
with_mariadb(cb => sub {
    my (@errors, $done);
    my $on_err;
    $m->on_error(sub { $on_err = $_[0] });
    for my $i (1..3) {
        $m->q("select $i", sub {
            my ($rows, $err) = @_;
            push @errors, $err if $err;
            if (++$done == 3) {
                is(scalar @errors, 3, 'send failure: all error callbacks fired');
                ok($on_err || $errors[0], 'send failure: error message received');
                EV::break;
            }
        });
    }
    # replace socket with /dev/null — fd stays valid for epoll, but reads return EOF
    open my $devnull, '<', '/dev/null' or die "open /dev/null: $!";
    POSIX::dup2(fileno($devnull), $m->socket);
    close $devnull;
});

# --- MEDIUM: write_timeout smoke (test 13) ---
with_mariadb(
    write_timeout => 5,
    cb => sub {
        $m->q("select 1", sub {
            my ($rows, $err) = @_;
            ok(!$err && $rows->[0][0] == 1, 'write_timeout: query succeeds');
            EV::break;
        });
    },
);

# --- MEDIUM: compress smoke (test 14) ---
with_mariadb(
    compress => 1,
    cb => sub {
        $m->q("select 1", sub {
            my ($rows, $err) = @_;
            ok(!$err && $rows->[0][0] == 1, 'compress: query succeeds');
            EV::break;
        });
    },
);

# --- MEDIUM: _set_option unknown key (test 15) ---
{
    my $obj = EV::MariaDB->new(on_error => sub {});
    eval { $obj->_set_option("bogus_key", 1) };
    like($@, qr/unknown option/, '_set_option: unknown key croaks');
}

# --- MEDIUM: accessors on non-connected object (tests 16-17) ---
{
    my $obj = EV::MariaDB->new(on_error => sub {});
    my @numeric = (
        $obj->is_connected,   $obj->error_number,
        $obj->warning_count,  $obj->server_version,
        $obj->thread_id,      $obj->pending_count,
        $obj->socket,
    );
    my @sv = (
        $obj->error_message,  $obj->sqlstate,
        $obj->insert_id,      $obj->info,
        $obj->server_info,    $obj->host_info,
        $obj->character_set_name,
    );
    ok(1, 'accessors on disconnected: numeric accessors no crash');
    ok(1, 'accessors on disconnected: SV accessors no crash');
}

# --- MEDIUM: escape UTF-8 warning (test 18) ---
with_mariadb(
    charset => 'latin1',
    cb => sub {
        my $utf8_str = "\x{263a}";  # smiley, sets SvUTF8
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        $m->escape($utf8_str);
        ok(scalar(grep { /non-utf8/ } @warnings), 'escape: UTF-8 on latin1 warns');
        EV::break;
    },
);

# --- MEDIUM: integer/float prepared stmt params (test 19) ---
with_mariadb(cb => sub {
    $m->prepare("select ?, ?, ?", sub {
        my ($stmt, $err) = @_;
        die "prepare: $err" if $err;
        $m->execute($stmt, [42, 3.14, "hello"], sub {
            my ($rows, $err2) = @_;
            ok(!$err2
               && $rows->[0][0] == 42
               && abs($rows->[0][1] - 3.14) < 0.001
               && $rows->[0][2] eq 'hello',
               'prepared params: int, float, string correct');
            $m->close_stmt($stmt, sub { EV::break });
        });
    });
});

# --- MEDIUM: multi-statement DML secondary (tests 20-21) ---
{
    my ($drain_ok, $subsequent_ok);
    $m = EV::MariaDB->new(
        TestMariaDB::connect_args(),
        multi_statements => 1,
        on_connect => sub {
            $m->q("select 1; do 1; select 2", sub {
                my ($rows, $err) = @_;
                $drain_ok = !$err && $rows->[0][0] == 1;
            });
            $m->q("select 'after_dml'", sub {
                my ($rows, $err) = @_;
                $subsequent_ok = !$err && $rows->[0][0] eq 'after_dml';
                ok($drain_ok, 'multi-stmt DML: drain handles mixed result sets');
                ok($subsequent_ok, 'multi-stmt DML: subsequent query works');
                EV::break;
            });
        },
        on_error => sub { diag("Error: $_[0]"); EV::break },
    );
    my $timeout = EV::timer(10, 0, sub { diag("timeout"); EV::break });
    EV::run;
    $m->finish if $m && $m->is_connected;
}

# --- LOW: reconnect/disconnect aliases (tests 22-23) ---
{
    $m = EV::MariaDB->new(
        TestMariaDB::connect_args(),
        on_connect => sub { EV::break },
        on_error   => sub { diag("Error: $_[0]"); EV::break },
    );
    my $timeout = EV::timer(10, 0, sub { diag("timeout"); EV::break });
    EV::run;

    $m->on_connect(sub {
        ok($m->is_connected, 'reconnect alias: reconnected');
        $m->disconnect;
        ok(!$m->is_connected, 'disconnect alias: disconnected');
        EV::break;
    });
    $m->reconnect;
    $timeout = EV::timer(10, 0, sub { diag("timeout"); EV::break });
    EV::run;
}

# --- LOW: on_error(undef) / on_connect(undef) clear handler (test 24) ---
{
    my $obj = EV::MariaDB->new(
        on_error   => sub { "err" },
        on_connect => sub { "conn" },
    );
    $obj->on_error(undef);
    $obj->on_connect(undef);
    ok(!defined $obj->on_error && !defined $obj->on_connect,
       'handler clear: on_error(undef) and on_connect(undef) clear handlers');
}
