use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);
use EV;
use EV::Pg;
use lib 't';
use TestHelper;

require_pg;
plan tests => 10;

# Test 1-2: connect failure — closed port
{
    my $err_msg;
    my $t0 = time;
    my $obj = EV::Pg->new(
        conninfo   => 'host=127.0.0.1 port=1 connect_timeout=2',
        on_connect => sub { EV::break },
        on_error   => sub { $err_msg = $_[0]; EV::break },
    );
    my $guard = EV::timer(10, 0, sub { EV::break });
    EV::run;
    my $elapsed = time - $t0;
    ok($err_msg, 'connect failure: got error');
    cmp_ok($elapsed, '<', 5, "connect failure: completed in ${elapsed}s");
}

# Test 3: statement_timeout — slow query aborted by server
with_pg(timeout => 15, cb => sub {
    my ($pg) = @_;
    $pg->query("set statement_timeout = 500", sub {
        my ($data, $err) = @_;
        die "set: $err" if $err;
        $pg->query("select pg_sleep(10)", sub {
            my ($rows, $qerr) = @_;
            ok($qerr, 'statement_timeout: got error on slow query');
            EV::break;
        });
    });
});

# Test 4-5: server-side terminate — on_error fires on killed connection
{
    my $victim_err;
    my $pg_victim;
    $pg_victim = EV::Pg->new(
        conninfo   => $conninfo,
        on_connect => sub {
            my $pid = $pg_victim->backend_pid;
            my $pg2;
            $pg2 = EV::Pg->new(
                conninfo   => $conninfo,
                on_connect => sub {
                    $pg2->query("select pg_terminate_backend($pid)", sub {
                        $pg2->finish;
                    });
                },
                on_error => sub { diag("pg2: $_[0]") },
            );
        },
        on_error => sub {
            $victim_err = $_[0];
            EV::break;
        },
    );
    my $guard = EV::timer(10, 0, sub { EV::break });
    EV::run;
    ok($victim_err, 'server terminate: on_error fired');
    ok(!$pg_victim->is_connected, 'server terminate: connection lost');
}

# Test 6-7: idle disconnect — idle_in_transaction_session_timeout
{
    my $err_received;
    my $pg_idle;
    $pg_idle = EV::Pg->new(
        conninfo   => $conninfo,
        on_connect => sub {
            $pg_idle->query("set idle_in_transaction_session_timeout = 1000", sub {
                my ($data, $err) = @_;
                die "set: $err" if $err;
                $pg_idle->query("begin", sub {
                    my ($data2, $err2) = @_;
                    die "begin: $err2" if $err2;
                    # now idle in transaction — server kills after 1s
                });
            });
        },
        on_error => sub {
            $err_received = $_[0];
            EV::break;
        },
    );
    my $guard = EV::timer(10, 0, sub { EV::break });
    EV::run;
    ok($err_received, 'idle disconnect: on_error fired');
    ok(!$pg_idle->is_connected, 'idle disconnect: connection lost');
}

# Test 8-9: connection loss during active query
{
    my $err_received;
    my $query_err;
    my $pg_active;
    $pg_active = EV::Pg->new(
        conninfo   => $conninfo,
        on_connect => sub {
            my $pid = $pg_active->backend_pid;

            $pg_active->query("select pg_sleep(10)", sub {
                my ($rows, $err) = @_;
                $query_err = $err;
                EV::break;
            });

            my $pg2;
            $pg2 = EV::Pg->new(
                conninfo   => $conninfo,
                on_connect => sub {
                    my $t; $t = EV::timer(0.3, 0, sub {
                        undef $t;
                        $pg2->query("select pg_terminate_backend($pid)", sub {
                            $pg2->finish;
                        });
                    });
                },
                on_error => sub { diag("pg2: $_[0]") },
            );
        },
        on_error => sub {
            $err_received = $_[0];
            EV::break;
        },
    );

    my $guard = EV::timer(10, 0, sub { EV::break });
    EV::run;

    ok($query_err || $err_received,
        'active query kill: got error');
    ok(!$pg_active->is_connected,
        'active query kill: connection lost');
}

# Test 10: reset after terminate recovers connection
{
    my $pg_reset;
    $pg_reset = EV::Pg->new(
        conninfo   => $conninfo,
        on_connect => sub {
            my $pid = $pg_reset->backend_pid;
            my $pg2;
            $pg2 = EV::Pg->new(
                conninfo   => $conninfo,
                on_connect => sub {
                    $pg2->query("select pg_terminate_backend($pid)", sub {
                        $pg2->finish;
                    });
                },
                on_error => sub { diag("pg2: $_[0]") },
            );
        },
        on_error => sub {
            # defer reset to next iteration (io_read_cb does cleanup_connection after on_error)
            my $t; $t = EV::timer(0, 0, sub {
                undef $t;
                $pg_reset->on_connect(sub {
                    $pg_reset->query("select 'recovered'", sub {
                        my ($rows, $err) = @_;
                        is($rows->[0][0], 'recovered',
                            'reset after terminate: query works');
                        EV::break;
                    });
                });
                $pg_reset->reset;
            });
        },
    );
    my $guard = EV::timer(10, 0, sub { EV::break });
    EV::run;
    $pg_reset->finish if $pg_reset && $pg_reset->is_connected;
}
