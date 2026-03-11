use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestMariaDB;
plan skip_all => 'No MariaDB/MySQL server' unless TestMariaDB::server_available();
plan tests => 10;
use Time::HiRes qw(time);
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
    my $timeout = EV::timer(15, 0, sub { EV::break });
    EV::run;
    $m->finish if $m && $m->is_connected;
}

# Test 1-2: connect_timeout — non-routable IP hangs until timeout
{
    my $err_msg;
    my $t0 = time;
    my $obj = EV::MariaDB->new(
        host            => '10.255.255.1',
        user            => 'x',
        connect_timeout => 2,
        on_connect      => sub { EV::break },
        on_error        => sub { $err_msg = $_[0]; EV::break },
    );
    my $guard = EV::timer(10, 0, sub { EV::break });
    EV::run;
    my $elapsed = time - $t0;
    ok($err_msg, 'connect_timeout: got error');
    cmp_ok($elapsed, '<', 8, "connect_timeout: completed in ${elapsed}s");
}

# Test 3: read_timeout — slow query aborted
with_mariadb(
    read_timeout => 1,
    cb => sub {
        $m->q("select sleep(10)", sub {
            my ($rows, $err) = @_;
            ok($err, 'read_timeout: got error on slow query');
            EV::break;
        });
    },
);

# Test 4-5: server-side kill — query on killed connection gets error
with_mariadb(cb => sub {
    my $tid = $m->thread_id;
    my $m2;
    $m2 = EV::MariaDB->new(
        TestMariaDB::connect_args(),
        on_connect => sub {
            $m2->q("kill $tid", sub {
                my (undef, $kerr) = @_;
                ok(!$kerr, 'server kill: kill command succeeded');
                # query on the killed connection
                $m->q("select 1", sub {
                    my ($rows, $err) = @_;
                    ok($err, 'server kill: query on killed conn gets error');
                    $m2->finish;
                    EV::break;
                });
            });
        },
        on_error => sub { diag("m2 error: $_[0]"); EV::break },
    );
});

# Test 6-7: wait_timeout — idle disconnect
with_mariadb(cb => sub {
    $m->q("set wait_timeout=1", sub {
        my (undef, $err) = @_;
        die "set: $err" if $err;
        my $t; $t = EV::timer(3, 0, sub {
            undef $t;
            $m->ping(sub {
                my ($ok, $perr) = @_;
                ok($perr, 'wait_timeout: ping after idle gets error');
                # connection is dead, queue a query to confirm
                $m->q("select 1", sub {
                    my ($rows, $qerr) = @_;
                    ok($qerr, 'wait_timeout: query after idle gets error');
                    EV::break;
                });
            });
        });
    });
});

# Test 8-9: on_error fires on connection loss during pipeline
with_mariadb(cb => sub {
    my $tid = $m->thread_id;
    my $on_error_msg;
    my $err_count = 0;
    $m->on_error(sub {
        $on_error_msg = $_[0];
    });

    for my $i (1..5) {
        $m->q("select sleep(0.2)", sub {
            my ($rows, $err) = @_;
            $err_count++ if $err;
        });
    }

    my $m2;
    $m2 = EV::MariaDB->new(
        TestMariaDB::connect_args(),
        on_connect => sub {
            # kill after a short delay so some queries are in flight
            my $t; $t = EV::timer(0.3, 0, sub {
                undef $t;
                $m2->q("kill $tid", sub {
                    $m2->finish;
                });
            });
        },
        on_error => sub { diag("m2 error: $_[0]") },
    );

    my $guard = EV::timer(10, 0, sub { EV::break });
    # wait until all callbacks have fired
    my $check; $check = EV::timer(0.1, 0.1, sub {
        if ($m->pending_count == 0 || $on_error_msg || $err_count > 0) {
            undef $check;
            ok($err_count > 0 || $on_error_msg,
                'pipeline kill: got errors or on_error');
            ok(!$m->is_connected || $err_count > 0,
                'pipeline kill: connection lost or errors received');
            EV::break;
        }
    });
});

# Test 10: reset after timeout recovers connection
with_mariadb(
    read_timeout => 1,
    cb => sub {
        $m->q("select sleep(10)", sub {
            my ($rows, $err) = @_;
            # should have timed out
            $m->on_connect(sub {
                $m->q("select 'recovered'", sub {
                    my ($rows2, $err2) = @_;
                    is($rows2->[0][0], 'recovered',
                        'reset after timeout: query works');
                    EV::break;
                });
            });
            $m->reset;
        });
    },
);
